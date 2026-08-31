local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorToggleGameSpeed = luaclass("GameCorePacketProcessorToggleGameSpeed", GameCorePacketProcessorBase)


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorToggleGameSpeed:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorToggleGameSpeed:Process(tbPacket)
    self.tbGameCoreProxyClient:ToggleGameSpeed(tbPacket.speed)
end



return GameCorePacketProcessorToggleGameSpeed