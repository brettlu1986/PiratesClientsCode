local luaclass = require("luaclass")
local GameCorePacketProcessorBase = luaclass("GameCorePacketProcessorBase")

GameCorePacketProcessorBase.tbGameCoreProxyClient = nil
GameCorePacketProcessorBase.szPacketId = nil

function GameCorePacketProcessorBase:Init(szPacketId)
    self.tbGameCoreProxyClient = require("GameCoreProxyClient")
    self.szPacketId = szPacketId
end

function GameCorePacketProcessorBase:Process(tbPacket)
    assert(false, "must be detived")
end

return GameCorePacketProcessorBase