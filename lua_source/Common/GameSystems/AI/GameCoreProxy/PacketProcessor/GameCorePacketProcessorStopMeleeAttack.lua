local luaclass = require("luaclass")
local GameCorePacketProcessorAction = require("GameCorePacketProcessorAction")
local GameCorePacketProcessorStopMeleeAttack = luaclass("GameCorePacketProcessorStopMeleeAttack", GameCorePacketProcessorAction)

local Proto                         = require("GameCoreClientProtoNames")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorStopMeleeAttack:", ...)
end
-- luacheck: pop


function GameCorePacketProcessorStopMeleeAttack:DoAction(tbPacket)
    self:StopAttack()
    self:ReportActionResult(Proto.ActionType.StopAttack, 0)
end


return GameCorePacketProcessorStopMeleeAttack