local BattleFFAD2SStatisticHelper = {}

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local PlayerStatsHelper = require("PlayerStatsHelper")
local BattleAwardHelper = require("BattleAwardHelper")
local GameResultManager = dynamic_require("GameResultManager")
local BattleItemToLobbyItemDataTable = require("BattleItemToLobbyItemDataTable")

--发到lobby的item id 需要转换一下
local function ChangeRewardIdToLobbyId(tbPlayerStatsAwards, tbAwards)
    if tbAwards == nil then return end
    for _, v in pairs(tbAwards) do
        local tbData = {}
        tbData.count = v.count
        tbData.award_type = v.award_type
        local nLobbyId = BattleItemToLobbyItemDataTable:ToLobbyItemId(v.templateId)
        if nLobbyId ~= -1 then  
            tbData.templateId = nLobbyId
        else  
            tbData.templateId = v.templateId
        end
        table.insert(tbPlayerStatsAwards, tbData)
    end
end

--Return 获得的奖励列表
function BattleFFAD2SStatisticHelper:SendPlayerStatisticsDataToLobby(tbPlayer, nPlayerRank, nExtraScore, nTeamId, tbLobbyRewardsData)
    local nPlayerId = tbPlayer.nPlayerId
    local szPlayerSessionId = tbPlayer.szPlayerSessionId
    local nPlayerToken = tbPlayer.nToken
    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbPlayerStats = PlayerStatsHelper:CreateLobbyPlayerStatisticsData(tbPlayer, nPlayerId, nPlayerRank, nExtraScore,nDungeonId)
    local tbAwards
    if tbPlayerStats ~= nil then
        tbAwards = BattleAwardHelper:GetBattleResultAward(tbPlayer, tbPlayerStats.battle_point, nDungeonId, nPlayerRank, tbLobbyRewardsData)
        tbPlayerStats.awards = {}
        
        ChangeRewardIdToLobbyId(tbPlayerStats.awards, tbAwards)
        GameResultManager:SendPlayerResult(nPlayerId, szPlayerSessionId, nPlayerToken, nTeamId, tbPlayerStats)
    end

    return tbAwards
end

function BattleFFAD2SStatisticHelper:SendTeamStatisticsDataToLobby(tbPlayerList, nTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
    local tbPlayerIdList = {}
    for _, tbPlayer in ipairs(tbPlayerList) do
        table.insert(tbPlayerIdList, tbPlayer.nPlayerId)
    end

    local tbTeamStats = PlayerStatsHelper:CreateLobbyTeamStatisticsData(tbPlayerIdList, nTeamId, nTeamRank, nMVPPlayerId, nPlayerCount, nTeamCount)
    if tbTeamStats ~= nil then
        GameResultManager:SendTeamResult(tbPlayerIdList, nTeamId, nTeamRank, tbTeamStats)
    end
end

return BattleFFAD2SStatisticHelper