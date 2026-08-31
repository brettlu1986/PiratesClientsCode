local luaclass = require("luaclass")
local PingSystem = require("PingSystem")
local PingSystem_S = luaclass("PingSystem_S", PingSystem)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonProtoNames")
local DefaultNetworkProxy = require("DefaultNetworkProxy")

function PingSystem_S:InitPingMessage()
    self.tbPing = Proto.Ping
end

function PingSystem_S:GetNetworkProxy()
    return NetworkManager:GetHubServerProxy()
end

function PingSystem_S:OnReadIdleTimeout(nSocketId, nDeltaTime)
    log("ping system OnReadIdleTimeOut ", nSocketId)

    local Socket = self:GetNetworkProxy()
    if Socket:IsConnect(nil, nSocketId) then
        if nDeltaTime > self.nReadIdleTime then
            -- 解决当副本服务器加载地图时，一帧长达数十秒，在同一帧会调用 connect server，根据虚幻的流程，
            -- 接下来 UTcpSocket::Tick 会触发，PollConnectionState 在同一帧将状态设置为 ETcpSocketState::Connected
            -- 由于该帧长达数十秒，很有可能达到 ReadIdleTimeout 的时间，同样在帧末触发 OnReadIdleTimeOut ，此处避免在该情况下直接断开连接的出现。
            -- 由于正常情况下，一帧的时间不会超过 ReadIdleTimeout 的时间，所以通常情况下，此分支不会走到
            logwarning("OnReadIdleTimeOut with long tick.", nDeltaTime, " seconds. Do NOT disconnect in this round.")
        else
            logwarning("OnReadIdleTimeOut causes disconnect. nSocketId:", nSocketId)
            Socket:Disconnect(nil, nSocketId, DefaultNetworkProxy.DisconnectReason.Disconnect_Passivity)
        end
    else
        log("ping system OnReadIdleTimeOut: disconnect")
    end
end

return PingSystem_S()