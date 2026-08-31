local luaclass = require("luaclass")
local PingSystem = require("PingSystem")
local PingSystem_C = luaclass("PingSystem_C", PingSystem)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local DefaultNetworkProxy = require("DefaultNetworkProxy")

function PingSystem_C:InitPingMessage()
    self.tbPing = Proto.Ping
end

function PingSystem_C:GetNetworkProxy()
    return NetworkManager:GetHubServerProxy()
end

function PingSystem_C:OnReadIdleTimeout(nSocketId, nDeltaTime)
    log("ping system OnReadIdleTimeOut ", nSocketId)

    local Socket = self:GetNetworkProxy()
    if Socket:IsConnect(nil, nSocketId) then
        Socket:Disconnect(nil, nSocketId, DefaultNetworkProxy.DisconnectReason.Disconnect_Passivity)
    else
        log("ping system OnReadIdleTimeOut: disconnect")
    end
    
end

return PingSystem_C()