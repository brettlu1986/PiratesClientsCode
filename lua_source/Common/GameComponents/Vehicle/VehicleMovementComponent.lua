local luaclass          = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local VehicleMovementComponent= luaclass("VehicleMovementComponent", GameComponentBase)
local SelfEventHelper = require("SelfEventHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local VehicleDataTable = require("VehicleDataTable")
local PropUtil = require("PropUtil")
local DamageTypeEx = require("DamageTypeEx")
local PropName = require("PropName")
local VehicleMovementIni = require("VehicleMovementIni")


local ENUM_Direction = {
    None = 0,
    Forward = 1,
    LeftRight = 2,
    Back = 3,
}

local BLOCK_DIST = VehicleMovementIni.tbDefaultFallParams.nJumpableBlockDistance
local BLOCK_HEIGHT = VehicleMovementIni.tbDefaultFallParams.nJumpableBlockHeight
local MIN_SPEED = VehicleMovementIni.tbDefaultFallParams.nJumpableMinSpeed

VehicleMovementComponent.nDirection = ENUM_Direction.Forward
VehicleMovementComponent.EventHelper = nil
VehicleMovementComponent.nBaseSpeed = 1
VehicleMovementComponent.nSpeedRatio = 1
VehicleMovementComponent.tbVehicleData = nil
VehicleMovementComponent.bIsFrightened = false

VehicleMovementComponent.bStartFalling = false
VehicleMovementComponent.nStartFallingZ = 0

VehicleMovementComponent.rSpeedBuffRatio = nil

local function DirectionChanged(self, nDirection, nAngle)
    self.nDirection = nDirection
    self:SetBaseSpeed(self.tbVehicleData.nSpeed)

    local nSpeed = 1
    if nDirection == ENUM_Direction.Forward or nDirection == ENUM_Direction.None then
        -- if self.rRunState:Get() then
            -- nSpeed =  self.tbVehicleData.nRunSpeed
        -- else
            nSpeed = 1
        -- end
    elseif nDirection == ENUM_Direction.LeftRight then
        nSpeed = self.tbVehicleData.nLeftRightSpeed
    else
        nSpeed = self.tbVehicleData.nBackSpeed
    end
    self:SetSpeedRatio(nSpeed)
    self:OnSpeedChanged()
end

local function OnUEMovementChanged(self, pUEActor, PrevMovementMode, PrevCustomMode)

    if not GlobalVariableSystem:IsServerLogic() then
        return
    end

    -- local tbSetting = BattleGameModeSystem:GetGameMode().Setting
    -- if tbSetting:IsWaitStage() then
    --     return false
    -- end
    if not GlobalVariableSystem:GetDungeonDamageEnabled() then
        return
    end

    local CurrentMovementMode = pUEActor.CharacterMovement.MovementMode

    if CurrentMovementMode == EMovementMode.MOVE_Falling then
        self.bStartFalling = true
        self.nStartFallingZ = pUEActor:K2_GetActorLocation().Z
        log("FallingDamage StartZ", self.nStartFallingZ, self.Owner.szName, self.Owner.nPlayerId)
    else
        if self.bStartFalling then
            local nActorZ = pUEActor:K2_GetActorLocation().Z
            local JumpZ = math.abs(nActorZ - self.nStartFallingZ)
              log("FallingDamage End Jump JumpZ", JumpZ, "nActorZ", nActorZ, self.tbVehicleData.nIngoreFallingDamageHeight, self.Owner.szName, self.Owner.nPlayerId)
            if JumpZ > self.tbVehicleData.nIngoreFallingDamageHeight then
                local nDamage = (JumpZ - self.tbVehicleData.nIngoreFallingDamageHeight) / self.tbVehicleData.nFallingDamageFactor
                log("FallingDamage Damage ", self.Owner.szName, nDamage, self.tbVehicleData.nFallingDamageFactor, self.Owner.nPlayerId)
                PropUtil.ApplyDamage(self.Owner, nil, DamageTypeEx.FALLING, nDamage, nil)
            end
            self.bStartFalling = false
        end
    end
end

local function OnServerMoveStopped(self, pUEActor)
    self.nStopType:Set(0)
end

local function OnHorseFrightened(self, bIsFrightened)
    if self.bIsFrightened == bIsFrightened then
        return
    end

    self.bIsFrightened = bIsFrightened

    self:OnSpeedChanged()
end

-- local function HumanMountFallConfigToStr(HumanFallConfig)
--     local str = string.format("{\"AirDragCoefficient\":%f,\"LateralAcceleration\":%f,\"LandStunTime\":%f,\"LandStunSpeedPreservation\":%f,\"JumpLateralSpeedRatio\":%f,\"JumpZVelocity\":%f,\"CustomGravityScale\":%f}",
--     HumanFallConfig.AirDragCoefficient, HumanFallConfig.LateralAcceleration, HumanFallConfig.LandStunTime, HumanFallConfig.LandStunSpeedPreservation, HumanFallConfig.JumpLateralSpeedRatio, HumanFallConfig.JumpZVelocity, HumanFallConfig.CustomGravityScale)
--     return str
-- end

local function InitCristMonitorConfig(pUEActor)
    local tbCrisisMonitorConfig = VehicleMovementIni.tbCrisisMonitorConfig
    pUEActor.CrisisTriggerSpeed = tbCrisisMonitorConfig.nSpeed
    pUEActor.CrisisTriggerDistance = tbCrisisMonitorConfig.nDistance
    pUEActor.CrisisTriggerHeight = tbCrisisMonitorConfig.nHeight
    pUEActor.CrisisMoniterCDTime = tbCrisisMonitorConfig.nCDTime
end

local function InitCheckCanJumpConfig(pUEActor)
    pUEActor.JumpableBlockDistance = BLOCK_DIST
    pUEActor.JumpableBlockHeight = BLOCK_HEIGHT
    pUEActor.JumpableMinSpeed = MIN_SPEED
end

function VehicleMovementComponent:OnCreate(Owner, tbParams)
    VehicleMovementComponent.super.OnCreate(self, Owner, tbParams)
    self.EventHelper = SelfEventHelper()
end

function VehicleMovementComponent:OnDestroy()
    self.EventHelper:UnregisterAll()
    self.MontageDelegate = nil
end

function VehicleMovementComponent:OnActorCreated(pUEActor)
    VehicleMovementComponent.super.OnActorCreated(self, pUEActor)
    self.tbVehicleData = VehicleDataTable:GetTemplate(self.Owner:GetTemplateId())

    self.EventHelper:RegisterCppDelegate(pUEActor.DirectionChange, self, DirectionChanged)
    self.EventHelper:RegisterCppDelegate(pUEActor.OnFrightened, self, OnHorseFrightened)
    if GlobalVariableSystem:IsServerLogic() then
        self.EventHelper:RegisterCppDelegate(pUEActor.MovementModeChangedDelegate, self, OnUEMovementChanged)
        self.EventHelper:RegisterCppDelegate(pUEActor.OnServerMoveStopped, self, OnServerMoveStopped)
    end

    local rComponent = self.Owner.CustomReplicationComponent
    self.rSpeedBuffRatio = rComponent:BindMethod(PropName.VehicleSpeedBuffRadio,
    0, self, self.OnBuffSpeedChanged, true)

    self.nStopType = rComponent:BindMethod(PropName.nStopType,
    0, self, self.OnStopTypeChanged, true)

    self:SetBaseSpeed(self.tbVehicleData.nSpeed)
    pUEActor:InitHumanMountMovementConfig(self.tbVehicleData.nSpeed)

    local HumanMountFallConfig = HumanMountFallConfig()
    local tbFallParams = VehicleMovementIni.tbDefaultFallParams
    HumanMountFallConfig.AirDragCoefficient = tbFallParams.nAirDragCoefficient
    HumanMountFallConfig.LateralAcceleration = tbFallParams.nLateralAcceleration
    HumanMountFallConfig.LandStunTime = tbFallParams.nLandStunTime
    HumanMountFallConfig.LandStunSpeedPreservation = tbFallParams.nLandStunSpeedPreservation
    HumanMountFallConfig.JumpLateralSpeedRatio = tbFallParams.nJumpLateralSpeedRatio
    HumanMountFallConfig.JumpZVelocity = tbFallParams.nJumpZVelocity
    HumanMountFallConfig.CustomGravityScale = tbFallParams.nCustomGravityScale
    pUEActor.CharacterMovement:SetHumanMountFallConfig(HumanMountFallConfig)
    -- destroyUserData(HumanMountFallConfig)

    InitCristMonitorConfig(pUEActor)
    InitCheckCanJumpConfig(pUEActor)
    self:OnSpeedChanged()

end
function VehicleMovementComponent:SetSpeedRatio(nSpeedRatio)
    -- self.nSpeed:ModifyOverlap(self.nSpeedRatio, nSpeedRatio)
    if nSpeedRatio == self.nSpeedRatio then
        return
    end
    self.nSpeedRatio = nSpeedRatio
    -- self:OnSpeedChanged()
end

function VehicleMovementComponent:SetBaseSpeed(nBaseSpeed)
    if nBaseSpeed == self.nBaseSpeed then
        return
    end
    self.nBaseSpeed = nBaseSpeed
    -- self:OnSpeedChanged()
end

function VehicleMovementComponent:OnSpeedChanged()
    if self.Owner.pUEActor.FallLandingStunTime > 0 then
        return
    end
    local CharacterMovement = self.Owner.pUEActor.CharacterMovement
    local nSpeed = self.nBaseSpeed *  self.nSpeedRatio * (1 + self.rSpeedBuffRatio:Get())
    if self.bIsFrightened then
        nSpeed = nSpeed * self.tbVehicleData.nRunAwaySpeed
    end
    -- logdebug("VehicleMovementComponent OnSpeedChanged", nSpeed, "bIsFrightened", self.bIsFrightened, 
    --   "nBaseSpeed", self.nBaseSpeed, "nSpeedRatio", self.nSpeedRatio, "nWeaponSpeedFactor", self.nWeaponSpeedFactor, "buff", self.rSpeedBuffRatio:Get())
    CharacterMovement.MaxWalkSpeed = nSpeed
    CharacterMovement.MaxSwimSpeed = nSpeed

end

function VehicleMovementComponent:ApplyDamage(tbCauser, nDamageType, nDamage, tbDamageExtraData)
end

function VehicleMovementComponent:ChangeSpeedBuffRatio(nValue)
    local nSpeedBuffRatio =  self.rSpeedBuffRatio:Get() + nValue
    self.rSpeedBuffRatio:Set(nSpeedBuffRatio)
end

function VehicleMovementComponent:OnBuffSpeedChanged(_Property, nNewSpeed)
    self:OnSpeedChanged()
end

function VehicleMovementComponent:Jump()
    local pUEActor = self.Owner.pUEActor
    if not pUEActor then
        return false
    end

    if pUEActor:CheckCanJump(BLOCK_DIST, BLOCK_HEIGHT, MIN_SPEED) then
        pUEActor:ClearRotationInput()
        pUEActor:Jump()
        return true
    else
        if not pUEActor.InStopMontage then
            pUEActor:StopMove(false)
        end
        return false
    end

end

function VehicleMovementComponent:StopMove(bWithMontage)
    if GlobalVariableSystem:IsServerLogic() then
        -- 用于类似读条之类的服务器发起的停止
        self.nStopType:Set(bWithMontage and 2 or 1)
    else
        self.Owner.pUEActor:StopMove(bWithMontage)
    end
end

function VehicleMovementComponent:OnStopTypeChanged(_Property, nStopType)
end

return VehicleMovementComponent