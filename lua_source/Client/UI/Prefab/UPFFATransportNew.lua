-----------------------------------------------------
--File Name    : UPFFATransport.lua
--Description  : ffa 飞行ui
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPFFABase = require("UPFFABase")
local UPFFATransportNew = luaclass("UPFFATransportNew", UPFFABase)
local ParachutingNewIni = require("ParachutingNewIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local ParachutionSystem_C = require("ParachutionSystem_C")
local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanMovementStateType = require("HumanMovementStateType")
local ClientEventDef = require("ClientEventDef")
local TransporterDataTable = require("TransporterDataTable")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local DungeonDataTable = require("DungeonDataTable")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local UIMapResDataTable = require("UIMapResDataTable")
local UISetUtils = require("UISetUtils")
local SoundManager = require("SoundManager")
local UIResourceDef = require("UIResourceDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local NetworkManager = dynamic_require("NetworkManager")
local DCProto = require("DungeonCommonProtoNames")
local DelayTimer = require("DelayTimer")

local TIMER_TICK = 0.3
local TXT_TOTAL_HEIGHT = 380
local VELOCITY_REFRESH_INTERVAL = 0.3
local FFA_MODE_TRANSPORT_MAX = 6
local FFA_MODE_TRANSPORT = 5

local l10nSecond = UISetUtils.GetTextByKey("COMMON_TIME_SECOND")
local LINESHIP_SOUND = {
    UIResourceDef.SC_SHIP_OCEAN_ENV,
    UIResourceDef.SC_SHIP_SAILING
}

local PARACHUTING_STEP = {
    PARABOLA = 1,
    NOPARACHUTE = 2,
    PARACHUTE = 3
}

local GLIDING_STATE = {
    NONE = 1,
    CANSET = 2,
    SETTED = 3
}

UPFFATransportNew.nTotalHeight = nil
UPFFATransportNew.nOperateHeight = nil
UPFFATransportNew.nCurHeight = nil

UPFFATransportNew.bFalling = nil
UPFFATransportNew.nGliding = nil
UPFFATransportNew.pGlidingClick = nil
UPFFATransportNew.nParachutingStep = nil
UPFFATransportNew.pTargetSpeedPosition = nil
UPFFATransportNew.nTxtTotalHeight = nil
UPFFATransportNew.nHeightRatio = 1
UPFFATransportNew.ulFreeView = nil
UPFFATransportNew.tbVelocityTimer = nil
UPFFATransportNew.bIsMaxVelocity = nil
UPFFATransportNew.bShowBlack = nil
-- UPFFATransportNew.bCalcLaunchTime = nil
UPFFATransportNew.nLaunchTime = nil
UPFFATransportNew.tbLineShipSound = nil
UPFFATransportNew.tbTimeTick = nil
UPFFATransportNew.tbMidwayTimer = nil

local function InitParachutingHeight(self)
    local tbLaunch = ParachutingNewIni.tbLaunch
    self.nTotalHeight = tbLaunch.nLaunchHeight
    self.nOperateHeight = tbLaunch.nOperateHeight
end

local function GetSelfHeight(self)
    local SelfObj = GamePlayerSelfHelper:Get()
    local pLocation = SelfObj:GetLocation()
    return pLocation.Z
end

local function SetTxtSpeedPosition(self, nTotalHeight, nHeight)
    local nValue = math.max(0, nHeight / self.nTotalHeight)
    local pSlot = self.pWidgetRef.olSpeed.Slot
    local pSpeedPadding = pSlot.Padding
    pSpeedPadding.Top = self.pTargetSpeedPosition.Y - self.nTxtTotalHeight * nValue 
    pSlot:SetPadding(pSpeedPadding)
end

local function VelocityTimer(self, nVelocityZ)
    if self.nParachutingStep == nil then
        return
    end
    local txtSpeed = self.pWidgetRef.txtSpeed
    if self.nParachutingStep == PARACHUTING_STEP.PARABOLA then
        if nVelocityZ ~= nil then
            local nVZ =  math.floor(math.abs(nVelocityZ) / 100)
            local l10nSpeed = L10N:Format(UITextDef.FFA_PARACHUTING_SPEED,nVZ)
            txtSpeed:SetText(l10nSpeed)
            if nVZ == 0 then
                self.pWidgetRef.imgDirection:SetRenderTransformAngle(180)
            end
        end
    else
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        local pVelocity = tbPlayerSelf.pUEActor.CharacterMovement.Velocity
        nVelocityZ = math.abs(pVelocity.Z)

        local l10nSpeed = L10N:Format(UITextDef.FFA_PARACHUTING_SPEED, math.floor(nVelocityZ / 100))

        if math.abs(tbPlayerSelf.pUEActor.CharacterMovement.MaxWalkSpeed - ParachutingNewIni.tbRedarMap.nTranslationSpeed) <= 0.1 then
            if not self.bIsMaxVelocity then
                self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, FFA_MODE_TRANSPORT_MAX)
            end
            self.bIsMaxVelocity = true
        else
            if self.bIsMaxVelocity then
                self.EventHelper:FireEvent(ClientEventDef.EV_FFA_MAP_SCOPE_CHANGE, FFA_MODE_TRANSPORT)
            end
            self.bIsMaxVelocity = false
        end
        txtSpeed:SetText(l10nSpeed)
    end
end

local function DestroyVelocityTimer(self)
    if self.tbVelocityTimer ~= nil then
        self.TimerHelper:ClearTimer(self.tbVelocityTimer) 
        self.tbVelocityTimer = nil 
    end
end

local function OnGliding(self)
    log("[parachuting] UI OnGliding")
    self.nGliding = GLIDING_STATE.SETTED
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnGliding:SetVisibility(ESlateVisibility_Collapsed)
    pWidgetRef.imgWing:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
end

local function TimerTick(self)
    local pWidgetRef = self.pWidgetRef

    local nHeight = GetSelfHeight(self)
    if not self.bFalling and self.nCurHeight and nHeight < self.nCurHeight then
        pWidgetRef.imgDirection:SetRenderTransformAngle(180)
        self.bFalling = true
    end

    if self.bFalling and self.nParachutingStep == PARACHUTING_STEP.PARABOLA and nHeight <= self.nOperateHeight then
        DestroyVelocityTimer(self)
        self.nParachutingStep = PARACHUTING_STEP.NOPARACHUTE
        self.Owner.pbCurrrentVirtualStick.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.sldSpeed:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    elseif ParachutingNewIni.tbParachuteOpen.bHad and self.nParachutingStep == PARACHUTING_STEP.NOPARACHUTE then
        if self.nGliding == GLIDING_STATE.NONE then
            if nHeight <= ParachutingNewIni.tbLaunch.nOpenParachuteMaxHeight then
                self.nGliding = GLIDING_STATE.CANSET
                self.pWidgetRef.btnGliding:SetVisibility(ESlateVisibility_Visible)
            end
        end
        if self.nGliding ~= GLIDING_STATE.SETTED then
            if nHeight <= ParachutingNewIni.tbLaunch.nOpenParachuteMinHeight then
                OnGliding(self)
            end
        end
    end

    -- 因为开伞时的状态是客户端自己的数据，不是rep数据，所以可能真正的rep数据时，高度会比现在客户端的高度高，所以伪造一下高度
    if self.nParachutingStep > PARACHUTING_STEP.PARABOLA and nHeight > self.nCurHeight then
        self.nCurHeight = self.nCurHeight - 100
    else
        self.nCurHeight = nHeight
    end
    
    local nValue = math.max(0, self.nCurHeight / self.nTotalHeight)
    if nValue ~= self.nHeightRatio then
        self.nHeightRatio = nValue
        SetTxtSpeedPosition(self, self.nTotalHeight, self.nCurHeight)
    end
    if self.nParachutingStep > PARACHUTING_STEP.PARABOLA then
        VelocityTimer(self)
    end
end

local function InitParachuting(self)
    InitParachutingHeight(self)

    local pWidgetRef = self.pWidgetRef
    local pSpeedPadding = pWidgetRef.olSpeed.Slot.Padding
    self.pTargetSpeedPosition = Vector2D{X = pSpeedPadding.Left, Y = pSpeedPadding.Top}
    self.nTxtTotalHeight = TXT_TOTAL_HEIGHT
    pWidgetRef.pgbHeight:SetPercent(self.nOperateHeight / self.nTotalHeight)
    pWidgetRef.imgDirection:SetRenderTransformAngle(0)
    self.bFalling = false
    if self.nParachutingStep == nil then
        self.nParachutingStep = PARACHUTING_STEP.PARABOLA        
    end
    self.tbTimeTick = self.TimerHelper:NewTimerMethod(self, TimerTick, TIMER_TICK, true)   
    pWidgetRef.ovlLandingHeight:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.hbTimer:SetVisibility(ESlateVisibility.Collapsed)
end

local function CalcLaunchTime(self)
    if ParachutionSystem_C:IsReconnect() then
        log("ParachutionSystem_C:IsReconnect", ParachutionSystem_C.nReconnectLaunchTime, GlobalVariableSystem_C:GetServerTimeUtc())
        local nTime = ParachutionSystem_C.nReconnectLaunchTime - GlobalVariableSystem_C:GetServerTimeUtc()
        if nTime > 0 then
            local pWidgetRef = self.pWidgetRef
            pWidgetRef.kmTimer:SetText(nTime..l10nSecond)      
            pWidgetRef.hbTimer:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.nLaunchTime = nTime
        else
            self.nLaunchTime = 0
        end
        return
    end  

    local tbDungeonTemplate = DungeonDataTable:GetTemplate(BattleGameModeSystem.nDungeonId)
    local tbMapResData = UIMapResDataTable:GetTemplate(tbDungeonTemplate.nUIRadarMapId)  
    local tbSelectedPoint = ParachutionSystem_C:GetSelectedPoint()  
    if tbMapResData and tbSelectedPoint then
        local nLaunchTime = 0
        if GlobalVariableSystem_C.bParachutingNewLaunchTime then
            local tbTransporterData = TransporterDataTable:GetTemplate(tbSelectedPoint.nTransporterId)
            nLaunchTime = tbTransporterData and tbTransporterData.nLaunchTime or 20 
            log("launch time: ", nLaunchTime)
        else
            local tbTransport = ParachutingNewIni.tbTransport
            local nMapSize = math.max(math.ceil((tbMapResData.nMapSizeX - tbMapResData.nScope) / 2), 
                math.ceil((tbMapResData.nMapSizeY - tbMapResData.nScope) / 2))
            local nTriggerSpeed = nMapSize / tbTransport.nTriggerTime  
            local nDistance = math.sqrt(tbSelectedPoint.nX ^ 2 + tbSelectedPoint.nY ^ 2) 
            nLaunchTime = math.floor(nDistance / nTriggerSpeed + 0.5)
            log("calc launch time：", nLaunchTime, nTriggerSpeed, nDistance, nMapSize)
        end
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.kmTimer:SetText(nLaunchTime..l10nSecond)      
        pWidgetRef.hbTimer:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.nLaunchTime = nLaunchTime   
    else
        logerror("calc launch time failed, not map data or select point", tbDungeonTemplate.nUIRadarMapId, tbSelectedPoint)
    end
end

local function SetLaunchTime(self)
    local pWidgetRef = self.pWidgetRef
    self.nLaunchTime = self.nLaunchTime - VELOCITY_REFRESH_INTERVAL
    local nLaunchTime = math.max(math.floor(self.nLaunchTime), 0)
    if nLaunchTime >= 0 then
        pWidgetRef.kmTimer:SetText(nLaunchTime..l10nSecond)
    else      
        pWidgetRef.hbTimer:SetVisibility(ESlateVisibility.Collapsed)
    end  
end

local function PlayLineShipSound(self)
    self.tbLineShipSound = {}
    for i, v in ipairs(LINESHIP_SOUND) do
        local tbSound = SoundManager:PlaySoundEffect(v, false)
        if tbSound then
            table.insert(self.tbLineShipSound, tbSound)
        end
    end
end

local function StopLineShipSound(self)
    if self.tbLineShipSound == nil then
        return
    end
    for i, v in ipairs(self.tbLineShipSound) do
        SoundManager:DeleteSound(v)
    end
    self.tbLineShipSound = nil
end

local function OnNewParachutingVelocity(self)
    local SelfObj = GamePlayerSelfHelper:Get()
    if SelfObj ~= nil and SelfObj.pUEActor ~= nil then
        local nVelocityZ = SelfObj.pUEActor:GetParachutingVelocity()
        VelocityTimer(self, nVelocityZ)       

        if not self.nLaunchTime then
            local pUEActor = SelfObj.pUEActor:GetAttachParentActor()
            if pUEActor ~= nil then
                if pUEActor.IsStartMove == true then
                    CalcLaunchTime(self)
                    PlayLineShipSound(self)
                end
            end  
        else
            SetLaunchTime(self)
        end      
    end
end

local function ShowDialog(self, szField)
    local tbInfo = ParachutionSystem_C:GetSelectedPoint()
    if tbInfo then
        local tbTransporterData = TransporterDataTable:GetTemplate(tbInfo.nTransporterId)
        local FieldData = tbTransporterData and tbTransporterData[szField]

        if FieldData == nil then
            return
        end
        if type(FieldData) == "number" then
            if FieldData > 0 then
                self.EventHelper:FireEvent(ClientEventDef.EV_FFA_SHOWDIALOG, FieldData)
            end
        elseif type(FieldData) == "table" then
            local nIndex = math.random(1, #FieldData)
            if FieldData[nIndex] > 0 then
                self.EventHelper:FireEvent(ClientEventDef.EV_FFA_SHOWDIALOG, FieldData[nIndex])
            end
        end
    end    
end

local function ClearMidwayTimer(self)
    if self.tbMidwayTimer ~= nil then
        DelayTimer:ClearTimer(self.tbMidwayTimer)
        self.tbMidwayTimer = nil 
    end
end

local function OnHumanMovementStateChange(self, Player, nOldState, nNewState)
    if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    if nNewState == HumanMovementStateType.InPlane_State then
        local tbData = ParachutionSystem_C:GetSelectedPoint()
        local nTransporterId = tbData and tbData.nTransporterId or 0
        local tbTransporterData = TransporterDataTable:GetTemplate(nTransporterId)
        if tbTransporterData ~= nil and tbTransporterData.nMidwayTime > 0 then
            self.tbMidwayTimer = DelayTimer:DelayRun(function()
                ClearMidwayTimer(self)
                ShowDialog(self, "tbMidwayDialogIds")
                end, tbTransporterData.nMidwayTime)
        end
    elseif nNewState == HumanMovementStateType.Falling_State then
        InitParachuting(self)
        StopLineShipSound(self)
        ShowDialog(self, "nLaunchDialogId")
    elseif nNewState == HumanMovementStateType.Parachutine_State then
        -- 切后台falling状态没有切，导致没有切界面
        if self.tbTimeTick == nil then
            log("OnHumanMovementStateChange init by Parachutine_State")
            InitParachuting(self)
        end
    elseif nNewState == HumanMovementStateType.Gliding_State then
        log("[parachuting] ui change movement state")
        -- 切后台falling状态没有切，导致没有切界面
        if self.tbTimeTick == nil then
            log("OnHumanMovementStateChange init by Gliding_State")
            InitParachuting(self)
        end
        self.nParachutingStep = PARACHUTING_STEP.PARACHUTE
        OnGliding(self)
    end
end

local function OnMatineeComplete(self)
    ShowDialog(self, "nStartDialogId")
end

local function LoadLayoutSetting(self, nFrom)
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(nFrom)
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == nFrom then
            local tbTemplate = v.tbTemplate
            local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
            local pScaleWidget = pWidgetRef[tbTemplate.szMainScaleWidgetName]
            local pAlphaWidget = pWidgetRef[tbTemplate.szMainAlphaWidgetName]
            if pWidget then
                pWidget.Slot:SetPosition(Vector2D{X = v.nX, Y = v.nY})
                pAlphaWidget:SetRenderOpacity(v.nAlpha)
                local SetUserSpecifiedScaleFunc = pScaleWidget.SetUserSpecifiedScale
                if SetUserSpecifiedScaleFunc then
                    SetUserSpecifiedScaleFunc(pScaleWidget, v.nScale)
                else
                    pScaleWidget:SetRenderTransformPivot(pScaleWidget.Slot:GetAlignment())
                    pScaleWidget:SetRenderScale(Vector2D{X = v.nScale, Y = v.nScale})
                end
            end
        end
    end
end

function UPFFATransportNew:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulFreeView = UILogicHelper:CreateUILogic("ULHumanFreeView")
    
end

function UPFFATransportNew:OnShow()
    LoadLayoutSetting(self, SettingLayoutFromDef.HUMAN)
end

function UPFFATransportNew:OnDestroy()
    StopLineShipSound(self)
end

local function OnParachuteCameraChanged(self, nGroupId)
    if nGroupId == GameCameraModeGroupDef.NewParachuteOpenParachute then  
        self.pWidgetRef.ovlJoystick:SetVisibility(ESlateVisibility.Visible)
        self.ulFreeView:Activate()
    end
end

local function OnGlidingClicked(self)
    if not ParachutingNewIni.tbParachuteOpen.bHad then
        return
    end
    if self.bGliding then
        return
    end
    local nHeight = GetSelfHeight(self)
    if nHeight <= ParachutingNewIni.tbLaunch.nOpenParachuteMaxHeight then
        NetworkManager:GetRPCNetworkProxy():SendToServer(DCProto.c2d_ParachuteOpen)
    end
end

function UPFFATransportNew:Activate(tbParam)
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    self.nGliding = GLIDING_STATE.NONE
    self.Owner.pbCurrrentVirtualStick.pWidgetRef:SetVisibility(Collapsed)
    pWidgetRef.sldSpeed:SetVisibility(Collapsed)
    pWidgetRef.ovlLandingHeight:SetVisibility(Collapsed)
    pWidgetRef.ovlJoystick:SetVisibility(Collapsed)
    pWidgetRef.hbTimer:SetVisibility(Collapsed)
    pWidgetRef.btnGliding:SetVisibility(Collapsed)
    pWidgetRef.imgWing:SetVisibility(Collapsed)

    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, self, OnParachuteCameraChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORTER_MATINEE_COMPLETE, self, OnMatineeComplete)
    EventHelper:RegisterEvent(CommonEventDef.EV_FFA_PARACHUTE_OPEN, self, OnGliding)
    self.pGlidingClick = EventHelper:RegisterCppDelegate(pWidgetRef.btnGliding.OnClicked , self, OnGlidingClicked)

    local SelfObj = GamePlayerSelfHelper:Get()
    if SelfObj ~= nil and SelfObj.pUEActor ~= nil then
        self.tbVelocityTimer = self.TimerHelper:NewTimerMethod(self, OnNewParachutingVelocity, VELOCITY_REFRESH_INTERVAL, true)
    end

    -- 为解决偶现movemementcomponent已经是跳伞状态了，EV_FFA_PROCESS_STATE_CHANGED = rFFAProcessState_EState.MATINEE这个包才rep下来
    local HumanMovementStateComponent = SelfObj.HumanMovementStateComponent
    if HumanMovementStateComponent ~= nil then
        local nCurState = HumanMovementStateComponent:GetCurrentState()
        if nCurState == HumanMovementStateType.Falling_State or 
            nCurState == HumanMovementStateType.InPlane_State then
            log("UPFFATransportNew active: ", nCurState)
            OnHumanMovementStateChange(self, SelfObj, nil, nCurState)
        elseif nCurState == HumanMovementStateType.Parachutine_State then
            log("UPFFATransportNew active in parachutine")
            InitParachuting(self)
            OnParachuteCameraChanged(self, GameCameraModeGroupDef.NewParachuteOpenParachute)
        end  
    end
end

function UPFFATransportNew:Deactivate()
    DestroyVelocityTimer(self)
    self.nLaunchTime = nil
    StopLineShipSound(self)
    self.bFalling = nil
    self.nGliding = nil
    self.EventHelper:UnregisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_FFA_TRANSPORTER_MATINEE_COMPLETE)
    self.EventHelper:UnregisterEvent(CommonEventDef.EV_FFA_PARACHUTE_OPEN)
    self.EventHelper:UnregisterCppDelegate(self.pGlidingClick)
    
    ClearMidwayTimer(self)
    self.TimerHelper:ClearAllTimer()
    self.tbTimeTick = nil
    self.Owner.ulPickupButton:Reset()

    self.ulFreeView:Deactivate()
end

return UPFFATransportNew