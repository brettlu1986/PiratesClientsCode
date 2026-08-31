local luaclass = require("luaclass")
local JGMFFASetting = require("JGMFFASetting")
local JGMFFASetting_S = luaclass("JGMFFASetting_S", JGMFFASetting)

local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")

-- local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

-- 告知服务器副本准备阶段结束，不能再进玩家
function JGMFFASetting_S:OnFFAWaitStageEnd()
    JGMFFASetting_S.super.OnFFAWaitStageEnd(self)

    local tbPacket = {}
    HubSenderManager:Multicast(HubProto.d2s_StopAcceptingNewPlayers, tbPacket)
end

function JGMFFASetting_S:OnFFAResult(tbPlayer)
    JGMFFASetting_S.super.OnFFAResult(self, tbPlayer)

    -- local tbPacket = {}
    -- tbPacket.win_player_id = nPlayerId
    -- tbPacket.type = BattleGameModeSystem:GetGameInitData().type
    -- HubSenderManager:Multicast(HubProto.d2s_FFAResult, tbPacket)
end

function JGMFFASetting_S:OnApproveLogin(szOptions)
--[[ 网络重连需要支持
    if not self:IsWaitStage() then
        return "Waiting Step Ended, Login Rejected."
    end
]]
    return ""
end

return JGMFFASetting_S