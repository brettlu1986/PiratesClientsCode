local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorFocus = luaclass("GameCorePacketProcessorFocus", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorFocus:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorFocus:DoAction(tbPacket)
    local nPitch = tbPacket.pitch
    local nYaw = tbPacket.yaw
    local pAIController = self.tbAgent.pAIController
    local tbGameObject = self.tbAgent:GetGameObject()

    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action focus failed: 1.")
            self:ReportActionResult(Proto.ActionType.Focus, 1)
            return
        end
    end

    if pAIController then
        pAIController:Focus(nPitch, nYaw)
        self:ReportActionResult(Proto.ActionType.Focus, 0)
    end
end


return GameCorePacketProcessorFocus