-- Used to build packet. Use hub player id instead of global player id to establish message package.
local luaclass = require "luaclass"
local HubSenderManager_S = luaclass("HubSenderManager_S")

local NetworkManager = dynamic_require("NetworkManager")
local NetPlayerManager = require("NetPlayerManager_S")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BotAISystem = dynamic_require("BotAISystem")

--local Proto = require("DungeonProtoNames")

function HubSenderManager_S:OnRegister()
end

function HubSenderManager_S:Init()
    log("HubSenderManager_S Init")
    return true
end

function HubSenderManager_S:Multicast(szProto, tbPacket)
    local tbSocketIds = NetPlayerManager:GetAllSocketIds()
    for i,SocketId in ipairs(tbSocketIds) do
        NetworkManager:GetHubServerProxy():SendPacket(szProto, tbPacket, SocketId)
    end
end

function HubSenderManager_S:Send(szProto, tbPacket, nPlayerId)
    local nSocketId = NetPlayerManager:GetSocketId(nPlayerId)
    if nSocketId ~= nil then
        NetworkManager:GetHubServerProxy():SendPacket(szProto, tbPacket, nSocketId)
    else
        local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
        if (not tbPlayer) or (not BotAISystem:IsBot(tbPlayer)) then
            logwarning("Proto ", szProto, " send failed. SocketId related to nPlayerId ", nPlayerId, " not found. tbPlayer:", tbPlayer)
        end
    end
end

function HubSenderManager_S:SendbySocketId(szProto, tbPacket, nSocketId)
    NetworkManager:GetHubServerProxy():SendPacket(szProto, tbPacket, nSocketId)
end

function HubSenderManager_S:Uninit()
end

return HubSenderManager_S()