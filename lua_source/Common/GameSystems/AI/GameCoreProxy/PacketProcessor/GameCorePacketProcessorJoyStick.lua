local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorJoyStick = luaclass("GameCorePacketProcessorJoyStick", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")

local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorJoyStick.ActorType = GameCoreActionActorType.All

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorJoyStick:", ...)
end
-- luacheck: pop

local function CheckHumanInVehicle(tbGameObject)
    if not tbGameObject then
        return false
    end

    if not tbGameObject:IsHuman() then
        return false
    end

    if not tbGameObject.GameVehicleComponent then
        return false
    end

    return tbGameObject.GameVehicleComponent:IsInVehicle()
end

function GameCorePacketProcessorJoyStick:DoAction(tbPacket)
    local tbAgent = self.tbAgent
    local tbGameObject  = tbAgent:GetGameObject()
    local pAIController = tbAgent.pAIController
    local nId = tbGameObject:GetServerInstanceId()
    if pAIController then
        if CheckHumanInVehicle(tbGameObject) then
            local tbVehicle = tbGameObject.GameVehicleComponent:GetVehicle()
            if tbVehicle then
                if tbVehicle:IsFalling() then
                    self:ReportActionResult(Proto.ActionType.JoyStick, 3)
                else
                    pAIController:AbortMoving()
                    pAIController:SetMoveInput(tbPacket.x, tbPacket.y, tbPacket.speed)
                    self:ReportActionResult(Proto.ActionType.JoyStick, 0)
                end
            else
                self:ReportActionResult(Proto.ActionType.JoyStick, 2)
            end
        elseif not self:IsFalling() then
            if tbGameObject:IsHuman() then
                pAIController:AbortMoving()
                -- local HumanMovementStateComponent = tbGameObject.HumanMovementStateComponent
                -- if HumanMovementStateComponent:IsInVehicle() then
                --     if tbPacket.y ~= 0 then
                --         self:ReportActionResult(Proto.ActionType.JoyStick, 1)
                --         return
                --     end
                -- end
            else
                tbGameObject.pUEActor:AbortNavMove(EMapNavGridPathFollowingResult.Aborted)
            end
            pAIController:SetMoveInput(tbPacket.x, tbPacket.y, tbPacket.speed)
            self:ReportActionResult(Proto.ActionType.JoyStick, 0)
        else
            if tbGameObject:IsHuman() then
                if tbGameObject.GameVehicleComponent then
                    LOG(nId, "vehicle state", tbGameObject.GameVehicleComponent:GetVehicleState(), tbGameObject.GameVehicleComponent.bUseNew)
                else
                    LOG(nId, "GameVehicleComponent is nil")
                end
            else
                LOG(nId, "is not Human")
            end
            self:ReportActionResult(Proto.ActionType.JoyStick, 1)
        end
    end
end


return GameCorePacketProcessorJoyStick