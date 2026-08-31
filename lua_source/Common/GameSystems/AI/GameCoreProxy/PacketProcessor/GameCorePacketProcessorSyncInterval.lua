local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorSyncInterval = luaclass("GameCorePacketProcessorSyncInterval", GameCorePacketProcessorBase)


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorSyncInterval:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorSyncInterval:Process(tbPacket)
    self.tbGameCoreProxyClient:SetSyncInterval(tbPacket.interval)
end



return GameCorePacketProcessorSyncInterval