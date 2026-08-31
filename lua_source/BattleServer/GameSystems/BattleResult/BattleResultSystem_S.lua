local luaclass = require("luaclass")
local BattleResultSystem = require("BattleResultSystem")
local BattleResultSystem_S = luaclass("BattleResultSystem_S", BattleResultSystem)
local BattleFFAD2SStatisticHelper = require("BattleFFAD2SStatisticHelper")
local BattleAwardHelper = require("BattleAwardHelper")

function BattleResultSystem_S:Init()
    BattleResultSystem_S.super.Init(self)
end

function BattleResultSystem_S:Uninit()
    BattleResultSystem_S.super.Uninit(self)
end

function BattleResultSystem_S:SendPlayerStatisticsDataToLobby(tbPlayer, nPlayerRank, nExtraScore, nTeamId, tbLobbyRewardsData)
    return BattleFFAD2SStatisticHelper:SendPlayerStatisticsDataToLobby(tbPlayer, nPlayerRank, nExtraScore, nTeamId, tbLobbyRewardsData)
end

function BattleResultSystem_S:SendTeamStatisticsDataToLobby(tbTeamdata, nTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
    return BattleFFAD2SStatisticHelper:SendTeamStatisticsDataToLobby(tbTeamdata, nTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
end

function BattleResultSystem:SaveClientShowAwardsToPacket(tbAwards, tbPacket)
    tbPacket.Awards = BattleAwardHelper:FillClientAwards(tbAwards)
end

return BattleResultSystem_S()