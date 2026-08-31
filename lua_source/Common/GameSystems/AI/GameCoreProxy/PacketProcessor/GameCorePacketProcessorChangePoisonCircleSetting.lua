local luaclass = require("luaclass")
local GameCorePacketProcessorBase = require("GameCorePacketProcessorBase")
local GameCorePacketProcessorChangePoisonCircleSetting = luaclass("GameCorePacketProcessorChangePoisonCircleSetting", GameCorePacketProcessorBase)


-- luacheck: push ignore
local function LOG(...)
    log("CJ->GameCorePacketProcessorChangePoisonCircleSetting:", ...)
end
-- luacheck: pop

function GameCorePacketProcessorChangePoisonCircleSetting:Process(tbPacket)
    self.tbGameCoreProxyClient:ChangePoisonCircleSetting(tbPacket)
end



return GameCorePacketProcessorChangePoisonCircleSetting