-----------------------------------------------------
--File Name    : BattleItemSystemServer.lua
--Author       : zhiyuan
--Create Time  : 2018-08-24
--Description  : Server上游戏世界的物品操作System
-----------------------------------------------------
local BattleItemFactory = require("BattleItemFactory")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleItemCategoryDataTable = require("BattleItemCategoryDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemRoomDef = require("BattleItemRoomDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local SceneItemContainer = require("SceneItemContainer")
local DiamondContainer = require("DiamondContainer")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local FFAItemIni = require("FFAItemIni")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local MaterialItemHelper = require("MaterialItemHelper")
local BattleItemUnequipCheckFailureDef = require("BattleItemUnequipCheckFailureDef")
local BattleItemThrowAwayCheckFailureDef = require("BattleItemThrowAwayCheckFailureDef")
local PropName = require("PropName")
local SceneItemActorDef = require("SceneItemActorDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local PvpInitItemDataTable = require("PvpInitItemDataTable")
local DungeonTypeDefine = require("DungeonTypeDefine")
local BattleItemSystemProtocalHelper = require("BattleItemSystemProtocalHelper")
local DelayTimer = require("DelayTimer")
local AIHelper = require("AIHelper")
local TriggerIni = require("TriggerIni")
local DungeonIni = require("DungeonIni")
local BattleItemSourceDef = require("BattleItemSourceDef")

local BattleItemSystemServer = {}

local MoveItem = nil
local UnEquipItem = nil
local EquipItem = nil

BattleItemSystemServer.bHasInit = nil

BattleItemSystemServer.tbAllItems = {}

BattleItemSystemServer.tbItemBuildingDatas = {}

BattleItemSystemServer.tbShipBuiltGrades = {}

BattleItemSystemServer.tbIsChangingShip = {}

BattleItemSystemServer.tbDelayTimerHandle = {}

BattleItemSystemServer.nMaxViewItemRequestId = nil
BattleItemSystemServer.tbViewItemRequestBeginTimes = nil

BattleItemSystemServer.tbPlayerInstanceIdsToResetItem = {}
BattleItemSystemServer.nResetItemPlayerCount = 0
BattleItemSystemServer.DelayResetItemsHandle = nil

local SHIP_DELAY_SECOND_CREATE_DIE_BOX = DungeonIni.tbDead.nCreateShipBoxDelayTime
local HUMAN_DELAY_SECOND_CREATE_DIE_BOX = DungeonIni.tbDead.nCreateHumanBoxDelayTime
local NPC_DELAY_SECOND_CREATE_DIE_BOX = DungeonIni.tbDead.nCreateNpcBoxDelayTime

local RESET_PLAYER_ITEMS_MAX_COUNT_IN_ONE_TICK = 2

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

local function AllItemsUninit(self)
    for _,v in pairs(self.tbAllItems) do
        v:OnDestroy()
    end
    self.tbAllItems = {}
end

local function GetPlayer(nCharacterInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if tbPlayer == nil then
        error("GetPlayer failed!nCharacterInstanceId:"..nCharacterInstanceId)
    end
    return tbPlayer
end

local function GetBattleItemComponent(nCharacterInstanceId)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if tbPlayer == nil then
        error("GetBattleItemComponent failed!nCharacterInstanceId:"..nCharacterInstanceId)
    end
    local BattleItemComponentServer = tbPlayer.BattleItemComponentServer
    if BattleItemComponentServer == nil then
        error("GetBattleItemComponent failed!BattleItemComponentServer == nil!nCharacterInstanceId:"..nCharacterInstanceId)
    end
    return BattleItemComponentServer
end

local function GetInventoryRoom(nCharacterInstanceId, nItemRoomType)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetOrCreateItemRoom(nItemRoomType, nCharacterInstanceId)
end

local function RemoveAllItemOnCharacter(nCharacterInstanceId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:RemoveAllItemOnCharacter()
end


-- local function ChangeToPreparationShipWeapon(nCharacterInstanceId, tbItemTemplate)
--     local nItemTemplateId = tbItemTemplate.nId
--     local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, false)
--     for _, v in ipairs(tbBuildDatas) do
--         local tbTemplate = v.tbBattleItemTemplate
--         if tbItemTemplate.nSubCategory == tbTemplate.nSubCategory then
--             return tbTemplate.nId
--         end
--     end
--     return nItemTemplateId
-- end

local function ChangeToPreparationShipPart(nCharacterInstanceId, tbItemTemplate)
    local nItemTemplateId = tbItemTemplate.nId
    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, false)
    for _, v in ipairs(tbBuildDatas) do
        local tbTemplate = v.tbBattleItemTemplate
        if tbItemTemplate.nSubCategory == tbTemplate.nSubCategory and tbItemTemplate.nGrade == tbTemplate.nGrade then
            return tbTemplate.nId
        end
    end
    return nItemTemplateId
end

local function ChangeToPreparationItem(nCharacterInstanceId, nItemTemplateId)
    local nTemplateIdAfterChange = nItemTemplateId
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    if AIHelper.IsAIControlled(tbPlayer) then
        return nTemplateIdAfterChange
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    -- if nCategory == BattleItemCategoryDef.SHIP_WEAPON then
    --     nTemplateIdAfterChange = ChangeToPreparationShipWeapon(nCharacterInstanceId, tbTemplate)
    if nCategory == BattleItemCategoryDef.SHIP_PART then
        nTemplateIdAfterChange = ChangeToPreparationShipPart(nCharacterInstanceId, tbTemplate)
    end
    return nTemplateIdAfterChange
end

local function GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    local nRoomType = BattleItemCategoryDataTable:GetEquippedRoomType(nCategory)
    if bNeedEmptySlot == nil then
        bNeedEmptySlot = false
    end
    local nOwnerInstanceId, nSlotIndex = ItemCategoryOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    return nRoomType, nOwnerInstanceId, nSlotIndex
end

local function GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    assert(tbItemTemplate ~= nil, "tbItemTemplate is nil!".. nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    if bNeedEmptySlot == nil then
        bNeedEmptySlot = false
    end
    return ItemCategoryOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
end

local function CanUnequipOnServer(self, nCharacterInstanceId, Item)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:CanUnequipOnServer(nCharacterInstanceId, Item)
end

local function CanThrowAwayOnServer(self, nCharacterInstanceId, Item)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:CanThrowAwayOnServer(nCharacterInstanceId, Item)
end

local function AfterBuiltOnServer(nCharacterInstanceId, Item)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:AfterBuiltOnServer(nCharacterInstanceId, Item)
end

local function AfterPickedUpOnServer(nCharacterInstanceId, Item)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:AfterPickedUpOnServer(nCharacterInstanceId, Item)
end

local function CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlot, Item)
    if nCharacterInstanceId < 0 or nOwnerInstanceId < 0 or nSlot < 0 then
        return false
    end
    return BattleItemSystemHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlot, Item, false)
end

local function BeforeAddedToCharacterOnServer(self, nCharacterInstanceId, Item)
    local nCategory = Item:GetCategory()
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:BeforeAddedToCharacterOnServer(nCharacterInstanceId, Item)
end

local function GetRemainStackCountOnEquipmentSlot(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, nItemTemplateId)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(nCategory)
    return ItemCategoryOperationHelper:GetRemainStackCountOnEquipmentSlot(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, nItemTemplateId)
end

local function GetItemBuildingData(self, nCharacterInstanceId)
    return self.tbItemBuildingDatas[nCharacterInstanceId]
end

local function ClearItemBuildingData(self, nCharacterInstanceId)
    local ItemBuildingData = self.tbItemBuildingDatas[nCharacterInstanceId]
    if ItemBuildingData then
        self.tbItemBuildingDatas[nCharacterInstanceId] = nil
        return true
    end
    return false
end

local function AddItemBuildingData(self, nCharacterInstanceId, nItemTemplateId)
    local tbBuildData = {}
    tbBuildData.nItemTemplateId = nItemTemplateId
    self.tbItemBuildingDatas[nCharacterInstanceId] = tbBuildData
end

local function GetShipBuiltGrade(self, nCharacterInstanceId)
    local nGrade = self.tbShipBuiltGrades[nCharacterInstanceId]
    if not nGrade then
        return FFAItemIni.tbShip.nInitShipGrade
    end
    return nGrade
end

local function SetShipBuiltGrade(self, nCharacterInstanceId, nGrade)
    self.tbShipBuiltGrades[nCharacterInstanceId] = nGrade
end

local function ClearShipBuiltGrade(self, nCharacterInstanceId)
    self.tbShipBuiltGrades[nCharacterInstanceId] = nil
end

local function CancelBuildItem(self, nCharacterInstanceId, bNeedSync)
    local bClearSuccess = ClearItemBuildingData(self, nCharacterInstanceId)
    if bClearSuccess and bNeedSync then
        local tbPlayer = GetPlayer(nCharacterInstanceId)
        local ProgressBarComponent = tbPlayer.ProgressBarComponent
        ProgressBarComponent:Abort()
        BattleItemSystemProtocalHelper:SyncD2CBuildItemCancel(tbPlayer)
    end
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_CANCEL_SERVER, nCharacterInstanceId)
    log("[BuildItem]CancelBuildItem!", nCharacterInstanceId)
end

local function DestroyAllPlayerItems(self, nCharacterInstanceId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local tbItemInstanceIds = BattleItemComponent:RemoveAllItemOnCharacter()
    RemoveItems(self, tbItemInstanceIds)
end

local function GetPositionNearbyCharacter(tbPlayer)
    local pUEActor = tbPlayer.pUEActor
    local pPos = pUEActor:K2_GetActorLocation()
    local tbTransform = {}
    tbTransform.X = pPos.X
    tbTransform.Y = pPos.Y
    tbTransform.Z = pPos.Z
    tbTransform.Yaw = 0
    return tbTransform
end

local function ClearAllDelayTimer(self)
    if self.tbDelayTimerHandle ~= nil then
        for i, v in ipairs(self.tbDelayTimerHandle) do
            if v then
                DelayTimer:ClearTimer(v)
                self.tbDelayTimerHandle[i] = nil
            end
        end
    end
    self.tbDelayTimerHandle = {}
end

local function CanDropShipWhenDie(tbGameObject)
    if GameObjectTypeDef.Npc == tbGameObject.ObjectType then
        return false
    end
    return true
end

local function RemoveShipInstanceId(self, tbItemInstanceIds)
    local nShipIndex = 0
    for i, v in ipairs(tbItemInstanceIds) do
        local Item = self:GetItem(v)
        if Item:GetCategory() == BattleItemCategoryDef.SHIP then
            nShipIndex = i
            break
        end
    end
    if nShipIndex > 0 then
        local nInstanceId = tbItemInstanceIds[nShipIndex]
        table.remove(tbItemInstanceIds, nShipIndex)
        self:DestroyItem(nInstanceId)
    end
end

local function CreateSceneItemPackageItemWhenCharacterDie(self, tbItemInstanceIds, szCharacterName, tbTransform, bIsShip, nHumanMovementStateType, bCanDropShipWhenDie, bHumanNpc)
    if not bCanDropShipWhenDie then
        RemoveShipInstanceId(self, tbItemInstanceIds)
    end
    local nItemTemplateId = FFAItemIni.tbSceneItemPackage.nPlayerDieHumanBoxTemplateId
    if bIsShip then
        nItemTemplateId = FFAItemIni.tbSceneItemPackage.nPlayerDieShipBoxTemplateId
    end
    local CreateDieBoxFunc = function()
        if tbItemInstanceIds == nil or #tbItemInstanceIds == 0 then
            logerror("Die box cannot create. No item drop.", szCharacterName)
            return
        end
        local BoxItem = SceneItemContainer:CreateSceneItemPackageItemWhenCharacterDie(nItemTemplateId, tbTransform, bIsShip, nHumanMovementStateType)
        SceneItemContainer:AddItemsWhenPlayerDie(BoxItem:GetInstanceId(), tbItemInstanceIds, szCharacterName, tbTransform)
    end
    local nDelayTime = bIsShip and SHIP_DELAY_SECOND_CREATE_DIE_BOX or HUMAN_DELAY_SECOND_CREATE_DIE_BOX
    if bHumanNpc then
        nDelayTime = NPC_DELAY_SECOND_CREATE_DIE_BOX
    end

    if self.nGmDelayCreateDieBoxSecond then
        nDelayTime = self.nGmDelayCreateDieBoxSecond
    end
    if nDelayTime > 0 then
        log("Delay create die box, delay time =", nDelayTime)
        local DelayHandle = DelayTimer:DelayRun(CreateDieBoxFunc, nDelayTime)
        table.insert(self.tbDelayTimerHandle, DelayHandle)
    else
        CreateDieBoxFunc()
    end
end

-- 处理玩家死亡后的物品处理
local function OnPlayerDie(self, tbPlayer)
    local nCharacterInstanceId = tbPlayer.nServerInstanceId

    -- todo @zhiyuan 为了支持老的pvp副本，所以临时加了这个判断，以后需要讨论下是不是把死亡后的处理交给玩法去控制
    local tbDungeonData = BattleGameModeSystem:GetDungeonTemplateData()
    if tbDungeonData.nType == DungeonTypeDefine.OLD_PVP then
        DestroyAllPlayerItems(self, nCharacterInstanceId)
        return
    end

    ClearItemBuildingData(self, nCharacterInstanceId)

    local tbItemInstanceIds = RemoveAllItemOnCharacter(nCharacterInstanceId)

    local szCharacterName = tbPlayer.szName
    local bIsShip = tbPlayer:IsShip()
    local nHumanMovementStateType = nil
    local bHumanNpc = false
    if not bIsShip then
        nHumanMovementStateType = tbPlayer.HumanMovementStateComponent:GetCurrentState()
        if tbPlayer.ObjectType == GameObjectTypeDef.Npc then
            bHumanNpc = true
        end
    end
    local tbTransform = GetPositionNearbyCharacter(tbPlayer)

    CreateSceneItemPackageItemWhenCharacterDie(self, tbItemInstanceIds, szCharacterName, tbTransform, bIsShip, nHumanMovementStateType, CanDropShipWhenDie(tbPlayer), bHumanNpc)
end

local function SetIsChangingShip(self, nCharacterInstanceId, bIsChanging)
    self.tbIsChangingShip[nCharacterInstanceId] = bIsChanging
end

local function ProcessEquippedItemsWhenPlayerShipChanged(self, nCharacterInstanceId, tbEquipmentItems)
    for _, Item in pairs(tbEquipmentItems) do
        -- todo @zhiyuan 后面调整物品安装层级关系来去掉这个特殊判断
        if Item:GetCategory() ~= BattleItemCategoryDef.SHIP then
            local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
            -- if nSlotIndex ~= nil and nSlotIndex ~= -1 then
            --     if not CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item) then
            --         nRoomType, nOwnerInstanceId, nSlotIndex = GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, Item:GetTemplateId(), true)
            --     end
            -- else
            --     nRoomType, nOwnerInstanceId, nSlotIndex = GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, Item:GetTemplateId(), true)
            -- end
            Item:ClearStorageLocation()
            if CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item) then
                EquipItem(self, nCharacterInstanceId, Item, nRoomType, nOwnerInstanceId, nSlotIndex, true)
            else
                UnEquipItem(self, nCharacterInstanceId, Item, nil, true)
            end
        end
    end
end

-- 同步让客户端重置物品数据
local function SyncD2CResetBattleItemData(self, tbPlayer)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local tbItemDatas = self:GetAllItemProtoDatas(nCharacterInstanceId)
    local nGrade = GetShipBuiltGrade(self, nCharacterInstanceId)
    BattleItemSystemProtocalHelper:SyncD2CResetBattleItemData(tbPlayer, tbItemDatas, nGrade)
end

local function ResetPlayerItems(self, nCharacterInstanceId, tbInitItems)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    ClearShipBuiltGrade(self, nCharacterInstanceId)
    DestroyAllPlayerItems(self, nCharacterInstanceId)
    self:AddInitItems(nCharacterInstanceId, tbInitItems)
    SyncD2CResetBattleItemData(self, tbPlayer)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_RESET_PLAYER_ITEMS_SERVER, nCharacterInstanceId, tbInitItems)
end

local function OnChangeDisplay(self, tbPlayer)
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    if tbPlayer:IsShip() then
        if not self:IsChangingShip(nCharacterInstanceId) then
            BattleItemSystemHelper:OnChangeToShip(BattleItemComponent, false)
        end
    elseif tbPlayer:IsHuman() then
        BattleItemSystemHelper:OnChangeToHuman(BattleItemComponent, false)
    end
end

local function OnPlayerPostLogin(self, tbPlayer)
    self:ResetBattleItemsFromPrepareInfo(tbPlayer:GetServerInstanceId())
    BattleItemSystemProtocalHelper:SyncD2CSyncShipPreparation(tbPlayer)
end

local function OnPlayerRelogin(self, tbPlayer)
    SyncD2CResetBattleItemData(self, tbPlayer)
    BattleItemSystemProtocalHelper:SyncD2CSyncShipPreparation(tbPlayer)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_RESET_AFTER_RELOGIN_SERVER, tbPlayer)
end

local function IsParachuting(self, nCharacterInstanceId)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    if not tbPlayer:IsHuman() then
        return
    end
    local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
    return HumanMovementStateComponent:IsInParachuting()
end

local function IsPlayerAlive(nCharacterInstanceId)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    if tbPlayer:IsDead() then
        return false
    end
    return true
end

local function IsPlayerDying(nCharacterInstanceId)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    if tbPlayer:IsDying() then
        return true
    end
    return false
end

local function OnPlayerLogout(self, tbPlayer)
    local nCharacterInstanceId = tbPlayer.nServerInstanceId
    -- DestroyAllPlayerItems(self, nCharacterInstanceId)
    CancelBuildItem(self, nCharacterInstanceId, false)
end

local function GetItemRoom(self, nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        error("GetItemRoom failed! nItemInstanceId".. nItemInstanceId)
    end
    if Item:GetOwnerCharacter() then
        local BattleItemComponent = GetBattleItemComponent(Item:GetOwnerCharacterInstanceId())
        return BattleItemComponent:GetItemRoom(Item:GetInstanceId())
    else
        return SceneItemContainer:GetOwnerItemRoom(Item)
    end
end

local function GetUnequippedRemoveItemDatas(nCharacterInstanceId, tbItems, nCount)
    local tbRemoveItems = {}
    local nRemainCount = nCount
    for _, v in pairs(tbItems) do
        local tbRemoveItem = {}
        tbRemoveItem.Item = v
        local nStackCount = v:GetStackCount()
        if nCount == 0 then
            tbRemoveItem.nRemoveCount = nStackCount
            nRemainCount = nRemainCount - nStackCount
        elseif nRemainCount >= nStackCount then
            tbRemoveItem.nRemoveCount = nStackCount
            nRemainCount = nRemainCount - nStackCount
        else
            tbRemoveItem.nRemoveCount = nRemainCount
            nRemainCount = 0
        end
        table.insert(tbRemoveItems, tbRemoveItem)
        if nRemainCount == 0 then
            break
        end
    end
    return tbRemoveItems
end

local function MoveEquipmentItemsOnItem(self, nCharacterInstanceId, OldOwnerItem, NewOwnerItem, nSlotIndex, bSyncToClient)
    if nCharacterInstanceId < 0 then
        return
    end
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    -- nSlotIndex大于0表示更换安装位置，这时候只需要调用OnUnequip
    -- 有NewOwnerItem但是还未安装，那只调用OnUnequip，不真的卸下
    if (nSlotIndex and nSlotIndex > 0) or (NewOwnerItem and not BattleItemRoomDef:IsEquipmentRoom(NewOwnerItem:GetStorageLocation().nRoomType)) then
        BattleItemSystemHelper:OnUnequipItemsOnItem(BattleItemComponent, OldOwnerItem)
    else
        local nOldOwnerItemInstanceId = OldOwnerItem:GetInstanceId()
        local tbRooms = BattleItemComponent:GetAllEquipmentItemRoomsWhichOwnerIsItem(nOldOwnerItemInstanceId)
        if tbRooms == nil then
            return
        end

        for _, Room in pairs(tbRooms) do
            local nInstanceIds = Room:GetAllItemInstanceIds()
            for nSlot, nInstanceId in pairs(nInstanceIds) do
                local Item = self:GetItem(nInstanceId)
                if not NewOwnerItem then
                    UnEquipItem(self, nCharacterInstanceId, Item, nil, bSyncToClient)
                else
                    if BattleItemSystemHelper:CanAutoEquipWhenOwnerChanged(Item)
                        and CheckItemSlotCompatibility(nCharacterInstanceId, NewOwnerItem:GetInstanceId(), nSlot, Item) then
                        EquipItem(self, nCharacterInstanceId, Item, Room:GetRoomType(), NewOwnerItem:GetInstanceId(), nSlot, bSyncToClient)
                    else
                        UnEquipItem(self, nCharacterInstanceId, Item, nil, bSyncToClient)
                    end
                end
            end
        end
        BattleItemComponent:RemoveEquipmentItemRoomsWhichOwnerIsItem(nOldOwnerItemInstanceId)
    end
end

local function AddItemToPlayerRoom(self, NewItemRoom, Item, nNewSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    local tbPlayer = NewItemRoom:GetOwnerCharacter()
    local nCharacterInstanceId = tbPlayer.nServerInstanceId
    -- 考虑槽位上有东西需要卸下来
    local OldItem = nil
    if BattleItemRoomDef:IsEquipmentRoom(NewItemRoom:GetRoomType()) then
        OldItem = NewItemRoom:GetItemBySlotIndex(nNewSlotIndex, false)
        if OldItem ~= nil then
            if bDestroyOld then
                self:DestroyPlayerItem(nCharacterInstanceId, OldItem:GetInstanceId(), Item)
            else
                UnEquipItem(self, nCharacterInstanceId, OldItem, Item, bSyncToClient)
            end
        end
    end

    local nItemInstanceId = Item:GetInstanceId()
    local bResult = NewItemRoom:AddItem(nItemInstanceId, nNewSlotIndex)
    -- luacheck: push ignore
    if not bResult then
        -- todo @zhiyuan 考虑背包满了装不进去的情况
    end
    -- luacheck: pop
    Item:SetOwnerCharacter(tbPlayer)
    local nRoomType = NewItemRoom:GetRoomType()
    local nRoomId = NewItemRoom:GetRoomId()
    Item:SetStorageLocation(nRoomType, nRoomId, nNewSlotIndex)

    if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
        local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
        BattleItemSystemHelper:OnEquipItem(BattleItemComponent, Item)
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_EQUIPED_SERVER, tbPlayer, Item, nRoomId, nNewSlotIndex, Item:GetStackCount(), nBattleItemSource)
    end
    return OldItem
end

local function AddItemToScene(nCharacterInstanceId, NewItemRoom, Item)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    local tbTransform = GetPositionNearbyCharacter(tbPlayer)
    local bIsShip = tbPlayer:IsShip()
    local nHumanMovementStateType = nil
    if not bIsShip then
        nHumanMovementStateType = tbPlayer.HumanMovementStateComponent:GetCurrentState()
    end
    SceneItemContainer:AddItem(NewItemRoom, Item, tbTransform, bIsShip, nHumanMovementStateType)
end

local function AddItemToRoom(self, nCharacterInstanceId, NewItemRoom, Item, nNewSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    if NewItemRoom == nil or NewItemRoom:GetRoomType() == BattleItemRoomDef.SCENE_ITEM_ROOM then
        Item:SetLastOwnerCharacterInstanceId(nCharacterInstanceId)
        AddItemToScene(nCharacterInstanceId, NewItemRoom, Item)
        return nil
    else
        return AddItemToPlayerRoom(self, NewItemRoom, Item, nNewSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    end
end

local function RemoveItemFromPlayerRoom(OldItemRoom, Item)
    Item:PreRemoveFromPlayer(false)
    local nItemInstanceId = Item:GetInstanceId()
    OldItemRoom:RemoveItemByInstanceId(nItemInstanceId)
    Item:ClearStorageLocationAndOwner()
end

local function CreateAndThrowAwayItem(self, nCharacterInstanceId, nItemTemplateId, nCount, bSyncToClient)
    local NewItem = self:CreateItem(nItemTemplateId, nCount)
    AddItemToRoom(self, nCharacterInstanceId, nil, NewItem, nil, nil, nil, true)
end

local function CreateAndAddItemToScene(self, nCharacterInstanceId, nItemTemplateId, nCount)
    local tbPlayer = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    local tbTransform = GetPositionNearbyCharacter(tbPlayer)
    return SceneItemContainer:CreateSceneItem(nItemTemplateId, nCount, tbTransform, SceneItemActorDef.ITEM, true)
end

local function RemoveItemFromRoom(self, nCharacterInstanceId, Item, nCount, NewItem, nNewSlotIndex, bSyncToClient)
    local nStackCount = Item:GetStackCount()
    local nRemainCount = 0
    if nCount ~= nil and nCount > 0 then
        nRemainCount = nStackCount - nCount
    end

    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local nItemTemplateId = Item:GetTemplateId()
    local nItemInstanceId = Item:GetInstanceId()

    local OldItemRoom = GetItemRoom(self, Item:GetInstanceId())
    if OldItemRoom and BattleItemRoomDef:IsEquipmentRoom(OldItemRoom:GetRoomType()) then
        local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
        BattleItemSystemHelper:OnUnequipItem(BattleItemComponent, Item)
    end

    MoveEquipmentItemsOnItem(self, nCharacterInstanceId, Item, NewItem, nNewSlotIndex, bSyncToClient)
    if OldItemRoom == nil or OldItemRoom:GetRoomType() == BattleItemRoomDef.SCENE_ITEM_ROOM then
        SceneItemContainer:RemoveItem(Item, bSyncToClient)
        if nRemainCount > 0 and nCharacterInstanceId ~= nil and nCharacterInstanceId > 0 then
            local tbRemainItem = CreateAndAddItemToScene(self, nCharacterInstanceId, nItemTemplateId, nRemainCount)
            EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_REMAIN_SERVER, tbRemainItem)
        end
    else
        RemoveItemFromPlayerRoom(OldItemRoom, Item)
    end

    if OldItemRoom and BattleItemRoomDef:IsEquipmentRoom(OldItemRoom:GetRoomType()) then
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_UNEQUIPED_SERVER, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nRoomType, nOwnerInstanceId, nSlotIndex, nStackCount, NewItem ~= nil)
        return true
    end
    return false
end

local function CheckCancelBuildItem(self, nCharacterInstanceId, nItemTemplateId)
    local tbBuildingData = GetItemBuildingData(self, nCharacterInstanceId)
    if tbBuildingData ~= nil then
        if tbBuildingData.nItemTemplateId == nItemTemplateId then
            logerror("BattleItemSystemServer:BuildItem failed! Already Building nItemTemplateId!", nItemTemplateId)
            return
        end
        CancelBuildItem(self, nCharacterInstanceId, true)
    end
end

local function OnRemoveItem(self, nCharacterInstanceId, nItemInstanceId, nItemTemplateId)
    CheckCancelBuildItem(self, nCharacterInstanceId, nItemTemplateId)
end

local function OnChangeStackCount(self, Item, bAdd)
    if not bAdd then
        CheckCancelBuildItem(self, Item:GetOwnerCharacterInstanceId(), Item:GetTemplateId())
    end
end

local function FireEventDecreasePlayerItem(tbPlayer, nItemTemplateId, nCount)
    EventManager:OnFireEvent(CommonEventDef.EV_DECREASE_PLAYER_BATTLE_ITEM_SERVER, tbPlayer, nItemTemplateId, nCount)
end

local function FireEventAndSyncRemoveItem(self, tbPlayer, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    BattleItemSystemProtocalHelper:SyncRemoveItem(tbPlayer, nItemInstanceId)
    OnRemoveItem(self, nCharacterInstanceId, nItemInstanceId, nItemTemplateId)
end

local function FireEventAndSyncAddItem(NewItemRoom, Item)
    if NewItemRoom:HasOwnerCharacter() then
        BattleItemSystemProtocalHelper:SyncAddItem(Item)
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER, Item)
    else
        error("Cannot move item from a scene-room to another scene-room!")
    end
end

local function FireEventAndSyncItemStorageLocation(Item, nOldRoomType)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STORAGE_LOCATION_SERVER, Item, nOldRoomType)
    BattleItemSystemProtocalHelper:SyncItemStorageLocation(Item)
end

local function FireEventAndSyncItemStackCount(self, Item, bAdd, bSyncToClient)
    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER, Item, bAdd)
    if Item:HasOwnerCharacter() and bSyncToClient then
        BattleItemSystemProtocalHelper:SyncItemStackCount(Item)
    end
    OnChangeStackCount(self, Item, bAdd)
end

local function FireBuildFinishEvent(nCharacterInstanceId, nItemInstanceId, nItemTemplateId, tbCosts)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == BattleItemCategoryDef.SHIP then
        local nShipId = tbItemTemplate.nShipId
        EventManager:OnFireEvent(CommonEventDef.EV_SHIP_BUILD_FINISH_SERVER, nCharacterInstanceId, nShipId)
    end
    local tbPlayer = GetPlayer(nCharacterInstanceId)

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_BUILD_FINISH_SERVER, tbPlayer, nItemInstanceId, nItemTemplateId, tbCosts)
end

local function DecreaseStackCount(self, Item, nDelta)
    Item:DecreaseStackCount(nDelta)
    FireEventAndSyncItemStackCount(self, Item, false, true)
end

local function SyncDataWhenMoveItemFromOldRoomToNew(self, nCharacterInstanceId, OldItemRoom, NewItemRoom, Item, bIsNew)
    local nItemInstanceId = Item:GetInstanceId()
    local nItemTemplateId = Item:GetTemplateId()

    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()

    if bIsNew then
        FireEventAndSyncAddItem(NewItemRoom, Item)
        return
    end
    if NewItemRoom ~= nil and NewItemRoom:HasOwnerCharacter() then
        if OldItemRoom == nil or OldItemRoom:GetOwnerCharacter() == NewItemRoom:GetOwnerCharacter() then
            local nOldRoomType = BattleItemRoomDef.SCENE_ITEM_ROOM
            if OldItemRoom then
                nOldRoomType = OldItemRoom:GetRoomType()
            end
            FireEventAndSyncItemStorageLocation(Item, nOldRoomType)
        else
            error("Cannot move item from one player to another!")
        end
    else
        FireEventAndSyncRemoveItem(self, GetPlayer(nCharacterInstanceId),
            nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    end
end

local function MoveItemToEquippedRoom(self, nCharacterInstanceId, BattleItemComponent, Item, nEquippedSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    local nRoomType, nOwnerInstanceId, nSlotIndex = GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, Item:GetTemplateId())
    if nOwnerInstanceId == -1 or nSlotIndex == -1 then
        logwarning("Cannot find slot to equip!", nRoomType, nOwnerInstanceId, nSlotIndex, Item:GetTemplateId())
        return false
    end
    if nEquippedSlotIndex and nEquippedSlotIndex > 0 and nSlotIndex ~= nEquippedSlotIndex then
        nSlotIndex = nEquippedSlotIndex
        if not CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item) then
            logerror("Cannot equip item to slotindex!nRoomType:", nRoomType, nOwnerInstanceId, nSlotIndex, Item:GetTemplateId())
            return false
        end
    end
    local NewItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nOwnerInstanceId)
    MoveItem(self, nCharacterInstanceId, Item, nil, NewItemRoom, nSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    return true
end

local function AddItemToUnequippedRoomAfterCheck(self, nCharacterInstanceId, Item, NewItemRoom, tbCheckResult, nBattleItemSource, bSyncToClient)
    local bRemove = true
    local nTemplateId = Item:GetTemplateId()
    local nNeedAdd = tbCheckResult.nCanAddCount
    local tbStackItemDatas = tbCheckResult.tbStackItemDatas
    if tbStackItemDatas then
        for _, v in pairs(tbStackItemDatas) do
            local StackItem = v.StackItem
            local nStackCount = v.nStackCount
            StackItem:AddStackCount(nStackCount)
            FireEventAndSyncItemStackCount(self, StackItem, true, bSyncToClient)
            nNeedAdd = nNeedAdd - nStackCount
        end
    end
    local nNeedAddSlotCount = tbCheckResult.nNeedAddSlotCount
    if nNeedAddSlotCount > 0 then
        for i = 1, nNeedAddSlotCount do
            local nCountOnOneSlot = 0
            if i == nNeedAddSlotCount then
                nCountOnOneSlot = nNeedAdd
            else
                local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
                if tbTemplate.bStackable then
                    nCountOnOneSlot = tbTemplate.nStackLimit
                else
                    nCountOnOneSlot = 1
                end
            end
            local ItemOnOneSlot = nil
            if i == 1 and tbCheckResult.bCanAddAll then
                ItemOnOneSlot = Item
                ItemOnOneSlot:SetStackCount(nCountOnOneSlot)
                bRemove = false
            else
                ItemOnOneSlot = self:CreateItem(nTemplateId, nCountOnOneSlot)
            end
            MoveItem(self, nCharacterInstanceId, ItemOnOneSlot, nil, NewItemRoom, nil, nil, false, nBattleItemSource, bSyncToClient)
            nNeedAdd = nNeedAdd - nCountOnOneSlot
        end
    end
    return bRemove
end

local function MoveItemToUnequippedRoomAfterCheck(self, nCharacterInstanceId, Item, NewItemRoom, tbCheckResult, nBattleItemSource, bSyncToClient)
    if tbCheckResult.bCanAddAll or tbCheckResult.bCanAddAPart then
        local bRemove = AddItemToUnequippedRoomAfterCheck(self, nCharacterInstanceId, Item, NewItemRoom, tbCheckResult, nBattleItemSource, bSyncToClient)
        if bRemove then
            local nOwnerCharacterInstanceId = Item:GetOwnerCharacterInstanceId()
            local nItemInstanceId = Item:GetInstanceId()
            local nItemTemplateId = Item:GetTemplateId()
            local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
            local bUnequip = RemoveItemFromRoom(self, nCharacterInstanceId, Item, tbCheckResult.nCanAddCount, nil, nil, true)
            if nOwnerCharacterInstanceId > 0 and bSyncToClient then
                FireEventAndSyncRemoveItem(self, GetPlayer(nCharacterInstanceId), nItemInstanceId, nItemTemplateId,
                nOwnerCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
            end
            if bUnequip then
                EventManager:OnFireEvent(CommonEventDef.EV_AFTER_BATTLE_ITEM_UNEQUIPED_SERVER, nCharacterInstanceId, nItemTemplateId, nSlotIndex, false)
            end
            RemoveItem(self, nItemInstanceId)
        end
        return true
    else
        -- 背包满了
        return false
    end
end

local function MoveItemToUnequippedRoom(self, nCharacterInstanceId, BattleItemComponent, Item, nBattleItemSource, bSyncToClient)
    local nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(Item:GetCategory())
    local NewItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nCharacterInstanceId)

    local nTemplateId = Item:GetTemplateId()
    local tbCheckResult = NewItemRoom:CheckAddItem(false, nTemplateId, Item:GetStackCount())
    return MoveItemToUnequippedRoomAfterCheck(self, nCharacterInstanceId, Item, NewItemRoom, tbCheckResult, nBattleItemSource, bSyncToClient), tbCheckResult
end

local function CanAddToInventoryRoom(self, nCharacterInstanceId, Item)
    return BattleItemSystemHelper:CanAddToInventoryRoom(nCharacterInstanceId, Item:GetTemplateIdAfterAddToCharacter(), false)
end

local function CanAddToEquippedRoom(self, nCharacterInstanceId, Item, nEquippedSlotIndex)
    local _, nOwnerInstanceId, nSlotIndex = GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, Item:GetTemplateId())
    if nOwnerInstanceId == -1 or nSlotIndex == -1 then
        return false
    end
    if nEquippedSlotIndex and nEquippedSlotIndex > 0 and nSlotIndex ~= nEquippedSlotIndex then
        nSlotIndex = nEquippedSlotIndex
        if not CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item) then
            return false
        end
    end
    return true
end

local function CanAddToCharacter(self, nCharacterInstanceId, Item, nEquippedSlotIndex)
    local nCategory = Item:GetCategoryAfterAddToCharacter()
    if BattleItemCategoryDataTable:CanInUnequippedRoom(nCategory) then
        local nOwnerInstanceId, nSlotIndex = -1, -1
        if BattleItemCategoryDataTable:CanInEquippedRoom(nCategory) then
            local _, nOwnerId, nSlot =  GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, Item:GetTemplateId(), true)
            nOwnerInstanceId, nSlotIndex = nOwnerId, nSlot
        end
        if nOwnerInstanceId == -1 or nSlotIndex == -1 then
            return CanAddToInventoryRoom(self, nCharacterInstanceId, Item)
        else
            return CanAddToEquippedRoom(self, nCharacterInstanceId, Item, nEquippedSlotIndex)
        end
    elseif BattleItemCategoryDataTable:CanInEquippedRoom(nCategory) then
        return CanAddToEquippedRoom(self, nCharacterInstanceId, Item, nEquippedSlotIndex)
    end
    return false
end

local function MoveItemToCharacter(self, nCharacterInstanceId, Item, nEquippedSlotIndex, nBattleItemSource, bSyncToClient)
    if not CanAddToCharacter(self, nCharacterInstanceId, Item, nEquippedSlotIndex) then
        return false, nil
    end
    local AddedItem = BeforeAddedToCharacterOnServer(self, nCharacterInstanceId, Item)
    local bSuccess = true

    local nAddedItemCount = AddedItem:GetStackCount();
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local nCategory = AddedItem:GetCategory()
    if BattleItemCategoryDataTable:CanInUnequippedRoom(nCategory) then
        local nOwnerInstanceId, nSlotIndex = -1, -1
        -- 如果是可叠加物品，就都不会自动装备
        if not AddedItem:IsStackable() and BattleItemCategoryDataTable:CanInEquippedRoom(nCategory) then
            local _, nOwnerId, nSlot =  GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, AddedItem:GetTemplateId(), true)
            nOwnerInstanceId, nSlotIndex = nOwnerId, nSlot
        end
        if nOwnerInstanceId == -1 or nSlotIndex == -1 then
            local tbCheckResult = nil
            bSuccess, tbCheckResult = MoveItemToUnequippedRoom(self, nCharacterInstanceId, BattleItemComponent, AddedItem, nBattleItemSource, bSyncToClient)
            nAddedItemCount = tbCheckResult.nCanAddCount
        else
            bSuccess = MoveItemToEquippedRoom(self, nCharacterInstanceId, BattleItemComponent, AddedItem, nEquippedSlotIndex, nil, nBattleItemSource, bSyncToClient)
        end
    elseif BattleItemCategoryDataTable:CanInEquippedRoom(nCategory) then
        -- 建造船要把旧船销毁
        local bDestroyOld = false
        local bIsInitOrBuild = (nBattleItemSource == BattleItemSourceDef.INIT or nBattleItemSource == BattleItemSourceDef.BUILD)
        if nCategory == BattleItemCategoryDef.SHIP and bIsInitOrBuild then
            bDestroyOld = true
        end
        bSuccess = MoveItemToEquippedRoom(self, nCharacterInstanceId, BattleItemComponent, AddedItem, nEquippedSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    end
    AddedItem:AfterAddedToCharacterOnServer(nBattleItemSource, bSyncToClient)
    AddedItem:SetOnceOwned()
    return bSuccess, AddedItem, nAddedItemCount
end

local function fnSortByStackCountDescendingOrder(ItemA, ItemB)
    return ItemA:GetStackCount() < ItemB:GetStackCount()
end

-- @return tbCheckResult
--         tbCheckResult = {}
--         tbCheckResult.tbRemoveItems = {}        -- 需要删除的物品列表
--         tbCheckResult.NeedDecreaseItem = {}   -- 需要扣除数量的物品
--         tbCheckResult.nTotalEditCount = 0       -- 总共需要扣除的数量
local function CheckEquipStackableItem(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount, nSlotIndex)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local tbCheckResult = {}
    local tbItems = BattleItemComponent:GetUnequippedItems(nItemTemplateId)
    if #tbItems == 0 then
        return tbCheckResult
    end
    local nRemainCount = GetRemainStackCountOnEquipmentSlot(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId)
    table.sort(tbItems, fnSortByStackCountDescendingOrder)
    local tbRemoveItems = {}
    local NeedDecreaseItem = nil
    local nMaxDecreaseCount = math.min(nCount, nRemainCount)
    local nTotalEditCount = 0
    for _, v in pairs(tbItems) do
        local nStackCount = v:GetStackCount()
        if nStackCount <= nMaxDecreaseCount then
            table.insert(tbRemoveItems, v)
            nTotalEditCount = nTotalEditCount + nStackCount
            nMaxDecreaseCount = nMaxDecreaseCount - nStackCount
        else
            NeedDecreaseItem = v
            nTotalEditCount = nTotalEditCount + nMaxDecreaseCount
            nMaxDecreaseCount = 0
        end
        if nMaxDecreaseCount == 0 then
            break
        end
    end
    tbCheckResult.tbRemoveItems = tbRemoveItems
    tbCheckResult.NeedDecreaseItem = NeedDecreaseItem
    tbCheckResult.nTotalEditCount = nTotalEditCount
    return tbCheckResult
end

local function DecreaseStackableItemAfterCheck(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, nCount, tbCheckResult)
    local nTotalEditCount = tbCheckResult.nTotalEditCount
    if nTotalEditCount == nil or nTotalEditCount == 0 then
        logerror("Cannot find item to equip!", nItemTemplateId)
        return false
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = self:GetEquippedItem(nCharacterInstanceId, tbTemplate.nCategory, nOwnerInstanceId, nSlotIndex)

    local nNeedDecreaseCount = nTotalEditCount
    local tbRemoveItems = tbCheckResult.tbRemoveItems

    local bNeedSendEquipResponse = false
    if tbRemoveItems ~= nil then
        for _, v in pairs(tbRemoveItems) do
            nNeedDecreaseCount = nNeedDecreaseCount - v:GetStackCount()
            assert(nNeedDecreaseCount >= 0, "nNeedDecreaseCount < 0 !!!")
            if EquippedItem == nil then
                self:EquipItem(nCharacterInstanceId, nOwnerInstanceId, v:GetInstanceId(), nSlotIndex, false)
                bNeedSendEquipResponse = true
                EquippedItem = v
                nTotalEditCount = nTotalEditCount - v:GetStackCount()
            else
                self:DestroyPlayerItem(nCharacterInstanceId, v:GetInstanceId())
            end
        end
    end

    local NeedDecreaseItem = tbCheckResult.NeedDecreaseItem
    if NeedDecreaseItem then
        DecreaseStackCount(self, NeedDecreaseItem, nNeedDecreaseCount)
        nNeedDecreaseCount = 0
    end

    return true, EquippedItem, nTotalEditCount, bNeedSendEquipResponse
end

local function CreateAndEquipItemWithSlot(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, nStackCount, nBattleItemSource, bSyncToClient)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local EquippedItem = self:CreateItem(nItemTemplateId, nStackCount)
    local nRoomType = BattleItemCategoryDataTable:GetEquippedRoomType(EquippedItem:GetCategory())
    local NewItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nOwnerInstanceId)
    MoveItem(self, nCharacterInstanceId, EquippedItem, nil, NewItemRoom, nSlotIndex, nil, nBattleItemSource, bSyncToClient)
    return EquippedItem
end

local function DoCreateAndAddItemToCharacter(self, nCharacterInstanceId, nItemTemplateId, nStackCount, nBattleItemSource, bSyncToClient)
    local Item = self:CreateItem(nItemTemplateId, nStackCount)
    MoveItemToCharacter(self, nCharacterInstanceId, Item, nil, nBattleItemSource, bSyncToClient)
end

local function CheckCanAdd(nItemTemplateId, nBattleItemSource)
    if BattleItemSystemHelper:CanKnownByPlayer(nItemTemplateId) then
        return true
    else
        if nBattleItemSource == BattleItemSourceDef.INIT
            or nBattleItemSource == BattleItemSourceDef.GM
            or nBattleItemSource == BattleItemSourceDef.DEFAULT_WEAPON then
            return true
        else
            return false
        end
    end
end

local function CreateAndAddItemToCharacter(self, nCharacterInstanceId, nItemTemplateId, nStackCount, nBattleItemSource, bSyncToClient)
    if not CheckCanAdd(nItemTemplateId, nBattleItemSource) then
        return
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local bStackable = tbTemplate.bStackable
    local nStackLimit = tbTemplate.nStackLimit
    if not bStackable then
        nStackLimit = 1
    end
    local nCount = nStackCount
    while nCount > 0 do
        if nCount <= nStackLimit then
            DoCreateAndAddItemToCharacter(self, nCharacterInstanceId, nItemTemplateId, nCount, nBattleItemSource, bSyncToClient)
            nCount = 0
        else
            DoCreateAndAddItemToCharacter(self, nCharacterInstanceId, nItemTemplateId, nStackLimit, nBattleItemSource, bSyncToClient)
            nCount = nCount - nStackLimit
        end
    end
end

local function IncreaseEquippedStackableItem(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, EquippedItem, nTotalEditCount, bNeedSendEquipResponse)
    if EquippedItem == nil then
        EquippedItem = CreateAndEquipItemWithSlot(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, nTotalEditCount, BattleItemSourceDef.CHANG_POS, true)
    else
        if nTotalEditCount > 0 then
            EquippedItem:AddStackCount(nTotalEditCount)
        end
        EquippedItem:OnEquip(false)
        if bNeedSendEquipResponse then
            local nOldRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(EquippedItem:GetCategory())
            FireEventAndSyncItemStorageLocation(EquippedItem, nOldRoomType)
            if nTotalEditCount > 0 then
                FireEventAndSyncItemStackCount(self, EquippedItem, true, true)
            end
        else
            FireEventAndSyncItemStackCount(self, EquippedItem, true, true)
        end
    end
    return EquippedItem
end

local function EquipStackableItemNormally(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount, nSlotIndex)
    local tbCheckResult = CheckEquipStackableItem(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount, nSlotIndex)

    local bSuccess, EquippedItem, nTotalEditCount, bNeedSendEquipResponse =
        DecreaseStackableItemAfterCheck(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, nCount, tbCheckResult)
    if not bSuccess then
        return
    end
    EquippedItem = IncreaseEquippedStackableItem(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, EquippedItem, nTotalEditCount, bNeedSendEquipResponse)

    BattleItemSystemProtocalHelper:SyncD2CEquipStackableItem(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.OK, nOwnerInstanceId, nItemTemplateId, nCount, tbCheckResult.nTotalEditCount)
end

local function EquipStackableItemWithoutDecrease(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount, nSlotIndex)
    local nRemainCount = GetRemainStackCountOnEquipmentSlot(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId)
    local nIncreaseCount = math.min(nCount, nRemainCount)

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = self:GetEquippedItem(nCharacterInstanceId, tbTemplate.nCategory, nOwnerInstanceId, nSlotIndex)
    if EquippedItem then
        EquippedItem:AddStackCount(nIncreaseCount)
        FireEventAndSyncItemStackCount(self, EquippedItem, true, true)
    else
        EquippedItem = CreateAndEquipItemWithSlot(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, nIncreaseCount, BattleItemSourceDef.UNLIMITED_BULLETS, true)
    end
    BattleItemSystemProtocalHelper:SyncD2CEquipStackableItem(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.OK, nOwnerInstanceId, nItemTemplateId, nCount, nIncreaseCount)
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
local function VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    return BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, false)
end

local function DecreaseItems(nCharacterInstanceId, nItemTemplateId, nItemCount, nSlotIndex)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    BattleItemComponent:DecreaseItems(nItemTemplateId, nItemCount, nSlotIndex)
end

local function PrerequisiteItemsCost(nCharacterInstanceId, nPrerequisiteId, nSlotIndex)
    DecreaseItems(nCharacterInstanceId, nPrerequisiteId, 1, nSlotIndex)
end

local function KeyItemsCost(nCharacterInstanceId, tbKeyItemIds)
    for _, v in ipairs(tbKeyItemIds) do
        DecreaseItems(nCharacterInstanceId, v, 1)
    end
end

local function MaterialCostItemsCost(nCharacterInstanceId, tbCosts)
    for nIndex, nCount in ipairs(tbCosts) do
        if nCount > 0 then
            local nItemTemplateId = MaterialItemHelper:GetMaterialTemplateId(nIndex)
            assert(nItemTemplateId ~= nil , "cannot find material template!index:"..nIndex)
            DecreaseItems(nCharacterInstanceId, nItemTemplateId, nCount)
        end
    end
end

local function ItemBuildingCost(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    local tbItemBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    assert(tbItemBuildTemplate ~= nil, "ItemBuilding template nil! "..nItemTemplateId)

    local nPrerequisiteId = tbItemBuildTemplate.nPrerequisiteId
    PrerequisiteItemsCost(nCharacterInstanceId, nPrerequisiteId, nSlotIndex)

    local tbKeyItemIds = tbItemBuildTemplate.tbKeyItemIds
    if tbKeyItemIds and #tbKeyItemIds > 0 then
        KeyItemsCost(nCharacterInstanceId, tbKeyItemIds)
    end

    local tbCosts = BattleItemSystemHelper:GetBuildMaterialCost(nCharacterInstanceId, nItemTemplateId, false)
    if tbCosts and #tbCosts > 0 then
        MaterialCostItemsCost(nCharacterInstanceId, tbCosts)
    end
    return tbCosts
end

local function BuildItemFinish(self, nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    --local bSucceeded, _ = VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId)
    --if not bSucceeded then
    --    logerror("Build Item Finish!But Verify Item Building failed!", nItemTemplateId)
    --end
    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        ClearItemBuildingData(self, nCharacterInstanceId)
        logerror("BuildItemFinish failed! player is dead or dying!", nCharacterInstanceId)
        return
    end
    local tbCosts = ItemBuildingCost(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    local Item = self:CreateItem(nItemTemplateId, 1)
    MoveItemToCharacter(self, nCharacterInstanceId, Item, nSlotIndex, BattleItemSourceDef.BUILD, true)
    ClearItemBuildingData(self, nCharacterInstanceId)

    local nItemInstanceId = Item:GetInstanceId()
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    BattleItemSystemProtocalHelper:SyncD2CBuildItemFinish(tbPlayer, nItemInstanceId)
    FireBuildFinishEvent(nCharacterInstanceId, nItemInstanceId, nItemTemplateId, tbCosts)
    AfterBuiltOnServer(nCharacterInstanceId, Item)
    log("[BuildItem]BuildItemFinish!", nCharacterInstanceId, nItemTemplateId, nSlotIndex)
end

local function GetBuildTime(self, tbPlayer, nItemTemplateId, nOriginTime)
    local ShipBattlePropertyComponent = tbPlayer.ShipBattlePropertyComponent
    local nAddValue1 = ShipBattlePropertyComponent:GetPropAddValue(PropName.nBuildingTimeAddition)
    local nMultiplyValue1 = ShipBattlePropertyComponent:GetPropMultiplyValue(PropName.nBuildingTimeAddition)
    local nAddValue2 = 0
    local nMultiplyValue2 = 1

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory

    if nCategory == BattleItemCategoryDef.SHIP then
        nAddValue2 = ShipBattlePropertyComponent:GetPropAddValue(PropName.nShipBuildingTimeAddition)
        nMultiplyValue2 = ShipBattlePropertyComponent:GetPropMultiplyValue(PropName.nShipBuildingTimeAddition)
    elseif nCategory == BattleItemCategoryDef.SHIP_PART then
        nAddValue2 = ShipBattlePropertyComponent:GetPropAddValue(PropName.nPartBuildingTimeAddition)
        nMultiplyValue2 = ShipBattlePropertyComponent:GetPropMultiplyValue(PropName.nPartBuildingTimeAddition)
    elseif nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        nAddValue2 = ShipBattlePropertyComponent:GetPropAddValue(PropName.nWeaponBuildingTimeAddition)
        nMultiplyValue2 = ShipBattlePropertyComponent:GetPropMultiplyValue(PropName.nWeaponBuildingTimeAddition)
    end

    local nTime = nOriginTime * (nMultiplyValue1 + nMultiplyValue2 - 1) + nAddValue1 + nAddValue2
    nTime = math.max(0, nTime)
    return nTime
end

local function BeginItemBuildingPrepare(self, nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    -- 已由ProgressBarComponent统一接管
    -- tbPlayer:StopMove(false)

    local fnBuildFinishCallback = function()
        BuildItemFinish(self, nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    end
    local fnBuildCancelCallback = function()
        CancelBuildItem(self, nCharacterInstanceId, true)
    end
    local tbItemBuildTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    local nProgressBar = tbItemBuildTemplate.nProgressBar
    local ProgressBarComponent = tbPlayer.ProgressBarComponent
    local nOriginTime = ProgressBarComponent:GetTime(nProgressBar)

    local nNewTime = GetBuildTime(self, tbPlayer, nItemTemplateId, nOriginTime)
    local bStartSuceeded = ProgressBarComponent:Start(nProgressBar, {}, fnBuildFinishCallback, fnBuildCancelCallback, nNewTime)

    if bStartSuceeded then
        AddItemBuildingData(self, nCharacterInstanceId, nItemTemplateId)
    end
    return bStartSuceeded
end

local function GetBuildItemRet(tbFailures)
    assert(#tbFailures > 0)
    return tbFailures[1].nType
end

local function ThrowAwayPartially(self, nCharacterInstanceId, Item, nCount)
    assert(Item:GetStackCount() > nCount, "Cannot ThrowAway partially!".."item stack count: ".. Item:GetStackCount().. ", nCount: ".. nCount)
    DecreaseStackCount(self, Item, nCount)
    CreateAndThrowAwayItem(self, nCharacterInstanceId, Item:GetTemplateId(), nCount, true)
end

local function ThrowAwayAll(self, nCharacterInstanceId, Item)
    MoveItem(self, nCharacterInstanceId, Item, nil, nil, nil, nil, nil, true)
end

local function UnEquipItemPartially(self, nCharacterInstanceId, Item, nCount)
    assert(Item:GetStackCount() > nCount, "Cannot Unequip partially!".."item stack count: ".. Item:GetStackCount().. ", nCount: ".. nCount)
    DecreaseStackCount(self, Item, nCount)
    CreateAndAddItemToCharacter(self, nCharacterInstanceId, Item:GetTemplateId(), nCount, BattleItemSourceDef.CHANG_POS, true)
end


local function ThrowAwayItem(self, nCharacterInstanceId, nItemInstanceId, nCount)
    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        logwarning("ThrowAwayItem failed!Item not found!", nItemInstanceId)
        return false
    end
    if Item:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        logwarning("ThrowAwayItem failed!Owner not match!".."owner instanceId:", Item:GetOwnerCharacterInstanceId(), nCharacterInstanceId)
        return false
    end

    local bCheckResult, nFailureReason = CanThrowAwayOnServer(self, nCharacterInstanceId, Item)
    if not bCheckResult then
        return false, BattleItemThrowAwayCheckFailureDef:ToReturnCode(nFailureReason)
    end

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_PRE_THROW_AWAY_ITEM_SERVER, Item)

    if nCount and nCount > 0 and Item:GetStackCount() > nCount then
        ThrowAwayPartially(self, nCharacterInstanceId, Item, nCount)
    else
        ThrowAwayAll(self, nCharacterInstanceId, Item)
    end

    return true, ProtoDC.ItemReturnCode.OK
end

local function GetItemInfosAfterRemoveCannotKnown(tbItemInfos)
    local tbItemInfoAfterCheck = {}
    for _, tbItemInfo in pairs(tbItemInfos) do
        local nItemTemplateId = tbItemInfo.nItemTemplateId
        if BattleItemSystemHelper:CanKnownByPlayer(nItemTemplateId) then
            table.insert(tbItemInfoAfterCheck, tbItemInfo)
        end
    end
    return tbItemInfoAfterCheck
end

MoveItem = function(self, nCharacterInstanceId, Item, NewItem, NewItemRoom, nNewSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    local bIsNew = true
    if Item:GetOwnerCharacterInstanceId() == nCharacterInstanceId then
        bIsNew = false
    end
    local _, _, nSlotIndex = Item:SplitAndGetStorageLocation()
    local OldItemRoom = GetItemRoom(self, Item:GetInstanceId())
    local bUnequip = RemoveItemFromRoom(self, nCharacterInstanceId, Item, nil, NewItem, nNewSlotIndex, bSyncToClient)
    local OldItem = AddItemToRoom(self, nCharacterInstanceId, NewItemRoom, Item, nNewSlotIndex, bDestroyOld, nBattleItemSource, bSyncToClient)
    if bSyncToClient then
        SyncDataWhenMoveItemFromOldRoomToNew(self, nCharacterInstanceId, OldItemRoom, NewItemRoom, Item, bIsNew)
    end
    if bUnequip then
        EventManager:OnFireEvent(CommonEventDef.EV_AFTER_BATTLE_ITEM_UNEQUIPED_SERVER, nCharacterInstanceId, Item:GetTemplateId(), nSlotIndex, NewItem ~= nil)
    end
    if OldItem ~= nil then
        MoveEquipmentItemsOnItem(self, nCharacterInstanceId, OldItem, Item, nil, bSyncToClient)
    end
end

UnEquipItem = function(self, nCharacterInstanceId, OldItem, NewItem, bSyncToClient)
    if OldItem:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        error("Owner not match!".."owner instanceId:"
        ..OldItem:GetOwnerCharacterInstanceId()..", nCharacterInstanceId:"..nCharacterInstanceId)
    end
    if not BattleItemSystemHelper:CanKnownByPlayer(OldItem:GetTemplateId()) then
        self:DestroyPlayerItem(nCharacterInstanceId, OldItem:GetInstanceId(), NewItem)
        return
    end
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local nCategory = OldItem:GetCategory()
    if BattleItemCategoryDataTable:CanInUnequippedRoom(nCategory) then
        -- todo @zhiyuan 不考虑能进背包的可装备物品上可以装备其他物品，所以不需要NewItem这个参数
        local bMoveSuccess, _ = MoveItemToUnequippedRoom(self, nCharacterInstanceId, BattleItemComponent, OldItem, BattleItemSourceDef.CHANG_POS, bSyncToClient)
        if not bMoveSuccess then
            -- 背包满了扔地上
            MoveItem(self, nCharacterInstanceId, OldItem, NewItem, nil, nil, nil, nil, bSyncToClient)
        end
    else
        MoveItem(self, nCharacterInstanceId, OldItem, NewItem, nil, nil, nil, nil, bSyncToClient)
    end
end

EquipItem = function(self, nCharacterInstanceId, Item, nRoomType, nOwnerInstanceId, nSlotIndex, bSyncToClient)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local ItemRoom = BattleItemComponent:GetOrCreateItemRoom(nRoomType, nOwnerInstanceId)
    if Item:GetOwnerCharacter() and Item:GetOwnerCharacter() ~= ItemRoom:GetOwnerCharacter() then
        error("EquipItem failed!Owner not match!".. Item:GetOwnerCharacterInstanceId()..", ".. ItemRoom:GetOwnerCharacter().nServerInstanceId)
    end

    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(Item:GetCategory())
    if not ItemCategoryOperationHelper:IsSlotIndexValid(nSlotIndex) then
        error("EquipItem failed!nSlotIndex not valid!"..nSlotIndex..", "..Item:GetTemplateId())
    end
    MoveItem(self, nCharacterInstanceId, Item, nil, ItemRoom, nSlotIndex, nil, BattleItemSourceDef.CHANG_POS, bSyncToClient)
end

local function RepHumanPickupAction(self, tbCharacter, nInstanceId, nTemplateId)
    local PickupItem =
    {
        instance_id = nInstanceId,
        template_id = nTemplateId
    }
    local HumanBattlePropertyComponent = tbCharacter.HumanBattlePropertyComponent
    if HumanBattlePropertyComponent then
        HumanBattlePropertyComponent:SetPropOriginValue(PropName.rHumanPickupItem, PickupItem)
    end
end

local function ClearResetItemDelayHandle(self)
    if self.DelayResetItemsHandle ~= nil then
        DelayTimer:ClearTimer(self.DelayResetItemsHandle)
        self.DelayResetItemsHandle = nil
    end
end

local function OnAllPlayerLogout(self)
    ClearResetItemDelayHandle(self)
    self.tbPlayerInstanceIdsToResetItem = {}
    self.nResetItemPlayerCount = 0
end

local function ResetBattleItemsFromPrepareInfo(self, nCharacterInstanceId)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    local tbPrepareInfo = tbPlayer.tbPrepareInfo
    local tbInitItems = tbPrepareInfo.tbInitItems
    ResetPlayerItems(self, nCharacterInstanceId, tbInitItems)
end

local function AddPlayerInstanceIdsToResetItem(self, nCharacterInstanceId)
    if not self.tbPlayerInstanceIdsToResetItem[nCharacterInstanceId] then
        self.tbPlayerInstanceIdsToResetItem[nCharacterInstanceId] = true
        self.nResetItemPlayerCount = self.nResetItemPlayerCount + 1
    end
end

local function ResetItemsCallBack(self)
    ClearResetItemDelayHandle(self)
    if self.nResetItemPlayerCount > 0 then
        local tbInstanceRemoved = {}
        for k, _ in pairs(self.tbPlayerInstanceIdsToResetItem) do
            if #tbInstanceRemoved < RESET_PLAYER_ITEMS_MAX_COUNT_IN_ONE_TICK then
                ResetBattleItemsFromPrepareInfo(self, k)
                table.insert(tbInstanceRemoved, k)
            else
                break
            end
        end
        for _, v in ipairs(tbInstanceRemoved) do
            self.tbPlayerInstanceIdsToResetItem[v] = nil
            self.nResetItemPlayerCount = self.nResetItemPlayerCount - 1
        end
    end
    if self.nResetItemPlayerCount > 0 then
        self.DelayResetItemsHandle = DelayTimer:RunNextTick(function() ResetItemsCallBack(self) end)
    end
end

local function IsInDeadBox(Item)
    local bDeadBox = false
    local tbOwnerBoxItem = SceneItemContainer:GetOwnerBoxItem(Item)
    if tbOwnerBoxItem then
        local tbTemplate = tbOwnerBoxItem:GetTemplate()
        bDeadBox = tbTemplate.bDeadBox
    end
    return bDeadBox
end

-----------------------------------------System Init UnInit---------------------------------------------

local function OnInitGameModeComplete(self)
    -- todo @zhiyuan 因为现在System注册不能指定必须在server上，所以判断了一下IsServerLogic
    if GlobalVariableSystem:IsServerLogic() then
        self.bHasInit = true
        SceneItemContainer:Init()
        DiamondContainer:Init()
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
        EventManager:BindEventMethod(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnChangeDisplay)
        EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnPlayerLogout)
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerPostLogin)
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerRelogin)
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, OnAllPlayerLogout)
    end
end

function BattleItemSystemServer:Init()
    BattleItemSystemHelper:InitItemClasses()
    self.nMaxViewItemRequestId = 0
    self.tbViewItemRequestBeginTimes = {}
    self.tbPlayerInstanceIdsToResetItem = {}
    self.nResetItemPlayerCount = 0
    EventManager:BindEventMethod(CommonEventDef.EV_INIT_GAME_MODE_COMPLETE, self, OnInitGameModeComplete)
    return true
end

-- todo @zhiyuan 因为现在System注册不能指定必须在server上，所以判断了一下IsServerLogic
function BattleItemSystemServer:Uninit()
    if self.bHasInit then
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPlayerDie)
        EventManager:UnBindEventMethod(CommonEventDef.EV_END_CHANGEDISPLAY, self, OnChangeDisplay)
        EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, self, OnPlayerLogout)
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerPostLogin)
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerRelogin)
        EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, OnAllPlayerLogout)

        AllItemsUninit(self)
        DiamondContainer:Uninit()
        SceneItemContainer:Uninit()
        self.bHasInit = false
    end
    EventManager:UnBindEventMethod(CommonEventDef.EV_INIT_GAME_MODE_COMPLETE, self, OnInitGameModeComplete)
    self.nMaxViewItemRequestId = nil
    self.tbViewItemRequestBeginTimes = nil
    ClearAllDelayTimer(self)
    self.tbPlayerInstanceIdsToResetItem = nil
    self.nResetItemPlayerCount = 0
    ClearResetItemDelayHandle(self)
end

-----------------------------------------给外部模块的调用接口---------------------------------------------
-- 获得某个物品实例
-- @param nItemInstanceId 物品实例的唯一id
-- @return Item的实例
function BattleItemSystemServer:GetItem(nItemInstanceId)
    if nItemInstanceId == nil or nItemInstanceId <= 0 then
        return nil
    end
    return self.tbAllItems[nItemInstanceId]
end

-- 获得物品component
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @return 物品component
function BattleItemSystemServer:GetBattleItemComponent(nCharacterInstanceId)
    return GetBattleItemComponent(nCharacterInstanceId)
end

-- 查询一件物品被安装的槽位
-- @param nItemInstanceId 物品实例的唯一id
-- @return nSlotIndex 槽位id
function BattleItemSystemServer:GetEquippedSlotIndex(nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        error("BattleItemSystemBase:GetEquippedSlotIndex failed! Cannot find Item!".. nItemInstanceId)
    end
    return Item:GetStorageLocation().nSlotIndex
end

-- 创建物品
-- @param nTemplateId 物品类型id
-- @param nStackCount 物品类型id
function BattleItemSystemServer:CreateItem(nTemplateId, nStackCount)
    local Item = BattleItemFactory:CreateItem(nTemplateId, nStackCount, true)
    AddItem(self, Item)
    return Item
end

-- 创建临时物品，不放进物品列表
-- @param nTemplateId 物品类型id
-- @param nStackCount 物品类型id
function BattleItemSystemServer:CreateTempItem(nTemplateId, nStackCount)
    local Item = BattleItemFactory:CreateItem(nTemplateId, nStackCount, true)
    return Item
end

-- 获得背包容量（承重上限）
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包容量
function BattleItemSystemServer:GetInventoryCapacity(nCharacterInstanceId, nItemRoomType)
    local ItemRoom = GetInventoryRoom(nCharacterInstanceId, nItemRoomType)
    return ItemRoom:GetInventoryCapacity(false)
end

-- 获得背包当前承重（背包内物品重量和）
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包当前承重
function BattleItemSystemServer:GetAllItemsWeight(nCharacterInstanceId, nItemRoomType)
    local ItemRoom = GetInventoryRoom(nCharacterInstanceId, nItemRoomType)
    return ItemRoom:GetAllItemsWeight(false)
end

-- 获得背包格子数上限
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包格子数上限
function BattleItemSystemServer:GetMaxInventorySlots(nCharacterInstanceId, nItemRoomType)
    local ItemRoom = GetInventoryRoom(nCharacterInstanceId, nItemRoomType)
    return ItemRoom:GetMaxInventorySlots(false)
end

-- 获得背包当前占用格子数
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的两个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
-- @return 背包当前占用格子数
function BattleItemSystemServer:GetInventorySlotsCount(nCharacterInstanceId, nItemRoomType)
    local ItemRoom = GetInventoryRoom(nCharacterInstanceId, nItemRoomType)
    return ItemRoom:GetInventorySlotsCount(false)
end

-- 获得玩家身上未装备的某个templateid的道具列表
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 道具类型id
-- @return tbItems 物品的数组 eg:
--         local tbItems = {}
--         table.insert(tbItems, BattleItemBase())
--         table.insert(tbItems, BattleItemBase())
--         return tbItems
function BattleItemSystemServer:GetUnEquippedItemsByTemplateId(nCharacterInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetUnequippedItems(nItemTemplateId)
end

-- 获得某一包玩家身上未装备的物品列表
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemRoomType 见BattleItemRoomDef 可以用下面的三个类型
--                      BattleItemRoomDef.HUMAN_INVENTORY-- 人的背包
--                      BattleItemRoomDef.CABIN          -- 船舱
--                      BattleItemRoomDef.MATERIAL_ROOM  -- 材料背包
-- @return tbItems 物品的数组 eg:
--         local tbItems = {}
--         table.insert(tbItems, BattleItemBase())
--         table.insert(tbItems, BattleItemBase())
--         return tbItems
function BattleItemSystemServer:GetUnEquippedItems(nCharacterInstanceId, nItemRoomType)
    local ItemRoom = GetInventoryRoom(nCharacterInstanceId, nItemRoomType)
    if ItemRoom then
        return ItemRoom:GetRoomItems(false)
    else
        return { }
    end
end

-- 查询已经装备的某个类型的物品列表，如果没安装就返回空table
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param nOwnerInstanceId 装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId，如果是装在武器上的，就是武器的nItemInstanceId
-- @return tbEquippedItems (key:nSlotIndex, value:Item) eg:
--         local tbEquippedItems = {}
--         tbEquippedItems[1] = BattleItemBase()
--         tbEquippedItems[3] = BattleItemBase()
--         return tbEquippedItems
function BattleItemSystemServer:GetEquippedItems(nCharacterInstanceId, nItemCategory, nOwnerInstanceId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemSystemHelper:GetRoomItemsInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, true)
end

-- 查询一装备的某个类型某个槽位的物品,如果没安装就返回nil
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nSlotIndex 槽位id,如果不填就返回第一个槽位的物品
-- @return 被安装在某个槽位上的Item的实例
function BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, nItemCategory, nOwnerInstanceId, nSlotIndex)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemSystemHelper:GetEquippedItemBySlotInOneComponent(BattleItemComponent, nItemCategory, nOwnerInstanceId, nSlotIndex)
end

-- 获得未装配的某个物品类型的数量
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemServer:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetUnequippedItemCount(nItemTemplateId)
end

-- 获得某个物品类型的数量(装配未装配都有)
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemServer:GetItemCount(nCharacterInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetItemCount(nItemTemplateId)
end

-- 同步物品耐久度
-- @param nItemInstanceId 物品实例的唯一id
function BattleItemSystemServer:SyncDurability(nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    BattleItemSystemProtocalHelper:SyncItemDurability(Item)
end

-- 获得已装配的某个物品类型的数量
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nOwnerInstanceId 拥有者的InstanceId。
--        如果装在船上或者人上的，nOwnerInstanceId就是LuaCharacter的nServerInstanceId
--        如果是装在武器上的，就是武器的nItemInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nCount 这个template id对应的物品数量
function BattleItemSystemServer:GetEquippedItemCount(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetEquippedItemCount(nOwnerInstanceId, nItemTemplateId)
end

-- 获得未装备的最小叠加数量的物品instance
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nItemInstance nil表示没有这个类型的物品，否则返回未装备的最小叠加数量的物品instance
function BattleItemSystemServer:GetUnequippedLeastStackCountInstance(nCharacterInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetUnequippedLeastStackCountInstance(nItemTemplateId)
end

-- 获得未装备的最小叠加数量的物品instanceid
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nItemInstanceId nil表示没有这个类型的物品，否则返回未装备的最小叠加数量的物品instanceid
function BattleItemSystemServer:GetUnequippedLeastStackCountInstanceId(nCharacterInstanceId, nItemTemplateId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
end

-- 查询某个大类型的所有物品列表(未装配的)
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemCategory 物品大类 见BattleItemCategoryDef.lua
-- @return tbItems 物品的数组 eg:
--         local tbItems = {}
--         table.insert(tbItems, BattleItemBase())
--         table.insert(tbItems, BattleItemBase())
--         return tbItems
function BattleItemSystemServer:GetUnequippedItemsByCategory(nCharacterInstanceId, nItemCategory)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetUnequippedItemsByCategory(nItemCategory)
end

-- 在场景中增加一组不属于玩家的物品并把item和actor进行绑定
-- @param tbSceneItemData ，eg：
--         local tbSceneItemData = {}
--         tbSceneItemData.tbTransform = {X=1,Y=1,Z=1,Yaw=0}
--         tbSceneItemData.tbItemInfos = {}
--         local tbItemInfo = {}
--         tbItemInfo.nItemTemplateId = 11010001
--         tbItemInfo.nItemCount = 1
--         table.insert(tbSceneItemData.tbItemInfos,tbItemInfo)
-- @return 道具的Item列表
function BattleItemSystemServer:AddItemsToScene(tbSceneItemData)
    local tbItemInfos = tbSceneItemData.tbItemInfos
    local tbTransform = tbSceneItemData.tbTransform
    local tbItemInfoAfterCheck = GetItemInfosAfterRemoveCannotKnown(tbItemInfos)

    if #tbItemInfoAfterCheck == 0 then
        return {}
    end

    local bRandomPosition = (#tbItemInfoAfterCheck > 1)

    local tbRetItems = {}

    for _, tbItemInfo in pairs(tbItemInfoAfterCheck) do
        -- todo @zhiyuan 把位置做偏移
        local nItemTemplateId = tbItemInfo.nItemTemplateId
        local nItemCount = tbItemInfo.nItemCount
        local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbTemplate.bStackable then
            local Item = SceneItemContainer:CreateSceneItem(nItemTemplateId, nItemCount, tbTransform, SceneItemActorDef.ITEM, bRandomPosition)
            table.insert(tbRetItems, Item)
        else
            for i = 1, nItemCount do
                local Item = SceneItemContainer:CreateSceneItem(nItemTemplateId, 1, tbTransform, SceneItemActorDef.ITEM, bRandomPosition or nItemCount > 1)
                table.insert(tbRetItems, Item)
            end
        end
    end
    return tbRetItems
end

-- 在场景中增加一个物品箱子并把item和actor进行绑定
-- @param tbSceneItemData ，eg：
--         local tbSceneItemData = {}
--         tbSceneItemData.tbTransform = {X=1,Y=1,Z=1,Yaw=0}
--         tbSceneItemData.tbItemInfos = {}
--         local tbItemInfo = {}
--         tbItemInfo.nItemTemplateId = 11010001
--         tbItemInfo.nItemCount = 1
--         table.insert(tbSceneItemData.tbItemInfos,tbItemInfo)
-- @param nSceneItemActorType 见SceneItemActorDef
-- @param nBoxItemTemplateId 箱子物品的类型id
-- @return Actor 箱子Actor
function BattleItemSystemServer:AddItemPackageToScene(tbSceneItemData, nSceneItemActorType, nBoxItemTemplateId)
    local tbItemInfos = tbSceneItemData.tbItemInfos
    if #tbItemInfos == 0 then
        logerror("Create Scene Item Box Failed! ItemInfo empty!", #tbItemInfos, nSceneItemActorType, nBoxItemTemplateId)
        return
    end

    local tbItemInfoAfterCheck = GetItemInfosAfterRemoveCannotKnown(tbItemInfos)
    if #tbItemInfoAfterCheck == 0 then
        logerror("Create Scene Item Box Failed! tbItemInfoAfterCheck empty!", #tbItemInfos, #tbItemInfoAfterCheck, nSceneItemActorType, nBoxItemTemplateId)
        return
    end

    local tbTransform = tbSceneItemData.tbTransform

    if nSceneItemActorType == nil or nSceneItemActorType == SceneItemActorDef.ITEM then
        error("AddItemPackageToScene Failed! nSceneItemActorType is not a box!nSceneItemActorType:".. nSceneItemActorType..", nBoxItemTemplateId:".. nBoxItemTemplateId)
    end

    if nBoxItemTemplateId == nil then
        error("AddItemPackageToScene Failed! Cannot find box templateId! nSceneItemActorType:".. nSceneItemActorType..", nBoxItemTemplateId:".. nBoxItemTemplateId)
    end

    local BoxItem = SceneItemContainer:CreateSceneItem(nBoxItemTemplateId, 1, tbTransform, nSceneItemActorType)
    local ItemRoom = SceneItemContainer:CreateItemRoom(BoxItem:GetInstanceId())

    local tbItems = {}
    for _, v in pairs(tbItemInfoAfterCheck) do
        local nItemTemplateId = v.nItemTemplateId
        local Item = self:CreateItem(nItemTemplateId, v.nItemCount)
        table.insert(tbItems, Item)
        SceneItemContainer:AddItemToRoom(ItemRoom, Item)
    end
    if nSceneItemActorType == SceneItemActorDef.AIR_DROP_BOX then
        EventManager:OnFireEvent(CommonEventDef.EV_CREATE_AIRDROP_BOX, BoxItem, tbTransform)
    end
    EventManager:OnFireEvent(CommonEventDef.EV_SCENE_ITEM_ADD_BOX, tbItems, tbTransform.X, tbTransform.Y, tbTransform.Z)
    return BoxItem:GetSceneActor()
end

-- 把玩家物品数据重置成初始状态
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
function BattleItemSystemServer:ResetBattleItemsFromPrepareInfo(nCharacterInstanceId)
    AddPlayerInstanceIdsToResetItem(self, nCharacterInstanceId)
    if self.DelayResetItemsHandle == nil then
        self.DelayResetItemsHandle = DelayTimer:RunNextTick(function() ResetItemsCallBack(self) end)
    end
end

-- 给副本玩法提供的接口，用来初始化某个玩家的数据
-- 这个方法不会把新增物品一个一个的同步给客户端
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nGroupId 物品组的id
function BattleItemSystemServer:InitPlayerItemsByGroupId(nCharacterInstanceId, nGroupId)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    local tbGroupItems = PvpInitItemDataTable:GetGroupItems(nGroupId)
    if tbGroupItems == nil then
        error("InitPlayerItemsByGroupId failed! Cannot find item group! nCharacterInstanceId:"..nCharacterInstanceId..", nGroupId"..nGroupId)
    end
    ClearShipBuiltGrade(self, nCharacterInstanceId)
    DestroyAllPlayerItems(self, nCharacterInstanceId)
    self:AddInitItems(nCharacterInstanceId, tbGroupItems)
    SyncD2CResetBattleItemData(self, tbPlayer)
end

-- 获得某个玩家所有物品的proto数据
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @return tbItemProtoDatas
function BattleItemSystemServer:GetAllItemProtoDatas(nCharacterInstanceId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetAllItemProtoDatas()
end

-- 获得某个玩家所有物品数据
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @return tbItems
function BattleItemSystemServer:GetAllPlayerItems(nCharacterInstanceId)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    return BattleItemComponent:GetAllItems()
end

-- 销毁玩家的物品
function BattleItemSystemServer:DestroyPlayerItem(nCharacterInstanceId, nItemInstanceId, NewItem)
    local Item = self:GetItem(nItemInstanceId)

    if Item:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        error("Owner not match!".."owner instanceId:"
            ..Item:GetOwnerCharacterInstanceId()..", nCharacterInstanceId:"..nCharacterInstanceId)
    end

    local nItemTemplateId = Item:GetTemplateId()
    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local bUnequip = RemoveItemFromRoom(self, nCharacterInstanceId, Item, nil, NewItem, nil, true)
    FireEventAndSyncRemoveItem(self, GetPlayer(nCharacterInstanceId), nItemInstanceId, nItemTemplateId,
    nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    if bUnequip then
        EventManager:OnFireEvent(CommonEventDef.EV_AFTER_BATTLE_ITEM_UNEQUIPED_SERVER, nCharacterInstanceId, nItemTemplateId, nSlotIndex, NewItem ~= nil)
    end
    RemoveItem(self, nItemInstanceId)
end

-- 销毁物品
function BattleItemSystemServer:DestroyItem(nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    local nItemTemplateId = Item:GetTemplateId()
    local nRoomType, nOwnerInstanceId, nSlotIndex = Item:SplitAndGetStorageLocation()
    local tbOwnerCharacter = Item:GetOwnerCharacter()
    local nCharacterInstanceId = Item:GetOwnerCharacterInstanceId()
    local bUnequip = RemoveItemFromRoom(self, nCharacterInstanceId, Item, nil, nil, nil, true)
    if tbOwnerCharacter then
        FireEventAndSyncRemoveItem(self, GetPlayer(nCharacterInstanceId), nItemInstanceId, nItemTemplateId,
        nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    end
    if bUnequip then
        EventManager:OnFireEvent(CommonEventDef.EV_AFTER_BATTLE_ITEM_UNEQUIPED_SERVER, nCharacterInstanceId, nItemTemplateId, nSlotIndex, false)
    end
    RemoveItem(self, nItemInstanceId)
end

-- 移除场景中的道具
function BattleItemSystemServer:RemoveSceneItem(nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    if not Item then
        logwarning("Try to remove scene item failed! Item is not exist!", nItemInstanceId)
        return
    end
    local nOwnerCharacterInstanceId = Item:GetOwnerCharacterInstanceId()
    if nOwnerCharacterInstanceId > 0 then
        logwarning("Try to remove scene item failed! Item has owner!", nItemInstanceId, nOwnerCharacterInstanceId)
        return
    end
    SceneItemContainer:RemoveItem(Item, true)
end

-- 减少某玩家的某个物品的数量
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemInstanceId 物品实例的唯一id
-- @param nDelta 变化值
function BattleItemSystemServer:DecreasePlayerItemCount(nCharacterInstanceId, nItemInstanceId, nDelta)
    local Item = self:GetItem(nItemInstanceId)
    if Item:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        error("Owner not match!".."owner instanceId:"
            ..Item:GetOwnerCharacterInstanceId()..", nCharacterInstanceId:"..nCharacterInstanceId)
    end
    local tbPlayer = Item:GetOwnerCharacter()
    local nItemTemplateId = Item:GetTemplateId()
    local nStackCount = Item:GetStackCount()
    if nStackCount > nDelta then
        DecreaseStackCount(self, Item, nDelta)
    else
        self:DestroyPlayerItem(nCharacterInstanceId, nItemInstanceId)
    end

    FireEventDecreasePlayerItem(tbPlayer, nItemTemplateId, nDelta)
end

-- 减少某个物品的数量
-- @param nItemInstanceId 物品实例的唯一id
-- @param nDelta 变化值
function BattleItemSystemServer:DecreaseItemCount(nItemInstanceId, nDelta)
    local Item = self:GetItem(nItemInstanceId)
    local tbPlayer = Item:GetOwnerCharacter()
    if not tbPlayer then
        logwarning("DecreaseItemCount and Item do not has owner!", Item:GetTemplateId(), debug.traceback())
    end
    local nItemTemplateId = Item:GetTemplateId()
    local nStackCount = Item:GetStackCount()
    if nStackCount > nDelta then
        DecreaseStackCount(self, Item, nDelta)
    else
        self:DestroyItem(nItemInstanceId)
    end
    if tbPlayer then
        FireEventDecreasePlayerItem(tbPlayer, nItemTemplateId, nDelta)
    end
end

-- 创建并直接装配物品
function BattleItemSystemServer:CreateAndEquipItemWithOwner(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nStackCount, nBattleItemSource, bSyncToClient)
    local nSlotIndex = GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId)
    if nSlotIndex <= 0 then
        logerror("CreateAndEquipItemWithOwner failed! cannot find slot index", nItemTemplateId)
        return
    end
    CreateAndEquipItemWithSlot(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, nStackCount, nBattleItemSource, bSyncToClient)
end

-- 是否可以自动拾取（给机器人AI使用）
function BattleItemSystemServer:CanAutoPickUp(nCharacterInstanceId, Item)
    local ItemCategoryOperationHelper = BattleItemSystemHelper:GetItemOperationHelper(Item:GetCategory())
    return ItemCategoryOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
end

-- 获得盒子里的物品列表（给机器人AI使用）
function BattleItemSystemServer:GetItemsInSceneItemPackage(nItemPackageInstanceId)
    return SceneItemContainer:GetItemsInSceneItemPackage(nItemPackageInstanceId)
end

-- 获得盒子里的物品列表（给机器人AI使用）
function BattleItemSystemServer:FillItemsInSceneItemPackage(nItemPackageInstanceId, tbItems)
    SceneItemContainer:FillItemsInSceneItemPackage(nItemPackageInstanceId, tbItems)
end

-- 正在换船
function BattleItemSystemServer:IsChangingShip(nCharacterInstanceId)
    return self.tbIsChangingShip[nCharacterInstanceId]
end

-- 给character初始化一批道具
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param tbInitItems ，eg：
--         local tbInitItems = {}
--         local tbItemInfo = {}
--         tbItemInfo.nItemTemplateId = 11010001
--         tbItemInfo.nItemCount = 1
--         table.insert(tbInitItems, tbItemInfo)
function BattleItemSystemServer:AddInitItems(nCharacterInstanceId, tbInitItems)
    for _, v in ipairs(tbInitItems) do
        local nItemTemplateId = ChangeToPreparationItem(nCharacterInstanceId, v.nItemTemplateId)
        CreateAndAddItemToCharacter(self, nCharacterInstanceId, nItemTemplateId, v.nItemCount, BattleItemSourceDef.INIT, false)
        local tbPlayer = GetPlayer(nCharacterInstanceId)
        log("Add Init Item.", nCharacterInstanceId, tbPlayer:GetName(), nItemTemplateId, v.nItemCount)
    end
end

-- 给character增加道具，为了机器人添加的方法
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param tbItemInfos ，eg：
--         local tbItemInfos = {}
--         local tbItemInfo = {}
--         tbItemInfo.nItemTemplateId = 11010001
--         tbItemInfo.nItemCount = 1
--         table.insert(tbItemInfos, tbItemInfo)
function BattleItemSystemServer:AddItems(nCharacterInstanceId, tbItemInfos)
    for _, v in ipairs(tbItemInfos) do
        local nItemTemplateId = v.nItemTemplateId
        CreateAndAddItemToCharacter(self, nCharacterInstanceId, nItemTemplateId, v.nItemCount, true, BattleItemSourceDef.OTHER, false)
        local tbPlayer = GetPlayer(nCharacterInstanceId)
        log("Add Items.", nCharacterInstanceId, tbPlayer:GetName(), nItemTemplateId, v.nItemCount)
    end
end

-- 检查道具是否有关联的actor,在地上或者在盒子里
-- 机器人拾取前需要调用此方法
-- @param nItemInstanceId 道具的唯一id
-- @return true 表示距离合法可以拾取，false表示距离太远不可以拾取
function BattleItemSystemServer:CheckItemReady(nItemInstanceId)
    local Item = self:GetItem(nItemInstanceId)
    if not Item then
        return false
    end
    local tbItemActor = Item:GetSceneActor()
    if tbItemActor == nil then
        local BoxItem = SceneItemContainer:GetOwnerBoxItem(Item)
        if BoxItem == nil then
            return false
        else
            tbItemActor = BoxItem:GetSceneActor()
            if tbItemActor == nil then
                return false
            else
                return true
            end
        end
    else
        return true
    end
end

-- 检查拾取距离
-- @param tbPlayer 拾取的GamePlayer
-- @param Item 被拾取的道具
-- @return true 表示距离合法可以拾取，false表示距离太远不可以拾取
function BattleItemSystemServer:CheckPickupDistance(tbPlayer, Item)
    local nPlayerLocX, nPlayerLocY, _nPlayerLocZ = tbPlayer:GetLocationXYZ()
    local tbItemActor = Item:GetSceneActor()
    if tbItemActor == nil then
        local BoxItem = SceneItemContainer:GetOwnerBoxItem(Item)
        if BoxItem == nil then
            logerror("Item do not have scene actor, and not in a box!", Item:GetTemplateId(), Item:GetInstanceId())
            return false
        end
        tbItemActor = BoxItem:GetSceneActor()
        if tbItemActor == nil then
            error("BoxItem do not have scene actor!", Item:GetTemplateId(), Item:GetInstanceId(), BoxItem:GetTemplateId(), BoxItem:GetInstanceId())
        end
    end
    local nItemLocX, nItemLocY, _nItemLocZ = tbItemActor:GetLocationXYZ()
    local nDistance = math.sqrt((nPlayerLocX - nItemLocX)^2 + (nPlayerLocY - nItemLocY)^2)
    local nRadius = nil
    local tbPickTrigger = TriggerIni.tbPickTrigger
    local tbSceneItem = FFAItemIni.tbSceneItem
    local nItemTriggerBaseRadius = tbPickTrigger.nItemTriggerBaseRadius
    if tbPlayer:IsShip() then
        nRadius = tbPlayer.ShipBattlePropertyComponent:GetProp(PropName.nShipPickupRange) + nItemTriggerBaseRadius * (tbSceneItem.nOceanMeshScale)
    elseif tbPlayer:IsHuman() then
        nRadius = tbPlayer.HumanBattlePropertyComponent:GetProp(PropName.nHumanPickupRange) + nItemTriggerBaseRadius * (tbSceneItem.nLandMeshScale)
    end
    if nRadius ~= nil then
        local nValidDistance = nRadius * 2 -- 为了避免网络延迟等原因导致的操作不顺畅，把校验范围扩大
        if nDistance > nValidDistance then
            log("Pickup distance is not valid.", nDistance, nValidDistance, nPlayerLocX, nPlayerLocY, nItemLocX, nItemLocY)
            return false
        else
            return true
        end
    else
        logerror("Player is not ship and not human!")
        return false
    end
end

-- 获得玩家已经建造的舰船的最高等级
function BattleItemSystemServer:GetShipBuiltGrade(nCharacterInstanceId)
    return GetShipBuiltGrade(self, nCharacterInstanceId)
end

-- 设置玩家已经建造的舰船的最高等级
function BattleItemSystemServer:SetShipBuiltGrade(nCharacterInstanceId, nGrade)
    SetShipBuiltGrade(self, nCharacterInstanceId, nGrade)
end

-- 处理玩家换船之前的物品处理
function BattleItemSystemServer:OnPlayerShipToChange(tbPlayer, nShipId)
    local nCharacterInstanceId = tbPlayer.nServerInstanceId
    SetIsChangingShip(self, nCharacterInstanceId, true)
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local tbEquipmentItems = BattleItemComponent:GetAllEquipmentItemsOnShip()
    if tbEquipmentItems == nil then
        return
    end
    BattleItemSystemHelper:OnUnequipAllShipEquipItems(BattleItemComponent)
    BattleItemSystemProtocalHelper:SyncOnUnequipAllShipEquipItems(tbPlayer)
end

-- 处理玩家换船后的物品处理
function BattleItemSystemServer:OnPlayerShipChanged(tbPlayer, nShipId)
    local nCharacterInstanceId = tbPlayer.nServerInstanceId
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local tbEquipmentItems = BattleItemComponent:GetAllEquipmentItemsOnShip()

    if tbEquipmentItems ~= nil then
        BattleItemComponent:ClearAllShipEquipmentItemRoom()
        ProcessEquippedItemsWhenPlayerShipChanged(self, nCharacterInstanceId, tbEquipmentItems)
    end

    SetIsChangingShip(self, nCharacterInstanceId, nil)
end

-- 获得玩家装备的道具数据
-- @param tbPlayer
-- @return tbEquippedItemDetails
-- tbEquippedItemDetails = {}
-- tbEquippedItemDetails.tbHumanEquippedItemTemplateIds = {}
-- tbEquippedItemDetails.tbShipEquippedItemTemplateIds = {}
function BattleItemSystemServer:GetPlayerEquippedItemDetails(tbPlayer)
    if tbPlayer == nil then
        return nil
    end
    local BattleItemComponent = tbPlayer.BattleItemComponentServer
    if BattleItemComponent == nil then
        return nil
    end
    local tbEquippedItemDetails = {}
    tbEquippedItemDetails.tbHumanEquippedItemTemplateIds = {}
    tbEquippedItemDetails.tbShipEquippedItemTemplateIds = {}
    local tbHumanEquippedItemTemplateIds = tbEquippedItemDetails.tbHumanEquippedItemTemplateIds
    local tbShipEquippedItemTemplateIds = tbEquippedItemDetails.tbShipEquippedItemTemplateIds
    local tbEquipmentItemsOnShip = BattleItemComponent:GetAllEquipmentItemsOnShip()
    if tbEquipmentItemsOnShip ~= nil then
        for _, v in ipairs(tbEquipmentItemsOnShip) do
            table.insert(tbShipEquippedItemTemplateIds, v:GetTemplateId())
        end
    end

    local tbEquipmentItemsOnHuman = BattleItemComponent:GetAllEquipmentItemsOnHuman()
    if tbEquipmentItemsOnHuman ~= nil then
        for _, v in ipairs(tbEquipmentItemsOnHuman) do
            table.insert(tbHumanEquippedItemTemplateIds, v:GetTemplateId())
        end
    end

    return tbEquippedItemDetails
end

-----------------------------------------玩家不同的操作的方法---------------------------------------------

-- 处理物品建造
-- todo @zhiyuan 假设了制造的物品都是不能叠加的
--               所以没有数量这个参数
--               以后有了其他需求就再修改
function BattleItemSystemServer:BuildItem(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    if not IsPlayerAlive(nCharacterInstanceId) then
        logerror("BuildItem failed! player is dead!", nCharacterInstanceId)
        return
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate == nil then
        logerror("BattleItemSystemServer:BuildItem failed! Cannot find nItemTemplateId!", nItemTemplateId)
        return
    end
    local bAvailable = BattleItemSystemHelper.IsItemAvailableBuild(nCharacterInstanceId, nItemTemplateId, false)
    if not bAvailable then
        logerror("BattleItemSystemServer:BuildItem failed! nItemTemplateId is not available to build!", nItemTemplateId)
        return
    end
    local tbBuildingData = GetItemBuildingData(self, nCharacterInstanceId)
    if tbBuildingData ~= nil then
        if tbBuildingData.nItemTemplateId == nItemTemplateId then
            log("BattleItemSystemServer:BuildItem failed! Already Building nItemTemplateId!", nItemTemplateId)
            return
        end
        CancelBuildItem(self, nCharacterInstanceId, true)
    end
    local bSucceeded, tbFailures = VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    if bSucceeded then
        local bPrepareSuceeded = BeginItemBuildingPrepare(self, nCharacterInstanceId, nItemTemplateId, nSlotIndex)
        log("[BuildItem]BattleItemSystemServer:BuildItem begin!", nCharacterInstanceId, nItemTemplateId, nSlotIndex)
        if bPrepareSuceeded then
            BattleItemSystemProtocalHelper:SyncD2CBuildItem(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.OK, nItemTemplateId, nSlotIndex)
        else
            BattleItemSystemProtocalHelper:SyncD2CBuildItem(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.CANNOT_BUILD_UNKNOWN_ERROR, nItemTemplateId, nSlotIndex)
        end
    else
        BattleItemSystemProtocalHelper:SyncD2CBuildItem(GetPlayer(nCharacterInstanceId), GetBuildItemRet(tbFailures), nItemTemplateId, nSlotIndex)
    end
end

-- 取消物品建造
function BattleItemSystemServer:CancelBuildItem(nCharacterInstanceId)
    CancelBuildItem(self, nCharacterInstanceId, true)
end

-- 处理增加物品（这种情况现在只有GM指令的时候发生,每次增加的数量不能超过叠加上限，超过了会默认改成等于上限）
function BattleItemSystemServer:AddBattleItem(nCharacterInstanceId, tbParams)
    if not IsPlayerAlive(nCharacterInstanceId) then
        logerror("AddBattleItem failed! player is dead!", nCharacterInstanceId)
        return
    end

    if IsParachuting(self, nCharacterInstanceId) then
        logerror("AddBattleItem failed! player is parachuting!", nCharacterInstanceId)
        return
    end
    if #tbParams < 2 then
        return
    end
    local i = 2
    while i <= #tbParams do
        local nItemTemplateId = tonumber(tbParams[i])
        i = i + 1
        local nCount = 1
        if i <= #tbParams then
            nCount = tonumber(tbParams[i])
        end
        local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbTemplate == nil then
            logerror("BattleItemSystemServer:AddBattleItem failed! Cannot find nItemTemplateId!", nItemTemplateId)
            return
        end
        if CheckCanAdd(nItemTemplateId, BattleItemSourceDef.GM) then
            local Item = self:CreateItem(nItemTemplateId, nCount)
            if CanAddToCharacter(self, nCharacterInstanceId, Item, nil) then
                MoveItemToCharacter(self, nCharacterInstanceId, Item, nil, BattleItemSourceDef.GM, true)
            else
                AddItemToScene(nCharacterInstanceId, nil, Item)
            end
        end
        i = i + 1
    end
end

-- gm指令设置死亡后掉落箱子的延迟秒数
function BattleItemSystemServer:SetGMDelayDieBoxTime(nDelayTime)
    self.nGmDelayCreateDieBoxSecond = nDelayTime
end

-- gm指令清除gm设定的死亡后掉落箱子的延迟秒数
function BattleItemSystemServer:ClearGMDelayDieBoxTime()
    self.nGmDelayCreateDieBoxSecond = nil
end

-- 处理装备物品(需要考虑是否需要count的参数，子弹如果作为配件来实现就需要，如果另外实现一套子弹逻辑就不需要)
function BattleItemSystemServer:EquipItem(nCharacterInstanceId, nOwnerInstanceId, nItemInstanceId, nSlot, bSyncToClient)
    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        log("EquipItem failed! player is dead or dying!", nCharacterInstanceId)
        return
    end

    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        logerror("EquipItem failed!Item not found!", nItemInstanceId)
        return
    end
    if Item:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        logerror("EquipItem failed!Owner not match!", Item:GetOwnerCharacterInstanceId(), nCharacterInstanceId)
        return
    end

    local nItemTemplateId = Item:GetTemplateId()
    if nOwnerInstanceId == 0 or nOwnerInstanceId == nil then
        local _, nOwnerId, nSlotIndex = GetAvailableEquipmentSlotForItem(self, nCharacterInstanceId, nItemTemplateId)
        nOwnerInstanceId = nOwnerId
        nSlot = nSlotIndex
    else
        if nSlot == 0 or nSlot == nil then
            nSlot = GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId)
        end
    end

    local nCategory = Item:GetCategory()
    local nRoomType = BattleItemCategoryDataTable:GetEquippedRoomType(nCategory)
    if not CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlot, Item) then
        logerror("EquipItem failed! slot not valid!", nCategory, nRoomType, nOwnerInstanceId, nSlot)
        return
    end

    EquipItem(self, nCharacterInstanceId, Item, nRoomType, nOwnerInstanceId, nSlot, bSyncToClient)
    if bSyncToClient then
        BattleItemSystemProtocalHelper:SyncD2CEquipItem(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.OK, nItemInstanceId, nOwnerInstanceId, nSlot)
    end
end

-- 处理卸下物品
function BattleItemSystemServer:UnEquipItem(nCharacterInstanceId, nItemInstanceId, nCount)
    if not IsPlayerAlive(nCharacterInstanceId) then
        logerror("UnEquipItem failed! player is dead!", nCharacterInstanceId)
        return
    end

    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        logerror("UnEquipItem failed!Item not found!", nItemInstanceId)
        return
    end
    if Item:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        logerror("UnEquipItem failed!Owner not match!".."owner instanceId:", Item:GetOwnerCharacterInstanceId(), nCharacterInstanceId)
        return
    end
    local nRoomType, _, _ = Item:SplitAndGetStorageLocation()
    if not BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
        logerror("UnEquipItem failed!Item is not equipped! Cannot unequip!", nCharacterInstanceId, nItemInstanceId, Item:GetTemplateId())
        return
    end

    local nItemTemplateId = Item:GetTemplateId()
    local bCheckResult, nFailureReason = CanUnequipOnServer(self, nCharacterInstanceId, Item)
    if not bCheckResult then
        BattleItemSystemProtocalHelper:SyncD2CUnequipItem(GetPlayer(nCharacterInstanceId), BattleItemUnequipCheckFailureDef:ToReturnCode(nFailureReason), nItemInstanceId, nCount, nItemTemplateId)
        return
    end

    if nCount and nCount > 0 and nCount < Item:GetStackCount() then
        UnEquipItemPartially(self, nCharacterInstanceId, Item, nCount)
    else
        UnEquipItem(self, nCharacterInstanceId, Item, nil, true)
    end
    BattleItemSystemProtocalHelper:SyncD2CUnequipItem(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.OK, nItemInstanceId, nCount, nItemTemplateId)
end

-- 处理装备可叠加的物品
function BattleItemSystemServer:EquipStackableItem(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount)
    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        logerror("EquipStackableItem failed! player is dead or dying!", nCharacterInstanceId, nItemTemplateId)
        return
    end

    if nCount <= 0 then
        logerror("Cannot Equip stackable item! nCount <= 0", nItemTemplateId, nCount)
        return
    end

    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if not tbItemTemplate then
        logerror("Cannot Equip stackable item! Cannot find item template!", nItemTemplateId, nCount)
        return
    end

    local nSlotIndex = GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, true)
    if nSlotIndex <= 0 then
        logerror("Cannot Equip stackable item!", nItemTemplateId, nCount, nCharacterInstanceId, debug.traceback())
        return
    end

    local bNoCost = false
    local nCategory = tbItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.HUMAN_BULLET and BattleItemSystemHelper:IsHumanBulletInfinite() then
        bNoCost = true
    elseif nCategory == BattleItemCategoryDef.SHIP_BULLET and BattleItemSystemHelper:IsShipBulletInfinite() then
        bNoCost = true
    end

    local tbPlayer = GetPlayer(nCharacterInstanceId)
    -- 机器人和npc不扣弹药
    -- bNoCost 表示不扣除弹药
    if bNoCost or AIHelper.IsAIControlled(tbPlayer) then
        EquipStackableItemWithoutDecrease(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount, nSlotIndex)
    else
        EquipStackableItemNormally(self, nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, nCount, nSlotIndex)
    end
end

-- 处理交换已装备的物品位置
function BattleItemSystemServer:ExchangeStorageLocation(nCharacterInstanceId, nItemInstanceId1, nItemInstanceId2)
    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        logerror("ExchangeStorageLocation failed! player is dead or dying!", nCharacterInstanceId)
        return
    end
    local Item1 = self:GetItem(nItemInstanceId1)
    local Item2 = self:GetItem(nItemInstanceId2)
    if Item1 == nil or Item2 == nil then
        logerror("ExchangeStorageLocation failed!Item not found!", nItemInstanceId1, nItemInstanceId2)
        return
    end
    if Item1:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId or Item2:GetOwnerCharacterInstanceId() ~= nCharacterInstanceId then
        logerror("ExchangeStorageLocation failed!Owner not match! owner instanceId:", Item1:GetOwnerCharacterInstanceId(), Item2:GetOwnerCharacterInstanceId(), nCharacterInstanceId)
        return
    end

    if not BattleItemSystemHelper:CanExchangeStorageLocation(nCharacterInstanceId, Item1, Item2, false) then
        return
    end

    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    BattleItemSystemHelper:ExchangeStorageLocation(BattleItemComponent, Item1, Item2)

    BattleItemSystemProtocalHelper:SyncD2CExchangeStorageLocation(GetPlayer(nCharacterInstanceId), ProtoDC.ItemReturnCode.OK, Item1, Item2)
end

-- 处理丢弃物品
function BattleItemSystemServer:ThrowAwayItem(nCharacterInstanceId, nItemInstanceId, nCount)
    if not IsPlayerAlive(nCharacterInstanceId) then
        logwarning("ThrowAwayItem failed! player is dead!", nCharacterInstanceId)
        return
    end

    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        logwarning("ThrowAwayItem failed!Item not found!", nCharacterInstanceId, nItemInstanceId)
        return
    end
    local nItemTemplateId = Item:GetTemplateId()
    local nThrowCount = nCount
    if nThrowCount == nil or nThrowCount <= 0 then
        nThrowCount = Item:GetStackCount()
    end
    local bSuccess, nReturnCode = ThrowAwayItem(self, nCharacterInstanceId, nItemInstanceId, nCount)
    if nReturnCode then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayItem(GetPlayer(nCharacterInstanceId), nReturnCode, nItemInstanceId, nThrowCount, nItemTemplateId)
    end
    if bSuccess then
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_THROW_AWAY_ITEM_FINISH_SERVER, nCharacterInstanceId, nItemInstanceId, nItemTemplateId, nThrowCount)
    end
end

local function AddBeginViewItemsRecord(self)
    self.nMaxViewItemRequestId = self.nMaxViewItemRequestId + 1
    self.tbViewItemRequestBeginTimes[self.nMaxViewItemRequestId] = ExtendBlueprintFunctions.GetPlatformMilliseconds()
end

-- 获得并删除请求查看地上道具列表的协议开始时间
function BattleItemSystemServer:GetAndRemoveViewItemRequestTime(nRequestId)
    local nTime = self.tbViewItemRequestBeginTimes[nRequestId]
    self.tbViewItemRequestBeginTimes[nRequestId] = nil
    return nTime
end

-- 获得请求查看地上道具列表的协议开始时间
function BattleItemSystemServer:GetViewItemRequestTime(nRequestId)
    return self.tbViewItemRequestBeginTimes[nRequestId]
end

-- 某个玩家开始查看场景中的物品
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param tbItemInstanceIds: 物品nItemInstanceId的数组
-- @return 所有相关的地上的物品数据（具体结构还需要根据UI需求定一下）
function BattleItemSystemServer:BeginViewItemsDetail(nCharacterInstanceId, tbItemInstanceIds)
    AddBeginViewItemsRecord(self)
    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        log("ViewItemsDetail failed! player is dead or dying!", nCharacterInstanceId)
        return
    end
    return SceneItemContainer:BeginViewItemsDetail(nCharacterInstanceId, tbItemInstanceIds, self.nMaxViewItemRequestId)
end

-- 某个玩家结束查看场景中的物品
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
function BattleItemSystemServer:EndViewItemsDetail(nCharacterInstanceId)
    SceneItemContainer:EndViewItemsDetail(nCharacterInstanceId)
end

-- 处理捡起场景中的物品
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemInstanceId: 需要拾取的物品InstanceId
-- @param nCount: 需要拾取的物品数量
function BattleItemSystemServer:PickUpSceneItem(nCharacterInstanceId, nItemInstanceId, nCount)
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    if IsParachuting(self, nCharacterInstanceId) then
        BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, ProtoDC.ItemReturnCode.CANNOT_PICKUP_PARACHUTING, nItemInstanceId)
        log("PickUp failed! player is parachuting!", nCharacterInstanceId)
        return
    end

    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, ProtoDC.ItemReturnCode.CANNOT_PICKUP_NOT_ALIVE, nItemInstanceId)
        log("PickUp failed! player is dead or dying!", nCharacterInstanceId)
        return
    end

    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, ProtoDC.ItemReturnCode.ITEM_HAS_OWNER, nItemInstanceId)
        log("PickUpSceneItem failed!Item not found!", nItemInstanceId)
        return
    end
    if Item:GetOwnerCharacter() ~= nil then
        BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, ProtoDC.ItemReturnCode.ITEM_HAS_OWNER, nItemInstanceId)
        log("Item has owner!Cannot pickup", Item:GetOwnerCharacterInstanceId(), nCharacterInstanceId, nItemInstanceId)
        return
    end

    if Item:GetCategory() == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, ProtoDC.ItemReturnCode.CANNOT_PICKUP_CATEGORY_INVALID, nItemInstanceId)
        logerror("Cannot pick up scene box!", Item:GetCategory())
        return
    end

    if not self:CheckPickupDistance(tbPlayer, Item) then
        BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, ProtoDC.ItemReturnCode.CANNOT_PICKUP_DISTANCE_INVALID, nItemInstanceId)
        log("Cannot pick up Item ! Distance check invalid!", nCharacterInstanceId, nItemInstanceId)
        return
    end

    local bInDeadBox = IsInDeadBox(Item)

    local nRoomActorId = SceneItemContainer:GetOwnerRoomActorServerInstanceId(Item)

    local nTemplateId = Item:GetTemplateId()

    -- if nCount is less than stack count, create Item for remaining count
    if Item:IsStackable() and nCount and nCount > 0 then
        local nStackCount = Item:GetStackCount()
        nCount = math.min(nStackCount, nCount)
        Item:SetStackCount(nCount)
        local nRemainingCount = nStackCount - nCount
        if nRemainingCount > 0 then
            local tbRemainItem = CreateAndAddItemToScene(self, nCharacterInstanceId, nTemplateId, nRemainingCount)
            EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_REMAIN_SERVER, tbRemainItem)
        end
    end

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_REQUEST_PICK_UP_SERVER, nCharacterInstanceId, nItemInstanceId)

    local bSuccess, AddedItem, nAddedCount = MoveItemToCharacter(self, nCharacterInstanceId, Item, nil, BattleItemSourceDef.PICK_UP, true)
    local nRet = ProtoDC.ItemReturnCode.OK
    if not bSuccess then
        nRet = ProtoDC.ItemReturnCode.INVENTORY_FULL
    end
    if nRet == ProtoDC.ItemReturnCode.OK then
        RepHumanPickupAction(self, tbPlayer, nItemInstanceId, nTemplateId)
    end
    BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbPlayer, nRet, nItemInstanceId, nTemplateId)

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER, tbPlayer, AddedItem, nRet == ProtoDC.ItemReturnCode.OK, nRoomActorId, nAddedCount, bInDeadBox)

    if nRet == ProtoDC.ItemReturnCode.OK then
        AfterPickedUpOnServer(nCharacterInstanceId, AddedItem)
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_AFTER_PICK_UP_SERVER, tbPlayer, nItemInstanceId)
    end
end

-- 处理捡起场景中的物品
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param tbItemInstanceIds: 物品nItemInstanceId的数组
function BattleItemSystemServer:ThrowAwayAndPickupItem(nCharacterInstanceId, tbPacket)
    local ItemReturnCode = ProtoDC.ItemReturnCode
    local tbPlayer = GetPlayer(nCharacterInstanceId)
    local nItemInstanceId = tbPacket.pick_up_instance_id
    if IsParachuting(self, nCharacterInstanceId) then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, ItemReturnCode.CANNOT_PICKUP_PARACHUTING, nItemInstanceId, nil)
        log("PickUp failed! player is parachuting!", nCharacterInstanceId)
        return
    end

    if not IsPlayerAlive(nCharacterInstanceId) or IsPlayerDying(nCharacterInstanceId) then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, ItemReturnCode.CANNOT_PICKUP_NOT_ALIVE, nItemInstanceId, nil)
        log("PickUp failed! player is dead or dying!", nCharacterInstanceId)
        return
    end

    local Item = self:GetItem(nItemInstanceId)
    if Item == nil then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, ItemReturnCode.ITEM_HAS_ALREADY_PICKED, nItemInstanceId, nil)
        log("PickUpSceneItem failed!Item not found!", nItemInstanceId)
        return
    end

    local nRoomActorId = SceneItemContainer:GetOwnerRoomActorServerInstanceId(Item)

    local nTemplateId = Item:GetTemplateId()
    if Item:GetOwnerCharacter() ~= nil then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, ItemReturnCode.ITEM_HAS_ALREADY_PICKED, nItemInstanceId, nTemplateId)
        log("Item has owner!Cannot pickup", Item:GetOwnerCharacterInstanceId(), nCharacterInstanceId, nItemInstanceId)
        return
    end

    if Item:GetCategory() == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, ItemReturnCode.CANNOT_PICKUP_CATEGORY_INVALID, nItemInstanceId, nil)
        logerror("Cannot pick up scene box!", Item:GetCategory())
        return
    end

    if not self:CheckPickupDistance(tbPlayer, Item) then
        BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, ItemReturnCode.CANNOT_PICKUP_DISTANCE_INVALID, nItemInstanceId, nil)
        log("Cannot pick up Item ! Distance check invalid!", nCharacterInstanceId, nItemInstanceId)
        return
    end

    local bInDeadBox = IsInDeadBox(Item)

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_REQUEST_PICK_UP_SERVER, nCharacterInstanceId, nItemInstanceId)

    local tbThrowItems = tbPacket.throw_items
    if tbThrowItems ~= nil then
        for _, v in ipairs(tbThrowItems) do
            local nMaterialInstanceId = v.instance_id
            local MaterialItem = self:GetItem(nMaterialInstanceId)
            local nThrowCount = v.count
            local nMaterialTemplateId = MaterialItem:GetTemplateId()
            local bSuccess, _ = ThrowAwayItem(self, nCharacterInstanceId, nMaterialInstanceId, nThrowCount)
            if bSuccess then
                EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_THROW_AWAY_ITEM_FINISH_SERVER, nCharacterInstanceId, nMaterialInstanceId, nMaterialTemplateId, nThrowCount)
            end
        end
    end

    local bSuccess, AddedItem, nAddedCount = MoveItemToCharacter(self, nCharacterInstanceId, Item, nil, BattleItemSourceDef.PICK_UP, true)
    local nRet = ItemReturnCode.OK
    if not bSuccess then
        nRet = ItemReturnCode.INVENTORY_FULL
    end
    if nRet == ItemReturnCode.OK then
        RepHumanPickupAction(self, tbPlayer, nItemInstanceId, nTemplateId)
    end
    BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbPlayer, nRet, nItemInstanceId, nTemplateId)

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_PICK_UP_FINISH_SERVER, tbPlayer, AddedItem, nRet == ProtoDC.ItemReturnCode.OK, nRoomActorId, nAddedCount, bInDeadBox)

    if nRet == ProtoDC.ItemReturnCode.OK then
        AfterPickedUpOnServer(nCharacterInstanceId, AddedItem)
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_ITEM_AFTER_PICK_UP_SERVER, tbPlayer, nItemInstanceId)
    end
end

-- 给玩家增加某一个类型的道具
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nCount 增加数量，不可超过道具的叠加数量，超过的部分会抹掉
function BattleItemSystemServer:AddItemByTemplate(nCharacterInstanceId, nItemTemplateId, nCount, nBattleItemSource)
    if not IsPlayerAlive(nCharacterInstanceId) then
        logerror("AddItemByTemplate failed! player is dead!", nCharacterInstanceId)
        return
    end

    if IsParachuting(self, nCharacterInstanceId) then
        logerror("AddItemByTemplate failed! player is parachuting!", nCharacterInstanceId)
        return
    end

    if not CheckCanAdd(nItemTemplateId, nBattleItemSource) then
        logerror("AddItemByTemplate failed! item cannot known by player!", nCharacterInstanceId)
        return
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbTemplate == nil then
        logerror("BattleItemSystemServer:AddBattleItem failed! Cannot find nItemTemplateId!", nItemTemplateId)
        return
    end
    local Item = self:CreateItem(nItemTemplateId, nCount)
    log("AddItemByTemplate", Item:GetInstanceId(), nItemTemplateId)
    if CanAddToCharacter(self, nCharacterInstanceId, Item, nil) then
        if not nBattleItemSource then
            nBattleItemSource = BattleItemSourceDef.OTHER
        end
        MoveItemToCharacter(self, nCharacterInstanceId, Item, nil, nBattleItemSource, true)
    else
        AddItemToScene(nCharacterInstanceId, nil, Item)
    end
end

-- 在玩家背包里移除某一个类型的道具
-- @param nCharacterInstanceId LuaCharacter的nServerInstanceId
-- @param nItemTemplateId 物品的template id
-- @return nCount 移除数量，如果nCount是nil或者0，就表示全部移除
function BattleItemSystemServer:DestroyUnequippedItemsByTemplate(nCharacterInstanceId, nItemTemplateId, nCount)
    if nCount == nil then
        nCount = 0
    end
    local BattleItemComponent = GetBattleItemComponent(nCharacterInstanceId)
    local tbItems = BattleItemComponent:GetUnequippedItems(nItemTemplateId)
    if #tbItems == 0 then
        return
    end
    local tbRemoveItems = GetUnequippedRemoveItemDatas(nCharacterInstanceId, tbItems, nCount)

    for _, v in ipairs(tbRemoveItems) do
        local Item = v.Item
        local nRemoveCount = v.nRemoveCount
        local nStackCount = Item:GetStackCount()
        local nItemInstanceId = Item:GetInstanceId()
        if nRemoveCount >= nStackCount then
            self:DestroyPlayerItem(nCharacterInstanceId, nItemInstanceId)
        else
            self:DecreasePlayerItemCount(nCharacterInstanceId, nItemInstanceId, nRemoveCount)
        end
    end
end

return BattleItemSystemServer
