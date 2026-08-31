local luaclass = require "luaclass"
local NetworkManagerClass = require "NetworkManager"
local NetworkManager_C = luaclass("NetworkManager_C", NetworkManagerClass)

local szProtoFile = "GameDataGenerated/protos/client.pb"
local szNewProtoFile = "GameDataGenerated/protos/client2.pb"

function NetworkManager_C:OnRegister()
    NetworkManager_C.super.OnRegister(self)
end

function NetworkManager_C:Init()
    NetworkManager_C.super.Init(self)

    local Shell = ClientShell.GetClient(GWorld)
    self.HubServerNetProxy:Init(Shell:GetClientNetworkManager())

    -- GlobalVariableSystem有依赖net，所以这里延迟require了
    local szFile
    if(require("GlobalVariableSystem_C").bEnableNewLobbyServer) then
        szFile = szNewProtoFile
    else
        szFile = szProtoFile
    end
    self.HubServerNetProxy:SetProtoFile(szFile)
    self.RPCNetworkProxy:SetProtoFile(szFile)
    return true
end

function NetworkManager_C:Uninit()
    NetworkManager_C.super.Uninit(self)
end

return NetworkManager_C()
