local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorResetDungeon = luaclass("GameCorePacketProcessorResetDungeon", GameCorePacketProcessorBase)

-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorResetDungeon:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorResetDungeon:Process(tbPacket)
    self.tbGameCoreProxyClient:ResetDungeon()
end



return GameCorePacketProcessorResetDungeon