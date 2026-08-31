-----------------------------------------------------
--File Name    : BattlePickupSystem.lua
--Author       : ranjie
--Create Time  : 2018-12-12
--Description  : 物品拾取system
-----------------------------------------------------
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local SelfAnimationHelper = require("SelfAnimationHelper")
local EventManager = require("EventManager")
local SceneItemActorDef = require("SceneItemActorDef")
local BattleItemSystemClient = require("BattleItemSystemClient")
local DelayTimer = require("DelayTimer")
--local ControlModeDef = require("ControlModeDef")
local BattlePickTypeDef = require("BattlePickTypeDef")
-- local HumanWeaponPositionDef = require("HumanWeaponPositionDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local HumanWeaponMisc = require("HumanWeaponMisc")
local ResourceManager = require("ResourceManager")
local BattleItemResDataTable = require("BattleItemResDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")
local ProgressBarTableNew = require("ProgressBarTableNew")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local ProtoDC = require("DungeonCommonProtoNames")
local SoundManager = require("SoundManager")
local BattlePickupIni = require("BattlePickupIni")
local HumanMovementStateType = require("HumanMovementStateType")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattlePickupSystem = {}


BattlePickupSystem.tbRequestItemData = nil
BattlePickupSystem.tbRequestInfo = nil
BattlePickupSystem.tbFinishPickupId = nil

BattlePickupSystem.tbPendingLoadServerData = nil
BattlePickupSystem.fnAsynLoadCallback = nil
BattlePickupSystem.tbAsynLoadHandles = nil
BattlePickupSystem.nProgressBarId = nil

BattlePickupSystem.tbManualPickUpRecords = nil
BattlePickupSystem.nPickupItemInstanceId = nil
BattlePickupSystem.tbPickupTimeHandle = nil
BattlePickupSystem.bItemAutoOpen = nil
BattlePickupSystem.bBoxAutoOpen = nil
BattlePickupSystem.tbTargetWatchPlayer = nil

local MANUAL_PICK_DELAY_REQUEST = 0.5
local RELOAD_DELAY = 1    --拾取完恢复装填的delay，必须大于AUTO_PICKUP_DELAY
local PICKUP_TIME_OUT = 1
local PLAY_SOUND_DISTANCE = BattlePickupIni.tbBattlePickup.nSoundDistance
local StaticFindObject = EngineExtShell.StaticFindObject

local TO_PICK_TYPE =
{
    [SceneItemActorDef.ITEM] = BattlePickTypeDef.ITEM,
    [SceneItemActorDef.SIGHT_FREE_ITEM] = BattlePickTypeDef.ITEM,
    [SceneItemActorDef.DIE_BOX] = BattlePickTypeDef.BOX,
    [SceneItemActorDef.AIR_DROP_BOX] = BattlePickTypeDef.BOX,
    [SceneItemActorDef.TREASURE_CHEST] = BattlePickTypeDef.BOX,
}

local REQUEST_VIEW_DELAY = 0.01

local function CheckAllItemLoaded(self, tbItems)
    if(tbItems == nil or #tbItems == 0) then
        return true
    end

    local tbAsynLoadHandles = self.tbAsynLoadHandles
    for _, v in ipairs(tbItems) do
        if(tbAsynLoadHandles[v.template_id] ~= nil) then
            return false
        end
    end
    return true
end

-- 这里其实有个小问题，因为没有hold住object，所以有可能还没用上时被gc掉了，但因为时间比较短出现概率较低
-- 所以这里就没管，如果管理hold就比较麻烦
local function OnAsynLoad(self, szAssetName, pObject, nHandle)
    local tbAsynLoadHandles = self.tbAsynLoadHandles
    for k, v in pairs(tbAsynLoadHandles) do
        if(v == nHandle) then
            tbAsynLoadHandles[k] = nil
            break
        end
    end

    local tbPacket, bAllLoaded
    local tbPendingLoadServerData = self.tbPendingLoadServerData
    local nIndex = 1
    while(nIndex <= #tbPendingLoadServerData) do
        bAllLoaded = true
        tbPacket = tbPendingLoadServerData[nIndex]
        if(tbPacket.scene_rooms) then
            for _, v in ipairs(tbPacket.scene_rooms) do
                bAllLoaded = bAllLoaded and CheckAllItemLoaded(self, v.items)
            end
        end
        if(bAllLoaded and tbPacket.items) then
            bAllLoaded = CheckAllItemLoaded(self, tbPacket.items)
        end

        if(bAllLoaded) then
            table.remove(tbPendingLoadServerData, nIndex)
            self:SyncViewSceneItem(tbPacket, true)
        else
            nIndex = nIndex + 1
        end
    end
end

local function InitAsynLoadData(self)
    self.tbPendingLoadServerData = {}
    self.tbAsynLoadHandles = {}
    self.fnAsynLoadCallback = function(szAssetName, pObject, nHandle)
        OnAsynLoad(self, szAssetName, pObject, nHandle)
    end
end

local function UninitAsynLoadData(self)
    self.tbPendingLoadServerData = nil
    for _, v in pairs(self.tbAsynLoadHandles) do
        ResourceManager:CancelLoadAsync(v)
    end
    self.tbAsynLoadHandles = nil
    self.fnAsynLoadCallback = nil
end

local function ClearTimer(self)
    if self.tbDelayReloadingHandle then
        DelayTimer:ClearTimer(self.tbDelayReloadingHandle)
        self.tbDelayReloadingHandle = nil
    end
    if self.tbRequestInfo and self.tbRequestInfo.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbRequestInfo.tbDelayHandle)
        self.tbRequestInfo.tbDelayHandle = nil
    end
    if self.tbPickupTimeHandle then
        DelayTimer:ClearTimer(self.tbPickupTimeHandle)
        self.tbPickupTimeHandle = nil
    end
    if self.OtherPlayerPickUpTimer then 
        DelayTimer:ClearTimer(self.OtherPlayerPickUpTimer)
        self.OtherPlayerPickUpTimer = nil 
    end 
end

local function LoadItemServerDataAsynImp(self, tbItems)
    local tbAsynLoadHandles = self.tbAsynLoadHandles
    local tbTemplate, tbResTemplate, nHandle, nItemTemplateId
    local bRet = false

    -- 没有continue只能套这么多层。。
    for _, v in ipairs(tbItems) do
        nItemTemplateId = v.template_id
        if(tbAsynLoadHandles[nItemTemplateId] == nil) then
            tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
            if tbTemplate then
                tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
                if(tbResTemplate) then
                    if(StaticFindObject(tbResTemplate.szIconPath) == nil) then
                        nHandle = ResourceManager:LoadAsync(tbResTemplate.szIconPath, self.fnAsynLoadCallback, false)
                        if(nHandle > 0) then
                            tbAsynLoadHandles[nItemTemplateId] = nHandle
                            bRet = true
                        end -- if(nHandle > 0) then
                    end -- if(StaticFindObject(tbResTemplate.szIconPath) == nil) then
                end -- if(tbResTemplate) then
            end -- if tbTemplate then
        end -- if(tbAsynLoadHandles[nItemTemplateId] == nil) then
    end -- for _, v in ipairs(tbItems) do
    return bRet
end

local function LoadItemServerDataAsyn(self, tbPacket)
    assert(tbPacket)

    local tbSceneRooms = tbPacket.scene_rooms
    local bHasAsynLoad = false
    if(tbSceneRooms) then
        for _, v in ipairs(tbSceneRooms) do
            bHasAsynLoad = LoadItemServerDataAsynImp(self, v.items) or bHasAsynLoad
        end
    end

    bHasAsynLoad = LoadItemServerDataAsynImp(self, tbPacket.items) or bHasAsynLoad

    if(bHasAsynLoad) then
        table.insert(self.tbPendingLoadServerData, tbPacket)
    end

    return bHasAsynLoad
end

local function UnloadItemServerDataWithItems(self, nInstanceId, tbItems)
    if(tbItems == nil) then
        return false
    end

    for k, v in ipairs(tbItems) do
        if(v.instance_id == nInstanceId) then
            table.remove(tbItems, k)
            return true
        end
    end

    return false
end

local function UnloadItemServerData(self, nInstanceId)
    local tbRooms, bRemoved
    for nPacketIndex, tbPendingPacket in ipairs(self.tbPendingLoadServerData) do
        tbRooms = tbPendingPacket.scene_rooms
        bRemoved = false
        if(tbRooms) then
            for nRoomIndex, tbRoom in ipairs(tbRooms) do
                if(tbRoom.instance_id == nInstanceId) then
                    table.remove(tbRooms, nRoomIndex)
                    if(#tbRooms == 0) then
                        tbPendingPacket.scene_rooms = nil
                        tbRooms = nil
                    end
                    bRemoved = true
                    break
                else
                    if(UnloadItemServerDataWithItems(self, nInstanceId, tbRoom.items)) then
                        bRemoved = true
                        break
                    end -- if(UnloadItemServerDataWithItems(self, nInstanceId, tbRoom.items)) then
                end -- if(tbRoom.instance_id == nInstanceId) then
            end -- for nRoomIndex, tbRoom in ipairs(tbRooms) do
        end -- if(tbRooms) then

        if(not bRemoved) then
            bRemoved = UnloadItemServerDataWithItems(self, nInstanceId, tbPendingPacket.items)
        end

        if(bRemoved) then
            if(tbPendingPacket.items and #tbPendingPacket.items > 0) then
                return
            end
            if(tbRooms ~= nil and #tbRooms > 0) then
                return
            end
            table.remove(self.tbPendingLoadServerData, nPacketIndex)
            return
        end
    end
end

--
local function GetPickupItemData(self, tbItemList, nInstanceId)
    for k, v in ipairs(tbItemList) do
        if v.nInstanceId == nInstanceId then
            return k, v
        end
        local tbServerData = v.tbServerData
        if tbServerData and tbServerData.items then
            for k1, v1 in ipairs(tbServerData.items) do
                if v1.instance_id == nInstanceId then
                    return k, v, k1, v1
                end
            end
        end
    end
end

local function SortCompareProtoFunc(tbItemProtoData1, tbItemProtoData2)
    if tbItemProtoData1.bIsAutoPickUp then
        if tbItemProtoData2.bIsAutoPickUp then
            return tbItemProtoData1.instance_id < tbItemProtoData2.instance_id
        else
            return true
        end
    else
        if tbItemProtoData2.bIsAutoPickUp then
            return false
        else
            if tbItemProtoData1.bIsBetter then
                if tbItemProtoData2.bIsBetter then
                    return tbItemProtoData1.instance_id < tbItemProtoData2.instance_id
                else
                    return true
                end
            else
                if tbItemProtoData2.bIsBetter then
                    return false
                else
                    return tbItemProtoData1.instance_id < tbItemProtoData2.instance_id
                end
            end
        end
    end
end

local function SortCompareItemFunc(tbItemData1, tbItemData2)
    local tbItemProtoData1 = tbItemData1.tbServerData
    local tbItemProtoData2 = tbItemData2.tbServerData
    if tbItemProtoData1 == nil or tbItemProtoData2 == nil or tbItemData1.nPickType == BattlePickTypeDef.BOX or tbItemData2.nPickType == BattlePickTypeDef.BOX then
        return tbItemData1.nInstanceId < tbItemData2.nInstanceId
    else
        return SortCompareProtoFunc(tbItemProtoData1, tbItemProtoData2)
    end
end

local function CreatePickupItemData(self, nPickType, nInstanceId)
    for k, v in ipairs(self.tbRequestItemData) do
        if v.nInstanceId == nInstanceId then
            log("BattlePickupSystem:CreatePickupItemData, data is exist,nPickType, nInstanceId=",nPickType, nInstanceId)
            return
        end
    end
    local tbData = {}
    tbData.nPickType = nPickType
    tbData.nInstanceId = nInstanceId
    table.insert(self.tbRequestItemData, tbData)
end

local function GetAutoPickup(tbItemProtoData)
    local bIsBetter, bIsAutoPickUp, nAutoPickUpCount = BattleItemSystemClient:CanAutoPickUp(tbItemProtoData)
    local bIsTraining = GlobalVariableSystem:IsInTrainingCamp(BattleGameModeSystem.nDungeonId)
    if bIsTraining then
        bIsAutoPickUp, nAutoPickUpCount = false, 0
    end
    return bIsBetter, bIsAutoPickUp, nAutoPickUpCount
end

local function SetCanAutoPickup(tbItemProtoData)
    local bIsBetter, bIsAutoPickUp, nAutoPickUpCount = GetAutoPickup(tbItemProtoData)
    tbItemProtoData.bIsBetter = bIsBetter
    tbItemProtoData.bIsAutoPickUp = bIsAutoPickUp
    if bIsAutoPickUp then
        tbItemProtoData.nAutoPickUpCount = nAutoPickUpCount
    end
end

local function UpdatePickupItemServerData(self, tbServerDatas)
    if tbServerDatas then
        for k, v in ipairs(tbServerDatas) do
            local _, tbData = GetPickupItemData(self, self.tbRequestItemData, v.instance_id)
            if tbData then
                tbData.tbServerData = v
                if v.items then
                    for k1, v1 in ipairs(v.items) do
                        SetCanAutoPickup(v1)
                    end
                    table.sort(v.items, SortCompareProtoFunc)
                else
                    SetCanAutoPickup(v)
                end
            end
        end
        table.sort(self.tbRequestItemData, SortCompareItemFunc)
    end
end

local function RemovePickupItemData(self, nInstanceId)
    if(GlobalVariableSystem.bEnableAsynPickup) then
        UnloadItemServerData(self, nInstanceId)
    end

    local nIndex, tbData, nSubIndex, tbSubData = GetPickupItemData(self, self.tbRequestItemData, nInstanceId)
    --logdebug("RemovePickupItemData,nInstanceId,nIndex, tbData, nSubIndex, tbSubData=",nInstanceId,nIndex, tbData, nSubIndex, tbSubData)
    if nIndex and tbData then
        if nSubIndex and tbSubData then
            table.remove(tbData.tbServerData.items, nSubIndex)
        else
            table.remove(self.tbRequestItemData, nIndex)
        end
        return true
    end
    return false
end

local function GetRequestIdByPickType(self, nPickType, bAllType)
    local tbRequestId = {}
    if self.tbRequestItemData then
        for k, v in ipairs(self.tbRequestItemData) do
            if v.nPickType == nPickType or bAllType then
                table.insert(tbRequestId, v.nInstanceId)
            end
        end
    end
    return tbRequestId
end

local function GetAllBoxRequestId(self)
    local tbRequestId = {}
    if self.tbRequestItemData then
        for k, v in ipairs(self.tbRequestItemData) do
            if v.nPickType ~= BattlePickTypeDef.ITEM then
                table.insert(tbRequestId, v.nInstanceId)
            end
        end
    end
    return tbRequestId
end

local function GetServerDataByPickType(self, nPickType)
    local tbServerDatas = {}
    if self.tbRequestItemData then
        for k, v in ipairs(self.tbRequestItemData) do
            if v.nPickType == nPickType and v.tbServerData then
                table.insert(tbServerDatas, v.tbServerData)
            end
        end
    end
    return tbServerDatas
end

local function GetAllBoxServerData(self)
    local tbServerDatas = {}
    if self.tbRequestItemData then
        for k, v in ipairs(self.tbRequestItemData) do
            if v.nPickType ~= BattlePickTypeDef.ITEM then
                table.insert(tbServerDatas, v.tbServerData)
            end
        end
    end
    return tbServerDatas
end

local function OnEnterPickupTrigger(self, Owner, GameObj)
    log("OnEnterPickupTrigger start")
    if Owner ~= GamePlayerSelfHelper:Get() then
        return
    end
    if GameObj:GetObjectType() ~= GameObjectTypeDef.Trigger or GameObj.tbCustomProtoData == nil or GameObj.tbCustomProtoData.scene_item_info == nil then
        return
    end
    local scene_item_info = GameObj.tbCustomProtoData.scene_item_info
    local nPickType = TO_PICK_TYPE[scene_item_info.type]
    if not nPickType then
        log("BattlePickupSystem:OnEnterPickupTrigger,nPickType is nil,",scene_item_info.type, scene_item_info.instance_id, GameObj:GetServerInstanceId(), GameObj.nTemplateId)
        return
    end
    local nInstanceId = scene_item_info.instance_id
    --log("BattlePickupSystem:OnEnterPickupTrigger,ItemType,nInstanceId=",nPickType, nInstanceId, GameObj:GetServerInstanceId(), GameObj.nTemplateId)
    CreatePickupItemData(self, nPickType, nInstanceId)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_PICKUP_ENTER, nPickType, nInstanceId)
    log("OnEnterPickupTrigger end")
end

local function TryRemovePickInfo(self, tbGameObject)
    local tbCustomProtoData = tbGameObject.tbCustomProtoData
    if not tbCustomProtoData then
        return
    end
    local scene_item_info = tbCustomProtoData.scene_item_info
    if not scene_item_info then
        return
    end
    local nPickType = TO_PICK_TYPE[scene_item_info.type]
    if not nPickType then
        log("BattlePickupSystem:TryRemovePickInfo,nPickType is nil,",scene_item_info.type, scene_item_info.instance_id, tbGameObject:GetServerInstanceId(), tbGameObject.nTemplateId)
        return
    end
    local nInstanceId = scene_item_info.instance_id
    local bRet = RemovePickupItemData(self, nInstanceId)
    if bRet then
        log("BattlePickupSystem:TryRemovePickInfo,nPickType,nInstanceId=",nPickType, nInstanceId, tbGameObject:GetServerInstanceId(), tbGameObject.nTemplateId)
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_PICKUP_LEAVE, nPickType, nInstanceId)
    end
end

local function OnLeavePickupTrigger(self, Owner, GameObj)
    if Owner ~= GamePlayerSelfHelper:Get() then
        return
    end
    if GameObj:GetObjectType() ~= GameObjectTypeDef.Trigger then
        return
    end
    TryRemovePickInfo(self, GameObj)
end

local function OnPickItemDestory(self, tbGameObject)
    TryRemovePickInfo(self, tbGameObject)
end




local function SortData(tbItemList)
    --log("SortData start")
    -- for _, v in pairs(tbItemList) do
    --     log("CanAutoPickUp start")
    --     local bIsBetter, bIsAutoPickUp, nAutoPickUpCount = BattleItemSystemClient:CanAutoPickUp(v)
    --     log("CanAutoPickUp end")
    --     v.bIsBetter = bIsBetter
    --     v.bIsAutoPickUp = bIsAutoPickUp
    --     if bIsAutoPickUp then
    --         v.nAutoPickUpCount = nAutoPickUpCount
    --     end
    -- end
    --log("SortData table.sort")
    table.sort(tbItemList, SortCompareProtoFunc)
    --log("SortData end")
end

local function PlayPickAnim(self, nInstanceId, nItemTemplateId, tbGamePlayer)
    local bSelf = false
    if not tbGamePlayer then
        tbGamePlayer = GamePlayerSelfHelper:Get()
        bSelf = true
    end
    if tbGamePlayer:IsShip() then
        return
    end
    if not tbGamePlayer.pUEActor:WasRecentlyRendered(0.2) then 
        return 
    end 

    local HumanWeaponComponent = tbGamePlayer.HumanWeaponComponent
    if not HumanWeaponComponent then
        return
    end
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if not tbItemTemplate then
        logerror("BattlePickupSystem:PlayPickAnim, tbItemTemplate is nil, nInstanceId, nItemTemplateId =", nInstanceId, nItemTemplateId, tbGamePlayer:GetObjectType())
        return
    end
    local nCategory = tbItemTemplate.nCategory
    -- local nCurrentWeaponPos = HumanWeaponPositionDef.NONE
    local nCurrentInstanceId = nInstanceId
    if HumanWeaponComponent then
        if HumanWeaponComponent:IsReloading() then
            return
        end
        nCurrentInstanceId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
    end

    local bExplosive
    if(nCurrentInstanceId ~= 0) then
        local tbWeapon = HumanWeaponComponent:GetCurrentWeapon(true)
        if tbWeapon then
            bExplosive = tbWeapon:IsType(HumanWeaponMisc.Type.THROW)
        end
    end

    if bExplosive then
        if nCategory == BattleItemCategoryDef.HUMAN_WEAPON or nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
            if nInstanceId ~= nCurrentInstanceId then
                if (nCurrentInstanceId ~= 0 and nCategory == BattleItemCategoryDef.HUMAN_THROWN_ITEM) or nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
                    local CurrentItem = BattleItemSystemClient:GetItem(nCurrentInstanceId)
                    if not CurrentItem then
                        --道具系统拿不到nCurrentInstanceId这个道具，说明已经替换掉了，需要等currentweaponchanged的事件
                        self.tbFinishPickupId[nInstanceId] = nItemTemplateId
                        return
                    end
                end
            end
        end
    end
    local szAnimKey = SelfAnimationHelper.AnimDef.PICK_UP
    if nCurrentInstanceId == 0 or bExplosive then
        szAnimKey = SelfAnimationHelper.AnimDef.UN_ARMED_PICK
    end
    log("BattlePickupSystem:PlayPickAnim,szAnimKey=",szAnimKey, nCurrentInstanceId)
    local _bRet, nTime = SelfAnimationHelper:PlayHumanAnimation(tbGamePlayer, szAnimKey)
    if not bSelf then 
        tbGamePlayer.pUEActor.bIsPickingUp = true 
        DelayTimer:ClearTimer(self.OtherPlayerPickUpTimer)
        self.OtherPlayerPickUpTimer = DelayTimer:DelayRun(function() 
            if tbGamePlayer and tbGamePlayer:IsHuman() and tbGamePlayer.pUEActor then 
                tbGamePlayer.pUEActor.bIsPickingUp = false 
            end
            self.OtherPlayerPickUpTimer = nil 
        end, nTime)
    end 
end

local function PlayPickUpSound(nItemTemplateId)
    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    if tbItemResTemplate.nPickSoundID > 0 then
        log("pick up play sound ", nItemTemplateId, tbItemResTemplate.nPickSoundID)
        SoundManager:PlaySoundEffect(tbItemResTemplate.nPickSoundID)
    end
end

local function OnCurrentWeaponChaned(self, nNewWeapon, nLastWeapon, nOwnerSeverId)
    -- if GamePlayerSelfHelper:GetServerInstanceId() ~= nOwnerSeverId then
    --     return
    -- end

    if self.tbFinishPickupId[nNewWeapon] then
        if GamePlayerSelfHelper:GetServerInstanceId() == nOwnerSeverId then
            local Item = BattleItemSystemClient:GetItem(nNewWeapon)
            if Item then
                PlayPickAnim(self, nNewWeapon, Item:GetTemplateId())
            end
        else
            PlayPickAnim(self, nNewWeapon, self.tbFinishPickupId[nNewWeapon])
        end
        self.tbFinishPickupId[nNewWeapon] = nil
    end
end

local function OnProgressChanged(self, nInstanceId, bStart, nProgressBarId, nProgressBarTime)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf == nil then
        return
    end
    local nSelfInstanceId = PlayerSelf:GetServerInstanceId()
    if nSelfInstanceId ~= nInstanceId then
        return
    end
    if bStart then
        self.nProgressBarId = nProgressBarId
    else
        local tbTemplate = ProgressBarTableNew:GetTemplate(self.nProgressBarId)
        self.nProgressBarId = nil
        if tbTemplate and tbTemplate.bRefreshPickList then
            EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_REFRESH_PICKUP_LIST)
        end
    end
end

-- local function OnPickupFinish(self, nInstanceId, _)
--     if self.tbManualPickUpRecords ~= nil then
--         self.tbManualPickUpRecords[nInstanceId] = nil
--     end
-- end

local function OnWatchTargetChanged(self, tbTargetWatchPlayer)
    self.tbTargetWatchPlayer = tbTargetWatchPlayer
end

local function OnHumanPickupAction(self, tbGamePlayer, nItemInstanceId, nItemTemplateId)
    local tbTargetPlayer = self.tbTargetWatchPlayer
    if not tbTargetPlayer then
        tbTargetPlayer = GamePlayerSelfHelper:Get()
    end
    --处理其他玩家的拾取动作
    if tbGamePlayer:GetObjectType() ~= GameObjectTypeDef.PlayerSelf then
        if nItemTemplateId and nItemTemplateId ~= 0 then
            if tbTargetPlayer.pUEActor and isvalidhandle(tbTargetPlayer.pUEActor) and tbGamePlayer.pUEActor then
                local nDistance = tbTargetPlayer.pUEActor:GetDistanceTo(tbGamePlayer.pUEActor)
                if nDistance <= PLAY_SOUND_DISTANCE then
                    log("PlayPickUpSound other player,type=",tbGamePlayer:GetObjectType())
                    PlayPickUpSound(nItemTemplateId)
                end
                PlayPickAnim(self, nItemInstanceId, nItemTemplateId, tbGamePlayer)
            end
        else
            log("BattlePickupSystem:OnHumanPickupAction:nItemTemplateId is nil or 0, type=",tbGamePlayer:GetObjectType())
        end
    end
end

local function ClearPickupState(self)
    if self.tbPickupTimeHandle then
        DelayTimer:ClearTimer(self.tbPickupTimeHandle)
        self.tbPickupTimeHandle = nil
    end
    self:SetPickingUp(nil)
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if HumanWeaponComponent and not self.nPickupItemInstanceId then
        if self.tbDelayReloadingHandle then
            DelayTimer:ClearTimer(self.tbDelayReloadingHandle)
            self.tbDelayReloadingHandle = nil
        end
        local function DelayTryReload()
                HumanWeaponHelper.TryReload(HumanWeaponComponent)
            --end
            self.tbDelayReloadingHandle = nil
        end
        self.tbDelayReloadingHandle = DelayTimer:DelayRun(DelayTryReload, RELOAD_DELAY)
    end
end

function BattlePickupSystem:Init()
    self.tbRequestItemData = {}
    self.tbRequestInfo = {}
    self.tbFinishPickupId = {}
    self:SetPickingUp(nil)
    self.bItemAutoOpen = true
    self.bBoxAutoOpen = false
    self.tbTargetWatchPlayer = nil
    InitAsynLoadData(self)
    EventManager:BindEventMethod(CommonEventDef.EV_PLAYER_ENTER_TRIGGER, self, OnEnterPickupTrigger)
    EventManager:BindEventMethod(CommonEventDef.EV_PLAYER_LEAVE_TRIGGER, self, OnLeavePickupTrigger)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, OnPickItemDestory)
    EventManager:BindEventMethod(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnCurrentWeaponChaned)
    EventManager:BindEventMethod(CommonEventDef.EV_HUMAN_PICKUP_ACTION, self, OnHumanPickupAction)
    EventManager:BindEventMethod(CommonEventDef.EV_PROGRESS_CHANGED, self, OnProgressChanged)
    --EventManager:BindEventMethod(ClientEventDef.EV_PICK_UP_FINISH, self, OnPickupFinish)
    EventManager:BindEventMethod(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnWatchTargetChanged)
    return true
end

function BattlePickupSystem:Uninit()
    UninitAsynLoadData(self)
    ClearTimer(self)
    self.tbRequestItemData = nil
    self.tbRequestInfo = nil
    self.tbFinishPickupId = nil
    self.tbPendingLoadServerData = nil
    self.nProgressBarId = nil
    EventManager:UnBindEventMethod(CommonEventDef.EV_PLAYER_ENTER_TRIGGER, self, OnEnterPickupTrigger)
    EventManager:UnBindEventMethod(CommonEventDef.EV_PLAYER_LEAVE_TRIGGER, self, OnLeavePickupTrigger)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_PRE_DESTORY, self, OnPickItemDestory)
    EventManager:UnBindEventMethod(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnCurrentWeaponChaned)
    EventManager:UnBindEventMethod(CommonEventDef.EV_HUMAN_PICKUP_ACTION, self, OnHumanPickupAction)
    EventManager:UnBindEventMethod(CommonEventDef.EV_PROGRESS_CHANGED, self, OnProgressChanged)
    --EventManager:UnBindEventMethod(ClientEventDef.EV_PICK_UP_FINISH, self, OnPickupFinish)
    EventManager:UnBindEventMethod(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnWatchTargetChanged)
end

---------------------------------------------------------------------
--服务器回包更新数据
function BattlePickupSystem:SyncViewSceneItem(tbPacket, bForce)
    --log("BattlePickupSystem:SyncViewSceneItem start")
    local t1 = getseconds() * 1000
    if(GlobalVariableSystem.bEnableAsynPickup) then
        if(not bForce and LoadItemServerDataAsyn(self, tbPacket)) then
            -- Test
            -- if(tbPacket.scene_rooms and #tbPacket.scene_rooms > 0) then
            --     local bRemoveRoom = math.random(1, 2) == 1
            --     local tbTempRoom = tbPacket.scene_rooms[math.random(1, #tbPacket.scene_rooms)]
            --     if(bRemoveRoom) then
            --         UnloadItemServerData(self, tbTempRoom.instance_id)
            --         logdebug("Test remove room", tbTempRoom.instance_id)
            --     else
            --         local tbItem = tbTempRoom.items[math.random(1, #tbTempRoom.items)]
            --         UnloadItemServerData(self, tbItem.instance_id)
            --         logdebug("Test remove item in room", tbItem.instance_id)
            --     end
            -- else
            --     local tbItem = tbPacket.items[math.random(1, #tbPacket.items)]
            --     UnloadItemServerData(self, tbItem.instance_id)
            --     logdebug("Test remove item", tbItem.instance_id)
            -- end

            return
        end
    end
    local t2 = getseconds() * 1000
    --log("BattlePickupSystem:LoadItemServerDataAsyn end")
    UpdatePickupItemServerData(self, tbPacket.scene_rooms)
    UpdatePickupItemServerData(self, tbPacket.items)
    local t3 = getseconds() * 1000
    log("BattlePickupSystem:fire EV_BATTLE_ITEM_SYNC_SCENE_ITEM start", getseconds() * 1000)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_ITEM_SYNC_SCENE_ITEM)
    local t4 = getseconds() * 1000
    log("BattlePickupSystem:fire EV_BATTLE_ITEM_SYNC_SCENE_ITEM end", t2-t1, t3-t2, t4-t3)
end

function BattlePickupSystem:RemovePickupItem(nInstanceId)
    local bRet = RemovePickupItemData(self, nInstanceId)
    if bRet then
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_PICKUP_REMOVE, nInstanceId)
    end
end

local function GetTemplateAndCountAfterConvert(tbItemTemplate, nCount)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.CONVERTIBLE_ITEM then
        return tbItemTemplate.nConvertItemTemplateId, tbItemTemplate.nConvertItemCount
    end
    return tbItemTemplate.nId, nCount
end

local function HaveOtherMaterial(nItemTemplateId)
    local tbItems = BattleItemSystemClient:GetUnequippedItemsByCategory(BattleItemCategoryDef.MATERIAL)
    for _, v in pairs(tbItems) do
        if v:GetTemplateId() ~= nItemTemplateId then
            return true
        end
    end
    return false
end

local function TryOpenPickupExchange(nItemInstanceId, nItemTemplateId, nCount)
    if not HaveOtherMaterial(nItemTemplateId) then
        --log("[DebugPickupExchange] UI_PickupExchangeItem 没有其他类型的材料可以替换")
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("NO_OTHER_MATERIAL_TO_EXCHANGE"))
        return false
    end

    local tbOpenArgs = {}
    tbOpenArgs.nItemInstanceId = nItemInstanceId
    tbOpenArgs.nItemTemplateId = nItemTemplateId
    tbOpenArgs.nCount = nCount
    local szWndName = UIDef.UI_PICKUP_EXCHANGE_ITEM
    if UIManager:IsWndOpen(szWndName) then
        --log("[DebugPickupExchange] UI_PickupExchangeItem 已处于打开状态，直接刷新数据")
        local tbWnd = UIManager:GetWnd(szWndName)
        tbWnd:RefreshData(tbOpenArgs)
    else
        --log("[DebugPickupExchange] 打开UI_PickupExchangeItem")
        UIManager:OpenWnd(szWndName, tbOpenArgs)
    end
    return true
end

local function CLosePickupExchange()
    local szWndName = UIDef.UI_PICKUP_EXCHANGE_ITEM
    if UIManager:IsWndOpen(szWndName) then
        UIManager:CloseWnd(szWndName)
    end
end

local function Pickup(self, nItemInstanceId, nCount)
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if HumanWeaponComponent then
        local nCurrentState = HumanWeaponComponent:GetCurrentState()
        if nCurrentState == HumanWeaponStateDef.ATTACKING then
            return false
        else
            --赋值必须放在CancelReload的前面，因为CancelReload里会判当前是否在拾取中
            self:SetPickingUp(nItemInstanceId)
            if nCurrentState == HumanWeaponStateDef.RELOADING then
                HumanWeaponComponent:CancelReload()
                HumanWeaponHelper.SendCancelReloadRequest(HumanWeaponComponent:GetCurrentWeaponInstanceId())
            end
        end
    else
        if self.tbPickupTimeHandle then
            DelayTimer:ClearTimer(self.tbPickupTimeHandle)
            self.tbPickupTimeHandle = nil
        end
        self.tbPickupTimeHandle = DelayTimer:DelayRun(function()
            log("BattlePickupSystem:Pickup time out")
            self.tbPickupTimeHandle = nil
            ClearPickupState(self)
        end, PICKUP_TIME_OUT)
        self:SetPickingUp(nItemInstanceId)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_BEGIN_PICKUP)
    BattleItemSystemClient:RequestPickUpSceneItem(nItemInstanceId, nCount)
    CLosePickupExchange()
    return true
end

---------------------------------------------------------------------
--手动拾取,判断手动拾取间隔
function BattlePickupSystem:ManualPickupItem(nItemInstanceId, nItemTemplateId, nCount)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    if self.tbManualPickUpRecords == nil then
        self.tbManualPickUpRecords = {}
    end
    local nLastTime = self.tbManualPickUpRecords[nItemInstanceId]
    --logdebug("BattlePickupSystem:ManualPickupItem", nItemInstanceId, now, nLastTime)
    if nLastTime == nil or nLastTime + MANUAL_PICK_DELAY_REQUEST < now then
        self:RequestPickupItem(nItemInstanceId, nItemTemplateId, nCount)
        self.tbManualPickUpRecords[nItemInstanceId] = now
    end
end

---------------------------------------------------------------------
--请求拾取
function BattlePickupSystem:RequestPickupItem(nItemInstanceId, nItemTemplateId, nCount)
    --logdebug("BattlePickupSystem:RequestPickupItem", nItemInstanceId)
    local bResult = false
    if nItemInstanceId == nil then
        return bResult
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if PlayerSelf:IsDying() or (HumanMovementStateComponent and (HumanMovementStateComponent:IsInVehicle() or HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall)) then
        return bResult
    end
    if nItemInstanceId == self.nPickupItemInstanceId then
        log("pick up same item.Ignore.")
        return bResult
    end
    if nItemTemplateId == nil then
        error("pick up param error! nItemTemplateId is nil")
    end
    if nCount == nil then
        error("pick up param error! nCount is nil")
    end
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate == nil then
        error("pick up param error! tbItemTemplate is nil"..nItemTemplateId)
    end

    nItemTemplateId, nCount = GetTemplateAndCountAfterConvert(tbItemTemplate, nCount)
    local tbConvertTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbConvertTemplate.nCategory

    if nCategory == BattleItemCategoryDef.MATERIAL then
        if BattleItemSystemHelper:CanAddToInventoryRoom(PlayerSelf:GetServerInstanceId(), nItemTemplateId, true) then
            --log("[DebugPickupExchange] 当前材料未满，直接拾取", nItemTemplateId)
            bResult = Pickup(self, nItemInstanceId, nCount)
        else
            --log("[DebugPickupExchange] 当前材料已满，尝试打开UI_PickupExchangeItem进行替换", nItemTemplateId)
            bResult = TryOpenPickupExchange(nItemInstanceId, nItemTemplateId, nCount)
        end
    else
        --log("[DebugPickupExchange] 不是材料，直接拾取", nItemTemplateId, nCategory, t2s(tbItemTemplate))
        bResult = Pickup(self, nItemInstanceId, nCount)
    end
    return bResult
end

function BattlePickupSystem:FinishPickupItem(nResult, nInstanceId, nItemTemplateId)
    --logdebug("BattlePickupSystem:FinishPickupItem,nResult=",nResult,nInstanceId,self.nPickupItemInstanceId)
    if nInstanceId == self.nPickupItemInstanceId then
        ClearPickupState(self)
    end
    if nResult ~= ProtoDC.ItemReturnCode.OK then
        return
    end
    PlayPickUpSound(nItemTemplateId)
    PlayPickAnim(self, nInstanceId, nItemTemplateId)
    --拾取完成后重新刷新自动拾取状态
    local tbItemServerData = GetServerDataByPickType(self, BattlePickTypeDef.ITEM)
    local tbBoxServerData = GetAllBoxServerData(self)
    for k, v in ipairs(tbItemServerData) do
        SetCanAutoPickup(v)
    end
    for k, v in ipairs(tbBoxServerData)do
        if v.items then
            for k1, v1 in ipairs(v.items) do
                SetCanAutoPickup(v1)
            end
        end
    end
    --
    if self.tbManualPickUpRecords ~= nil then
        self.tbManualPickUpRecords[nInstanceId] = nil
    end
end

--请求查看拾取列表
function BattlePickupSystem:RequestViewBegin(nPickType, bNotUseDelay)
    log("BattlePickupSystem:RequestViewBegin,nItemType=",nPickType)
    local tbRequestInfo = self.tbRequestInfo
    if tbRequestInfo.nCurrentRequestPickType == nPickType then
        return
    end
    if tbRequestInfo.tbDelayHandle then
        DelayTimer:ClearTimer(tbRequestInfo.tbDelayHandle)
        tbRequestInfo.tbDelayHandle = nil
    end
    tbRequestInfo.nCurrentRequestPickType = nPickType
    local function DelayRequestView()
        local bAll = tbRequestInfo.nCurrentRequestPickType == BattlePickTypeDef.BOX or tbRequestInfo.nCurrentRequestPickType == BattlePickTypeDef.TREASURE_CHEST or false
        local tbRequestId = GetRequestIdByPickType(self, tbRequestInfo.nCurrentRequestPickType, bAll)
        if tbRequestId and #tbRequestId > 0 then
            BattleItemSystemClient:RequestBeginViewSceneItems(tbRequestId)
        end
        tbRequestInfo.tbDelayHandle = nil
        tbRequestInfo.nCurrentRequestPickType = nil
    end
    if not bNotUseDelay then
        tbRequestInfo.tbDelayHandle = DelayTimer:DelayRun(DelayRequestView, REQUEST_VIEW_DELAY)
    else
        DelayRequestView()
    end
end

--结束查看拾取列表
function BattlePickupSystem:RequestViewEnd()
    -- local tbRequestInfo = self.tbRequestInfo
    -- if tbRequestInfo and tbRequestInfo.tbDelayHandle then
    --     DelayTimer:ClearTimer(tbRequestInfo.tbDelayHandle)
    --     tbRequestInfo.tbDelayHandle = nil
    -- end
    BattleItemSystemClient:RequestEndViewSceneItems()
    self.tbManualPickUpRecords = {}
end

function BattlePickupSystem:ResetRequestIds()
    self.tbRequestItemData = {}
    self.tbRequestInfo = {}
end

function BattlePickupSystem:GetRequestIdsByPickType(nPickType)
    --logdebug("BattlePickupSystem:GetRequestIdsByPickType,nPickType=",nPickType)
    return GetRequestIdByPickType(self, nPickType)
end

function BattlePickupSystem:GetViewDataByPickType(nPickType)
    --log("BattlePickupSystem:GetServerDataByPickType start")
    local tbViewData = GetServerDataByPickType(self, nPickType)
    -- if nPickType == BattlePickTypeDef.ITEM then
    --     --log("BattlePickupSystem:SortData start")
    --     SortData(tbViewData)
    --     --log("BattlePickupSystem:SortData end")
    -- else
    --     for k, v in pairs(tbViewData) do
    --         if v.items then
    --             SortData(v.items)
    --         else
    --             logerror("v.items is nil, instance_id=", v.instance_id)
    --         end
    --     end
    -- end
    return tbViewData
end

function BattlePickupSystem:GetAllBoxRequestIds()
    return GetAllBoxRequestId(self)
end

function BattlePickupSystem:GetAllBoxViewData()
    local tbViewData = GetAllBoxServerData(self)
    for k, v in pairs(tbViewData) do
        if v.items then
            SortData(v.items)
        else
            logerror("v.items is nil, instance_id=", v.instance_id)
        end
    end
    return tbViewData
end

function BattlePickupSystem:SetPickingUp(nItemInstanceId)
    self.nPickupItemInstanceId = nItemInstanceId
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or PlayerSelf:IsShip() then
        return
    end    
    PlayerSelf.pUEActor.bIsPickingUp = self:IsPickingUp()
end
function BattlePickupSystem:IsPickingUp()
    return self.nPickupItemInstanceId ~= nil
end

function BattlePickupSystem:SetItemAutoOpen(bAutoOpen)
    self.bItemAutoOpen = bAutoOpen
end

function BattlePickupSystem:IsItemAutoOpen()
    return self.bItemAutoOpen
end

function BattlePickupSystem:SetBoxAutoOpen(bAutoOpen)
    self.bBoxAutoOpen = bAutoOpen
end

function BattlePickupSystem:IsBoxAutoOpen()
    return self.bBoxAutoOpen
end

return BattlePickupSystem