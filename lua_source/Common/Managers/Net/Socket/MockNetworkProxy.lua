local luaclass = require("luaclass")
local NetworkProxyBase = require("NetworkProxyBase")
local MockNetworkProxy = luaclass("MockNetworkProxy", NetworkProxyBase)

function MockNetworkProxy:SetProtoFile()
end

function MockNetworkProxy:SendPacket(PacketID, tbPacket)
    log("MockNetworkProxy:SendPacket. Ignore sending. PacketId: ", PacketID)
    return true
end

return MockNetworkProxy