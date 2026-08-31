local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorPing = luaclass("GameCorePacketProcessorPing", GameCorePacketProcessorBase)

local Proto  = require("GameCoreClientProtoNames")

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorPing:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorPing:Process(tbPacket)
    self.tbGameCoreProxyClient:Send(Proto.c2s_ping, { })
end



return GameCorePacketProcessorPing