local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorDirectMove = luaclass("GameCorePacketProcessorDirectMove", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")

local pLocationVector = Vector()

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorDirectMove:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorDirectMove:DoAction(tbPacket)
    local tbAgent = self.tbAgent
    local tbGameObject = tbAgent:GetGameObject()
    local pAIController = tbAgent.pAIController
    --self:StopRun()

    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action direct move failed: 3.")
            self:ReportActionResult(Proto.ActionType.DirectMove, 3)
            return
        end
    end

    if pAIController then
        if not self:IsFalling() then
            pAIController:SetMoveInput(0, 0, 0)
            self:StopAttack()
            pLocationVector.X = tbPacket.x
            pLocationVector.Y = tbPacket.y
            pLocationVector.Z = tbPacket.z
            local nResult = pAIController:DirectMoveTo(pLocationVector)
            if nResult == 0 then
                LOG("Do Action direct move failed: 1.")
                self:ReportActionResult(Proto.ActionType.DirectMove, 1)
                return
            end
            self:ReportActionResult(Proto.ActionType.DirectMove, 0)
        else
            LOG("Do Action direct move failed: 2.")
            self:ReportActionResult(Proto.ActionType.DirectMove, 2)
        end
    end

end


return GameCorePacketProcessorDirectMove