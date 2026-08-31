-----------------------------------------------------
--Author       : Ran Jie
--Description  : UPHumanWeaponAim
-----------------------------------------------------

local luaclass = require ("luaclass")
local UPHumanAimBase = require("UPHumanAimBase")
local UPHumanWeaponAim = luaclass("UPHumanWeaponAim", UPHumanAimBase)

-- import require
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local HumanCameraDataTable = require("HumanCameraDataTable")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")

local TIMER_TICK = 0.1
local TempRootSize = Vector2D()
UPHumanWeaponAim.nCurrentScale = nil
UPHumanWeaponAim.nTargetScale = nil
UPHumanWeaponAim.AnimTimer = nil
UPHumanWeaponAim.tbCurrentSize = Vector2D() 

--策劃配置的參數
UPHumanWeaponAim.nMinDisperValue = nil
UPHumanWeaponAim.nMaxDisperValue = nil
UPHumanWeaponAim.nMaxUIZoomValue = nil
UPHumanWeaponAim.pModeChangeDelegate = nil



local function InternalAnimTimerFunc(self)
    if math.abs(self.nCurrentScale - self.nTargetScale) < 0.001 then
        if self.AnimTimer then
            self.TimerHelper:ClearTimer(self.AnimTimer)
            self.AnimTimer = nil
        end
        return
    end
    --logdebug("self.nCurrentScale,self.nTargetScale=",self.nCurrentScale,self.nTargetScale)
    local nNextScale = KismetMathLibrary.FInterpTo(self.nCurrentScale, self.nTargetScale, 1, 0.6)
    --logdebug("nNextScale=",nNextScale)
    local NextSize = Vector2D{X = self.tbNotAimInitSize.X * nNextScale, Y = self.tbNotAimInitSize.Y * nNextScale}
    self.nCurrentScale = nNextScale
    self.pWidgetRef.ovlNotAim.Slot:SetSize(NextSize)
end


local function CalculateAimUISize(self, nPose, nMoveType, bFirstAttack)
    local tbProperty = self.tbItem:GetProperty(true)
    --local nSpreadValue = HumanWeaponCalculator.CalculateSpread(GamePlayerSelfHelper:Get(), tbProperty)
    local nSpreadValue = HumanWeaponCalculator.CalculateSpreadWithParams(GamePlayerSelfHelper:Get(), tbProperty, nPose, nMoveType, bFirstAttack, false)
    local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(GameCameraModeGroupDef.HumanState.Normal)
    local nFov = tbInitParams.nFov

    local pRootGeometry = self.Owner.pWidgetRef:GetCachedGeometry()
    TempRootSize = SlateBlueprintLibrary.GetLocalSize(pRootGeometry)
    local AimUISize = TempRootSize.X / nFov * (nSpreadValue + tbProperty.nDispersionDeviation) * 2
    --logdebug("CalculateAimUISize,AimUISize, nSpreadValue=",AimUISize, nSpreadValue,nFov,TempRootSize.X, GamePlayerSelfHelper:Get():GetName())
    return AimUISize
end

local function InternalScaleToTargetSize(self, bReset, nPose, nMoveType, bFirstAttack)
    if bReset or not self.nCurrentScale then
        self.nCurrentScale = 1
    end
    -- logdebug("InternalScaleToTargetSize",nDelta,self.nTargetScale,nTargetSizX)
    local AimUISize = CalculateAimUISize(self, nPose, nMoveType, bFirstAttack)
    self.nTargetScale = AimUISize / self.tbNotAimInitSize.X
    self:PlayScalAnim()
end

local function OnPoseChanged(self, nPose)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.HumanMovementStateComponent then
        local _, nMoveType =  HumanWeaponCalculator.GetOnwerPosAndMoveType(PlayerSelf)
        InternalScaleToTargetSize(self, false, nPose, nMoveType, true)
    end
end

local function OnMoveTypeChanged(self, nMoveType)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.HumanMovementStateComponent then
        local nPose, _ =  HumanWeaponCalculator.GetOnwerPosAndMoveType(PlayerSelf)
        InternalScaleToTargetSize(self, false, nPose, nMoveType, true)
    end
end

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if Owner:GetServerInstanceId() ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return
    end
    if nCurrentState == HumanWeaponStateDef.ATTACKING then
        self:ScaleToTargetSize(false, false)
    else
        self:ScaleToTargetSize(false, true)
    end
end

---------------------------

local function OnMovementModeChanged(self, pUEActor, pPreMovementMode, pPreCustomMode)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.HumanMovementStateComponent then
        local MovementMode = pUEActor.CharacterMovement.MovementMode
        local nPose, nMoveType =  HumanWeaponCalculator.GetOnwerPosAndMoveType(GamePlayerSelfHelper:Get())
        if MovementMode == EMovementMode.MOVE_Falling then
            InternalScaleToTargetSize(self, false, nPose, HumanWeaponCalculator.SpreadEnum.MOVE_JUMP, true)
        elseif pPreMovementMode == EMovementMode.MOVE_Falling and MovementMode == EMovementMode.MOVE_Walking then
            InternalScaleToTargetSize(self, false, nPose, nMoveType, true)
        end
    end
end



--member function
function UPHumanWeaponAim:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_POSE_CHANGED, self, OnPoseChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, self, OnMoveTypeChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    local SelfActor = GamePlayerSelfHelper:Get().pUEActor
    if SelfActor and SelfActor.MovementModeChangedDelegate then
        self.pModeChangeDelegate = EventHelper:RegisterCppDelegate(SelfActor.MovementModeChangedDelegate, self, OnMovementModeChanged)
    end
end 


function UPHumanWeaponAim:OnDestroy()
    --self.TimerHelper:ClearAllTimer()
end

function UPHumanWeaponAim:PlayScalAnim()
    if self.AnimTimer then
        self.TimerHelper:ClearTimer(self.AnimTimer)
        self.AnimTimer = nil
    end
    self.AnimTimer = self.TimerHelper:NewTimerMethod(self, InternalAnimTimerFunc, TIMER_TICK, true)
end

function UPHumanWeaponAim:ScaleToTargetSize(bReset, bFirstAttack)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.HumanMovementStateComponent and not PlayerSelf:IsDead() then
        local nPose, nMoveType =  HumanWeaponCalculator.GetOnwerPosAndMoveType(PlayerSelf)
        InternalScaleToTargetSize(self, false, nPose, nMoveType, bFirstAttack)
    end
end

function UPHumanWeaponAim:Init(tbItem)
    UPHumanWeaponAim.super.Init(self, tbItem)
    if not tbItem then
        return
    end
    
    self.nMinDisperValue, self.nMaxDisperValue = tbItem:GetUISightDispersionRange()
    self.nMaxUIZoomValue = tbItem:GetUISightZoomMax()
    self:ScaleToTargetSize(true, true)
end


return UPHumanWeaponAim
