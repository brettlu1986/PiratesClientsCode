local luaclass = require "luaclass"
local NetworkManager = luaclass("NetworkManager")

NetworkManager.HubServerNetProxy = nil
NetworkManager.RPCNetworkProxy = nil
NetworkManager.pTableRef = nil

function NetworkManager:OnRegister()
    local DefaultNetworkProxyClass = require("DefaultNetworkProxy")
    self.HubServerNetProxy = DefaultNetworkProxyClass()
    local RPCNetworkProxyClass = require("RPCNetworkProxy")
    self.RPCNetworkProxy = RPCNetworkProxyClass()
end

function NetworkManager:Init()
    self.pTableRef = luaholder(exposetable({}))
    local Shell = CommonShell.GetCommon(GWorld)
    self.RPCNetworkProxy:Init(Shell:GetRPCNetworkManager())
    return true
end

function NetworkManager:Uninit()
    self.HubServerNetProxy:Uninit()
    self.RPCNetworkProxy:Uninit()
    self.HubServerNetProxy = nil
    self.RPCNetworkProxy = nil
    self.pTableRef = nil
end

function NetworkManager:GetHubServerProxy()
    return self.HubServerNetProxy
end

function NetworkManager:GetRPCNetworkProxy()
    return self.RPCNetworkProxy
end

function NetworkManager:SetPending(bPending)
    if self.HubServerNetProxy then
        self.HubServerNetProxy:SetPending(bPending)
    end
    if self.RPCNetworkProxy then
        self.RPCNetworkProxy:SetPending(bPending)
    end
end

function NetworkManager:ClearRPCPendingPackets()
    if(self.RPCNetworkProxy) then
        self.RPCNetworkProxy:ClearPendingPackets()
    end
end

return NetworkManager()
