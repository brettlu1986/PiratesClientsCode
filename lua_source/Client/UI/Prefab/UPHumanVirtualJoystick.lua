-----------------------------------------------------
--File Name    : UPHumanVirtualJoystick.lua
--Author       : Song Fuhao
--Create Time  : 2017-06-15
--Description  : UPHumanVirtualJoystick
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPHumanVirtualJoystick = luaclass("UPHumanVirtualJoystick", PrefabBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ProtoDC = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local DelayTimer = require("DelayTimer")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")

local Multiply_Vector2DFloat = KismetMathLibrary.Multiply_Vector2DFloat
local FN_MAKE_VECTOR_2D = KismetMathLibrary.MakeVector2D
local MAX_DISTANCE = 140
local CONTINUS_ANGLE = 60
local SPRINT_ANGLE = 45
local CONTINUOUS_LOCAL_ID = 120
local nXOffset = 0
local nYOffset = 0
local nScale = 1

local DirectionLocks = {
    Forward = true,
    Left    = true,
    Back    = true,
    Right   = true
}

local JOYSTICK_LOCAL_IDs = {
    116,
    304
}

UPHumanVirtualJoystick.nViewportScale = 1
UPHumanVirtualJoystick.bEnable = false
UPHumanVirtualJoystick.pDefaultPadPosition = nil
UPHumanVirtualJoystick.pDefaultPadAchors = nil
UPHumanVirtualJoystick.nKValue = nil
UPHumanVirtualJoystick.bContinuousEnable = false
UPHumanVirtualJoystick.bContinuousRun = false
UPHumanVirtualJoystick.bTouchStart = false
UPHumanVirtualJoystick.bSprint = false
UPHumanVirtualJoystick.pCurrentFingerIndex = nil
UPHumanVirtualJoystick.tbLayoutTimer = nil
UPHumanVirtualJoystick.bContinuousChecked = false
UPHumanVirtualJoystick.bSprintEnable = false
UPHumanVirtualJoystick.CurrentLayoutFrom = SettingLayoutFromDef.HUMAN

local function IsJoystickTarget(nTargetUniqueID)
    for _, v in pairs(JOYSTICK_LOCAL_IDs) do
        if nTargetUniqueID == v then
            return true
        end
    end
    return false
end

local function ChangeContinuousRun(self, bRun)
    
    local c2d_ChangeContinuousRun =
    {
        is_continuous_run = bRun
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ChangeContinuousRun, c2d_ChangeContinuousRun)
end

local function IsSpecialState(self, nCurrentState, HumanWeaponComponent)
    if nCurrentState == HumanWeaponStateDef.RELOADING
        or HumanWeaponComponent:IsAiming()
        or nCurrentState == HumanWeaponStateDef.ATTACKING then
        return true
    end
    return false
end


local function OnContinuousEnter(self)
    if not self.bTouchStart then
        return WidgetBlueprintLibrary.Handled()
    end
    --logdebug("OnContinuousEnter")
    --self:OnSprintActivate()
    local pWidgetRef = self.pWidgetRef
    if (not self.bContinuousRun) and self.bContinuousEnable then
        pWidgetRef.chkContinuous:SetCheckedState(ECheckBoxState.Unchecked)
        pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_SPRINT_CONTINUOUS)
    end
    --self:OnContinuousUnlock()
    pWidgetRef.bdrVirtualStick:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.bdrLock:SetVisibility(ESlateVisibility.Visible)
    if not pWidgetRef:IsAnimationPlaying(pWidgetRef.animGO) then
        self:PlayAnimation("animGO", 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

local function OnContinuousLeave(self)
    --logdebug("OnContinuousLeave")
    self.pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
    self:OnContinuousUnlock()
    self:StopAnimation("animGO")
end

local function SetSprintImmediatelyEnable(self, bEnable)
    if ControlModeSystem:GetCurrentModeType() ~= ControlModeDef.HUMAN then
        return
    end
    if bEnable then
        self.pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Visible)
    else
        self.pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.HitTestInvisible)
    end
end

local function VerifyMoveDirection(nDeltaX, nDeltaY)
    if DirectionLocks.Forward == false then
        nDeltaY = nDeltaY < 0 and 0 or nDeltaY
    end
    if DirectionLocks.Back == false then
        nDeltaY = nDeltaY > 0 and 0 or nDeltaY
    end
    if DirectionLocks.Right == false then
        nDeltaX = nDeltaX > 0 and 0 or nDeltaX
    end
    if DirectionLocks.Left == false then
        nDeltaX = nDeltaX < 0 and 0 or nDeltaX
    end
    return nDeltaX, nDeltaY
end

local function OnMoveTouchStarted( self, pFingerIndex, pCenterPosition )
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    if pPlayerInputComponent and pPlayerInputComponent.MoveEnabled == false then
        log("UPHumanVirtualJoystick:OnMoveTouchStarted, MoveEnabled = false")
    end
    if self.pCurrentFingerIndex then
        log("UPHumanVirtualJoystick:OnMoveTouchStarted return")
        return
    end
    self.pCurrentFingerIndex = pFingerIndex
    self.bTouchStart = true
    self.bContinuousChecked = false
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgThumb:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

    self:DeactivateContinuousRun()
    if self.bContinuousEnable then
        if pCenterPosition then
            local pGeometry = self.pWidgetRef.cvsVirtualSticker:GetCachedGeometry()
            local pLocCenter = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, pCenterPosition)
            pLocCenter.X = pLocCenter.X - nXOffset
            pLocCenter.Y = pLocCenter.Y + nYOffset
            self.pWidgetRef.cvsContinuous.Slot:SetPosition(pLocCenter)
        end
    end

    self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, HumanWeaponCalculator.SpreadEnum.MOVE_RUN)
    if self.bContinuousEnable then
        SetSprintImmediatelyEnable(self, false)
    end
end

local function OnMoveTouchMoved( self, pCenterPosition, pMoveDelta, pFingerIndex )
    --logdebug("pFingerIndex,self.pCurrentFingerIndex=",pFingerIndex,self.pCurrentFingerIndex)
    if not self.bTouchStart or self.pCurrentFingerIndex ~= pFingerIndex then
        log("UPHumanVirtualJoystick:OnMoveTouchMoved return, bTouchStart, pCurrentFingerIndex = ", self.bTouchStart, self.pCurrentFingerIndex)
        return
    end
    local DeltaX = pMoveDelta.X
    local DeltaY = pMoveDelta.Y
    DeltaX, DeltaY = VerifyMoveDirection(DeltaX, DeltaY)

    if math.abs(DeltaX) == 1 and math.abs(DeltaY) == 1 then
        DeltaX = math.cos(math.rad(SPRINT_ANGLE)) * DeltaX
        DeltaY = math.cos(math.rad(SPRINT_ANGLE)) * DeltaY
    end
    local pMoveDeltaFixed = Vector2D{X = DeltaX, Y = DeltaY}
    self.pWidgetRef.imgThumb.Slot:SetPosition(Multiply_Vector2DFloat(pMoveDeltaFixed, MAX_DISTANCE))
    local nKValue = nil
    if DeltaX ~= 0.0 then
        nKValue = math.abs(DeltaY / DeltaX)
    end
    --logdebug("UPHumanVirtualJoystick:OnMoveTouchMoved................................pMoveDelta, nKValue=",pMoveDelta.X, pMoveDelta.Y, nKValue,self.bSprint)
    if (not nKValue or nKValue >= math.tan(math.rad(CONTINUS_ANGLE))) and self.bSprint then
        --self:OnSprintActivate()
        OnContinuousEnter(self)
    else
        self:OnContinuousUnlock()
        OnContinuousLeave(self)
    end
    self.nKValue = nKValue
    --self:DeactivateContinuousRun()
end

local function OnMoveTouchEnded( self, pFingerIndex )
    if self.pCurrentFingerIndex ~= pFingerIndex and self.pCurrentFingerIndex ~= nil then
        log("UPHumanVirtualJoystick:OnMoveTouchEnded return")
        return
    end
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    if pPlayerInputComponent and pPlayerInputComponent.MoveEnabled == false then
        log("UPHumanVirtualJoystick:OnMoveTouchEnded, MoveEnabled = false")
    end
    self.pCurrentFingerIndex = nil
    self.bTouchStart = false
    self.pWidgetRef.imgThumb.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
    self.pWidgetRef.bdrContinuous:SetVisibility(ESlateVisibility.Hidden)
    self.pWidgetRef.bdrVirtualStick:SetVisibility(ESlateVisibility.Collapsed)
    self:ActivateContinuousRun()
    if not self.bContinuousRun then
        self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, HumanWeaponCalculator.SpreadEnum.MOVE_STAY)
    else
        self.bContinuousChecked = true
    end
    self:StopAnimation("animGO")
    if self.bContinuousEnable then
        SetSprintImmediatelyEnable(self, true)
    end
end

local function OnForceEndJoystickMove(self)
    OnMoveTouchEnded(self, self.pCurrentFingerIndex)
    self:OnContinuousUnlock(true)
end

local function OnPlayerActorEndPlay(self)
    self.EventHelper:UnregisterAll()
end

local function OnInterruptRun(self)
    self:DeactivateContinuousRun(true)
    self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, HumanWeaponCalculator.SpreadEnum.MOVE_STAY)
end

local function CheckRecoverContinueRun(self, nCurrentState, Owner)
    if self.bSprint then
        if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
            return
        end
        --logdebug("OnWeaponStateChanged,nCurrentState=",nCurrentState)
        if IsSpecialState(self, nCurrentState, Owner.HumanWeaponComponent) then
            ChangeContinuousRun(self, false)
            self.pWidgetRef.chkSprintImmediately:SetCheckedState(ECheckBoxState.Unchecked)
        else
            ChangeContinuousRun(self, true)
            self.pWidgetRef.chkSprintImmediately:SetCheckedState(ECheckBoxState.Checked)

        end
    end
end

local function OnContinueRunRecover(self, nCurrentState, Owner)
    if Owner then
        CheckRecoverContinueRun(self, nCurrentState, Owner)
    end
end

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    CheckRecoverContinueRun(self, nCurrentState, Owner)
end

local function OnSprint(self, bOnSprint)
    if (self.bSprint == bOnSprint) or (not self.bSprintEnable) then
        return
    end
    if bOnSprint then
        self:OnSprintActivate()
    else
        self.tbDelayHandle = DelayTimer:RunNextTick(function()
            if not self.bContinuousChecked then
                self:OnSprintDectivate()
            end
            self.tbDelayHandle = nil
        end)
    end
end

local function OnLockEnter(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    --logdebug("OnSprintEnter,nTouchIndex,self.pCurrentFingerIndex=",nTouchIndex,self.pCurrentFingerIndex)
    if not self.pCurrentFingerIndex or nTouchIndex ~= enumtoint(self.pCurrentFingerIndex) then
        return
    end
    if not self.bTouchStart then
        return
    end
    --logdebug("OnLockEnter")
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
    self:OnSprintActivate()
    self:OnContinuousLock()
    local pWidgetRef = self.pWidgetRef
    self.pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.chkContinuous:SetCheckedState(ECheckBoxState.Checked)
    self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_LOCK)
end

local function OnHumanStopMovementImmediately(self)
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    pPlayerInputComponent:StopMoveImmediately()
end

local function OnMoveStopImmediately(self)
    log("UPHumanVirtualJoystick:OnMoveStopImmediately")
    self:DeactivateContinuousRun(true)
end

local function OnSprintCheckChanged(self, bChecked)
    self.bContinuousChecked = bChecked
    if bChecked then
        self:OnSprintActivate()
        self:OnContinuousLock()
        local pWidgetRef = self.pWidgetRef
        pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.chkContinuous:SetCheckedState(ECheckBoxState.Checked)
        self.nKValue = math.tan(math.rad(CONTINUS_ANGLE))
        self:ActivateContinuousRun()
        if not self.bContinuousRun then
            self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, HumanWeaponCalculator.SpreadEnum.MOVE_STAY)
        end
        self:StopAnimation("animGO")
    else
        OnHumanStopMovementImmediately(self)
    end
end

local function OnAppWillDeactive(self)
    if not self.bContinuousChecked then
        OnHumanStopMovementImmediately(self)
    end
end

local function CheckIsMovingOnShow(self)
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    if pPlayerInputComponent and pPlayerInputComponent:IsInMove() then
        local nCurrentFingerIndex = pPlayerInputComponent.CurrentPlayerMoveFingerIndex
        local pCenterPosition = pPlayerInputComponent.CenterPosition
        local pMoveDelta = pPlayerInputComponent.MoveDelta
        OnMoveTouchStarted(self, nCurrentFingerIndex, pCenterPosition)
        OnMoveTouchMoved(self, pCenterPosition, pMoveDelta, nCurrentFingerIndex)
    end
end

function UPHumanVirtualJoystick:OnBindEvent(EventHelper)
    UPHumanVirtualJoystick.super.OnBindEvent(self, EventHelper)
    local pWidgetRef = self.pWidgetRef
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveTouchStarted, self, OnMoveTouchStarted)
    EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveTouchMoved, self, OnMoveTouchMoved)
    EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveTouchEnded, self, OnMoveTouchEnded)
    EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveStopImmediately, self, OnMoveStopImmediately)
    EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnSprint, self, OnSprint)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrLock.OnMouseEnterEvent, self, OnLockEnter)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkSprintImmediately.OnCheckStateChanged, self, OnSprintCheckChanged)


    EventHelper:RegisterCppDelegate(pUEActor.OnEndPlay, self, OnPlayerActorEndPlay)
    EventHelper:RegisterCppDelegate(pUEActor.CharacterMovement.OnHumanStopMovementImmediately, self, OnHumanStopMovementImmediately)
    EventHelper:RegisterEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN, self, OnInterruptRun)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CONTINUE_RUN_RECOVER, self, OnContinueRunRecover)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_FORCE_END_MOVE, self, OnForceEndJoystickMove)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_ENABLE_CONTINOUS, self, self.SetContinuousEnable)
    EventHelper:RegisterEvent(ClientEventDef.EV_APP_WILL_DEACTIVE, self, OnAppWillDeactive)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_JOYSTICK_SPRINT_PC, self, OnSprint)

end

function UPHumanVirtualJoystick:OnShow()
    local pWidgetRef = self.pWidgetRef
    local pIconRes = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_RUN:load()
    if pIconRes then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgContinuous, pIconRes)
    end
    pIconRes = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_CHECK:load()
    if pIconRes then
        UISetUtils.SetCheckBoxCheckedBrushRes(pWidgetRef.chkContinuous, pIconRes)
    end
    pIconRes = UIResourceDef.FFA_VIRTUALSTICK_HUMAN_UNCHECK:load()
    if pIconRes then
        UISetUtils.SetCheckBoxUncheckedBrushRes(pWidgetRef.chkContinuous, pIconRes)
    end
    pWidgetRef.chkContinuous:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if ControlModeSystem:GetCurrentModeType() == ControlModeDef.HUMAN then
        pWidgetRef.chkSprintImmediately:SetCheckedState(ECheckBoxState.Unchecked)
        pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Visible)
    else
        pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Collapsed)
    end
    self:RefreshLayout()
    CheckIsMovingOnShow(self)
end

function UPHumanVirtualJoystick:OnDestroy()
    -- OnHumanStopMovementImmediately(self)
    self:DeactivateContinuousRun(true)
    self:StopAnimation("animGO")
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
    if self.tbLayoutTimer then
        DelayTimer:ClearTimer(self.tbLayoutTimer)
        self.tbLayoutTimer = nil
    end
    self.pWidgetRef.chkSprintImmediately:SetVisibility(ESlateVisibility.Collapsed)
    self.EventHelper:UnregisterAll()
end

function UPHumanVirtualJoystick:SetVirtualJoystickIcon(szIconRes)
    local IconResObj = szIconRes:load()
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgThumb, IconResObj)
end

function UPHumanVirtualJoystick:SetContinuousEnable(bEnable)
    self.bContinuousEnable = bEnable
    if not bEnable then
        self.pWidgetRef.bdrContinuous:SetVisibility(ESlateVisibility.Hidden)
        self.pWidgetRef.bdrLock:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
    if ControlModeSystem:GetCurrentModeType() == ControlModeDef.TRANSPORTNEW then
        self.bSprintEnable = false
    else
        self.bSprintEnable = true
    end
end


function UPHumanVirtualJoystick:ActivateContinuousRun()
    if not self.bContinuousEnable then
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrContinuous:SetVisibility(ESlateVisibility.Hidden)
    pWidgetRef.bdrLock:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrVirtualStick:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrSprint:SetVisibility(ESlateVisibility.Collapsed)
    --logdebug("ActivateContinuousRun,self.bContinuousRun=",self.bContinuousRun)
    if (not self.nKValue or self.nKValue >= math.tan(math.rad(CONTINUS_ANGLE))) and self.bSprint and self.bContinuousRun then
        pWidgetRef.imgThumb.Slot:SetPosition(Multiply_Vector2DFloat(FN_MAKE_VECTOR_2D(0, -1), MAX_DISTANCE))
        pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hbxLock:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.imgContinuous:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.imgThumb.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
        pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
        self:OnSprintDectivate()
    end
end

function UPHumanVirtualJoystick:DeactivateContinuousRun(bStopMove)
    local pWidgetRef = self.pWidgetRef
    --if self.bContinuousRun then
        pWidgetRef.imgThumb.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
    --end
    if not self.bContinuousEnable then
        return
    end
    pWidgetRef.bdrLock:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.imgContinuous:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hbxLock:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrContinuous:SetVisibility(ESlateVisibility.Hidden)
    pWidgetRef.bdrVirtualStick:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.bdrSprint:SetVisibility(ESlateVisibility.Collapsed)
    self:OnSprintDectivate()
    self:OnContinuousUnlock(bStopMove)
end

function UPHumanVirtualJoystick:OnContinuousLock()
    if self.bContinuousRun then
        return
    end
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    if not pPlayerInputComponent then
        return false
    end
    self.bContinuousRun = true
    pPlayerInputComponent:SetContinuousRun(true)
    return true
end

function UPHumanVirtualJoystick:OnContinuousUnlock(bInStopMove)
    if not self.bContinuousRun then
        return
    end
    self.bContinuousRun = false
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    if not pPlayerInputComponent then
        return
    end
    local bStopMove = bInStopMove ~= nil and bInStopMove or false
    pPlayerInputComponent:SetContinuousRun(false, bStopMove)
end

function UPHumanVirtualJoystick:OnSprintActivate()
    if self.bSprint or (not self.bContinuousEnable) then
        return
    end
    self.bSprint = true
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if HumanWeaponComponent then
        local nCurrentState = HumanWeaponComponent:GetCurrentState()
        if not IsSpecialState(self, nCurrentState, HumanWeaponComponent) then
            ChangeContinuousRun(self, true)
            self.pWidgetRef.chkSprintImmediately:SetCheckedState(ECheckBoxState.Checked)
            self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_SPRINT)
        end
    end
end

function UPHumanVirtualJoystick:OnSprintDectivate()
    if not self.bSprint then
        return
    end
    self.bSprint = false
    ChangeContinuousRun(self, false)

    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    if HumanWeaponComponent then   
        HumanWeaponComponent:DeactiveLastRun()
    end
    self.pWidgetRef.chkSprintImmediately:SetCheckedState(ECheckBoxState.Unchecked)
end

function UPHumanVirtualJoystick:IsVirtualJoystickTouched()
    return self.bTouchStart
end

function UPHumanVirtualJoystick:RefreshLayout()
    nYOffset = 0
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local pViewPortSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(self.CurrentLayoutFrom)
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == self.CurrentLayoutFrom then
            local tbTemplate = v.tbTemplate
            local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
            local pScaleWidget = pWidgetRef[tbTemplate.szMainScaleWidgetName]
            local pAlphaWidget = pWidgetRef[tbTemplate.szMainAlphaWidgetName]
            if pWidget and pScaleWidget and pAlphaWidget then
                local pCurPos = Vector2D{X = v.nX, Y = v.nY}
                pWidget.Slot:SetPosition(pCurPos)
                pAlphaWidget:SetRenderOpacity(v.nAlpha)
                local SetUserSpecifiedScaleFunc = pScaleWidget.SetUserSpecifiedScale
                if tbTemplate.szMainScaleWidgetName == "sboxVirtualStickerBar" then
                    nScale = v.nScale
                end
                if SetUserSpecifiedScaleFunc then
                    SetUserSpecifiedScaleFunc(pScaleWidget, v.nScale)
                else
                    pScaleWidget:SetRenderScale(Vector2D{X = v.nScale, Y = v.nScale})
                end 
                if IsJoystickTarget(v.nLocalId) then
                    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
                    if pUEActor and pUEActor.PlayerInputComponent then
                        pCurPos.X = 0.25 * pViewPortSize.X
                        pUEActor.PlayerInputComponent:SetMoveCenterPosition(pCurPos)
                        local pLocalSize = pScaleWidget.Slot:GetSize()
                        pCurPos.X = (v.nX + nScale * pLocalSize.X / 2) * nViewPortScale
                        pCurPos.Y = pViewPortSize.Y + (v.nY - nScale * pLocalSize.Y / 2) * nViewPortScale
                        pUEActor.PlayerInputComponent.JoystickPadCenterPosition = pCurPos
                        pLocalSize.X = pLocalSize.X * nScale * nViewPortScale
                        pLocalSize.Y = pLocalSize.Y * nScale * nViewPortScale
                        pUEActor.PlayerInputComponent.JoystickPadSize = pLocalSize
                    end
                    if self.tbLayoutTimer then
                        DelayTimer:ClearTimer(self.tbLayoutTimer)
                        self.tbLayoutTimer = nil
                    end
                    self.tbLayoutTimer = DelayTimer:DelayRun(function()
                        local pLocalSize = SlateBlueprintLibrary.GetLocalSize(pWidgetRef.sboxVirtualStickerBar:GetCachedGeometry())
                        local pVirtualStickPos = pWidgetRef.cvsVirtualSticker.Slot:GetPosition()
                        pWidgetRef.hbxLock.Slot:SetPosition(Vector2D{X = 0, Y = -pLocalSize.Y })
                        pWidgetRef.bdrSprint.Slot:SetPosition(Vector2D{X = 0, Y = -pLocalSize.Y + pVirtualStickPos.Y - 50 })
                        pWidgetRef.bdrVirtualStick.Slot:SetSize(Vector2D{X = 0, Y = pLocalSize.Y + math.abs(pVirtualStickPos.Y)})

                        local pCvsLocalSize = SlateBlueprintLibrary.GetLocalSize(pWidgetRef.cvsVirtualSticker:GetCachedGeometry())
                        nYOffset = nYOffset - pCvsLocalSize.Y + pLocalSize.Y / 2

                        local pSize = self.pWidgetRef.cvsVirtualSticker:GetDesiredSize()
                        nXOffset = pSize.X / 2
                    end, 0.1)
                end
                if v.nLocalId == CONTINUOUS_LOCAL_ID then
                    nYOffset = nYOffset + v.nY
                    local pOriginContinuousSize = pWidgetRef.bdrContinuous.Slot:GetSize()
                    nYOffset = nYOffset + pOriginContinuousSize.Y * (1 - v.nScale) * 0.5
                end
            end
        end
    end
end

function UPHumanVirtualJoystick.LockDirections(bCanForward, bCanLeft, bCanBack, bCanRight)
    local pUEActor = GamePlayerSelfHelper:Get().pUEActor
    local pPlayerInputComponent = pUEActor.PlayerInputComponent
    
    pPlayerInputComponent:SetDirectionLocks(bCanForward, bCanLeft, bCanBack, bCanRight)
    DirectionLocks.Forward = bCanForward
    DirectionLocks.Left = bCanLeft
    DirectionLocks.Back = bCanBack
    DirectionLocks.Right = bCanRight
end

function UPHumanVirtualJoystick:SetCurrentLayoutFromByVehicleState(nState)
    local CurrentLayoutFrom = SettingLayoutFromDef.HUMAN
    if nState == HumanVehicleStateDef.AttachToVehicle then
        CurrentLayoutFrom = SettingLayoutFromDef.VEHICLE
    end
    if self.CurrentLayoutFrom ~= CurrentLayoutFrom then
        self.CurrentLayoutFrom = CurrentLayoutFrom
        self:RefreshLayout()
    end
end

return UPHumanVirtualJoystick
