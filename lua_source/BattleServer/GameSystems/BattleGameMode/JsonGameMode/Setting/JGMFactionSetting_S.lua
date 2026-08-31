local luaclass = require("luaclass")
local JGMFactionSetting = require("JGMFactionSetting")
local JGMFactionSetting_S = luaclass("JGMFactionSetting_S", JGMFactionSetting)
local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")

-- 增加阵营点
function JGMFactionSetting_S:PlayerAddFactionPoint(tbPlayer, point)
    local nPlayerId = tbPlayer.nPlayerId
    local tbPacket = 
    {
        player_id = nPlayerId,
        faction_point = point
    }
    HubSenderManager:Send(HubProto.d2s_PlayerAddFactionPoint, tbPacket, nPlayerId)
end

-- 告知服务器副本开始
function JGMFactionSetting_S:FactionDungeonBegin()
    local tbPacket = {}
    HubSenderManager:Multicast(HubProto.d2s_GameStart, tbPacket)
end


return JGMFactionSetting_S