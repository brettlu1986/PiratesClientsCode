-----------------------------------------------------
--File Name    : ShipPreparationComponent.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-18
--Description  : 船战备
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShipPreparationComponent = luaclass("ShipPreparationComponent", GameComponentBase)

local Proto = require("ClientProtoNames")
local ItemSystem = require("ItemSystem")
local EventManager = require("EventManager")
local ShipDataTable = require("ShipDataTable")
local ClientEventDef = require("ClientEventDef")
local ItemCategoryDef = require("ItemCategoryDef")
local ShipResDatatable = require("ShipResDatatable")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local NetworkManager = dynamic_require("NetworkManager")
local LobbyShipDef = require("LobbyShipDef")
local SaveGameDef = require("SaveGameDef")
local StringUtil = require("StringUtil")

local INVALID_INSTANCE_ID = -1
local SOURCE_TYPE_DEFAULT_OWNED = 0
local ShipOwningStateDef = LobbyShipDef.OwningStateDef

ShipPreparationComponent.PERMANENT_ITEM_TIME = -1

ShipPreparationComponent.tbCreateData = nil
ShipPreparationComponent.tbUnlockedShipSlots = nil
ShipPreparationComponent.tbEquippedShipIds = nil
ShipPreparationComponent.tbActiveWeaponIds = nil
ShipPreparationComponent.tbActivePartIds = nil
ShipPreparationComponent.tbEquippedShipSkinIds = nil
ShipPreparationComponent.tbAllNewShipItems = {}
ShipPreparationComponent.tbNewShipItemsCount = {}

-- 根据TemplateId获取InstanceId
local function GetItemInstanceId(nTemplateId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nTemplateId)
    if tbItems and (#tbItems > 0) then
        return tbItems[1]:GetInstanceId()
    end
    return INVALID_INSTANCE_ID
end

-- 根据InstanceId获取TemplateId
local function GetItemTemplateId(nInstanceId)
    local Item = ItemSystem:GetItem(nInstanceId)
    return Item and Item:GetTemplateId()
end

local function SaveAllNewShipItems(self)
    local szData = ""
    local bFlag = true
    for k, v in pairs(self.tbAllNewShipItems) do
        if v then
            if bFlag then
                szData = szData..tostring(k)
            else
                szData = szData..","..tostring(k)
            end

            if bFlag then
                bFlag = false
            end
        end
    end
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    pSaveGameMgr:AddStringData(SaveGameDef.NEW_SHIP_ITEMS, szData)
    pSaveGameMgr:Save()
end

local function ModifyNewShipItemsCount(self, nCategory, nModify)
    if not self.tbNewShipItemsCount[nCategory] then
        self.tbNewShipItemsCount[nCategory] = 0
    end
    self.tbNewShipItemsCount[nCategory] = self.tbNewShipItemsCount[nCategory] + nModify
    if self.tbNewShipItemsCount[nCategory] < 0 then
        self.tbNewShipItemsCount[nCategory] = 0
    end
end

local function InitAllNewShipItems(self)
    local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    local szData = pSaveGameMgr:GetStringDataWithDefault(SaveGameDef.NEW_SHIP_ITEMS , "")
    local tbTemplateIds = StringUtil.Split(szData, ",")
    for _, szTemplateId in pairs(tbTemplateIds) do
        local nTemplateId = tonumber(szTemplateId)
        self.tbAllNewShipItems[nTemplateId] = true
        local nCategory = ItemSystem:GetItemTemplate(nTemplateId).nCategory
        ModifyNewShipItemsCount(self, nCategory, 1)
    end
end

local function InitUnlockedShipSlots(self, tbUnlockedShipSlots)
    self.tbUnlockedShipSlots = {}
    for _, nSlotId in ipairs(tbUnlockedShipSlots) do
        self.tbUnlockedShipSlots[nSlotId] = true
    end
end

local function InitEquippedShipIds(self, tbEquippedShipInstanceIds)
    self.tbEquippedShipIds = {}
    for i, tbShipData in ipairs(tbEquippedShipInstanceIds) do
        self.tbEquippedShipIds[tbShipData.slot_id] = GetItemTemplateId(tbShipData.ship_instance_id)
    end
end

local function InitActiveWeaponIds(self, tbActiveShipWeapons)
    self.tbActiveWeaponIds = {}
    for i, tbWeaponInfo in ipairs(tbActiveShipWeapons) do
        self.tbActiveWeaponIds[tbWeaponInfo.category] = GetItemTemplateId(tbWeaponInfo.instance_id)
    end
end

local function InitActivePartIds(self, tbActiveShipParts)
    self.tbActivePartIds = {}
    for i, tbPartInfo in ipairs(tbActiveShipParts) do
        self.tbActivePartIds[tbPartInfo.category] = GetItemTemplateId(tbPartInfo.instance_id)
    end
end

local function InitEquippedShipSkinIds(self, tbShipSkinIds)
    self.tbEquippedShipSkinIds = {}
    for i, tbShipSkinInfo in ipairs(tbShipSkinIds) do
        local nShipTemplateId = GetItemTemplateId(tbShipSkinInfo.ship_instance_id)
        local nShipSkinTemplateId = GetItemTemplateId(tbShipSkinInfo.ship_skin_instance_id)
        if nShipTemplateId and nShipSkinTemplateId then
            self.tbEquippedShipSkinIds[nShipTemplateId] = nShipSkinTemplateId
        end
    end
end

local function NeedMarkNewShipItem(tbTemplate)
    local nCategory = tbTemplate.nCategory
    local nSourceType = tbTemplate.nSourceType
    return nCategory >= ItemCategoryDef.SHIP and nCategory <= ItemCategoryDef.SHIP_SKIN and nSourceType ~= SOURCE_TYPE_DEFAULT_OWNED and nCategory ~= ItemCategoryDef.SHIP_PART
end

local function OnItemAdded(self, tbItem)
    local tbTemplate = tbItem:GetTemplate()
    if NeedMarkNewShipItem(tbTemplate) then
       self:MarkNewShipItem(tbTemplate.nId)
    end
end

local function IsSourceTypeDefaultOwned(nSourceType)
    return nSourceType == SOURCE_TYPE_DEFAULT_OWNED
end

function ShipPreparationComponent:OnCreate(Owner, tbParams)
    ShipPreparationComponent.super.OnCreate(self, Owner, tbParams)
    self.tbCreateData = tbParams

    InitAllNewShipItems(self)

    EventManager:BindEventMethod(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnItemAdded)
end

function ShipPreparationComponent:OnDestroy()
    EventManager:UnBindEventMethod(ClientEventDef.EV_ADD_LOBBY_ITEM, self, OnItemAdded)
    self.tbAllNewShipItems = {}
end

function ShipPreparationComponent:OnPostCreate()
    local tbCreateData = self.tbCreateData
    if tbCreateData then
        InitUnlockedShipSlots(self, tbCreateData.unlocked_slot) -- tbUnlockedShipSlots
        InitEquippedShipIds(self, tbCreateData.equipped_ship)   -- tbEquippedShipIds
        InitActiveWeaponIds(self, tbCreateData.weapon)          -- tbActiveWeaponIds
        InitActivePartIds(self, tbCreateData.part)              -- tbActivePartIds
        InitEquippedShipSkinIds(self, tbCreateData.ship_skin)   -- tbEquippedShipSkinIds
    end
end

-- 获取已经装备的船列表
function ShipPreparationComponent:GetUnlockedShipSlots()
    return self.tbUnlockedShipSlots
end

-- 获取已经装备的船列表
function ShipPreparationComponent:GetEquippedShipIds()
    return self.tbEquippedShipIds
end

-- 获取所有船的Template
function ShipPreparationComponent:GetShipTemplates()
    local tbShipTemplates = {}
    local tbShipTemplateMap = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.SHIP)
    for _, tbTemplate in pairs(tbShipTemplateMap) do
        table.insert(tbShipTemplates, tbTemplate)
    end
    return tbShipTemplates
end

-- 获取所有船的Template
function ShipPreparationComponent:GetSortedShipTemplates()
    local tbShipTemplates = self:GetShipTemplates()
    table.sort(tbShipTemplates, function(A, B)
        if A.nLevel ~= B.nLevel then
            return A.nLevel < B.nLevel
        end
        if A.nSubCategory ~= B.nSubCategory then
            return A.nSubCategory < B.nSubCategory
        end
        return A.nSortIndex < B.nSortIndex
    end)
    return tbShipTemplates
end

-- 跟据船Id获取所有船皮肤排序Template
function ShipPreparationComponent:GetSortedShipSkinTemplatesByShipId(nShipItemId)
    local tbDatas = {}
    local tbTemplates = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.SHIP_SKIN)

    for _, tbTemplate in pairs(tbTemplates) do
        if tbTemplate.nShipItemId == nShipItemId then
            local tbData = {}
            tbData.nId = tbTemplate.nId
            tbData.nShipItemId = tbTemplate.nShipItemId
            tbData.nResId = tbTemplate.nResId
            tbData.nSourceType = tbTemplate.nSourceType
            tbData.nGrade = tbTemplate.nGrade
            tbData.nLevel = tbTemplate.nLevel
            tbData.nShipOwningState = ShipOwningStateDef.Locked
            tbData.nCategory = tbTemplate.nCategory
            tbData.bIsNew = self:IsNewShipItem(tbTemplate.nId) and (not IsSourceTypeDefaultOwned(tbTemplate.nSourceType))
            tbData.tbChangedEffects = tbTemplate.tbChangedEffects
            if ShipPreparationComponent:IsItemUnlocked(tbData.nId) then
                if ShipPreparationComponent:IsShipItemPurchased(tbData.nId) then
                    tbData.nShipOwningState = ShipOwningStateDef.Owned
                else
                    tbData.nShipOwningState = ShipOwningStateDef.Experience
                end
            end
            table.insert(tbDatas, tbData)
        end
    end

    table.sort(tbDatas, function(A, B)
        -- 优先按是否拥有排序
        if A.nShipOwningState ~= B.nShipOwningState then
            return A.nShipOwningState < B.nShipOwningState
        end
        -- 之后按照是否为默认皮肤排序，默认皮肤排在非默认皮肤前面
        if IsSourceTypeDefaultOwned(A.nSourceType) or IsSourceTypeDefaultOwned(B.nSourceType) then
            return IsSourceTypeDefaultOwned(A.nSourceType)
        end
        -- 之后按照是否已装配排序，已装配皮肤排在未装配皮肤前面
        if self:IsEquippedShipSkin(nShipItemId, A.nId) or self:IsEquippedShipSkin(nShipItemId, B.nId) then
            return self:IsEquippedShipSkin(nShipItemId, A.nId)
        end
        -- 再按照品质排序，品质高的排在品质低的前面
        if A.nLevel ~= B.nLevel then
            return A.nLevel > B.nLevel
        end
        -- 同一品质的皮肤，则按照id从小到大排序
        return A.nId < B.nId
    end)

    return tbDatas
end

-- 获取所有未装备船的Template
function ShipPreparationComponent:GetUnequippedShipTemplates()
    local fnCheckCanEquip = function(tbTemplate)
        for nSlotId, nTemplateId in pairs(self.tbEquippedShipIds) do
            if tbTemplate.nId == nTemplateId then
                return false
            end
        end
        return not tbTemplate.bDefaultEquipped and self:IsItemUnlocked(tbTemplate.nId)
    end
    local tbShipTemplates = self:GetSortedShipTemplates()
    for i = #tbShipTemplates, 1, -1 do
        if not fnCheckCanEquip(tbShipTemplates[i]) then
            table.remove(tbShipTemplates, i)
        end
    end
    return tbShipTemplates
end

-- 获取某个分类下所有武器的Templates
function ShipPreparationComponent:GetWeaponTemplatesByCategory(nWeaponCategory)
    local tbWeaponTemplates = {}
    local tbWeaponTemplateMap = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.SHIP_WEAPON)
    for _, tbTemplate in pairs(tbWeaponTemplateMap) do
        if tbTemplate.nSubCategory == nWeaponCategory then
            table.insert(tbWeaponTemplates, tbTemplate)
        end
    end
    table.sort(tbWeaponTemplates, function(A, B)
        return A.nId < B.nId
    end)
    return tbWeaponTemplates
end

-- 根据零件类型判断当前激活的零件套装Id
function ShipPreparationComponent:GetActivePartId(nPartCategory)
    return self.tbActivePartIds[nPartCategory]
end

-- 获得当前激活的零件套装Id
function ShipPreparationComponent:GetActivePartIds()
    return self.tbActivePartIds
end

-- 根据武器类型获取当前激活的武器Id
function ShipPreparationComponent:GetActiveWeaponId(nWeaponCategory)
    return self.tbActiveWeaponIds[nWeaponCategory]
end

-- 获取当前激活的武器Id
function ShipPreparationComponent:GetActiveWeaponIds()
    return self.tbActiveWeaponIds
end

-- 判断战备物品是否解锁
function ShipPreparationComponent:IsItemUnlocked(nTemplateId)
    return GetItemInstanceId(nTemplateId) ~= INVALID_INSTANCE_ID
end

-- 判断舰船是否已购买（可能体验解锁，但是没购买）
function ShipPreparationComponent:IsShipItemPurchased(nTemplateId)
    if self:IsItemUnlocked(nTemplateId) then
        local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(nTemplateId)
        return nExpirationTime == ShipPreparationComponent.PERMANENT_ITEM_TIME
    end
    return false
end

-- 获取战备物品有效期，返回-1时代表是永久道具
function ShipPreparationComponent:GetItemExpirationTime(nTemplateId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nTemplateId)
    if tbItems and (#tbItems > 0) then
        local Item = tbItems[1]
        if Item:HasExpiration() then
            return Item:GetRemainCanUseSeconds()
        end
    end
    return ShipPreparationComponent.PERMANENT_ITEM_TIME
end

-- 获取已装备的皮肤Id
function ShipPreparationComponent:GetEquippedShipSkinId(nShipItemId)
    return self.tbEquippedShipSkinIds[nShipItemId]
end

-- 是否已装备的舰船
function ShipPreparationComponent:IsEquippedShip(nShipItemId)
    for _, nTemplateId in pairs(self.tbEquippedShipIds) do
        if nShipItemId == nTemplateId then
            return true
        end
    end
    return false
end

-- 是否已装备的舰船皮肤
function ShipPreparationComponent:IsEquippedShipSkin(nShipItemId, nShipSkinId)
    return self:GetEquippedShipSkinId(nShipItemId) == nShipSkinId
end

local function GetShipResTemplate(self, nShipItemId)
    local nShipSkinId = self.tbEquippedShipSkinIds[nShipItemId]
    if nShipSkinId then
        -- 先查已装备皮肤
        local tbShipSkinTemplate = ItemSystem:GetItemTemplate(nShipSkinId)
        return ShipResDatatable:GetTemplate(tbShipSkinTemplate.nShipResId)
    else
        -- 没有皮肤用默认的
        local tbShipItemTemplate = ItemSystem:GetItemTemplate(nShipItemId)
        local tbBattleItemTemplate = BattleItemDataTable:GetTemplate(tbShipItemTemplate.nBattleItemId)
        return ShipDataTable:GetResTemplate(tbBattleItemTemplate.nShipId)
    end
end

function ShipPreparationComponent:GetVerticalPosterPath(nShipItemId)
    local tbShipResTemplate = GetShipResTemplate(self, nShipItemId)
    return tbShipResTemplate and tbShipResTemplate.szPortrait
end

function ShipPreparationComponent:GetHorizontalPosterPath(nShipItemId)
    local tbShipResTemplate = GetShipResTemplate(self, nShipItemId)
    return tbShipResTemplate and tbShipResTemplate.szIconPath
end

function ShipPreparationComponent:MarkNewShipItem(nTemplateId)
    self.tbAllNewShipItems[nTemplateId] = true
    local nCategory = ItemSystem:GetItemTemplate(nTemplateId).nCategory
    ModifyNewShipItemsCount(self, nCategory, 1)
    SaveAllNewShipItems(self)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SHIP_TIP_ICON, true, nTemplateId)
end

function ShipPreparationComponent:UnmarkNewShipItem(nTemplateId)
    self.tbAllNewShipItems[nTemplateId] = nil
    local nCategory = ItemSystem:GetItemTemplate(nTemplateId).nCategory
    ModifyNewShipItemsCount(self, nCategory, -1)
    SaveAllNewShipItems(self)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SHIP_TIP_ICON, false, nTemplateId)
end

function ShipPreparationComponent:IsNewShipItem(nTemplateId)
    return self.tbAllNewShipItems[nTemplateId]
end

function ShipPreparationComponent:CheckShipHasNewSkins(nShipTemplateId)
    local tbAllSkins = self:GetSortedShipSkinTemplatesByShipId(nShipTemplateId)
    for _, v in pairs(tbAllSkins) do
        if v.bIsNew then
            return true
        end
    end
    return false
end

function ShipPreparationComponent:CheckHasNewShipItems()
    for i = ItemCategoryDef.SHIP, ItemCategoryDef.SHIP_SKIN do
        if self:CheckCategoryHasNewShipItems(i) then
            return true
        end
    end
    return false
end

function ShipPreparationComponent:CheckCategoryHasNewShipItems(nCategory)
    return self.tbNewShipItemsCount[nCategory] and (self.tbNewShipItemsCount[nCategory] > 0)
end

function ShipPreparationComponent:CheckWeaponSlotHasNewWeapon(nWeaponSlot)
    for nId, bNew in pairs(self.tbAllNewShipItems) do
        if bNew then
            local tbTemplate = ItemSystem:GetItemTemplate(nId)
            if tbTemplate.nCategory == ItemCategoryDef.SHIP_WEAPON then
                local tbCategoryTemplate = ShipWeaponCategoryDataTable:GetTemplate(tbTemplate.nSubCategory)
                if tbCategoryTemplate.nWeaponSlot == nWeaponSlot then
                    return true
                end
            end
        end
    end

    return false
end

---------------------------------------------------------------
-- 以下为s2c回包处理逻辑
---------------------------------------------------------------
-- 收到解锁舰船槽位结果
function ShipPreparationComponent:ReceiveUnlockShipSlot(nSlotId)
    self.tbUnlockedShipSlots[nSlotId] = true
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UNLOCK_SHIP_SLOT_RESULT, nSlotId)
end

-- 收到装备/替换上阵舰船结果
function ShipPreparationComponent:ReceiveEquipShipResult(nSlotId, nShipItemInstanceId)
    local Item = ItemSystem:GetItem(nShipItemInstanceId)
    local nTemplateId = Item:GetTemplateId()
    self.tbEquippedShipIds[nSlotId] = nTemplateId
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_EQUIP_SHIP_RESULT, nSlotId, nTemplateId)
end

-- 收到零件套装激活结果
function ShipPreparationComponent:ReceiveActivatePartResult(nShipWeaponItemInstanceId)
    local Item = ItemSystem:GetItem(nShipWeaponItemInstanceId)
    local nPartCategory = Item:GetSubCategory()
    local nTemplateId = Item:GetTemplateId()
    self.tbActivePartIds[nPartCategory] = nTemplateId
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_PART_RESULT, nPartCategory, nTemplateId)
end

-- 收到武器激活结果
function ShipPreparationComponent:ReceiveActivateWeaponResult(nShipPartItemInstanceId)
    local Item = ItemSystem:GetItem(nShipPartItemInstanceId)
    local nWeaponCategory = Item:GetSubCategory()
    local nTemplateId = Item:GetTemplateId()
    self.tbActiveWeaponIds[nWeaponCategory] = nTemplateId
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_ACTIVATE_SHIP_WEAPON_RESULT, nWeaponCategory, nTemplateId)
end

-- 收到舰船皮肤使用结果
function ShipPreparationComponent:ReceiveEquipShipSkinResult(nShipInstanceId, nShipSkinInstanceId)
    local nShipItemId = GetItemTemplateId(nShipInstanceId)
    local nShipSkinTemplateId = GetItemTemplateId(nShipSkinInstanceId)
    self.tbEquippedShipSkinIds[nShipItemId] = nShipSkinTemplateId
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, nShipItemId, nShipSkinTemplateId)
end

-- 收到舰船被卸载结果
function ShipPreparationComponent:ReceiveUnequipShipResult(nSlotId)
    self.tbEquippedShipIds[nSlotId] = nil
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_UNEQUIP_SHIP_RESULT, nSlotId)
end

-- 收到舰船皮肤被卸载结果
function ShipPreparationComponent:ReceiveUnequipShipSkinResult(nShipInstanceId, nEquippedShipSkinInstanceId)
    local nShipItemId = GetItemTemplateId(nShipInstanceId)
    local nEquippedShipSkinId = GetItemTemplateId(nEquippedShipSkinInstanceId)
    self.tbEquippedShipSkinIds[nShipItemId] = nEquippedShipSkinId
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RECEIVE_SHIP_SKIN_CHANGED, nShipItemId, nEquippedShipSkinId)
end

---------------------------------------------------------------
-- 以下为c2s协议请求接口
---------------------------------------------------------------
-- 请求解锁舰船槽位
function ShipPreparationComponent:RequestUnlockShipSlot(nSlotId, bAutoExchange)
    local c2s_UnlockShipSlot = {
        ship_slot_id = nSlotId,
        currency_auto_exchange = bAutoExchange
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UnlockShipSlot, c2s_UnlockShipSlot)
end

-- 请求装备上阵舰船
function ShipPreparationComponent:RequestEquipShip(nSlotId, nTemplateId)
    local nInstanceId = GetItemInstanceId(nTemplateId)
    local c2s_EquipShip = {
        ship_instance_id = nInstanceId,
        slot_id = nSlotId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_EquipShip, c2s_EquipShip)
end

-- 请求卸载上阵舰船
function ShipPreparationComponent:RequestUnequipShip(nSlotId)
    local nTemplateId = self.tbEquippedShipIds[nSlotId]
    if nTemplateId then
        local nInstanceId = GetItemInstanceId(nTemplateId)
        local c2s_UnequipShip = {
            ship_instance_id = nInstanceId
        }
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_UnequipShip, c2s_UnequipShip)
    end
end

-- 请求激活零件套装
function ShipPreparationComponent:RequestActivatePart(nTemplateId)
    local nInstanceId = GetItemInstanceId(nTemplateId)
    local c2s_ChooseShipPart = {
        ship_part_instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ChooseShipPart, c2s_ChooseShipPart)
end

-- 请求激活武器
function ShipPreparationComponent:RequestActivateWeapon(nTemplateId)
    local nInstanceId = GetItemInstanceId(nTemplateId)
    local c2s_ChooseShipWeapon = {
        ship_weapon_instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ChooseShipWeapon, c2s_ChooseShipWeapon)
end

-- 请求穿戴船皮肤
function ShipPreparationComponent:RequestEquipShipSkin(nShipSkinTemplateId)
    local nInstanceId = GetItemInstanceId(nShipSkinTemplateId)
    local c2s_EquipShipSkin = {
        ship_skin_instance_id = nInstanceId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_EquipShipSkin, c2s_EquipShipSkin)
end

return ShipPreparationComponent