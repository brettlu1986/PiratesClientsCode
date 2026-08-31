local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorJump = luaclass("GameCorePacketProcessorJump", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")
local HumanMovementStateType  = require("HumanMovementStateType")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorJump.ActorType = GameCoreActionActorType.All

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorJump:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorJump:DoAction(tbPacket)
    local tbGameObject  = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() and not self:IsFalling() then

        local HumanMovementStateComponent = tbGameObject.HumanMovementStateComponent
        local nVehicleInstanceId = HumanMovementStateComponent:GetVehicleInstanceId(false)
        if nVehicleInstanceId > 0 then
            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
            local VehicleMovementComponent = tbVehicle.VehicleMovementComponent
            if not VehicleMovementComponent:Jump() then
                LOG("Do Action jump failed: 3.")
                self:ReportActionResult(Proto.ActionType.Jump, 3)
                return
            end
        else
            if not self:CanChangeMovementState() or not HumanMovementStateComponent.bEnableMove then
                LOG("Do Action jump failed: 1.")
                self:ReportActionResult(Proto.ActionType.Jump, 1)
                return
            end
            local nMovementState = HumanMovementStateComponent.rMovementState
            if nMovementState == HumanMovementStateType.Crouch_State or
            nMovementState == HumanMovementStateType.Crawl_State then
                LOG("Do Action jump failed: 2.")
                HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
                self:ReportActionResult(Proto.ActionType.Jump, 2)
                return
            end
            tbGameObject.pUEActor:Jump()
        end
    end
end


return GameCorePacketProcessorJump