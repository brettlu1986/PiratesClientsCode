local luaclass = require "luaclass"
local GameResultManager_S = luaclass("GameResultManager_S")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonLobbyProtoNames")
local HttpHelper = require("HttpHelper")
local Json = require("dkjson")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")

local szSavePlayerStatsUrl = nil
local szSaveTeamRankUrl = nil

function GameResultManager_S:Init()
    log("GameResultManager_S Init")
    szSavePlayerStatsUrl = ServerShell.GetServer(GWorld):GetHistoryServiceSavePlayerStatsUrl();
    szSaveTeamRankUrl = ServerShell.GetServer(GWorld):GetHistoryServiceSaveTeamRankUrl();
    log("Init player game result service url to:", szSavePlayerStatsUrl)
    log("Init team game result service url to:", szSaveTeamRankUrl)
    return true
end

function GameResultManager_S:Uninit()
    log("GameResultManager_S Uninit")
end

-- tbPlayerStatsPacket 结构为 DungeonLobbyProtoNames.PlayerStats 
function GameResultManager_S:SendPlayerResult(nPlayerId, szPlayerSessionId, nPlayerToken, nTeamId, tbPlayerStatsPacket)
    local szPlayerStats = NetworkManager:GetHubServerProxy():MessageToBase64String(Proto.PlayerStats, tbPlayerStatsPacket)

    local szDungeonSessionId = BattleGameModeSystem:GetDungeonSessionId()
    -- local nDungeonTemplateId = BattleGameModeSystem.nDungeonId
    -- local nDungeonStartTime = GlobalVariableSystem_S:GetStartTime()
    local nTeamMode = BattleGameModeSystem:GetGameInitData().nTeamModeId
    local nBattleTime = BattleDataStatisticsSystem:GetCombatProperty(PropertyDef.DUNGEONBEGINTIME) or 0

    local tbPostBody = {
        dungeonId = szDungeonSessionId,
        -- dungeonTemplateId = nDungeonTemplateId,
        -- dungeonStartTime = nDungeonStartTime,
        playerId = nPlayerId,
        playerSessionId = szPlayerSessionId,
        playerToken = nPlayerToken,
        teamMode = nTeamMode,
        teamId = nTeamId,
        battleTime = nBattleTime,
        stats = szPlayerStats
    }

    -- FOR DEBUG PURPOSE. OUTPUT POST BODY.
    log("GameResultManager_S:SendPlayerResult post player result to", szSavePlayerStatsUrl)
    local BaseUtil = require("BaseUtil")
    BaseUtil:PrintTable(tbPostBody)

    local bRet = HttpHelper:SendPostRequest(szSavePlayerStatsUrl, "Content-Type", "application/json", Json.encode(tbPostBody),
        function(nRetCode, szContent)
            if nRetCode == HttpHelper.HttpResponseCodes.OK then
                log("GameResultManager_S post player game result success.", szContent)
            else
                log("GameResultManager_S post player game result fail. Return code:", nRetCode)
            end
        end)
    if not bRet then
        log("GameResultManager_S post player game result fail.")
    end
end

-- tbPlayerIds 为 PlayerId 的 List
-- tbTeamStatsPacket 结构为 DungeonLobbyProtoNames.TeamStats 
function GameResultManager_S:SendTeamResult(tbPlayerIds, nTeamId, nTeamRank, tbTeamStatsPacket)
    local szTeamStats = NetworkManager:GetHubServerProxy():MessageToBase64String(Proto.TeamStats, tbTeamStatsPacket)

    local szDungeonSessionId = BattleGameModeSystem:GetDungeonSessionId()
    -- local nDungeonTemplateId = BattleGameModeSystem.nDungeonId
    -- local nDungeonStartTime = GlobalVariableSystem_S:GetStartTime()
    local nTeamMode = BattleGameModeSystem:GetGameInitData().nTeamModeId

    local tbPostBody = {
        dungeonId = szDungeonSessionId,
        -- dungeonTemplateId = nDungeonTemplateId,
        -- dungeonStartTime = nDungeonStartTime,
        playerIds = tbPlayerIds,
        teamMode = nTeamMode,
        teamRank = nTeamRank,
        teamId = nTeamId,
        stats = szTeamStats
    }

    -- FOR DEBUG PURPOSE. OUTPUT POST BODY.
    log("GameResultManager_S:SendTeamResult post team result to", szSaveTeamRankUrl)
    local BaseUtil = require("BaseUtil")
    BaseUtil:PrintTable(tbPostBody)

    local bRet = HttpHelper:SendPostRequest(szSaveTeamRankUrl, "Content-Type", "application/json", Json.encode(tbPostBody),
        function(nRetCode, szContent)
            if nRetCode == HttpHelper.HttpResponseCodes.OK then
                log("GameResultManager_S post team game result success.", szContent)
            else
                log("GameResultManager_S post team game result fail. Return code:", nRetCode)
            end
        end)
    if not bRet then
        log("GameResultManager_S post team game result fail.")
    end
end

return GameResultManager_S()
