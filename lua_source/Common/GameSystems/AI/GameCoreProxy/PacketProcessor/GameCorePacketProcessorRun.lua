local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorRun = luaclass("GameCorePacketProcessorRun", GameCorePacketProcessorAction)

local Proto  = require("GameCoreClientProtoNames")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorRun:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorRun:DoAction(tbPacket)
    local tbGameObject = self.tbAgent:GetGameObject()
    if tbGameObject:IsHuman() then
        if not self:CanChangeMovementState() then
            LOG("Do Action run failed: 1.")
            self:ReportActionResult(Proto.ActionType.Run, 1)
            return
        end
        tbGameObject.HumanMovementStateComponent:SetRun(tbPacket.run)
        self:ReportActionResult(Proto.ActionType.Run, 0)
    end
end


return GameCorePacketProcessorRun