local luaclass = require("luaclass")
local NetworkManagerClass = require("NetworkManager")
local NetworkManager_S = luaclass("NetworkManager_S", NetworkManagerClass)

-- local CommonEventDef       = require("CommonEventDef")
-- local EventManager         = require("EventManager")

local szProtoFile = "GameDataGenerated/protos/dungeon.pb"

function NetworkManager_S:OnRegister()
    NetworkManager_S.super.OnRegister(self)
    if not ServerShell.GetServer(GWorld):IsDungeonWithHub() then
        local MockNetworkProxyClass = require("MockNetworkProxy")
        self.HubServerNetProxy = MockNetworkProxyClass()
    end
end

function NetworkManager_S:Init()
    NetworkManager_S.super.Init(self)
    log("NetworkManager_S Init")
    local Shell = ServerShell.GetServer(GWorld)

    local HubServerNetProxy = self.HubServerNetProxy
    HubServerNetProxy:Init(Shell:GetDungeonNetManager())
    HubServerNetProxy:SetProtoFile(szProtoFile)
    HubServerNetProxy:BindDisconnected(self, self.OnDisconnectedWithHub)

    local RPCNetworkProxy = self.RPCNetworkProxy
    RPCNetworkProxy:SetProtoFile(szProtoFile)
    RPCNetworkProxy.bCheckDispatchSender = true
    return true
end

function NetworkManager_S:Uninit()
    NetworkManager_S.super.Uninit(self)
end

function NetworkManager_S:OnDisconnectedWithHub()
    log("NetworkManager_S:OnDisconnectedWithHub")
    -- Add FireEvent here if other modules care this event.
    -- EventManager:OnFireEvent(CommonEventDef.EV_ON_DISCONNECT_WITH_HUB)
    -- local kickedCount = ServerShell.GetServer(GWorld):KickAllPlayers();
    -- log("Kicked", kickedCount, " players from dungeon.")
    -- EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_RELEASE_DUNGEON)
end

return NetworkManager_S()
