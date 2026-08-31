local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorMove = luaclass("GameCorePacketProcessorMove", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")

local GameCoreActionActorType = require("GameCoreActionActorType")

GameCorePacketProcessorMove.ActorType = GameCoreActionActorType.All

local pLocationVector = Vector()

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorMove:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorMove:DoAction(tbPacket)
    local tbAgent = self.tbAgent
    local tbGameObject  = tbAgent:GetGameObject()
    local pAIController = tbAgent.pAIController

    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action move failed: 3.")
            self:ReportActionResult(Proto.ActionType.Move, 3)
            return
        end
    end

    if pAIController then
        if not self:IsFalling() then
            pLocationVector.X = tbPacket.x
            pLocationVector.Y = tbPacket.y
            pLocationVector.Z = tbPacket.z
            pAIController:SetMoveInput(0, 0, 0)
            self:StopAttack()
            if tbGameObject:IsHuman() then
                local pLocation = ExtendBlueprintFunctions.GetAISafePosition(GWorld, pLocationVector, 0, 50000, -10000)
                pLocationVector.Z = pLocation.Z
                destroyUserData(pLocation)
            end

            local nResult = pAIController:MoveTo(pLocationVector)
            if nResult == 0 then
                LOG("Do Action move failed: 1.")
                self:ReportActionResult(Proto.ActionType.Move, 1)
                return
            end
            self:ReportActionResult(Proto.ActionType.Move, 0)
        else
            LOG("Do Action move failed: 2.")
            self:ReportActionResult(Proto.ActionType.Move, 2)
        end
    end
end


return GameCorePacketProcessorMove