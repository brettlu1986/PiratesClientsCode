-----------------------------------------------------
--File Name    : BattleItemSystemServer.lua
--Author       : zhiyuan
--Create Time  : 2018-08-24
--Description  : Client上物品操作System
-----------------------------------------------------
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local ProtoDC = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local BattleItemFactory = require("BattleItemFactory")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local ProgressBarHelper = require("ProgressBarHelper")
local ItemDataTable = require("ItemDataTable")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local BattleItemAutoPickUpHelper = require("BattleItemAutoPickUpHelper")
local HumanWeaponHelper = require("HumanWeaponHelper")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local BattleItemSystemClient = {}

BattleItemSystemClient.tbAllItems = {}
BattleItemSystemClient.nBuiltGrade = nil
BattleItemSystemClient.nLastRequestBuildTemplateId = nil

-----------------------------------------local function---------------------------------------------
local function AddItem(self, NewItem)
    self.tbAllItems[NewItem:GetInstanceId()] = NewItem
end

local function RemoveItem(self, nInstanceId)
    local Item = self.tbAllItems[nInstanceId]
    Item:OnDestroy()
    self.tbAllItems[nInstanceId] = nil
end

local function RemoveItems(self, tbItemInstanceIds)
    for _, v in ipairs(tbItemInstanceIds) do
        RemoveItem(self, v)
    end
end

local function HasBattleItemComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local BattleItemComponentClient = PlayerSelf.BattleItemComponentClient
    if BattleItemComponentClient == nil then
        return false
    end
    return true
end

local function GetBattleItemComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local BattleItemComponentClient = PlayerSelf.BattleItemComponentClient
    if BattleItemComponentClient == nil then
        error("GetBattleItemComponent failed!BattleItemComponentClient == nil!")
    end
    return BattleItemComponentClient
end

local function GetCharacterInstanceId()
    return PlayerSelfHelper:Get().nServerInstanceId
end

local function AllItemsUninit(self)
    local PlayerSelf = PlayerSelfHelper:Get()
    if PlayerSelf and HasBattleItemComponent() then
        local BattleItemComponent = GetBattleItemComponent()
        BattleItemComponent:RemoveAllItemOnCharacter()
    end

    for _,v in pairs(self.tbAllItems) do
        v:OnDestroy()
    end
    self.tbAllItems = {}
end

local function AddItemToNewRoom(self, BattleItemComponent, Item)
    local nItemInstanceId = Item:GetInstanceId()
    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local Room = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nOwnerInstanceId)
    Room:AddItem(nItemInstanceId, nSlotIndex)
    if BattleItemRoomDef:IsEquipmentRoom(Room:GetRoomType()) then
        Item:OnEquip(true)
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT, Item, nOwnerInstanceId, nSlotIndex, Item:GetStackCount())
    end
end

local function RemoveItemFromOldRoom(self, BattleItemComponent, Item)
    local nStackCount = Item:GetStackCount()
    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local nItemInstanceId = Item:GetInstanceId()
    local nItemTemplateId = Item:GetTemplateId()

    local Room = BattleItemComponent:GetItemRoom(nItemInstanceId)

    if Room then
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
            BattleItemSystemHelper:OnUnequipItem(BattleItemComponent, Item)
        end
        Room:RemoveItemByInstanceId(nItemInstanceId)
    end
    if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
        local nCharacterInstanceId = GetCharacterInstanceId()
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_UNEQUIPED_CLIENT, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nStackCount)
    end
end

local function GetInventoryRoom(nItemRoomType)
    local BattleItemComponent = GetBattleItemComponent()
    local nCharacterInstanceId = GetCharacterInstanceId()
    return BattleItemComponent:GetOrCreateItemRoom(nItemRoomType, nCharacterInstanceId)
end

local function RequestCancelBuildItem()
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_CancelBuildItem)
end

local function OnPlayerSelfReady(self)
    local tbPlayer = PlayerSelfHelper:Get()
    local BattleItemComponent = GetBattleItemComponent()
    if tbPlayer:IsShip() then
        BattleItemSystemHelper:OnChangeToShip(BattleItemComponent, true)
    elseif tbPlayer:IsHuman() then
        BattleItemSystemHelper:OnChangeToHuman(BattleItemComponent, true)
    end
end

local function OnPlayerDie(self, Deader)
    if Deader == PlayerSelfHelper:Get() then
        AllItemsUninit(self)
    end
end

local function FireBuildFinishEvent(self, nItemInstanceId)
    local nCharacterInstanceId = GetCharacterInstanceId()
    local Item = self:GetItem(nItemInstanceId)
    local nItemTemplateId = Item:GetTemplateId()
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP then
        local nShipId = tbItemTemplate.nShipId
        EventManager:OnFireEvent(ClientEventDef.EV_SHIP_BUILD_FINISH_CLIENT, nCharacterInstanceId, nShipId)
    end
    local PlayerSelf = PlayerSelfHelper:Get()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_BUILD_FINISH_CLIENT, PlayerSelf, nItemInstanceId, nItemTemplateId)
end

local function FireBeginBuildItemEvent(nItemTemplateId)
    EventManager:OnFireEvent(ClientEventDef.EV_BEGIN_ITEM_BUILD, nItemTemplateId)
end

local function FireBuildItemCancelEvent()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_BUILD_CANCEL_CLIENT)
end

local function CheckPlayerDead(szFunName)
    local PlayerSelf = PlayerSelfHelper:Get()
    if PlayerSelf:IsDead() then
        log(szFunName, " failed! Player is already dead!")
        return true
    end
    return false
end

local function CancelReservedItemWhenAddItem(self, NewItem)
    local nItemTemplateId = NewItem:GetTemplateId()
    local nReservedItemTemplateId = self:GetReservedItemTemplateId()
    if nItemTemplateId == nReservedItemTemplateId then
        self:CancelReserveItemBuild(nReservedItemTemplateId)
    end
end

function BattleItemSystemClient:CheckReservedItem()
    local nReservedItemTemplateId = self:GetReservedItemTemplateId()
    if not nReservedItemTemplateId then
        return
    end
    local tbReservedItemTemplate = BattleItemDataTable:GetTemplate(nReservedItemTemplateId)
    local nReservedItemCategory = tbReservedItemTemplate.nCategory

    local nCharacterInstanceId = GetCharacterInstanceId()
    if nReservedItemCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        local tbMatchedSlots = HumanWeaponHelper.GetMatchedSlotIndexes(nReservedItemTemplateId)
        local bNeedCancel = true
        for _, nSlotIndex in ipairs(tbMatchedSlots) do
            local tbWeaponItem = self:GetEquippedItem(BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlotIndex)
            if tbWeaponItem and BattleItemBuildDataTable:IsSameBaseItemTemplateIds(nReservedItemTemplateId, tbWeaponItem:GetTemplateId()) and tbReservedItemTemplate.nGrade > tbWeaponItem:GetGrade() then
                bNeedCancel = false
                break
            end
        end
        if bNeedCancel then
            self:CancelReserveItemBuild(nReservedItemTemplateId)
        end
    elseif nReservedItemCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        local tbArmorItem = self:GetEquippedItem(BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId, tbReservedItemTemplate.nArmorCategory)
        if not tbArmorItem then
            self:CancelReserveItemBuild(nReservedItemTemplateId)
        end
    end
end

local function GetShipBuiltGrade(self)
    return self.nBuiltGrade
end

local function SetShipBuiltGrade(self, nGrade)
    self.nBuiltGrade = nGrade
    EventManager:OnFireEvent(ClientEventDef.EV_SHIP_BUILD_GRADE_CHANGED_CLIENT, PlayerSelfHelper:Get(), nGrade)
end

-----------------------------------------System Init UnInit---------------------------------------------

-- local function Init
function BattleItemSystemClient:Init()
    BattleItemSystemHelper:InitItemClasses()
    EventManager:BindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
    return true
end

function BattleItemSystemClient:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
    AllItemsUninit(self)
end

-----------------------------------------给外部的查询接口---------------------------------------------

-- 获得某个物品实例
-- @param nItemInstanceId 物品实例的唯一id
-- @return Item的实例
function BattleItemSystemClient:GetItem(nItemInstanceId)
    if nItemInstanceId == nil or nItemInstanceId <= 0 then
        return nil
    end
    return self.tbAllItems[nItemInstanceId]
end

-- 获得某个物品实例
-- @param nItemInstanceId 物品实例的唯一id
-- @return Item的实例
function BattleItemSystemClient:GetPlayerServerInstanceId()
    return PlayerSelfHelper:GetServerInstanceId()
end

-- 获得物品component
-- @return 物品component
function BattleItemSystemClient:GetBattleItemComponent()
    return GetBattleItemComponent()
end

-- 获得船已经建造的最大等级
function BattleItemSystemClient:GetShipBuiltGrade()
    return GetShipBuiltGrade(self)
end

-- 设置船已经建造的最大等级
function BattleItemSystemClient:SetShipBuiltGrade(nGrade)
    SetShipBuiltGrade(self, nGrade)
end

-- 查询一件物品被安装的槽位
-- @param nItemInstanceId 物品实例的唯一id
-- @return nSlotIndex 槽位id
function BattleItemSystemClient:GetEquippedSlotIndex(nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        error("BattleItemSystemClient:GetEquippedSlotIndex failed! Cannot find Item!".. nItemInstanceId)
    end
    return Item:GetStorageLocation().nSlotIndex
end

-- 查询某个大类型的所有物品列表(未装配的)
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @return tbItems 物品的数组 eg:
--         local tbItems = {}
--         table.insert(tbItems, BattleItemBase())
--         table.insert(tbItems, BattleItemBase())
--         return tbItems
function BattleItemSystemClient:GetUnequippedItemsByCategory(nItemCategory)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetUnequippedItemsByCategory(nItemCategory)
end

-- 获得某一包玩家身上未装备的物品列表
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的三个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
--                      BattleItemRoomDef.MATERIAL_ROOM  -- 材料背包
-- @return tbItems 物品的数组 eg:
--         local tbItems = {}
--         table.insert(tbItems, BattleItemBase())
--         table.insert(tbItems, BattleItemBase())
--         return tbItems
function BattleItemSystemClient:GetUnEquippedItems(nItemRoomType)
    local ItemRoom = GetInventoryRoom(nItemRoomType)
    if ItemRoom then
        return ItemRoom:GetRoomItems(true)
    else
        return { }
    end
end

-- 获得背包容量（承重上限）
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包容量
function BattleItemSystemClient:GetInventoryCapacity(nItemRoomType)
    local ItemRoom = GetInventoryRoom(nItemRoomType)
    return ItemRoom:GetInventoryCapacity(true)
end

-- 获得背包当前承重（背包内物品重量和）
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包当前承重
function BattleItemSystemClient:GetAllItemsWeight(nItemRoomType)
    local ItemRoom = GetInventoryRoom(nItemRoomType)
    return ItemRoom:GetAllItemsWeight(true)
end

-- 获得背包格子数上限
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包格子数上限
function BattleItemSystemClient:GetMaxInventorySlots(nItemRoomType)
    local ItemRoom = GetInventoryRoom(nItemRoomType)
    return ItemRoom:GetMaxInventorySlots(true)
end

-- 获得背包当前占用格子数
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包当前占用格子数
function BattleItemSystemClient:GetInventorySlotsCount(nItemRoomType)
    local ItemRoom = GetInventoryRoom(nItemRoomType)
    return ItemRoom:GetInventorySlotsCount(true)
end

-- 查询已经装备的某个类型的物品列表，如果没安装就返回空table
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param nOwnerInstanceId 装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId，如果是装在武器上的，就是武器的nItemInstanceId
-- @return tbEquippedItems (key:nSlotIndex, value:Item) eg:
--         local tbEquippedItems = {}
--         tbEquippedItems[1] = BattleItemBase()
--         tbEquippedItems[3] = BattleItemBase()
--         return tbEquippedItems
function BattleItemSystemClient:GetEquippedItems(nItemCategory, nOwnerInstanceId)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemSystemHelper:GetRoomItemsInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, true)
end

-- 查询一装备的某个类型某个槽位的物品,如果没安装就返回nil
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nSlotIndex 槽位id,如果不填就返回第一个槽位的物品
-- @return 被安装在某个槽位上的Item的实例
function BattleItemSystemClient:GetEquippedItem(nItemCategory, nOwnerInstanceId, nSlotIndex)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemSystemHelper:GetEquippedItemBySlotInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, nSlotIndex)
end

-- 获得未装配的某个物品类型的数量
-- @param nItemTemplateId 物品的template id
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemClient:GetUnequippedItemCount(nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetUnequippedItemCount(nItemTemplateId)
end

-- 获得已装配的某个物品类型的数量
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemClient:GetEquippedItemCount(nOwnerInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetEquippedItemCount(nOwnerInstanceId, nItemTemplateId)
end

-- 获得某个物品类型的数量(装配未装配都有)
-- @param nItemTemplateId 物品的template id
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemClient:GetItemCount(nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetItemCount(nItemTemplateId)
end

-- 是否可以自动拾取
-- @param tbItemProtoData 物品的proto数据
-- @return bIsBetter, bAutoPickUp
-- bIsBetter true表示需要给出的提示让玩家拾取，false表示不需要
-- bAutoPickUp true表示可以自动拾取，false表示不能自动拾取
-- nAutoPickUpCount 可以自动拾取的最大数量，外部要使用这个值和Item的stackcount求最小值来进行拾取
function BattleItemSystemClient:CanAutoPickUp(tbItemProtoData)
    local Item = BattleItemFactory:CreateItemWithProtoData(nil, tbItemProtoData)
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(Item:GetCategory())
    local bIsBatter, bAutoPickUp, nAutoPickUpCount = ItemCategoryOperationHelper:CanAutoPickUpOnClient(Item)
    local bCanAutoPick = BattleItemAutoPickUpHelper.CanAutoPickUp(true)
    log("BattleItemSystemClient:CanAutoPickUp", bCanAutoPick, bAutoPickUp)
    if not bCanAutoPick then
        bAutoPickUp = false
        nAutoPickUpCount = nil
    end
    return bIsBatter, bAutoPickUp, nAutoPickUpCount
end

-- 是否可以手动拾取
-- @param tbItemProtoData 物品的proto数据
-- @return true可以手动拾取，false不能手动拾取
function BattleItemSystemClient:CanManuallyPickUp(tbItemProtoData)
    local Item = BattleItemFactory:CreateItemWithProtoData(nil, tbItemProtoData)
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(Item:GetCategory())
    return ItemCategoryOperationHelper:CanManuallyPickUpOnClient(Item)
end

-- 检查物品和槽位是否兼容
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nSlotIndex 槽位index
-- @param Item 物品实例
-- @return
function BattleItemSystemClient:CheckItemSlotCompatibility(nOwnerInstanceId, nSlotIndex, Item)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(Item:GetTemplateId())
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    local nCharacterInstanceId = GetCharacterInstanceId()
    return ItemCategoryOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item, true)
end

-- 获得可以安装的槽位
-- @param nItemTemplateId物品的类型id
-- @param bNeedEmptySlot true表示必须是空槽位，false表示不管是不是空槽位
-- @return
-- 返回值：nOwnerInstanceId, nSlotIndex (如果找不到装配位置，就返回 -1,-1)
function BattleItemSystemClient:GetAvailableEquipmentSlotForItem(nItemTemplateId, bNeedEmptySlot)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    if bNeedEmptySlot == nil then
        bNeedEmptySlot = false
    end
    return ItemCategoryOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
end

-- 获得装配位置index
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nItemTemplateId物品的类型id
-- @param bNeedEmptySlot true表示必须是空槽位，false表示不管是不是空槽位
-- @return nSlotIndex (如果找不到装配位置，就返回 -1)
function BattleItemSystemClient:GetAvailableEquipmentSlotForItemWithOwner(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    if bNeedEmptySlot == nil then
        bNeedEmptySlot = false
    end
    return ItemCategoryOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
end

-- 是否可以往背包或船舱里增加某个类型的物品
-- @param nItemTemplateId 物品类型id
-- @return ture表示可以加到背包或船舱里，false表示不能
function BattleItemSystemClient:CanAddToInventoryRoom(nItemTemplateId)
    local nCharacterInstanceId = GetCharacterInstanceId()
    return BattleItemSystemHelper:CanAddToInventoryRoom(nCharacterInstanceId, nItemTemplateId, true)
end

-- 两个已安装的物品是否可以交换位置
-- @param 物品1的instanceid
-- @param 物品2的instanceid
-- @return true表示可以交换位置，false表示不能交换位置
function BattleItemSystemClient:CanExchangeStorageLocation(nItemInstanceId1, nItemInstanceId2)
    local nCharacterInstanceId = GetCharacterInstanceId()
    local Item1 = self:GetItem(nItemInstanceId1)
    local Item2 = self:GetItem(nItemInstanceId2)
    return BattleItemSystemHelper:CanExchangeStorageLocation(nCharacterInstanceId, Item1, Item2, true)
end

-- 获得未装备的最小叠加数量的物品instance
-- @param nItemTemplateId 物品的template id
-- @return nItemInstance nil表示没有这个类型的物品，否则返回未装备的最小叠加数量的物品instance
function BattleItemSystemClient:GetUnequippedLeastStackCountInstance(nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetUnequippedLeastStackCountInstance(nItemTemplateId)
end

-- 获得未装备的最小叠加数量的物品instanceid
-- @param nItemTemplateId 物品的template id
-- @return nItemInstanceId nil表示没有这个类型的物品，否则返回未装备的最小叠加数量的物品instanceid
function BattleItemSystemClient:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
end

-- 校验物品建造
-- @param nItemTemplateId 物品的类型id
-- @param nSlotIndex 目标槽位
-- @return bSucceeded, tbFailures
--         bSucceeded为true表示校验成功，false表示校验失败
--         tbFailures 表示失败原因的列表，eg：
--         local tbFailures = {}
--         local tbFailure = {}
--         tbFailure.nType = ItemBuildingVerificationFailureDef.MATERIALS_NOT_ENOUGH
--         tbFailure.Params = nil --不同类型的参数不同，详情见ItemBuildingVerificationFailureDef
--         table.insert(tbFailures, tbFailure)
function BattleItemSystemClient:VerifyItemBuilding(nItemTemplateId, nSlotIndex)
    local nCharacterInstanceId = GetCharacterInstanceId()
    return BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, true)
end

-- 创建临时物品，不放进物品列表
-- @param nTemplateId 物品类型id
-- @param nStackCount 物品类型id
function BattleItemSystemClient:CreateTempItem(nTemplateId, nStackCount)
    local Item = BattleItemFactory:CreateItem(nTemplateId, nStackCount, false)
    return Item
end

-- 获得预约建造的道具类型id
-- @return 预约建造的道具类型id
function BattleItemSystemClient:GetReservedItemTemplateId()
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetReservedItemTemplateId()
end

-- 获得正在建造的道具类型id
-- @return 正在建造的道具类型id
function BattleItemSystemClient:GetBuildingItemTemplateId()
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetBuildingItemTemplateId()
end

-- 设置舰船配置的类型
function BattleItemSystemClient:SetShipPreparationTemplatesIds(tbShipPreparationTemplateIds)
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:SetShipPreparationTemplatesIds(tbShipPreparationTemplateIds)
end

-- 获得舰船配置的类型
function BattleItemSystemClient:GetShipPreparationTemplatesIds()
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetShipPreparationTemplatesIds()
end

-- 设置舰船皮肤
function BattleItemSystemClient:SetShipSkinIds(tbShipSkinIds)
    local BattleItemComponent = GetBattleItemComponent()
    local tbShipPreparationTemplateIds = BattleItemComponent:GetShipPreparationTemplatesIds()
    local tbShipSkinDatas = {}
    for _, v1 in ipairs(tbShipSkinIds) do
        local tbItemTemplate = ItemDataTable:GetTemplate(v1)
        local nShipItemId = tbItemTemplate.nShipItemId
        for _, v2 in ipairs(tbShipPreparationTemplateIds) do
            if v2 == nShipItemId then
                local tbLobbyShipTemplate = ItemDataTable:GetTemplate(nShipItemId)
                tbShipSkinDatas[tbLobbyShipTemplate.nBattleItemId] = v1
            end
        end
    end
    return BattleItemComponent:SetShipSkinIds(tbShipSkinDatas)
end

-- 获得舰船皮肤
function BattleItemSystemClient:GetShipSkinIds()
    local BattleItemComponent = GetBattleItemComponent()
    return BattleItemComponent:GetShipSkinIds()
end

-- 获得上次请求建造的道具templateId
function BattleItemSystemClient:GetLastRequestBuildItemTemplateId()
    return self.nLastRequestBuildTemplateId
end

function BattleItemSystemClient:GetPackageUsed(nItemRoomType)
    if GlobalVariableSystem:IsFFAPackageUseWeight() then
        return self:GetAllItemsWeight(nItemRoomType)
    else
        return self:GetInventorySlotsCount(nItemRoomType)
    end
end

function BattleItemSystemClient:GetPackageMax(nItemRoomType)
    if GlobalVariableSystem:IsFFAPackageUseWeight() then
        return self:GetInventoryCapacity(nItemRoomType)
    else
        return self:GetMaxInventorySlots(nItemRoomType)
    end
end

-----------------------------------------玩家不同的操作的方法---------------------------------------------
-- 请求制造物品
function BattleItemSystemClient:RequestBuildItem(nItemTemplateId, nSlotIndex)
    local PlayerSelf = PlayerSelfHelper:Get()
    if not ProgressBarHelper.CanStartHumanProgressBar(PlayerSelf) then
        return
    end

    self.nLastRequestBuildTemplateId = nItemTemplateId
    local c2d_BuildItem =
    {
        template_id = nItemTemplateId,
        slot_index = nSlotIndex
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_BuildItem, c2d_BuildItem)
end

-- 请求取消制造物品
function BattleItemSystemClient:RequestCancelBuildItem()
    RequestCancelBuildItem()
end

-- 请求装备物品
function BattleItemSystemClient:RequestEquipItem(nOwnerInstanceId, nItemInstanceId, nSlotIndex)
    local c2d_EquipItem =
    {
        owner_instance_id = nOwnerInstanceId,
        item_instance_id = nItemInstanceId,
        slot_index = nSlotIndex
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_EquipItem, c2d_EquipItem)
end

-- 请检查是否可以安装在这个槽位，可以的话请求装备物品
function BattleItemSystemClient:TryToRequestEquipItem(nOwnerInstanceId, nSlotIndex, Item)
    if BattleItemSystemClient:CheckItemSlotCompatibility(nOwnerInstanceId, nSlotIndex, Item) then
        BattleItemSystemClient:RequestEquipItem(nOwnerInstanceId, Item:GetInstanceId(), nSlotIndex)
    else
        log("Cannot equip item! slot not valid.", Item:GetTemplateId(), nSlotIndex, nOwnerInstanceId)
    end
end

-- 请求装备可叠加的物品(比如船的炮的弹药，人的武器弹药，默认这种情况不需要指定槽位index，只需要指定ownerInstanceId)
function BattleItemSystemClient:RequestEquipStackableItem(nOwnerInstanceId, nItemTemplateId, nCount)
    if nCount == nil then
        nCount = 1
    end
    local c2d_EquipStackableItem =
    {
        owner_instance_id = nOwnerInstanceId,
        item_template_id = nItemTemplateId,
        count = nCount
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_EquipStackableItem, c2d_EquipStackableItem)
end

-- 请求交换已安装物品的位置
function BattleItemSystemClient:RequestExchangeStorageLocation(nItemInstanceId1, nItemInstanceId2)
    local c2d_ExchangeStorageLocation =
    {
        item_instance_id1 = nItemInstanceId1,
        item_instance_id2 = nItemInstanceId2
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ExchangeStorageLocation, c2d_ExchangeStorageLocation)
end

-- 请求卸下物品
-- nCount 可以不传，表示全部都卸下
function BattleItemSystemClient:RequestUnEquipItem(nItemInstanceId, nCount)
    local c2d_UnequipItem =
    {
        item_instance_id = nItemInstanceId,
        count = nCount
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_UnequipItem, c2d_UnequipItem)
end

-- 请求丢弃物品
-- nCount 可以不传，表示全部都丢弃
function BattleItemSystemClient:RequestThrowAwayItem(nItemInstanceId, nCount)
    local c2d_ThrowAwayItem =
    {
        instance_id = nItemInstanceId,
        count = nCount
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ThrowAwayItem, c2d_ThrowAwayItem)
end

-- 请求查看场景中的物品
function BattleItemSystemClient:RequestBeginViewSceneItems(nItemInstanceIds)
    log("[SyncSceneItemsDetail] client send request", getseconds() * 1000)
    local c2d_BeginViewSceneItems =
    {
        instance_ids = nItemInstanceIds
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_BeginViewSceneItems, c2d_BeginViewSceneItems)
end

-- 结束查看场景中的物品
function BattleItemSystemClient:RequestEndViewSceneItems()
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_EndViewSceneItems)
end

-- 请求捡起场景中的物品
function BattleItemSystemClient:RequestPickUpSceneItem(nItemInstanceId, nCount)
    local c2d_PickupItem =
    {
        instance_id = nItemInstanceId,
        count = nCount
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_PickupItem, c2d_PickupItem)
end

-- 请求丢弃物品之后捡起物品
-- @param tbThrowItems 丢弃的道具
-- tbThrowItems = {}
-- local tbThrowItem = {}
-- tbThrowItem.instance_id = 1
-- tbThrowItem.count = 1
-- table.insert(tbThrowItems, tbThrowItem)
-- @param nItemInstanceId 拾取的道具id
function BattleItemSystemClient:RequestThrowAwayAndPickupItem(tbThrowItems, nItemInstanceId)
    local c2d_ThrowAwayAndPickupItem =
    {
        throw_items = tbThrowItems,
        pick_up_instance_id = nItemInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ThrowAwayAndPickupItem, c2d_ThrowAwayAndPickupItem)
end

-- 请求消耗物品
function BattleItemSystemClient:RequestConsumeItem(nItemInstanceId)
    local c2d_ConsumeItemRequest = {
        instance_id = nItemInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ConsumeItemRequest, c2d_ConsumeItemRequest)
end

-- 请求预约物品建造
function BattleItemSystemClient:ReserveItemBuild(nReservedItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemComponent:SetReservedItemTemplateId(nReservedItemTemplateId)

    EventManager:OnFireEvent(ClientEventDef.EV_RESERVE_ITEM_BUILD, nReservedItemTemplateId)
end

-- 取消预约物品建造
function BattleItemSystemClient:CancelReserveItemBuild(nCancelReserveItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemComponent:ClearReservedItemTemplateId()
    EventManager:OnFireEvent(ClientEventDef.EV_CANCEL_RESERVE_ITEM_BUILD, nCancelReserveItemTemplateId)
end
-----------------------------------------------处理dungeon发过来的物品数据同步---------------------------------------------------

function BattleItemSystemClient:OnSyncAddItem(tbBattleItemProtoData)
    if CheckPlayerDead("OnSyncAddItem") then
        return
    end
    local PlayerSelf = PlayerSelfHelper:Get()
    local NewItem = BattleItemFactory:CreateItemWithProtoData(PlayerSelf, tbBattleItemProtoData)
    AddItem(self, NewItem)
    local BattleItemComponent = GetBattleItemComponent()
    AddItemToNewRoom(self, BattleItemComponent, NewItem)
    NewItem:SetOnceOwned()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_CLIENT, NewItem)

    CancelReservedItemWhenAddItem(self, NewItem)
end

function BattleItemSystemClient:OnSyncRemoveItem(nItemInstanceId)
    if CheckPlayerDead("OnSyncRemoveItem") then
        return
    end
    local BattleItemComponent = GetBattleItemComponent()
    local Item = self:GetItem(nItemInstanceId)
    local nItemTemplateId = Item:GetTemplateId()
    if Item == nil then
        logerror("Cannot find item to remove!", nItemInstanceId)
        return
    end
    Item:PreRemoveFromPlayer(false)
    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local nCharacterInstanceId = Item:GetOwnerCharacterInstanceId()
    RemoveItemFromOldRoom(self, BattleItemComponent, Item)
    RemoveItem(self, nItemInstanceId)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_CLIENT, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
end

function BattleItemSystemClient:OnSyncItemStackCount(nItemInstanceId, nStackCount)
    if CheckPlayerDead("OnSyncItemStackCount") then
        return
    end
    local Item = self:GetItem(nItemInstanceId)
    if not Item then
        logerror("OnSyncItemStackCount failed!", nItemInstanceId, nStackCount)
        return
    end
    local nItemTemplateId = Item:GetTemplateId()
    local nOldStackCount = Item:GetStackCount()
    Item:SetStackCount(nStackCount)

    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local BattleItemComponent = GetBattleItemComponent()
    local Room = BattleItemComponent:GetRoom(nRoomType, nOwnerInstanceId)
    local bAdd = nOldStackCount < nStackCount
    if BattleItemRoomDef:IsEquipmentRoom(Room:GetRoomType()) then
        if bAdd then
            Item:OnEquip(true)
            EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_EQUIPED_CLIENT, Item, nOwnerInstanceId, nSlotIndex, nStackCount - nOldStackCount)
        elseif nOldStackCount > nStackCount then
            Item:OnUnequip(true)
            local nCharacterInstanceId = GetCharacterInstanceId()
            EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_UNEQUIPED_CLIENT, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nOldStackCount - nStackCount)
        end
    end

    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_CLIENT, Item, bAdd)
end

function BattleItemSystemClient:OnSyncItemDurability(nItemInstanceId, nDurability)
    if CheckPlayerDead("OnSyncItemDurability") then
        return
    end
    local Item = self:GetItem(nItemInstanceId)
    if not Item then
        log("[Item]Item already removed! Do not need sync durability!", nItemInstanceId, nDurability)
        return
    end
    Item:SetDurability(nDurability)
    Item:OnDurabilityChangedOnClient()
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_DURABILITY_CLIENT, nItemInstanceId, nDurability)
end

function BattleItemSystemClient:OnSyncItemStorageLocation(nItemInstanceId, tbItemStorageLocationProtoData)
    if CheckPlayerDead("OnSyncItemStorageLocation") then
        return
    end
    local BattleItemComponent = GetBattleItemComponent()
    local Item = self:GetItem(nItemInstanceId)
    RemoveItemFromOldRoom(self, BattleItemComponent, Item)

    Item:ParseStorageLocation(tbItemStorageLocationProtoData)
    AddItemToNewRoom(self, BattleItemComponent, Item)

    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_CLIENT, nItemInstanceId)
end

function BattleItemSystemClient:OnExchangeStorageLocation(nItemInstanceId1, nItemInstanceId2, tbPosition1, tbPosition2)
    if CheckPlayerDead("OnExchangeStorageLocation") then
        return
    end
    local Item1 = self:GetItem(nItemInstanceId1)
    local Item2 = self:GetItem(nItemInstanceId2)

    local nRoomType1, nOwnerInstanceId1, nSlotIndex1 = Item1:SplitAndGetStorageLocation()
    local nRoomType2, nOwnerInstanceId2, nSlotIndex2 = Item2:SplitAndGetStorageLocation()

    if not (tbPosition1.room_type == nRoomType2 and tbPosition1.owner_instance_id == nOwnerInstanceId2 and tbPosition1.slot_index == nSlotIndex2) then
        logerror("OnExchangeStorageLocation Error! Position not match!", nRoomType2, nOwnerInstanceId2, nSlotIndex2, tbPosition1.room_type, tbPosition1.owner_instance_id, tbPosition1.slot_index)
        return
    end

    if not (tbPosition2.room_type == nRoomType1 and tbPosition2.owner_instance_id == nOwnerInstanceId1 and tbPosition2.slot_index == nSlotIndex1) then
        logerror("OnExchangeStorageLocation Error! Position not match!", nRoomType1, nOwnerInstanceId1, nSlotIndex1, tbPosition2.room_type, tbPosition2.owner_instance_id, tbPosition2.slot_index)
        return
    end

    local BattleItemComponent = GetBattleItemComponent()
    BattleItemSystemHelper:ExchangeStorageLocation(BattleItemComponent, Item1, Item2)
end

function BattleItemSystemClient:OnSyncUnequipAllItems()
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemSystemHelper:OnUnequipAllItem(BattleItemComponent)

    local tbEquipmentItems = BattleItemComponent:GetAllEquipmentItems()
    if tbEquipmentItems == nil then
        return
    end
    BattleItemComponent:ClearAllEquipmentItemRoom()
end

function BattleItemSystemClient:OnSyncUnequipAllShipEquipItems()
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemSystemHelper:OnUnequipAllShipEquipItems(BattleItemComponent)
end

function BattleItemSystemClient:ResetItemInitData(tbItemProtos, nBuiltGrade)
    SetShipBuiltGrade(self, nBuiltGrade)

    local BattleItemComponent = GetBattleItemComponent()
    local tbItemInstanceIds = BattleItemComponent:RemoveAllItemOnCharacter()
    RemoveItems(self, tbItemInstanceIds)
    if tbItemProtos then
        for i, v in ipairs(tbItemProtos) do
            log("[ResetItemInitData]", v.template_id, v.instance_id)
            self:OnSyncAddItem(v)
        end
    end
end

function BattleItemSystemClient:BuildItemFinish(nItemInstanceId)
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemComponent:ClearBuildingItemTemplateId()

    FireBuildFinishEvent(self, nItemInstanceId)
end

function BattleItemSystemClient:BeginBuildItem(nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemComponent:SetBuildingItemTemplateId(nItemTemplateId)
    FireBeginBuildItemEvent(nItemTemplateId)
end

function BattleItemSystemClient:CancelBuildItem()
    local BattleItemComponent = GetBattleItemComponent()
    BattleItemComponent:ClearBuildingItemTemplateId()
    FireBuildItemCancelEvent()
end

return BattleItemSystemClient