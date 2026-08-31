local luaclass = require("luaclass")
local JGMTrainingCampSetting = require("JGMTrainingCampSetting")
local JGMTrainingCampSetting_S = luaclass("JGMTrainingCampSetting_S", JGMTrainingCampSetting)

local BattleKickPlayerReasonDef = require("BattleKickPlayerReasonDef")
local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")

-- 告知服务器这个人状态改回大厅
function JGMTrainingCampSetting_S:OnNotifyPlayerLeaveDungeon(tbPlayer)
    JGMTrainingCampSetting_S.super.OnNotifyPlayerLeaveDungeon(self, tbPlayer)

    local nPlayerId = tbPlayer.nPlayerId
    local szPlayerSessionId = tbPlayer.szPlayerSessionId
    local tbPacket =
    {
        player_id         = nPlayerId,
        reason            = BattleKickPlayerReasonDef.TrainingCampNotifyLeave,
        player_session_id = szPlayerSessionId
    }

    HubSenderManager:Send(HubProto.d2s_PlayerKicked, tbPacket, nPlayerId)
    log("JGMTrainingCampSetting_S Hub Send:PlayerKicked")
end

return JGMTrainingCampSetting_S