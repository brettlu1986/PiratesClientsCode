-- 显示Actor Component

local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase") 
local BattleHumanMovementComponent = luaclass("BattleHumanMovementComponent", GameComponentBaseClass)
local HumanVehicleHelper = require("HumanVehicleHelper")
local HumanMovementIni = require("HumanMovementIni")

BattleHumanMovementComponent.pMovementComponent = nil

function BattleHumanMovementComponent:OnCreate(Owner, tbParams)
    BattleHumanMovementComponent.super.OnCreate(self, Owner, tbParams)
    return true
end

function BattleHumanMovementComponent:OnActorCreated(pUEActor)
    BattleHumanMovementComponent.super.OnActorCreated(self, pUEActor)

    local pComponent = pUEActor.CharacterMovement
    if(pComponent and pComponent.InitData) then
        local HumanMovementConfig = HumanMovementConfig()
        local MovementParams = HumanMovementIni.tbMovementParams
        HumanMovementConfig.SafeTeleportMinDistance = MovementParams.nSafeTelePortMinDistance
        HumanMovementConfig.SafeTeleportMaxDistance = MovementParams.nSafeTelePortMaxDistance
        self.pMovementComponent = pUEActor.CharacterMovement

        local HumanFallConfig = HumanFallConfig()
        local tbFallParams = HumanMovementIni.tbDefaultFallParams
        HumanFallConfig.AirDragCoefficient = tbFallParams.nAirDragCoefficient
        HumanFallConfig.LateralAcceleration = tbFallParams.nLateralAcceleration
        HumanFallConfig.DefaultOriginSpeed = tbFallParams.nDefaultOriginSpeed
        HumanFallConfig.LandStunTime = tbFallParams.nLandStunTime
        HumanFallConfig.LandStunSpeedPreservation = tbFallParams.nLandStunSpeedPreservation
        HumanFallConfig.JumpLateralSpeedRatio = tbFallParams.nJumpLateralSpeedRatio
        HumanFallConfig.JumpZVelocity = tbFallParams.nJumpZVelocity
        HumanFallConfig.CustomGravityScale = tbFallParams.nCustomGravityScale

        pComponent:InitData(HumanMovementConfig, HumanFallConfig)
    end
end

function BattleHumanMovementComponent:OnActorDestroyed(pUEActor)
    BattleHumanMovementComponent.super.OnActorDestroyed(self, pUEActor)
end

function BattleHumanMovementComponent:TeleportToSafeLocation()
    if self.pMovementComponent then
        HumanVehicleHelper.ClearVehicle(self.Owner)
        self.pMovementComponent:TeleportToSafeLocation()
    end
end

return BattleHumanMovementComponent