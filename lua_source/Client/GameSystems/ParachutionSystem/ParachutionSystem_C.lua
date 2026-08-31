local luaclass = require("luaclass")
local ParachutionSystem = require("ParachutionSystem")
local ParachutionSystem_C = luaclass("ParachutionSystem_C", ParachutionSystem)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local SelfAnimationHelper = require("SelfAnimationHelper")
local DelayTimer = require("DelayTimer")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local EventManager = require("EventManager")
local ProtoDR = require("DungeonRepProtoNames")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local HumanMovementStateType = require("HumanMovementStateType")
-- local ControlModeDef = require("ControlModeDef")
local UEClientActorHelper = require("UEClientActorHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
-- local ReconnectIni= require("ReconnectIni")
local TransporterDataTable = require("TransporterDataTable")
local BattleInteractionSystem = dynamic_require("BattleInteractionSystem")
local CommonEventDef = require("CommonEventDef")
-- local SoundManager = require("SoundManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ParachutingNewIni = require("ParachutingNewIni")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local ResourceManager = require("ResourceManager")
local MatineeDataTable = require("MatineeDataTable")
local GameplayUtilityHelper = require("GameplayUtilityHelper")

ParachutionSystem_C.bChangeToShip = nil
ParachutionSystem_C.tbSelectionPointes = nil
ParachutionSystem_C.tbTransporterInfos = nil
ParachutionSystem_C.tbSelectedPoint = nil
ParachutionSystem_C.bCanSelectPoint = true
ParachutionSystem_C.nCountDownTime = nil
ParachutionSystem_C.tbDelayCountDownHandle = nil
ParachutionSystem_C.nState = nil
-- ParachutionSystem_C.tbPreLoadPacketName = nil
ParachutionSystem_C.nVisiblityFactor = nil
ParachutionSystem_C.tbVerifyStateTimer = nil
ParachutionSystem_C.tbDisconnectData = nil
ParachutionSystem_C.nReconnectLaunchTime = nil
ParachutionSystem_C.tbAsyncMatineeHandler = nil
ParachutionSystem_C.bSetCameraInPlane = nil

-- local REBORN_ANIMATION_ID = 7000
local REBORN_ANIMATION_KEY = "Change"
-- local DRAW_DISTANCE_TEXT = "pir.CharacterDrawDis 30000"
-- local DRAW_DISTANCE = 30000

local VisibleTypes = {
    [GameObjectTypeDef.PlayerSelf] = true,
	[GameObjectTypeDef.PlayerOther] = true
}

local function ClearVerifyStateTimer(self)
    if self.tbVerifyStateTimer ~= nil then
        DelayTimer:ClearTimer(self.tbVerifyStateTimer)
        self.tbVerifyStateTimer = nil
    end
end

local function ProcessAbnormalState(self)
    ClearVerifyStateTimer(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = tbPlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent ~= nil then
        local nState = HumanMovementStateComponent:GetCurrentState()
        -- 客户端特别卡,服务器强制结束玩家跳伞
        if nState ~= HumanMovementStateType.Parachutine_State and nState ~= HumanMovementStateType.Gliding_State and HumanMovementStateComponent:IsInParachuting() then
            logwarning("ParachutionSystem_C:OnParachutionEnd but human move state is ", nState)
            -- 服务器已经由跳伞切换到正常状态， 客户端还在跳伞阶段的某个状态，这时只需要改客户端自己的状态就可以了，
            -- 不需要向服务器发包改状态，因为向服务器发状态改变需要先改成Parachutine_State，再改成正常状态，这两个包之间可能断线，
            -- 导致服务器只收到一个包，这样服务器本来已经跳伞结束，但是状态确由正常状态变为跳伞状态。
            -- HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.Parachutine_State, true)
            if not ParachutingNewIni.tbParachuteOpen.bHad then
                HumanMovementStateComponent.StateHelper:ChangeState(HumanMovementStateType.Parachutine_State)
            else
                 HumanMovementStateComponent.StateHelper:ChangeState(HumanMovementStateType.Gliding_State)
            end
            EventManager:OnFireEvent(ClientEventDef.EV_FORCE_GROUND_HUMAN_VIEW)

            local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
            local pLocation = tbPlayerSelf:GetLocation()
            local nRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)
            local CharacterMovement = tbPlayerSelf.pUEActor and tbPlayerSelf.pUEActor.CharacterMovement
            if nRegionType == EPiratesGridRegionType.Port and CharacterMovement.SwimLocationZ >= pLocation.Z then
                log("ParachutionSystem_C:OnParachutionEnd force swimming", pLocation.Z, CharacterMovement.SwimLocationZ)
                HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.Swimming, true)
            else            
                -- HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State, true)
                HumanMovementStateComponent.StateHelper:ChangeState(HumanMovementStateType.UpRight_State)
            end
        end
        -- 强制清除跳伞特效（因为出现过，服务器bp_parachting已经删除，但是客户端确没有删除的情况）
        if  isvalidhandle(tbPlayerSelf.pUEActor) and isvalidhandle(tbPlayerSelf.pUEActor.BPParachutingNew) then
            log("ParachutionSystem_C:OnParachutionEnd and clear parachution effect")
            tbPlayerSelf.pUEActor.BPParachutingNew:OnSelfEndPlayProcess()
        end 
    end    
end

local function ShipBorn(self)
    if self.bChangeToShip then
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf:IsHuman() then
            -- logerror("on parachution end and change to ship, but still is human", debug.traceback(  ))
            return
        end
        if tbPlayerSelf.pUEActor == nil then
            logerror("on parachution end and change to ship, but pUEActor is nil")
            return
        end

        SelfAnimationHelper:PlayShipAnimation(tbPlayerSelf, nil, REBORN_ANIMATION_KEY)
        self.bChangeToShip = false
    end
end

function ParachutionSystem_C:OnParachutionEnd(bIsShip)
    log("parachutionend ParachutionSystem_C 1:")

    self.bChangeToShip = bIsShip

    if not self.bChangeToShip then
        log("parachutionend system 1:")
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf:IsHuman() and tbPlayerSelf.pUEActor then
            local pRotation = tbPlayerSelf:GetRotation()
            if pRotation.Pitch ~= 0 then
                tbPlayerSelf:SetRotation(0, pRotation.Yaw, pRotation.Roll)
            end
            EventManager:OnFireEvent(ClientEventDef.EV_FORCE_GROUND_HUMAN_VIEW)
            
            log("parachutionend system 2:")
            local fnVerifyMovementState = function()
                ProcessAbnormalState(self)
            end
            self.tbVerifyStateTimer = DelayTimer:RunNextTick(fnVerifyMovementState)
            log("parachutionend system 3:")
        end
    else
        ShipBorn(self)        
    end
    -- 恢复副本超时时间
    -- ClientShell.GetClient(GWorld):SetClientConnectionTimeout(0)

    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_PARACHUTION_END, bIsShip)
    log("parachutionend ParachutionSystem_C 2:")
end

local function ClearTimer(self)
    if self.tbTimeHandler ~= nil then
        DelayTimer:ClearTimer(self.tbTimeHandler)
        self.tbTimeHandler = nil
    end
    if self.tbDelayCountDownHandle then
        DelayTimer:ClearTimer(self.tbDelayCountDownHandle)
        self.tbDelayCountDownHandle = nil
    end    
end

local function OnPlayerSelfReady(self)
    log("On Player Self Ready.")
    if self.bChangeToShip == nil and 
        self.nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf:IsShip() then
            -- 已经到跳伞阶段，并且没有收到D2C_ParachutingEnd,但是变船了，播放出生动画
            self.bChangeToShip = true
        end
    end
    ShipBorn(self)
end

local function PreLoadSubLevel(self)
    if self.bCanSelectPoint or self.tbSelectedPoint == nil or self.tbTransporterInfos == nil then
        return
    end
    
    log("PreLoadSubLevel")
    local tbInfos = self.tbTransporterInfos
    for _, v in ipairs(tbInfos) do
        if v.nTransporterId == self.tbSelectedPoint.nTransporterId then
            ExtendBlueprintFunctions.PreLoadLevelStreamingPackageForPoint(GWorld, Vector{X=v.Node[1].nX, Y=v.Node[1].nY, Z = 0})
            break
        end
    end

end

local function SetSelfTransport(self)
    local tbInfos = self.tbTransporterInfos
    if tbInfos == nil then
        log("SetSelfTransport error, transporterInfo is nil")
        return
    end
    -- log("select point Set selftransport11")
    local nMinDistance, nTransporterId, nDistance = -1, 0, 0
    local nX, nY = self.tbSelectedPoint.nX, self.tbSelectedPoint.nY
    for _, v in ipairs(tbInfos) do
        nDistance = math.sqrt((nX - v.Node[1].nX)^2 + (nY - v.Node[1].nY)^2)
        if nMinDistance < 0 or nMinDistance > nDistance then
            nMinDistance = nDistance
            nTransporterId = v.nTransporterId
        end
    end
    self.tbSelectedPoint.nTransporterId = nTransporterId
    -- log("select point Set selftransport22")
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_POINT_TRANSPORTER, nTransporterId, nX, nY)
end

function ParachutionSystem_C:OnFFASelectPoint(tbPacket)
    local fnUpdateSelectPoint = function(tbData)
        local bHad = false
        for _, value in ipairs(self.tbSelectionPointes) do
            if value.nInstanceId == tbData.nInstanceId then
                value.nX = tbData.nX
                value.nY = tbData.nY
                bHad = true
                break
            end
        end
        if not bHad then
            table.insert(self.tbSelectionPointes, tbData)
        end
    end
    log("select point parachutingsystem 1")
    local nSelfId = GamePlayerSelfHelper:GetServerInstanceId()
    log("recv select point", nSelfId)
    for i, v in ipairs(tbPacket.PointInfos) do
        if v.nInstanceId == nSelfId then 
            log("select point parachutingsystem 3")
            self.tbSelectedPoint = v
            SetSelfTransport(self)
            log("select point parachutingsystem 4")
            -- PreLoadSubLevel(self)
        end
        fnUpdateSelectPoint(v)
    end

    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_SELECT_POINT, tbPacket)
    log("select point parachutingsystem 2")
end

function ParachutionSystem_C:OnFFACancelSelectPoint(nInstanceId)
    for index, value in ipairs(self.tbSelectionPointes) do
        if value.nInstanceId == nInstanceId then
            table.remove(self.tbSelectionPointes, index)

            self.EventHelper:FireEvent(ClientEventDef.EV_FFA_SELECT_POINT_CANCEL, self.tbSelectionPointes, nInstanceId)
            break
        end
    end
end

local function OnFFASelectPointes(self, tbPacket)
    self.tbSelectionPointes = tbPacket.PointInfos

    local nSelfId = GamePlayerSelfHelper:GetServerInstanceId()
    for i, v in ipairs(self.tbSelectionPointes) do
        if v.nInstanceId == nSelfId then 
            self.tbSelectedPoint = v
            SetSelfTransport(self)
            PreLoadSubLevel(self)
        end
    end
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_POINTES_UPDATE)
end

local function HidePlayerSelf(self)
    -- 为解决偶现movemementcomponent已经是跳伞状态了，但是matinee才播完的情况，然后隐藏玩家导致，玩家再也显示不出来的问题
    -- 因此需要添加如果玩家在船上才隐藏玩家的判断
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent ~= nil then
        local nCurState = HumanMovementStateComponent:GetCurrentState()
        if nCurState == HumanMovementStateType.InPlane_State then
            log("ParachutionSystem_C: hide player self")
            UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, VisibleTypes, false)
        else
            log("ParachutionSystem_C: hide player self failed ", nCurState)
        end
    else
        logwarning("ParachutionSystem_C: hide player self, but no movementcomponent")
    end
end

local function ShowPlayerSelf(self)
    log("ParachutionSystem_C: show player self")
    UEClientActorHelper:SetAllObjectVisibilityFactor(self.nVisiblityFactor, VisibleTypes, true)
    EventManager:OnFireEvent(ClientEventDef.EV_PARACHUTE_SHOW_PLAYER)
end

local function HoldMatinee(self)
    local nTransporterId = self.tbSelectedPoint and self.tbSelectedPoint.nTransporterId
    local tbTransporterData = nTransporterId and TransporterDataTable:GetTemplate(nTransporterId)
    local nMatineeId = tbTransporterData and tbTransporterData.nMatineeId
    if nMatineeId == nil then
        return
    end
    local tbMatineeData = MatineeDataTable:GetTemplate(nMatineeId)
    if tbMatineeData == nil then
        return
    end
    local fnOnComplete = function(szAssetName, pObject, nHandle)
        self.pMatineeObject = pObject
        ResourceManager:Hold(pObject)
    end
    self.tbAsyncMatineeHandler = ResourceManager:LoadAsync(tbMatineeData.szMaleRes, fnOnComplete)
end

local function UnholdMatinee(self)
    if self.tbAsyncMatineeHandler ~= nil then
        ResourceManager:CancelLoadAsync(self.tbAsyncMatineeHandler)    
        self.tbAsyncMatineeHandler = nil
    end
    if self.pMatineeObject ~= nil then
        ResourceManager:Unhold(self.pMatineeObject)
        self.pMatineeObject = nil
    end
end

local function PlayMatinee(self)
    local nTransporterId = self.tbSelectedPoint and self.tbSelectedPoint.nTransporterId or 1
    local tbTransporterData = TransporterDataTable:GetTemplate(nTransporterId)
    local fnOnComplete = function()
        self.tbTimeHandler = DelayTimer:RunNextTick(function()
            ClearTimer(self)
            HidePlayerSelf(self)
        end)
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_TRANSPORTER_MATINEE_COMPLETE)
        UnholdMatinee(self)
    end
    BattleInteractionSystem:OnPlayMatinee(tbTransporterData.nMatineeId, nil, fnOnComplete, false, false)       
end

local function VerifyLineShipMove(self, szKey)
    log("VerifyLineShipMove", szKey)
    if self.tbDisconnectData == nil then
        self.tbDisconnectData = {
            bReconnected = false,
            bInPlane = false,
            bHasTransporterInfo = false, 
            -- bHasTransporterActor = false
        }
    end
    self.tbDisconnectData[szKey] = true

    local bStartMove = true
    for k, v in pairs(self.tbDisconnectData) do
        if not v then
            bStartMove = false
            break
        end
    end

    if not bStartMove then
        return
    end

    local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Dummy)
    for v, _ in pairs(tbAllObjs) do
        if v.pUEActor ~= nil and v.pUEActor.TransporterId ~= nil then
            log("VerifyLineShipMove reconnect transporter move")
            v.pUEActor:OnStartMove()
        end
    end
end

-- local function SetDrawDistance()
--     RenderExtendBlueprintFunctions.ExecuteCommand(DRAW_DISTANCE_TEXT)
--     ExtendBlueprintFunctions.ResetCharacterSkeletalDrawDistance(GWorld)
-- end

function ParachutionSystem_C:GetAttachedLineShip()
    local nTransporterId = self.tbSelectedPoint and self.tbSelectedPoint.nTransporterId or 1
    local tbPlayer = GamePlayerSelfHelper:Get()
    local pParentActor = tbPlayer.pUEActor:GetAttachParentActor()
    if isvalidhandle(pParentActor) then
        return pParentActor, nTransporterId
    end

    local tbAllObjs = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.Dummy)
    for v, _ in pairs(tbAllObjs) do
        local pUEActor = v.pUEActor
        if isvalidhandle(pUEActor) 
            and pUEActor.TransporterId ~= nil and pUEActor.TransporterId == nTransporterId then 
            return pUEActor, nTransporterId
        end
    end
end

local function ChangeCameraInPlane(self)
    if self.bSetCameraInPlane then
        return
    end
    local tbPlayer = GamePlayerSelfHelper:Get()
    if isvalidhandle(tbPlayer.pUEActor) then
        local tbHumanMovementStateComponent = tbPlayer.HumanMovementStateComponent 
        if tbHumanMovementStateComponent ~= nil and tbHumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.InPlane_State then
            local pAttachActor, nTransporterId = self:GetAttachedLineShip()
            log("rFFAProcessState_EState.PARACHUTING set camera", nTransporterId, pAttachActor)
            if isvalidhandle(pAttachActor) then
                self.bSetCameraInPlane = true
                EventManager:OnFireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.NewParachuteShipping, {pTarget = pAttachActor, nTransporterId = nTransporterId})
            end                
        end
    end
end

local function OnFFAProcessStateChanged(self, nState, bBattle, nTime)
    log("OnFFAProcessStateChanged ", nState)
    if nState == ProtoDR.rFFAProcessState_EState.SELECTION then
        if self.tbSelectedPoint == nil then
            self.nState = nState
            if self.tbTransporterInfos ~= nil then
                UIManager:OpenWnd(UIDef.UI_FFA_SELECT_BORNPOINT, {bPlayAni = false})
            end
        end
    elseif nState == ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        self.bCanSelectPoint = false
        PreLoadSubLevel(self)
        if self.nCountDownTime and self.nCountDownTime - 0.5 > 0 then
            self.tbDelayCountDownHandle = DelayTimer:DelayRun(function()
                -- UIManager:DestroyWnd(UIDef.UI_FIVECOUNTDOWN)
                self.tbDelayCountDownHandle = nil
            end, self.nCountDownTime - 0.5)
            HoldMatinee(self)
            UIManager:OpenWnd(UIDef.UI_FIVECOUNTDOWN, {nTime = self.nCountDownTime, szText = ""})
        end              
        if self.nState == nil then
            -- 系统自动选点后才进入游戏
            EventManager:OnFireEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, ProtoDR.rFFAProcessState_EState.COUNTDOWN)
            EventManager:OnFireEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, ProtoDR.rFFAProcessState_EState.SELECTION)            
        end
    elseif nState == ProtoDR.rFFAProcessState_EState.MATINEE then
        -- 开始播放matinee时，玩家所在的地图可能会被卸载，所以停止movmentcomponent，
        -- 在下航线船后会开启movmentcomponent
        --[[
        local tbPlayer = GamePlayerSelfHelper:Get()
        if tbPlayer:IsHuman() and isvalidhandle(tbPlayer.pUEActor) then
            tbPlayer.pUEActor.CharacterMovement:SetActive(false)
        end
        ]]

        GameplayUtilityHelper.DestoryThrowWeaponEffectComponent(GWorld,GWorld)
        PlayMatinee(self)
    elseif nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        ChangeCameraInPlane(self)

        if self.nState == nil then
            if bBattle ~= nil and bBattle == false then
                VerifyLineShipMove(self, "bReconnected")
                self.nReconnectLaunchTime = nTime
            end
        end

         -- 应景昭需要把BP_OnLanding中的一部分内容移到开船时处理
        -- SetDrawDistance()
    end

    if nState >= ProtoDR.rFFAProcessState_EState.MATINEE or nState <= ProtoDR.rFFAProcessState_EState.COUNTDOWN then
        UIManager:CloseWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    end
    self.nState = nState
end

local function OnEnterDungeonInBattle(self)
    -- SetDrawDistance()
end

local function OnFFATransportInfo(self, tbPacket)
    log("[lineship] OnFFATransportInfo", #tbPacket.Infos)
    self.tbTransporterInfos = tbPacket.Infos
    if self.tbSelectedPoint == nil and (self.nState ~= nil and self.nState == ProtoDR.rFFAProcessState_EState.SELECTION)then
        UIManager:OpenWnd(UIDef.UI_FFA_SELECT_BORNPOINT, {bPlayAni = false})
    else
        UIManager:CloseWnd(UIDef.UI_FFA_SELECT_BORNPOINT)
    end
    VerifyLineShipMove(self, "bHasTransporterInfo")
end

local function OnRecvRepairStepRemainTime(self, rStepRemainTime)
    self.nCountDownTime = rStepRemainTime.nTime
end

local function OnGameObjectActorCreate(self, tbGameObject)
    if tbGameObject:GetObjectType() ~= GameObjectTypeDef.Dummy then
        return
    end
    local pUEActor = tbGameObject.pUEActor
    if not isvalidhandle(pUEActor) then
        return
    end
    local nTransporterId = pUEActor.TransporterId
    if nTransporterId == nil then
        return
    end
    if self.tbTransporterInfos == nil then
        log("[lineship] OnGameObjectActorCreate transporterInfo is nil")
        return
    end
    -- 客户端航线船添加路点
    log("[lineship] rep transporter object ", tbGameObject.szName)
    local tbInfos = self.tbTransporterInfos
    for _, v in ipairs(tbInfos) do
        if v.nTransporterId == nTransporterId then
            for i, Node in ipairs(v.Node) do
                if i > 1 then
                    pUEActor:AddPathNode(Node.nX, Node.nY)
                end
            end
            break
        end
    end
end

function ParachutionSystem_C:OnHumanMovmentStateChanged(tbCharacter, nOldState, nNewState)
    ParachutionSystem_C.super.OnHumanMovmentStateChanged(self, tbCharacter, nOldState, nNewState)
    if not tbCharacter or tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end    
    log("ParachutionSystem_C:OnHumanMovmentStateChanged", nOldState, nNewState)
    if nNewState == HumanMovementStateType.InPlane_State then
        HidePlayerSelf(self)
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        if tbPlayerSelf and tbPlayerSelf.pUEActor then
            log("movement is inplane ", tbPlayerSelf.pUEActor:GetAttachParentActor())
        end
        VerifyLineShipMove(self, "bInPlane")
        ChangeCameraInPlane(self)
    -- elseif nNewState == HumanMovementStateType.Falling_State then
        -- ShowPlayerSelf(self)
        -- -- 设置跳伞时，副本超时时间
        -- ClientShell.GetClient(GWorld):SetClientConnectionTimeout(ReconnectIni.nDungeonParachutingStepTimeout)        
    end

    if nOldState == HumanMovementStateType.InPlane_State then
        ShowPlayerSelf(self)
    end
end

function ParachutionSystem_C:Init()
    if not ParachutionSystem_C.super.Init(self) then
        return false
    end

    self.bChangeToShip = nil
    self.tbSelectionPointes = {}
    self.nVisiblityFactor = UEClientActorHelper:AllocateObjectVisiblityFactor()
    GlobalVariableSystem:SetParachutingNewLaunchTime(ParachutingNewIni.tbNewTarget.IsSameTimeLaunch)

    local EventHelper = self.EventHelper
    -- EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, self.OnParachutionEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_BINDREPLICATE_UEACTOR, self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINTES, self, OnFFASelectPointes)
    -- EventHelper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINT, self, OnFFASelectPoint)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_INFO_NEW, self, OnFFATransportInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvRepairStepRemainTime) 
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnGameObjectActorCreate) 
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ENTER_DUNGEON_IN_BATTLE, self, OnEnterDungeonInBattle) 
    return true

end

function ParachutionSystem_C:Uninit()
    UnholdMatinee(self)
    ClearTimer(self)
    ClearVerifyStateTimer(self)
    self.tbDisconnectData = nil
    self.nReconnectLaunchTime = nil
    self.tbSelectedPoint = nil
    self.tbSelectionPointes = nil
    self.nState = nil
    self.tbTransporterInfos = nil
    self.nVisiblityFactor = nil
    self.bSetCameraInPlane = nil

    ParachutionSystem_C.super.Uninit(self)
end

function ParachutionSystem_C:GetSelectionPointes()
    return self.tbSelectionPointes
end

function ParachutionSystem_C:GetSelectedPoint()
    return self.tbSelectedPoint
end

function ParachutionSystem_C:GetTransporterInfos()
    return self.tbTransporterInfos
end

function ParachutionSystem_C:GetCountDownTime()
    return self.nCountDownTime
end

function ParachutionSystem_C:GetState()
    return self.nState
end

function ParachutionSystem_C:GetPreLoadPacketName()
    return self.szPreLoadPacketName
end

function ParachutionSystem_C:IsReconnect()
    return self.tbDisconnectData and self.tbDisconnectData.bReconnected
end

function ParachutionSystem_C:GetTransporterId(nX, nY)
    local tbInfos = self.tbTransporterInfos
    if tbInfos == nil then
        log("GetTransporterId error, transporterInfo is nil")
        return
    end
    -- log("select point Set selftransport11")
    local nMinDistance, nTransporterId, nDistance = -1, 0, 0
    for _, v in ipairs(tbInfos) do
        nDistance = math.sqrt((nX - v.Node[1].nX)^2 + (nY - v.Node[1].nY)^2)
        if nMinDistance < 0 or nMinDistance > nDistance then
            nMinDistance = nDistance
            nTransporterId = v.nTransporterId
        end
    end

    return nTransporterId
end

-- function ParachutionSystem_C:IsShowOtherPoint()
--     return not self.bHideOtherPoint
-- end

return ParachutionSystem_C()