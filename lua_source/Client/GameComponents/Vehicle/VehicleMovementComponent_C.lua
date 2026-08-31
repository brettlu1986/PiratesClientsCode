local luaclass = require("luaclass")
local VehicleMovementComponent = require("VehicleMovementComponent")
local VehicleMovementComponent_C = luaclass("VehicleMovementComponent_C", VehicleMovementComponent)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local ENUM_JumpMode = {
    HideJump = 0,
    Jump = 1,
    Stop = 2,
}

VehicleMovementComponent_C.nJumpMode = 2

local function OnMoveStopped(self, Actor, pVehicleActor)
    if not Actor then
        return
    end
    local pPlayer = GamePlayerSelfHelper:Get().pUEActor
    if pPlayer ~= Actor then  
        return 
    end 
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_MOVE_STOPPED, pVehicleActor)
end

local function OnJumpModeChanged(self, nJumpMode)
    self.nJumpMode = nJumpMode
    if self.Owner.bDriving then
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_JUMP_MODE_CHANGED, nJumpMode)
    end
end

function VehicleMovementComponent_C:OnActorCreated(pUEActor)
    VehicleMovementComponent_C.super.OnActorCreated(self, pUEActor)
    self.EventHelper:RegisterCppDelegate(pUEActor.OnMoveStopped, self, OnMoveStopped)
    self.EventHelper:RegisterCppDelegate(pUEActor.OnJumpModeChanged, self, OnJumpModeChanged)
end

function VehicleMovementComponent_C:Jump()
    local pUEActor = self.Owner.pUEActor
    if not pUEActor then
        return
    end

    if self.nJumpMode == ENUM_JumpMode.HideJump then
        return
    elseif self.nJumpMode == ENUM_JumpMode.Jump then
        pUEActor:ClearRotationInput()
        pUEActor:Jump()
    elseif self.nJumpMode == ENUM_JumpMode.Stop then
        pUEActor:StopMove(true)
    end
end

function VehicleMovementComponent_C:OnStopTypeChanged(_Property, nStopType)
    local pUEActor = self.Owner.pUEActor
    if nStopType == 1 then
        pUEActor:StopMove(false)
    elseif nStopType == 2 then
        pUEActor:StopMove(true)
    end
end

return VehicleMovementComponent_C