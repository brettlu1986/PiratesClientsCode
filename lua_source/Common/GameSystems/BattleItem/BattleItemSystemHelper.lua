-----------------------------------------------------
--File Name    : BattleItemSystemHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-08-11
--Description  : 物品操作System的工具类
-----------------------------------------------------
local BattleItemCategoryDataTable = require("BattleItemCategoryDataTable")
local BattleItemRoomDef = require("BattleItemRoomDef")

local PropName = require("PropName")
local MathUtil = require("MathUtil")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")
local BattleItemDataTable = require("BattleItemDataTable")
local MaterialItemHelper = require("MaterialItemHelper")
local ItemDataTable = require("ItemDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local FFAItemIni = require("FFAItemIni")
local BattleItemSourceDef = require("BattleItemSourceDef")

local BattleItemSystemHelper = {}

local ClientEventDef = nil
local BattleItemSystemClient = nil
local BattleItemSystemServer = nil

BattleItemSystemHelper.tbCategoryOperationHelpers = nil

BattleItemSystemHelper.tbItemClasses = nil

-----------------------------------------------local function------------------------------------------------

local SORT_WEIGHTS = {}
SORT_WEIGHTS[BattleItemCategoryDef.SHIP] = 5
SORT_WEIGHTS[BattleItemCategoryDef.SHIP_WEAPON] = 4
SORT_WEIGHTS[BattleItemCategoryDef.SHIP_PART] = 3
SORT_WEIGHTS[BattleItemCategoryDef.HUMAN_WEAPON] = 2
SORT_WEIGHTS[BattleItemCategoryDef.HUMAN_ARMOR] = 1

local function GetPlayer(nCharacterInstanceId, bIsClient)
    local tbPlayer = nil
    if bIsClient then
        local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
        tbPlayer = GamePlayerSelfHelper:Get()
    else
        local GameObjectSystem = dynamic_require("GameObjectSystem")
        tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    end
    return tbPlayer
end

-- 获得物品component
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @return 物品component
local function GetBattleItemComponent(self, nCharacterInstanceId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetBattleItemComponent()
    else
        return BattleItemSystemServer:GetBattleItemComponent(nCharacterInstanceId)
    end
end

local function GetSortWeight(nCategory)
    local nWeight = SORT_WEIGHTS[nCategory]
    if nWeight == nil then
        nWeight = 0
    end
    return nWeight
end

local function fnSortByCategory(Item1, Item2)
    local nItemTemplateId1 = Item1:GetTemplateId()
    local nItemTemplateId2 = Item2:GetTemplateId()

    local tbItemTemplate1 = Item1:GetTemplate()
    local tbItemTemplate2 = Item2:GetTemplate()

    local nCategory1 = tbItemTemplate1.nCategory
    local nCategory2 = tbItemTemplate2.nCategory

    local nWeight1 = GetSortWeight(nCategory1)
    local nWeight2 = GetSortWeight(nCategory2)

    if nWeight1 ~= nWeight2 then
        return nWeight1 > nWeight2
    end

    return nItemTemplateId1 < nItemTemplateId2
end

local function FuncSortItemData(tbItemDataA, tbItemDataB)
    return tbItemDataA.tbBattleItemTemplate.nId < tbItemDataB.tbBattleItemTemplate.nId
end

local function UnequipAndEquipItems(tbItems, bIsClient)
    if tbItems == nil or #tbItems == 0 then
        return
    end
    table.sort(tbItems, fnSortByCategory)
    for i = 1, #tbItems do
        local nIndex = #tbItems - i + 1
        local Item = tbItems[nIndex]
        if Item:GetCategory() ~= BattleItemCategoryDef.SHIP then
            Item:OnUnequip(bIsClient)
        end
    end

    for _, v in ipairs(tbItems) do
        if v:GetCategory() ~= BattleItemCategoryDef.SHIP then
            v:OnEquip(bIsClient)
        end
    end
end

-- @param tbItemCostDatas 需要消耗的物品列表，eg：
--         local tbItemCostDatas = {}
--         local tbItemCostData = {}
--         tbItemCostData.nItemTemplateId = 11010001
--         tbItemCostData.nItemCount = 1
--         table.insert(tbItemCostDatas,tbItemCostData)
-- @return bResult, tbItemIdsNotEnough   bResult是true表示成功，false表示失败，tbItemIdsNotEnough表示不足的物品templateId的列表
local function VerifyItemsCount(BattleItemComponent, tbItemCostDatas)
    local tbItemIdsNotEnough = {}
    for _, v in ipairs(tbItemCostDatas) do
        local nItemTemplateId = v.nItemTemplateId
        local bEnough = BattleItemComponent:IsItemEnough(v.nItemTemplateId, v.nItemCount)
        if not bEnough then
            table.insert(tbItemIdsNotEnough, nItemTemplateId)
        end
    end
    return (#tbItemIdsNotEnough) == 0, tbItemIdsNotEnough
end

local function AddFailure(bSucceeded, nFailureType, Param, tbFailures)
    if not bSucceeded then
        local tbFailure = {}
        tbFailure.nType = nFailureType
        tbFailure.Params = Param
        table.insert(tbFailures, tbFailure)
    end
end

local function VerifyItemsCountAndAddFailure(BattleItemComponent, tbItemCostDatas, tbFailures, nFailureType)
    local bSucceeded, tbItemIdsNotEnough = VerifyItemsCount(BattleItemComponent, tbItemCostDatas)
    AddFailure(bSucceeded, nFailureType, tbItemIdsNotEnough, tbFailures)
end

local function VerifyPrerequisiteItems(BattleItemComponent, nPrerequisiteId, tbFailures)
    local tbItemCostDatas = {}
    local tbItemCostData = {}
    tbItemCostData.nItemTemplateId = nPrerequisiteId
    tbItemCostData.nItemCount = 1
    table.insert(tbItemCostDatas, tbItemCostData)
    VerifyItemsCountAndAddFailure(BattleItemComponent, tbItemCostDatas, tbFailures, ItemBuildingVerificationFailureDef.PREREQUISITE_ITEMS_NOT_ENOUGH)
end

local function VerifyKeyItems(BattleItemComponent, tbKeyItemIds, tbFailures)
    local tbItemCostDatas = {}
    for _, v in ipairs(tbKeyItemIds) do
        local tbItemCostData = {}
        tbItemCostData.nItemTemplateId = v
        tbItemCostData.nItemCount = 1
        table.insert(tbItemCostDatas, tbItemCostData)
    end
    VerifyItemsCountAndAddFailure(BattleItemComponent, tbItemCostDatas, tbFailures, ItemBuildingVerificationFailureDef.KEY_ITEMS_NOT_ENOUGH)
end

local function VerifyMaterialCostItems(BattleItemComponent, tbCosts, tbFailures)
    local tbItemCostDatas = {}
    for nIndex, nCount in ipairs(tbCosts) do
        if nCount > 0 then
            local tbItemCostData = {}
            local nItemTemplateId = MaterialItemHelper:GetMaterialTemplateId(nIndex)
            assert(nItemTemplateId ~= nil , "cannot find material template!index:"..nIndex)
            tbItemCostData.nItemTemplateId = nItemTemplateId
            tbItemCostData.nItemCount = nCount
            table.insert(tbItemCostDatas, tbItemCostData)
        end
    end
    VerifyItemsCountAndAddFailure(BattleItemComponent, tbItemCostDatas, tbFailures, ItemBuildingVerificationFailureDef.MATERIALS_NOT_ENOUGH)
end

local function VerifyCustomBuildingConditions(nCharacterInstanceId, BattleItemComponent, nItemTemplateId, nSlotIndex, tbFailures)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(tbItemTemplate.nCategory)
    local bSucceeded = false
    local tbVerifyFailures = nil
    if BattleItemComponent.bIsClient then
        bSucceeded, tbVerifyFailures = ItemCategoryOperationHelper:VerifyCustomBuildingConditionsOnClient(nItemTemplateId, nSlotIndex)
    else
        bSucceeded, tbVerifyFailures = ItemCategoryOperationHelper:VerifyCustomBuildingConditionsOnServer(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    end
    if not bSucceeded then
        for _, v in pairs(tbVerifyFailures) do
            table.insert(tbFailures, v)
        end
    end
end

local function FillPreparationShip(tbBuildDatas, tbShipPreparationTemplateIds)
    for _, v in pairs(tbShipPreparationTemplateIds) do
        if v == nil then
            error("item id is nil!")
        end
        local tbLobbyItemTemplate = ItemDataTable:GetTemplate(v)
        if tbLobbyItemTemplate == nil then
            error("Cannot find lobby item!"..v)
        end
        if tbLobbyItemTemplate.nCategory == ItemCategoryDef.SHIP then
            local nBattleItemTemplateId = tbLobbyItemTemplate.nBattleItemId
            local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nBattleItemTemplateId)
            local bContains = false
            for _, tbTemplate in ipairs(tbBuildDatas) do
                if nBattleItemTemplateId == tbTemplate.nId then
                    bContains = true
                end
            end
            if not bContains then
                local tbData = {}
                tbData.tbBuildItemTemplate = BattleItemBuildDataTable:GetBuildTemplate(nBattleItemTemplateId)
                tbData.tbBattleItemTemplate = tbBattleItemTemplate

                table.insert(tbBuildDatas, tbData)
            else
                logerror("Item template id already can build!", nBattleItemTemplateId)
            end
        end
    end
end

local function FillPreparationShipWeapon(tbBuildDatas, tbShipPreparationTemplateIds)
    for _, nPreparationItemTemplateId in pairs(tbShipPreparationTemplateIds) do
        local tbLobbyItemTemplate = ItemDataTable:GetTemplate(nPreparationItemTemplateId)
        if tbLobbyItemTemplate.nCategory == ItemCategoryDef.SHIP_WEAPON then
            local nBattleItemTemplateId = tbLobbyItemTemplate.nBattleItemId
            local tbData = {}
            tbData.tbBuildItemTemplate = BattleItemBuildDataTable:GetBuildTemplate(nBattleItemTemplateId)
            local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nBattleItemTemplateId)
            tbData.tbBattleItemTemplate = tbBattleItemTemplate

            table.insert(tbBuildDatas, tbData)
        end
    end
end

local function FillPreparationShipPart(tbBuildDatas, tbShipPreparationTemplateIds)
    for _, nPreparationItemTemplateId in pairs(tbShipPreparationTemplateIds) do
        local tbLobbyItemTemplate = ItemDataTable:GetTemplate(nPreparationItemTemplateId)
        if tbLobbyItemTemplate.nCategory == ItemCategoryDef.SHIP_PART then
            local tbBattleItemIdList = tbLobbyItemTemplate.tbBattleItemIdList
            for _, nBattleItemTemplateId in pairs(tbBattleItemIdList) do
                local tbData = {}
                tbData.tbBuildItemTemplate = BattleItemBuildDataTable:GetBuildTemplate(nBattleItemTemplateId)
                local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nBattleItemTemplateId)
                tbData.tbBattleItemTemplate = tbBattleItemTemplate

                table.insert(tbBuildDatas, tbData)
            end
        end
    end
end

local function FillDefaultCanBuildItem(tbBuildDatas, nCategory)
    local tbBuildTemplates = BattleItemBuildDataTable:GetDefaultBuildTemplatesByCategory(nCategory)
    for _, v in pairs(tbBuildTemplates) do
        local tbData = {}
        tbData.tbBuildItemTemplate = v
        tbData.tbBattleItemTemplate = BattleItemDataTable:GetTemplate(v.nId)

        table.insert(tbBuildDatas, tbData)
    end
end

local function FireBattleItemEquippedEvent(tbPlayer, Item, nOwnerInstanceId, nSlotIndex, nStackCount, bIsClient)
    if bIsClient then
        if not ClientEventDef then
            ClientEventDef = require("ClientEventDef")
        end
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT, Item, nOwnerInstanceId, nSlotIndex, nStackCount)
    else
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_EQUIPED_SERVER, tbPlayer, Item, nOwnerInstanceId, nSlotIndex, nStackCount, BattleItemSourceDef.CHANG_POS)
    end
end

local function FireBattleItemUnequippedEvent(nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nStackCount, bIsClient)
    if bIsClient then
        if not ClientEventDef then
            ClientEventDef = require("ClientEventDef")
        end
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_UNEQUIPED_CLIENT, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nStackCount)
    else
        local bHasNewItemOnSlot = true
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_UNEQUIPED_SERVER, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nStackCount, bHasNewItemOnSlot)
    end
end

local function FireBeforeBattleItemExchangeStorageLocationEvent(Item1, Item2, bIsClient)
    if bIsClient then
        if not ClientEventDef then
            ClientEventDef = require("ClientEventDef")
        end
        EventManager:OnFireEvent(ClientEventDef.EV_BEFORE_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, Item1, Item2)
    else
        EventManager:OnFireEvent(CommonEventDef.EV_BEFORE_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_SERVER, Item1, Item2)
    end
end

local function FireBattleItemExchangeStorageLocationEvent(Item1, Item2, bIsClient)
    if bIsClient then
        if not ClientEventDef then
            ClientEventDef = require("ClientEventDef")
        end
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_CLIENT, Item1, Item2)
    else
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_EXCHANGE_STORAGE_LOCATION_SERVER, Item1, Item2)
    end
end

local function InitItemCategoryOperationHelper(self)
    self.tbCategoryOperationHelpers = {}
    local tbTemplates = BattleItemCategoryDataTable:GetAllTemplate()
    for nCategory, tbTemplate in pairs(tbTemplates) do
        self.tbCategoryOperationHelpers[nCategory] = require(tbTemplate.szItemCategoryOperationHelper)
    end
end

local function InitItemClasses(self)
    self.tbItemClasses = {}
    local tbCategoryInfoTable = BattleItemDataTable:GetAllCategoryInfoTable()
    for nCategory, tbSubCategoryInfos in pairs(tbCategoryInfoTable) do
        local nCategoryItemClasses = self.tbItemClasses[nCategory]
        if nCategoryItemClasses == nil then
            nCategoryItemClasses = {}
            self.tbItemClasses[nCategory] = nCategoryItemClasses
        end
        for nSubcategory, tbInfo in pairs(tbSubCategoryInfos) do
            nCategoryItemClasses[nSubcategory] = require(tbInfo.szItemClass)
        end
    end
end
-----------------------------------------------给外部的接口------------------------------------------------------
-- 获得BattleItemSystem
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return bIsClient是true就返回BattleItemSystemClient，bIsClient是false就返回BattleItemSystemServer
function BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    if bIsClient then
        if not BattleItemSystemClient then
            BattleItemSystemClient = require("BattleItemSystemClient")
        end
        return BattleItemSystemClient
    else
        if not BattleItemSystemServer then
            BattleItemSystemServer = require("BattleItemSystemServer")
        end
        return BattleItemSystemServer
    end
end

-- 获得BattleItemSystemServer
-- @return BattleItemSystemServer
function BattleItemSystemHelper:GetBattleItemSystemServer()
    return self:GetBattleItemSystem(false)
end

-- 获得BattleItemSystemClient
-- @return BattleItemSystemClient
function BattleItemSystemHelper:GetBattleItemSystemClient()
    return self:GetBattleItemSystem(true)
end

-- 获得某个物品实例
-- @param nItemInstanceId 物品实例的唯一id
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return Item的实例
function BattleItemSystemHelper:GetItem(nItemInstanceId, bIsClient)
    local BattleItemSystem = nil
    if bIsClient then
        BattleItemSystem = require("BattleItemSystemClient")
    else
        BattleItemSystem = require("BattleItemSystemServer")
    end
    return BattleItemSystem:GetItem(nItemInstanceId)
end

-- 获得玩家已经建造的舰船的最高等级
function BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetShipBuiltGrade()
    else
        return BattleItemSystemServer:GetShipBuiltGrade(nCharacterInstanceId)
    end
end

-- 人的武器是否无限弹药
-- @return true表示无限弹药，false表示不是无限弹药
function BattleItemSystemHelper:IsHumanBulletInfinite()
    local tbBullet = FFAItemIni.tbBullet
    return tbBullet.bHumanBulletInfinite
end

-- 船的武器是否无限弹药
-- @return true表示无限弹药，false表示不是无限弹药
function BattleItemSystemHelper:IsShipBulletInfinite()
    local tbBullet = FFAItemIni.tbBullet
    return tbBullet.bShipBulletInfinite
end

-- 查询一装备的某个类型某个槽位的物品,如果没安装就返回nil
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nSlotIndex 槽位id,如果不填就返回第一个槽位的物品
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return 被安装在某个槽位上的Item的实例
function BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, nCategory, nOwnerInstanceId, nSlotIndex, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetEquippedItem(nCategory, nOwnerInstanceId, nSlotIndex)
    else
        return BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId,nCategory, nOwnerInstanceId, nSlotIndex)
    end
end

-- 查询已经装备的某个类型的物品列表，如果没安装就返回空table
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param nOwnerInstanceId 装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId，如果是装在武器上的，就是武器的nItemInstanceId
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return tbEquippedItems (key:nSlotIndex, value:Item) eg:
--         local tbEquippedItems = {}
--         tbEquippedItems[1] = BattleItemBase()
--         tbEquippedItems[3] = BattleItemBase()
--         return tbEquippedItems
function BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, nCategory, nOwnerInstanceId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetEquippedItems(nCategory, nOwnerInstanceId)
    else
        return BattleItemSystemServer:GetEquippedItems(nCharacterInstanceId, nCategory, nOwnerInstanceId)
    end
end


-- 是否可以往背包或船舱里增加某个类型的物品
-- @param nItemTemplateId 物品类型id
-- @return ture表示可以加到背包或船舱里，false表示不能
function BattleItemSystemHelper:CanAddToInventoryRoom(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(self, nCharacterInstanceId, bIsClient)
    local InventoryRoom = self:GetRoomInOneComponent(BattleItemComponent, tbTemplate.nCategory, nCharacterInstanceId, false)
    if InventoryRoom == nil then
        return true
    end
    return InventoryRoom:CanAddToInventoryRoom(nItemTemplateId, bIsClient)
end

-- 查询某个大类型的所有物品列表(未装配的)
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return tbItems 物品的数组 eg:
--         local tbItems = {}
--         table.insert(tbItems, BattleItemBase())
--         table.insert(tbItems, BattleItemBase())
--         return tbItems
function BattleItemSystemHelper:GetUnequippedItemsByCategory(nCharacterInstanceId, nItemCategory, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetUnequippedItemsByCategory(nItemCategory)
    else
        return BattleItemSystemServer:GetUnequippedItemsByCategory(nCharacterInstanceId, nItemCategory)
    end
end

-- 查询一件物品被安装的槽位
-- @param nItemInstanceId 物品实例的唯一id
-- @return nSlotIndex 槽位id
-- @param bIsClient true表示客户端调用，false表示服务端调用
function BattleItemSystemHelper:GetEquippedSlotIndex(nItemInstanceId, bIsClient)
    local Item = self:GetItem(nItemInstanceId, bIsClient)
    if Item == nil then
        logwarning("BattleItemSystemHelper:GetEquippedSlotIndex failed! Cannot find Item!".. nItemInstanceId)
        return
    end
    return Item:GetStorageLocation().nSlotIndex
end

-- 获得已装配的某个物品类型的数量
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nItemTemplateId 物品的template id
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemHelper:GetEquippedItemCount(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetEquippedItemCount(nOwnerInstanceId, nItemTemplateId)
    else
        return BattleItemSystemServer:GetEquippedItemCount(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId)
    end
end

-- 获得未装配的某个物品类型的数量
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetUnequippedItemCount(nItemTemplateId)
    else
        return BattleItemSystemServer:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId)
    end
end

-- 获得某个物品类型的数量(装配未装配都有)
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemHelper:GetItemCount(nCharacterInstanceId, nItemTemplateId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetItemCount(nItemTemplateId)
    else
        return BattleItemSystemServer:GetItemCount(nCharacterInstanceId, nItemTemplateId)
    end
end

-- 获得未装备的最小叠加数量的物品instance
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nItemInstance nil表示没有这个类型的物品，否则返回未装备的最小叠加数量的物品instance
function BattleItemSystemHelper:GetUnequippedLeastStackCountInstance(nCharacterInstanceId, nItemTemplateId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetUnequippedLeastStackCountInstance(nItemTemplateId)
    else
        return BattleItemSystemServer:GetUnequippedLeastStackCountInstance(nCharacterInstanceId, nItemTemplateId)
    end
end

-- 获得未装备的最小叠加数量的物品instanceid
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nItemInstanceId nil表示没有这个类型的物品，否则返回未装备的最小叠加数量的物品instanceid
function BattleItemSystemHelper:GetUnequippedLeastStackCountInstanceId(nCharacterInstanceId, nItemTemplateId, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
    else
        return BattleItemSystemServer:GetUnequippedLeastStackCountInstanceId(nCharacterInstanceId, nItemTemplateId)
    end
end

-- 获得背包容量（承重上限）
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return 背包容量
function BattleItemSystemHelper:GetInventoryCapacity(nCharacterInstanceId, nItemRoomType, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetInventoryCapacity(nItemRoomType)
    else
        return BattleItemSystemServer:GetInventoryCapacity(nCharacterInstanceId, nItemRoomType)
    end
end

-- 获得背包当前承重（背包内物品重量和）
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return 背包当前承重
function BattleItemSystemHelper:GetAllItemsWeight(nCharacterInstanceId, nItemRoomType, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetAllItemsWeight(nItemRoomType)
    else
        return BattleItemSystemServer:GetAllItemsWeight(nCharacterInstanceId, nItemRoomType)
    end
end

-- 获得背包格子数上限
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return 背包格子数上限
function BattleItemSystemHelper:GetMaxInventorySlots(nCharacterInstanceId, nItemRoomType, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetMaxInventorySlots(nItemRoomType)
    else
        return BattleItemSystemServer:GetMaxInventorySlots(nCharacterInstanceId, nItemRoomType)
    end
end

-- 获得背包当前占用格子数
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return 背包当前占用格子数
function BattleItemSystemHelper:GetInventorySlotsCount(nCharacterInstanceId, nItemRoomType, bIsClient)
    self:GetBattleItemSystem(bIsClient)
    if bIsClient then
        return BattleItemSystemClient:GetInventorySlotsCount(nItemRoomType)
    else
        return BattleItemSystemServer:GetInventorySlotsCount(nCharacterInstanceId, nItemRoomType)
    end
end


-- 获得建造的材料消耗
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 要建造物品的template id
-- @param bIsClient true表示客户端调用，false表示服务端调用
-- @return tbCosts, bHasDec
-- tbCosts 需要材料的消耗
-- bHasDec 是否有消耗降低的效果
function BattleItemSystemHelper:GetBuildMaterialCost(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbPlayer = GetPlayer(nCharacterInstanceId, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local nPercentage = 0
    if (nCategory == BattleItemCategoryDef.SHIP_WEAPON) or (nCategory == BattleItemCategoryDef.HUMAN_WEAPON) then
        nPercentage = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nWeaponBuildingMaterialRatio)
    elseif (nCategory == BattleItemCategoryDef.SHIP_PART) or (nCategory == BattleItemCategoryDef.HUMAN_ARMOR) then
        nPercentage = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nPartBuildingMaterialRatio)
    elseif nCategory == BattleItemCategoryDef.SHIP then
        nPercentage = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nShipBuildingMaterialRatio)
    end
    local tbItemBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    local tbCosts = tbItemBuildTemplate.tbCosts
    if tbCosts and #tbCosts > 0 and nPercentage ~= nil and nPercentage > 0 then
        nPercentage = MathUtil.Round(nPercentage * 10000) / 10000
        local tbCostsAfterDec = {}
        for i, v in ipairs(tbCosts) do
            local nCost = MathUtil.Round(v * nPercentage)
            tbCostsAfterDec[i] = nCost
        end
        return tbCostsAfterDec, true
    else
        return tbCosts, false
    end
end

-- 获取实际可以某种物品填加的数量
-- @param nCharacterInstanceId
-- @param nItemTemplateId
-- @param nCount: 想填加的数量
-- @return  根据背包的容量，实际可以填加的数量
function BattleItemSystemHelper:GetAvailableAddCount(nCharacterInstanceId, nItemTemplateId, nCount, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory

    local nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nCategory)
    local BattleItemComponent = GetBattleItemComponent(self, nCharacterInstanceId, bIsClient)
    local NewItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType,  nCharacterInstanceId)
    local tbCheckResult = NewItemRoom:CheckAddItem(bIsClient, nItemTemplateId, nCount)
    if not tbCheckResult.nCanAddCount then
        return 0
    end
    return tbCheckResult.nCanAddCount
end

---------------------------BattleItemSystemClient和BattleItemSystemServer使用的工具方法---------------------------------------------

function BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    local tbHelper = self.tbCategoryOperationHelpers[nCategory]
    if not tbHelper then
        error("Cannot find item operation helper!"..nCategory)
    end
    return tbHelper
end

-- 如果是未装备的room类型，则nOwnerInstanceId可以不填
function BattleItemSystemHelper:GetRoomInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, bEquipped)
    local nRoomType = -1
    if bEquipped then
        nRoomType = BattleItemCategoryDataTable:GetEquippedRoomType(nItemCategory)
    else
        nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nItemCategory)
    end
    local ItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nOwnerInstanceId)
    return ItemRoom
end

function BattleItemSystemHelper:GetRoomItemsInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, bEquipped)
    local ItemRoom = self:GetRoomInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, bEquipped)
    if ItemRoom == nil then
        return {}
    end
    if not BattleItemRoomDef:IsEquipmentRoom(ItemRoom:GetRoomType()) then
        error("BattleItemSystemHelper:GetRoomItemsInOneComponent failed! room is not equipped room!"
        .."nItemCategory:"..nItemCategory..", nOwnerInstanceId:"..nOwnerInstanceId)
    end
    return ItemRoom:GetRoomItems(BattleItemComponent.bIsClient)
end

function BattleItemSystemHelper:GetEquippedItemBySlotInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, nSlotIndex)
    local ItemRoom = self:GetRoomInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, true)
    if ItemRoom == nil then
        log("ItemRoom is nil", nItemCategory, nOwnerInstanceId, nSlotIndex)
        return nil
    end
    if not BattleItemRoomDef:IsEquipmentRoom(ItemRoom:GetRoomType()) then
        error("BattleItemSystemHelper:GetEquippedItemBySlotInOneComponent failed! room is not equipped room!"
        .."nItemCategory:"..nItemCategory..", nOwnerInstanceId:"..nOwnerInstanceId)
    end
    return ItemRoom:GetItemBySlotIndex(nSlotIndex, BattleItemComponent.bIsClient)
end

-- 移除物品上的物品的装配效果
function BattleItemSystemHelper:OnUnequipItemsOnItem(BattleItemComponent, Item)
    local nItemInstanceId = Item:GetInstanceId()

    local tbEquipmentRooms = BattleItemComponent:GetAllEquipmentItemRoomsWhichOwnerIsItem(nItemInstanceId)
    if tbEquipmentRooms ~= nil then
        for _, EquipmentRoom in pairs(tbEquipmentRooms) do
            for _, nEquipmentItemInstanceId in pairs(EquipmentRoom:GetAllItemInstanceIds()) do
                local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(BattleItemComponent.bIsClient)
                local EquipmentItem = BattleItemSystem:GetItem(nEquipmentItemInstanceId)
                EquipmentItem:OnUnequip(BattleItemComponent.bIsClient)
            end
        end
    end
end

function BattleItemSystemHelper:OnUnequipItem(BattleItemComponent, Item)
    local nItemInstanceId = Item:GetInstanceId()
    -- 移除物品上的物品的装配效果
    self:OnUnequipItemsOnItem(BattleItemComponent, Item)

    -- 移除物品的装配效果
    local OldItemRoom = BattleItemComponent:GetItemRoom(nItemInstanceId)
    if OldItemRoom ~= nil and BattleItemRoomDef:IsEquipmentRoom(OldItemRoom:GetRoomType()) then
        Item:OnUnequip(BattleItemComponent.bIsClient)
    end
end

-- 生效物品上的物品的装配效果
function BattleItemSystemHelper:OnEquipItemsOnItem(BattleItemComponent, Item)
    local nItemInstanceId = Item:GetInstanceId()
    local tbEquipmentRooms = BattleItemComponent:GetAllEquipmentItemRoomsWhichOwnerIsItem(nItemInstanceId)
    if tbEquipmentRooms ~= nil then
        for _, EquipmentRoom in pairs(tbEquipmentRooms) do
            for _, nEquipmentItemInstanceId in pairs(EquipmentRoom:GetAllItemInstanceIds()) do
                local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(BattleItemComponent.bIsClient)
                local EquipmentItem = BattleItemSystem:GetItem(nEquipmentItemInstanceId)
                EquipmentItem:OnEquip(BattleItemComponent.bIsClient)
            end
        end
    end
end

function BattleItemSystemHelper:OnEquipItem(BattleItemComponent, Item)
    local nItemInstanceId = Item:GetInstanceId()
    -- 生效物品的装配效果
    local OldItemRoom = BattleItemComponent:GetItemRoom(nItemInstanceId)
    if OldItemRoom ~= nil and BattleItemRoomDef:IsEquipmentRoom(OldItemRoom:GetRoomType()) then
        Item:OnEquip(BattleItemComponent.bIsClient)
    end

    -- 生效物品上的物品的装配效果
    self:OnEquipItemsOnItem(BattleItemComponent, Item)
end

function BattleItemSystemHelper:OnUnequipAllItem(BattleItemComponent)
    local tbEquipmentRooms = BattleItemComponent:GetAllEquipmentItemRooms()
    if tbEquipmentRooms ~= nil then
        for _, EquipmentRoom in pairs(tbEquipmentRooms) do
            for _, nEquipmentItemInstanceId in pairs(EquipmentRoom:GetAllItemInstanceIds()) do
                local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(BattleItemComponent.bIsClient)
                local EquipmentItem = BattleItemSystem:GetItem(nEquipmentItemInstanceId)
                -- todo @zhiyuan 后面调整物品安装层级关系来去掉这个特殊判断
                if EquipmentItem:GetCategory() ~= BattleItemCategoryDef.SHIP then
                    self:OnUnequipItem(BattleItemComponent, EquipmentItem)
                end
            end
        end
    end
end

function BattleItemSystemHelper:OnUnequipAllShipEquipItems(BattleItemComponent)
    local tbEquipmentRooms = BattleItemComponent:GetAllEquipmentShipItemRooms()
    if tbEquipmentRooms ~= nil then
        for _, EquipmentRoom in pairs(tbEquipmentRooms) do
            for _, nEquipmentItemInstanceId in pairs(EquipmentRoom:GetAllItemInstanceIds()) do
                local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(BattleItemComponent.bIsClient)
                local EquipmentItem = BattleItemSystem:GetItem(nEquipmentItemInstanceId)
                -- todo @zhiyuan 后面调整物品安装层级关系来去掉这个特殊判断
                if EquipmentItem:GetCategory() ~= BattleItemCategoryDef.SHIP then
                    self:OnUnequipItem(BattleItemComponent, EquipmentItem)
                end
            end
        end
    end
end

-- 玩家是否可见（可见：地上，背包里会出现  不可见：地上，背包里不会出现）
function BattleItemSystemHelper:CanKnownByPlayer(nItemTemplateId)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:CanKnownByPlayer(nItemTemplateId)
end

function BattleItemSystemHelper:CanAutoEquipWhenOwnerChanged(Item)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:CanAutoEquipWhenOwnerChanged()
end

function BattleItemSystemHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlot, Item, bIsClient)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlot, Item, bIsClient)
end

function BattleItemSystemHelper:CanExchangeStorageLocation(nCharacterInstanceId, Item1, Item2, bIsClient)
    local nRoomType1, nOwnerInstanceId1, nSlotIndex1 = Item1:SplitAndGetStorageLocation()
    local nRoomType2, nOwnerInstanceId2, nSlotIndex2 = Item2:SplitAndGetStorageLocation()

    if (not BattleItemRoomDef:IsEquipmentRoom(nRoomType1))
            or (not BattleItemRoomDef:IsEquipmentRoom(nRoomType2)) then
        if not bIsClient then
            logerror("ExchangeStorageLocation failed!Item not equip!", nRoomType1, nRoomType2)
        end
        return false
    end

    if (not self:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId2, nSlotIndex2, Item1, bIsClient))
            or (not self:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId1, nSlotIndex1, Item2, bIsClient)) then
        if not bIsClient then
            logerror("ExchangeStorageLocation failed!Item slot not compatibility!",
                Item1:GetTemplateId(), nRoomType1, nOwnerInstanceId1, nSlotIndex1,
                Item2:GetTemplateId(), nRoomType2, nOwnerInstanceId2, nSlotIndex2)
        end
        return false
    end

    return true
end

function BattleItemSystemHelper:ExchangeStorageLocation(BattleItemComponent, Item1, Item2)
    local tbPlayer = BattleItemComponent.Owner
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local bIsClient = BattleItemComponent.bIsClient

    FireBeforeBattleItemExchangeStorageLocationEvent(Item1, Item2, bIsClient)

    self:OnUnequipItem(BattleItemComponent, Item1)
    self:OnUnequipItem(BattleItemComponent, Item2)

    local nRoomType1, nOwnerInstanceId1, nSlotIndex1 = Item1:SplitAndGetStorageLocation()
    local nRoomType2, nOwnerInstanceId2, nSlotIndex2 = Item2:SplitAndGetStorageLocation()

    local nItemInstanceId1 = Item1:GetInstanceId()
    local nItemTemplateId1 = Item1:GetTemplateId()
    local nItemInstanceId2 = Item2:GetInstanceId()
    local nItemTemplateId2 = Item2:GetTemplateId()

    local ItemRoom1 = BattleItemComponent:GetItemRoom(nItemInstanceId1)
    local ItemRoom2 = BattleItemComponent:GetItemRoom(nItemInstanceId2)

    ItemRoom1:RemoveItemBySlotIndex(nSlotIndex1)
    FireBattleItemUnequippedEvent(nCharacterInstanceId, nItemInstanceId1, nItemTemplateId1, nRoomType1, nOwnerInstanceId1, nSlotIndex1, Item1:GetStackCount(), bIsClient)

    ItemRoom2:RemoveItemBySlotIndex(nSlotIndex2)
    FireBattleItemUnequippedEvent(nCharacterInstanceId, nItemInstanceId2, nItemTemplateId2, nRoomType2, nOwnerInstanceId2, nSlotIndex2, Item2:GetStackCount(), bIsClient)

    ItemRoom2:AddItem(nItemInstanceId1, nSlotIndex2)
    Item1:SetStorageLocation(nRoomType2, nOwnerInstanceId2, nSlotIndex2)

    ItemRoom1:AddItem(nItemInstanceId2, nSlotIndex1)
    Item2:SetStorageLocation(nRoomType1, nOwnerInstanceId1, nSlotIndex1)

    self:OnEquipItem(BattleItemComponent, Item1)
    FireBattleItemEquippedEvent(tbPlayer, Item1, nOwnerInstanceId2, nSlotIndex2, Item1:GetStackCount(), bIsClient)
    self:OnEquipItem(BattleItemComponent, Item2)
    FireBattleItemEquippedEvent(tbPlayer, Item2, nOwnerInstanceId1, nSlotIndex1, Item2:GetStackCount(), bIsClient)

    FireBattleItemExchangeStorageLocationEvent(Item1, Item2, bIsClient)
end

-- 某个道具是否是这个玩家在这个副本中可以建造的
function BattleItemSystemHelper.IsItemAvailableBuild(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, nCategory, bIsClient)
    if tbBuildDatas == nil then
        return false
    end
    for _, v in pairs(tbBuildDatas) do
        if v.tbBattleItemTemplate.nId == nItemTemplateId then
            return true
        end
    end
    return false
end

-- 某个玩家在当前副本中某个类型的所有可以建造的道具
function BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, nCategory, bIsClient)
    local tbShipPreparationTemplateIds = nil
    local tbPlayer = GetPlayer(nCharacterInstanceId, bIsClient)
    if bIsClient then
        tbShipPreparationTemplateIds = BattleItemSystemClient:GetShipPreparationTemplatesIds()
    else
        tbShipPreparationTemplateIds = tbPlayer.tbPrepareInfo.tbShipPreparationTemplateIds
    end
    if tbShipPreparationTemplateIds == nil or #tbShipPreparationTemplateIds == 0 then
        return nil
    end

    local tbBuildDatas = {}
    if nCategory == BattleItemCategoryDef.SHIP then
        FillPreparationShip(tbBuildDatas, tbShipPreparationTemplateIds)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        FillPreparationShipWeapon(tbBuildDatas, tbShipPreparationTemplateIds)
    elseif nCategory == BattleItemCategoryDef.SHIP_PART then
        FillPreparationShipPart(tbBuildDatas, tbShipPreparationTemplateIds)
    elseif nCategory == BattleItemCategoryDef.HUMAN_WEAPON or nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        FillDefaultCanBuildItem(tbBuildDatas, nCategory)
    end
    table.sort(tbBuildDatas, FuncSortItemData)
    return tbBuildDatas
end

-- 某个玩家在当前副本中某个类型的所有可以建造的道具(人的武器和人的护甲才能使用)
function BattleItemSystemHelper:GetAvailableHumanBuildTemplatesBySlot(nCharacterInstanceId, nCategory, nSlotIndex, bIsClient)
    local tbBuildDatas = {}
    local EquippedItem = nil
    if nCategory == BattleItemCategoryDef.HUMAN_WEAPON or nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        EquippedItem = self:GetEquippedItem(nCharacterInstanceId, nCategory, nCharacterInstanceId, nSlotIndex, bIsClient)
        if EquippedItem then
            local nItemTemplateId = EquippedItem:GetTemplateId()
            local tbSameBaseBuildItemTemplates = BattleItemBuildDataTable:GetSameBaseBuildItemTemplates(nItemTemplateId)
            if tbSameBaseBuildItemTemplates then
                for i, v in ipairs(tbSameBaseBuildItemTemplates) do
                    if i == 1 then  -- 把不能建造的1级人武器和人装备也放进列表
                        local nBaseItemTemplateId = v.nBaseItemTemplateId
                        local tbData = {}
                        tbData.tbBuildItemTemplate = nil
                        tbData.tbBattleItemTemplate = BattleItemDataTable:GetTemplate(nBaseItemTemplateId)
                        table.insert(tbBuildDatas, tbData)
                    end
                    local tbData = {}
                    tbData.tbBuildItemTemplate = v
                    tbData.tbBattleItemTemplate = BattleItemDataTable:GetTemplate(v.nId)
                    table.insert(tbBuildDatas, tbData)
                end
            end
        end
    end
    table.sort(tbBuildDatas, FuncSortItemData)
    return tbBuildDatas, EquippedItem
end

-- 校验物品建造
-- @return bSucceeded, tbFailures
--         bSucceeded为true表示校验成功，false表示校验失败
--         tbFailures 表示失败原因的列表，eg：
--         local tbFailures = {}
--         local tbFailure = {}
--         tbFailure.nType = ItemBuildingVerificationFailureDef.MATERIALS_NOT_ENOUGH
--         tbFailure.Params = nil --不同类型的参数不同，详情见ItemBuildingVerificationFailureDef
--         table.insert(tbFailures, tbFailure)
function BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
    local BattleItemComponent = GetBattleItemComponent(self, nCharacterInstanceId, bIsClient)

    local tbFailures = {}

    local tbItemBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    if tbItemBuildTemplate == nil then
        AddFailure(false, ItemBuildingVerificationFailureDef.ITEM_TYPE_CANNOT_BUILD, nil, tbFailures)
        return false, tbFailures
    end

    local nPrerequisiteId = tbItemBuildTemplate.nPrerequisiteId
    if nPrerequisiteId > 0 then
        VerifyPrerequisiteItems(BattleItemComponent, nPrerequisiteId, tbFailures)
    end

    local tbKeyItemIds = tbItemBuildTemplate.tbKeyItemIds
    if tbKeyItemIds and #tbKeyItemIds > 0 then
        VerifyKeyItems(BattleItemComponent, tbKeyItemIds, tbFailures)
    end

    local tbCosts, _ = self:GetBuildMaterialCost(nCharacterInstanceId, nItemTemplateId, bIsClient)
    if tbCosts and #tbCosts > 0 then
        VerifyMaterialCostItems(BattleItemComponent, tbCosts, tbFailures)
    end

    VerifyCustomBuildingConditions(nCharacterInstanceId, BattleItemComponent, nItemTemplateId, nSlotIndex, tbFailures)

    if #tbFailures == 0 then
        return true, nil
    else
        return false, tbFailures
    end
end

function BattleItemSystemHelper:OnChangeToHuman(BattleItemComponent, bIsClient)
    local tbItems = BattleItemComponent:GetAllEquipmentItemsOnHuman()
    UnequipAndEquipItems(tbItems, bIsClient)
end

function BattleItemSystemHelper:OnChangeToShip(BattleItemComponent, bIsClient)
    local tbItems = BattleItemComponent:GetAllEquipmentItemsOnShip()
    UnequipAndEquipItems(tbItems, bIsClient)
end

function BattleItemSystemHelper:InitItemClasses()
    InitItemCategoryOperationHelper(self)
    InitItemClasses(self)
    BattleItemRoomDef:FillItemRoomClassTable()
end

function BattleItemSystemHelper:GetItemClass(nCategory, nSubCategory)
    local nCategoryItemClasses = self.tbItemClasses[nCategory]
    if nCategoryItemClasses == nil then
        error("Cannot find item class!"..nCategory)
    end
    local tbClass = nCategoryItemClasses[nSubCategory]
    if tbClass == nil then
        error("Cannot find item class!"..nCategory..", "..nSubCategory)
    end
    return tbClass
end

return BattleItemSystemHelper
