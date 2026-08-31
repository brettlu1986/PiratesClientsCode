-----------------------------------------------------
--File Name    : BattleItemPacketProcessor_C.lua
--Author       : zhiyuan
--Create Time  : 2018-08-15
--Description  : 接收dungeon发过来的协议
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemPacketProcessor = require("BattleItemPacketProcessor")
local BattleItemPacketProcessor_C = luaclass("BattleItemPacketProcessor_C", BattleItemPacketProcessor)

local ProtoDC = require("DungeonCommonProtoNames")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local UIResourceDef = require("UIResourceDef")
local BattleItemDataTable = require("BattleItemDataTable")
local SoundManager = require("SoundManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local Proto = require("DungeonCommonProtoNames")
local BattleItemSystemClient  = require("BattleItemSystemClient")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local BattlePickupSystem = require("BattlePickupSystem")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemCategoryDataTable = require("BattleItemCategoryDataTable")
local BattleItemRoomDef = require("BattleItemRoomDef")

BattleItemPacketProcessor_C.tbSceneItemsDetail = nil

local function CheckPlayerDead(szFunName)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsDead() then
        log(szFunName, " failed! Player is already dead!")
        return true
    end
    return false
end

local function OnSyncAddItem(self, tbPacket)
    if CheckPlayerDead("OnSyncAddItem") then
        return
    end
    BattleItemSystemClient:OnSyncAddItem(tbPacket.item)
end

local function OnSyncRemoveItem(self, tbPacket)
    if CheckPlayerDead("OnSyncRemoveItem") then
        return
    end
    BattleItemSystemClient:OnSyncRemoveItem(tbPacket.instance_id)
end

local function OnSyncItemStackCount(self, tbPacket)
    if CheckPlayerDead("OnSyncItemStackCount") then
        return
    end
    BattleItemSystemClient:OnSyncItemStackCount(tbPacket.instance_id, tbPacket.stack_count)
end

local function OnSyncItemDurability(self, tbPacket)
    if CheckPlayerDead("OnSyncItemDurability") then
        return
    end
    BattleItemSystemClient:OnSyncItemDurability(tbPacket.instance_id, tbPacket.durability)
end

local function OnSyncItemStorageLocation(self, tbPacket)
    if CheckPlayerDead("OnSyncItemStorageLocation") then
        return
    end
    BattleItemSystemClient:OnSyncItemStorageLocation(tbPacket.instance_id, tbPacket.storage_location)
end

local function OnBatchItemOps(self, tbPacket)
    if CheckPlayerDead("OnBatchItemOps") then
        return
    end
    local adds = tbPacket.sync_adds
    local removes = tbPacket.sync_removes
    local sync_counts = tbPacket.sync_counts
    local sync_locations = tbPacket.sync_locations

    if removes ~= nil then
        for _, v in ipairs(removes) do
            OnSyncRemoveItem(self, v)
        end
    end

    if adds ~= nil then
        for _, v in ipairs(adds) do
            OnSyncAddItem(self, v)
        end
    end

    if sync_locations ~= nil then
        for _, v in ipairs(sync_locations) do
            OnSyncItemStorageLocation(self, v)
        end
    end

    if sync_counts ~= nil then
        for _, v in ipairs(sync_counts) do
            OnSyncItemStackCount(self, v)
        end
    end
end

local function OnSyncUnequipAllShipEquipItems(self, tbPacket)
    if CheckPlayerDead("OnSyncUnequipAllShipEquipItems") then
        return
    end
    BattleItemSystemClient:OnSyncUnequipAllShipEquipItems()
end

local function MergeSceneRoomData(tbSceneItemsDetail, tbPacket)
    local tbOldSceneRoomData = tbSceneItemsDetail.scene_rooms
    local tbAddedSceneRoomData = tbPacket.scene_rooms
    if tbOldSceneRoomData == nil or #tbOldSceneRoomData == 0 then
        tbSceneItemsDetail.scene_rooms = tbAddedSceneRoomData
    else
        if tbAddedSceneRoomData ~= nil and #tbAddedSceneRoomData > 0 then
            for _, tbAddedRoom in ipairs(tbAddedSceneRoomData) do
                local SameRoom = nil
                for _, tbRoom in ipairs(tbOldSceneRoomData) do
                    if tbRoom.instance_id == tbAddedRoom.instance_id then
                        SameRoom = tbRoom
                        break
                    end
                end
                if SameRoom then
                    local tbItems = tbAddedRoom.items
                    for _, tbItem in ipairs(tbItems) do
                        table.insert(SameRoom.items, tbItem)
                    end
                else
                    table.insert(tbOldSceneRoomData, tbAddedRoom)
                end
            end
        end
    end
end

local function MergeSingleItemData(tbSceneItemsDetail, tbPacket)
    local tbOldSingleItemData = tbSceneItemsDetail.items
    local tbAddedSingleItemData = tbPacket.items
    if tbOldSingleItemData == nil or #tbOldSingleItemData == 0 then
        tbOldSingleItemData = tbAddedSingleItemData
    else
        if tbAddedSingleItemData ~= nil and #tbAddedSingleItemData > 0 then
            for _, v in ipairs(tbAddedSingleItemData) do
                table.insert(tbOldSingleItemData, v)
            end
        end
    end
end

local function MergeSceneItemsDetail(self, tbPacket)
    if self.tbSceneItemsDetail == nil then
        self.tbSceneItemsDetail = tbPacket
    else
        if self.tbSceneItemsDetail.package_id ~= tbPacket.package_id then
            self.tbSceneItemsDetail = tbPacket
        else
            MergeSceneRoomData(self.tbSceneItemsDetail, tbPacket)
            MergeSingleItemData(self.tbSceneItemsDetail, tbPacket)
        end
    end
end

local function OnSyncSceneItemsDetail(self, tbPacket)
    if CheckPlayerDead("OnSyncSceneItemsDetail") then
        return
    end
    MergeSceneItemsDetail(self, tbPacket)
    if tbPacket.is_last_package then
        BattlePickupSystem:SyncViewSceneItem(self.tbSceneItemsDetail)
        self.tbSceneItemsDetail = nil
    end
end

local function OnSyncAddSceneItem(self, tbPacket)
    if CheckPlayerDead("OnSyncAddSceneItem") then
        return
    end
    --EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_ADD_SCENE_ITEM, tbPacket)
end

local function OnSyncRemoveSceneItem(self, tbPacket)
    if CheckPlayerDead("OnSyncRemoveSceneItem") then
        return
    end
    --EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_SCENE_ITEM, tbPacket)
    BattlePickupSystem:RemovePickupItem(tbPacket.instance_id)
end

local function OnSyncRemoveScenePackage(self, tbPacket)
    if CheckPlayerDead("OnSyncRemoveScenePackage") then
        return
    end
    --EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_REMOVE_SCENE_ITEM_PACKAGE, tbPacket)
end

local function OnBuildItem(self, tbPacket)
    if CheckPlayerDead("OnBuildItem") then
        return
    end
    local ItemReturnCode = ProtoDC.ItemReturnCode
    if tbPacket.result == ItemReturnCode.OK then
        BattleItemSystemClient:BeginBuildItem(tbPacket.template_id)
    elseif tbPacket.result == ItemReturnCode.MATERIALS_NOT_ENOUGH then
        UIUtils.ShowToast(UITextDef.FFA_MATERIALS_NOT_ENOUGH)
    elseif tbPacket.result == ItemReturnCode.KEY_ITEMS_NOT_ENOUGH then
        UIUtils.ShowToast(UITextDef.FFA_KEY_ITEMS_NOT_ENOUGH)
    elseif tbPacket.result == ItemReturnCode.PREREQUISITE_ITEMS_NOT_ENOUGH then
        UIUtils.ShowToast(UITextDef.FFA_PREREQUISITE_ITEMS_NOT_ENOUGH)
    elseif tbPacket.result == ItemReturnCode.ITEM_TYPE_CANNOT_BUILD then
        UIUtils.ShowToast(UITextDef.FFA_ITEM_TYPE_CANNOT_BUILD)
    elseif tbPacket.result == ItemReturnCode.INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL then
        UIUtils.ShowToast(UITextDef.FFA_INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL)
    elseif tbPacket.result == ItemReturnCode.NOT_COMPATIBLE then
        UIUtils.ShowToast(UITextDef.FFA_NOT_COMPATIBLE)
    end
end

local function OnBuildItemCancel(self, tbPacket)
    if CheckPlayerDead("OnBuildItemCancel") then
        return
    end
    BattleItemSystemClient:CancelBuildItem()
end

local function OnBuildItemFinish(self, tbPacket)
    if CheckPlayerDead("OnBuildItemFinish") then
        return
    end
    BattleItemSystemClient:BuildItemFinish(tbPacket.instance_id)
    BattleItemSystemClient:CheckReservedItem()
end

local function OnEquipItem(self, tbPacket)
    if CheckPlayerDead("OnEquipItem") then
        return
    end
    if tbPacket.result == ProtoDC.ItemReturnCode.OK then
        local nInstanceId = tbPacket.item_instance_id
        local tbItem = BattleItemSystemClient:GetItem(nInstanceId)
        if tbItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT or
                tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
            SoundManager:PlaySoundEffect(UIResourceDef.SC_EQUIP_ATTACHMENT)
        end
    end
end

local function OnUnequipItem(self, tbPacket)
    if CheckPlayerDead("OnUnequipItem") then
        return
    end
    if tbPacket.result ~= ProtoDC.ItemReturnCode.OK then
        UIUtils.ShowToast(UITextDef.FFA_INVENTORY_CAPACITY_NOT_ENOUGHT)
        return
    end
    local nTemplateId = tbPacket.item_template_id
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    if tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT or
            tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
        SoundManager:PlaySoundEffect(UIResourceDef.SC_UNEQUIP_ATTACHMENT)
    end
    BattleItemSystemClient:CheckReservedItem()
end

local function OnEquipStackableItem(self, tbPacket)
    if CheckPlayerDead("OnEquipStackableItem") then
        return
    end
    local tbItem = BattleItemSystemClient:GetItem(tbPacket.owner_instance_id)
    assert(tbItem)
    BattleHumanWeaponSystemNew:OnEquipStackableItem(tbItem, tbPacket.count, tbPacket.add_count)
end

local function OnExchangeStorageLocation(self, tbPacket)
    if CheckPlayerDead("OnExchangeStorageLocation") then
        return
    end
    if tbPacket.result == ProtoDC.ItemReturnCode.OK then
        BattleItemSystemClient:OnExchangeStorageLocation(tbPacket.item_instance_id1, tbPacket.item_instance_id2,
                               tbPacket.storage_location1, tbPacket.storage_location2)

        local nInstanceId = tbPacket.item_instance_id1
        local tbItem = BattleItemSystemClient:GetItem(nInstanceId)
        if tbItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT or
                tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
            SoundManager:PlaySoundEffect(UIResourceDef.SC_EQUIP_ATTACHMENT)
        end
    end
end

-- local function PlayPickUpSound(nItemTemplateId)
--     local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
--     if tbItemResTemplate.nPickSoundID > 0 then
--         log("pick up play sound ", nItemTemplateId, tbItemResTemplate.nPickSoundID)
--         SoundManager:PlaySoundEffect(tbItemResTemplate.nPickSoundID)
--     end
-- end

local function OnPickupItem(self, tbPacket)
    if CheckPlayerDead("OnPickupItem") then
        return
    end
    local nInstanceId = tbPacket.instance_id
    local nItemTemplateId = tbPacket.template_id
    local nResult = tbPacket.result
    BattlePickupSystem:FinishPickupItem(nResult, nInstanceId, nItemTemplateId)
    EventManager:OnFireEvent(ClientEventDef.EV_PICK_UP_FINISH, nInstanceId, nItemTemplateId, nResult == ProtoDC.ItemReturnCode.OK)
    if nResult ~= ProtoDC.ItemReturnCode.OK then
        local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbTemplate == nil then
            return
        end
        local nCategory = tbTemplate.nCategory
        local nRoomType = nil
        if nCategory == BattleItemCategoryDef.CONVERTIBLE_ITEM then
            local nConvertItemTemplateId = tbTemplate.nConvertItemTemplateId
            local tbConvertTemplate = BattleItemDataTable:GetTemplate(nConvertItemTemplateId)
            local nConvertCategory = tbConvertTemplate.nCategory
            nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nConvertCategory)
        else
            nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nCategory)
        end
        if nRoomType == BattleItemRoomDef.HUMAN_INVENTORY then
            UIUtils.ShowToast(UITextDef.FFA_HUMAN_INVENTORY_FULL)
        elseif nRoomType == BattleItemRoomDef.CABIN then
            UIUtils.ShowToast(UITextDef.FFA_SHIP_INVENTORY_FULL)
        elseif nRoomType == BattleItemRoomDef.MATERIAL_ROOM then
            UIUtils.ShowToast(UITextDef.FFA_MATERAIL_INVENTORY_FULL)
        end
    else
        --PlayPickUpSound(nItemTemplateId)
        BattleItemSystemClient:CheckReservedItem()
    end
end

local function OnThrowAwayAndPickupItem(self, tbPacket)
    if CheckPlayerDead("OnThrowAwayAndPickupItem") then
        return
    end
    local nResult = tbPacket.result
    if nResult == ProtoDC.ItemReturnCode.ITEM_HAS_ALREADY_PICKED then
        UIUtils.ShowToast(UITextDef.FFA_ITEM_HAS_ALREADY_PICKED)
    else
        OnPickupItem(self, tbPacket)
    end
end

local function OnThrowAwayItem(self, tbPacket)
    if CheckPlayerDead("OnThrowAwayItem") then
        return
    end
    if tbPacket.result == ProtoDC.ItemReturnCode.OK then
        local nTemplateId = tbPacket.item_template_id
        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        if tbTemplate.nCategory == BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT or
                tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT then
            SoundManager:PlaySoundEffect(UIResourceDef.SC_UNEQUIP_ATTACHMENT)
        end
        BattleItemSystemClient:CheckReservedItem()
    elseif tbPacket.result == ProtoDC.ItemReturnCode.INVENTORY_CAPACITY_NOT_ENOUGHT then
        UIUtils.ShowToast(UITextDef.FFA_INVENTORY_CAPACITY_NOT_ENOUGHT)
    end
end

local function ResetHumanWeaponState()
    local tbPlayer = GamePlayerSelfHelper:Get()
    if not tbPlayer:IsHuman() then
        return
    end

    -- 服务器设了，客户端就不用管了
    --tbPlayer.HumanWeaponComponent:SetCurrentWeapon(0, true)
end

local function OnResetBattleItemData(self, tbPacket)
    ResetHumanWeaponState() -- todo @WuJizhou  临时解决人从安全区上飞艇时，持雷狂扔会出错的问题
    BattleItemSystemClient:ResetItemInitData(tbPacket.items, tbPacket.built_grade)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_RESET_BATTLE_ITEM)
end

local function OnSyncShipPreparation(self, tbPacket)
    BattleItemSystemClient:SetShipPreparationTemplatesIds(tbPacket.ship_preparation_template_ids)
    BattleItemSystemClient:SetShipSkinIds(tbPacket.ship_skin_ids)
    local tbPlayer = GamePlayerSelfHelper:Get()
    local BattleShipSkinComponent = tbPlayer.BattleShipSkinComponent
    BattleShipSkinComponent:InitWhenShipPreparationOnClient(tbPacket.ship_skin_ids)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_SYNC_SHIP_PREPARATION)
end

function BattleItemPacketProcessor_C:RegisterPackets()
    BattleItemPacketProcessor_C.super.RegisterPackets(self)
    self:BindMethod(Proto.d2c_SyncAddItem, self, OnSyncAddItem)
    self:BindMethod(Proto.d2c_SyncRemoveItem, self, OnSyncRemoveItem)
    self:BindMethod(Proto.d2c_SyncItemStackCount, self, OnSyncItemStackCount)
    self:BindMethod(Proto.d2c_SyncItemDurability, self, OnSyncItemDurability)
    self:BindMethod(Proto.d2c_SyncItemStorageLocation, self, OnSyncItemStorageLocation)
    self:BindMethod(Proto.d2c_BatchItemOps, self, OnBatchItemOps)
    self:BindMethod(Proto.d2c_OnUnequipAllShipEquipItems, self, OnSyncUnequipAllShipEquipItems)
    self:BindMethod(Proto.d2c_SyncSceneItemsDetail, self, OnSyncSceneItemsDetail)
    self:BindMethod(Proto.d2c_SyncAddSceneItem, self, OnSyncAddSceneItem)
    self:BindMethod(Proto.d2c_SyncRemoveSceneItem, self, OnSyncRemoveSceneItem)
    self:BindMethod(Proto.d2c_SyncRemoveScenePackage, self, OnSyncRemoveScenePackage)
    self:BindMethod(Proto.d2c_ResetBattleItemData, self, OnResetBattleItemData)

    self:BindMethod(Proto.d2c_BuildItem, self, OnBuildItem)
    self:BindMethod(Proto.d2c_BuildItemCancel, self, OnBuildItemCancel)
    self:BindMethod(Proto.d2c_BuildItemFinish, self, OnBuildItemFinish)
    self:BindMethod(Proto.d2c_EquipItem, self, OnEquipItem)
    self:BindMethod(Proto.d2c_UnequipItem, self, OnUnequipItem)
    self:BindMethod(Proto.d2c_EquipStackableItem, self, OnEquipStackableItem)
    self:BindMethod(Proto.d2c_ExchangeStorageLocation, self, OnExchangeStorageLocation)
    self:BindMethod(Proto.d2c_PickupItem, self, OnPickupItem)
    self:BindMethod(Proto.d2c_ThrowAwayItem, self, OnThrowAwayItem)
    self:BindMethod(Proto.d2c_ThrowAwayAndPickupItem, self, OnThrowAwayAndPickupItem)

    self:BindMethod(Proto.d2c_SyncShipPreparation, self, OnSyncShipPreparation)
end

return BattleItemPacketProcessor_C
