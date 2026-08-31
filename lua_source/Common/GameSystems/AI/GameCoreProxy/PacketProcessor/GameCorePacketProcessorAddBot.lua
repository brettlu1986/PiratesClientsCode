local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorAddBot = luaclass("GameCorePacketProcessorAddBot", GameCorePacketProcessorBase)


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorAddBot:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorAddBot:Process(tbPacket)
    self.tbGameCoreProxyClient:AddBot(tbPacket.x, tbPacket.y, tbPacket.z, tbPacket.teamid, tbPacket.auto_teleport)
end



return GameCorePacketProcessorAddBot