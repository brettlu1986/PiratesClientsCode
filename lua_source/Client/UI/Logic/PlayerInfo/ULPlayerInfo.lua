-----------------------------------------------------
--File Name    : ULPlayerInfo.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 8:35:24 PM
--Description  : ULPlayerInfo
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULPlayerInfo = luaclass("ULPlayerInfo", UILogicBase)
local ClientEventDef = require("ClientEventDef")
local PlayerInfoSystem = require("PlayerInfoSystem")
local FriendSystem = require("FriendSystem")
local SeasonSystem = require("SeasonSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- local UISetUtils = require("UISetUtils")
local Proto = require("ClientProtoNames")
local SeasonIni = require("SeasonIni")

local BASIC_INFO = 1
-- local SCORE_STATISTIC = 2
-- local RECENT_GAME_SCORE = 3

ULPlayerInfo.BasicInfoDataReceivedCallback = nil

ULPlayerInfo.tbCacheInfo = {}

local function OnBasicInfoDataReceived(self, tbBasicInfo)
    local nPlayerId = tbBasicInfo.nPlayerId
    if self:GetTargetPlayerId() ~= nPlayerId then
        return
    end
    self.tbCacheInfo[BASIC_INFO] = tbBasicInfo
    local BasicInfoDataReceivedCallback = self.BasicInfoDataReceivedCallback
    if not BasicInfoDataReceivedCallback then
        return
    end
    BasicInfoDataReceivedCallback(tbBasicInfo)
end


local function GetSelfSeasonData(SeasonComponent)
    local tbSeason = {}
    tbSeason.season_battle_pass = {}
    if SeasonComponent ~= nil and SeasonComponent:GetBattlePass() ~= nil then
        tbSeason.battle_tier = SeasonComponent:GetBattlePass().battle_tier
        tbSeason.season_point_ranking = SeasonComponent.tbSeasonSummary.season_point_ranking
        tbSeason.season_participants = SeasonComponent.tbSeasonSummary.season_participants
        tbSeason.record_high_rank = SeasonComponent.tbSeasonSummary.record_high_rank
        tbSeason.record_high_rank_count = SeasonComponent.tbSeasonSummary.record_high_rank_count
        tbSeason.record_high_rank_point = SeasonComponent.tbSeasonSummary.record_high_rank_point > 0 and SeasonComponent.tbSeasonSummary.record_high_rank_point or SeasonIni.tbRank.nDefaultStarRankPoint 
        tbSeason.season_rank = SeasonComponent:GetCurRank()
        tbSeason.season_point = SeasonComponent.tbSeasonSummary.season_point
        tbSeason.active_battle_pass = SeasonComponent:IsPassActive()
    else
        log("not find self season component")
        tbSeason.battle_tier = 1
        tbSeason.record_high_rank = 1
        tbSeason.record_high_rank_count = 1
        tbSeason.record_high_rank_point = SeasonIni.tbRank.nDefaultStarRankPoint
        tbSeason.season_point_ranking = 0
        tbSeason.season_participants = 0
        local tbRank = {}
        for i = 1, 3 do
            local nMode = i == 3 and 4 or i
            table.insert(tbRank, {mode = nMode, rank = 11, rank_point = 0, rank_protect = 0})
        end
        tbSeason.season_rank = {rank_daily_chest = 0, rank = tbRank}
        tbSeason.season_point = 0
        tbSeason.active_battle_pass = false
    end
    return tbSeason
end

local function FillSeasonBasicInfoFromSeasonSummary(nPlayerId, tbSeasonSummary)
    local tbBasicInfo = {}
    local tbBestRank = {}
    tbBestRank.nRank = tbSeasonSummary.record_high_rank
    tbBestRank.nRankPoint = tbSeasonSummary.record_high_rank_point
    tbBasicInfo.tbBestRank = tbBestRank
    tbBasicInfo.nBestRankCount = tbSeasonSummary.record_high_rank_count
    tbBasicInfo.nPointRanking = tbSeasonSummary.season_point_ranking
    tbBasicInfo.nParticipants = tbSeasonSummary.season_participants
    tbBasicInfo.nBattleTier = tbSeasonSummary.battle_tier

    local tbCurrentRank = tbSeasonSummary.season_rank.rank
    local tbCurrentRankInfo = {}
    for _, tbRank in ipairs(tbCurrentRank) do
        local tbModeInfo = {}
        tbModeInfo.nRank = tbRank.rank
        tbModeInfo.nMode = tbRank.mode
        tbModeInfo.nRankPoint = tbRank.rank_point
        tbCurrentRankInfo[tbRank.mode] = tbModeInfo
    end
    tbBasicInfo.tbCurrentRank = tbCurrentRankInfo
    tbBasicInfo.nSeasonPoint = tbSeasonSummary.season_point
    tbBasicInfo.bBattlePassActive = tbSeasonSummary.active_battle_pass
    tbBasicInfo.nPlayerId = nPlayerId
    return tbBasicInfo
end

local function OnSeasonSummaryReceived(self, nPlayerId, tbSeasonSummary)
    local tbSeasonBasicInfo = FillSeasonBasicInfoFromSeasonSummary(nPlayerId, tbSeasonSummary)
    self.EventHelper:FireEvent(ClientEventDef.EV_PLAYER_SEASON_BASIC_INFO_RECEIVED, tbSeasonBasicInfo)
end


function ULPlayerInfo:SetBasicInfoDataReceivedCallback(fnCallback)
    self.BasicInfoDataReceivedCallback = fnCallback
end

-- 可能返回nil，此时请等待BasicInfoDataReceivedCallback的回调
function ULPlayerInfo:GetPlayerBasicInfo(nPlayerId)
    if nPlayerId ~= self:GetTargetPlayerId() then
        logerror("ULPlayerInfo", "GetPlayerBasicInfo, player id not match!")
        return
    end
    local tbCacheInfo = self.tbCacheInfo[BASIC_INFO]
    if tbCacheInfo then
        return tbCacheInfo
    end
    local tbBasicInfo = PlayerInfoSystem:GetPlayerBasicInfo(nPlayerId)
    return tbBasicInfo
end

function ULPlayerInfo:GetPlayerSeasonBasicInfo(nPlayerId)
    if nPlayerId ~= self:GetTargetPlayerId() then
        logerror("ULPlayerInfo", "GetPlayerSeasonBasicInfo, player id not match!")
        return
    end

    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:GetPlayerId() == nPlayerId then
        local tbSeasonComponent = tbPlayer.SeasonComponent
        local tbSeason = GetSelfSeasonData(tbSeasonComponent)
        local tbBasicInfo = FillSeasonBasicInfoFromSeasonSummary(nPlayerId, tbSeason)
        return tbBasicInfo
    else
        SeasonSystem:RequestToGetSeasonSummary(nPlayerId)
        return nil
    end
end

function ULPlayerInfo:GetTargetPlayerId()
    local nPlayerId = self.Owner.nPlayerId
    if not nPlayerId then
        logerror("ULPlayerInfo:GetTargetPlayerId(), player id is nil!")
    end
    return nPlayerId
end

function ULPlayerInfo:RequestToAddFriend(nPlayerId, szApplyMsg)
    FriendSystem:RequestApplyFriend(nPlayerId, szApplyMsg, Proto.FriendSource.PLAYER_INFO)
end

----------life cycle----------
-- function ULPlayerInfo:OnCreate()
-- end

-- function ULPlayerInfo:OnDestroy()
-- end

-- function ULPlayerInfo:OnLoad()
-- end

-- function ULPlayerInfo:OnUnload()
-- end

function ULPlayerInfo:OnEnter()
    self.tbCacheInfo = {}
end

-- function ULPlayerInfo:OnShow()
-- end

-- function ULPlayerInfo:OnHide()
-- end

function ULPlayerInfo:OnExit()
    self.tbCacheInfo = {}
end

function ULPlayerInfo:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_OTHER_PLAYER_BASIC_INFO_RECEIVED, self, OnBasicInfoDataReceived)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SEASON_SUMMARY_RECEIVED, self, OnSeasonSummaryReceived)
end

-- function ULPlayerInfo:OnUnbindEvent( EventHelper )
-- end

return ULPlayerInfo