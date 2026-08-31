-----------------------------------------------------
--File Name    : SeasonComponent.lua
--Author       : Chen Jing
--Create Time  : 2019-03-13
--Description  : 赛季系统的客户端
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local SeasonComponent = luaclass("SeasonComponent", GameComponentBase)
local BattleTierDataTable = require("BattleTierDataTable")
local TimeUtil = require("TimeUtil")
local BitHelper = require("BitHelper")
local BattleTierRewardDataTable = require("BattleTierRewardDataTable")
----------------------------------------------------------------------------------
SeasonComponent.tbSeasonPrimary = nil
SeasonComponent.nStartTime = nil --赛季开始时间
SeasonComponent.tbSeasonSummary = nil
SeasonComponent.tbBattlePass = nil
SeasonComponent.tbCurRank = nil
SeasonComponent.tbLastRank = nil
SeasonComponent.tbStats = nil --赛季战绩统计
SeasonComponent.tbChallenge = nil --挑战
SeasonComponent.nCurWeek = nil
SeasonComponent.tbChallengeAwardStatus = nil
SeasonComponent.tbHistorySummaries = nil

local MAX_TIER = 100
local MAX_INT = 32

local function GetMaxBattleTier()
    local tbContainer = BattleTierDataTable:GetContainer()
    local nTier = 0
    for k, v in pairs(tbContainer) do
        if k > nTier then
            nTier = k
        end
    end
    return nTier
end

-- local function GetStartTime(nSeasonId)
--     local tbSeasonData = SeasonDataTable:GetTemplate(nSeasonId)
--     if tbSeasonData == nil then
--         logerror("SeasonComponent get season start time failed: invalid season :", nSeasonId)
--         return 0
--     end
--     return tbSeasonData.nStartTime
-- end

local function GetBattleTierAwards(tbAwards)
    local tbResult = {}
    local nCount = 0
    for _, v in ipairs(tbAwards) do
        for i = 1, MAX_INT do
            nCount = nCount + 1
            local nValue = BitHelper:GetBit(v, i)
            -- log("season battle tier award ", nCount, nValue)
            table.insert(tbResult, nValue)

            if nCount >= MAX_TIER then
                break
            end
        end
        if nCount >= MAX_TIER then
            break
        end
    end
    for i = #tbResult, MAX_TIER do
        table.insert(tbResult, 0)
    end

    return tbResult
end

function SeasonComponent:OnCreate(Owner, tbParams)
    log("SeasonComponent:OnCreate")
    SeasonComponent.super.OnCreate(self, Owner, tbParams)
    self.tbSeasonPrimary = tbParams
    -- self.nStartTime = GetStartTime(tbParams.season_id)
    self.nStartTime = tbParams.season_start_time
    self.tbChallenge = {}
    self.tbChallengeAwardStatus = {}
end

function SeasonComponent:OnDestroy()
    log("SeasonComponent:OnDestroy")

    SeasonComponent.super.OnDestroy(self)
end

function SeasonComponent:SetSeasonSummary(tbSeasonSummary)
    self.tbSeasonSummary = {
        season_point = tbSeasonSummary.season_point,
        season_point_ranking = tbSeasonSummary.season_point_ranking,
        season_participants = tbSeasonSummary.season_participants,
        record_high_rank = tbSeasonSummary.record_high_rank,
        record_high_rank_count = tbSeasonSummary.record_high_rank_count,
        record_high_rank_point = tbSeasonSummary.record_high_rank_point
    }
    self:SetCurSeasonRank(tbSeasonSummary.season_rank)
end

function SeasonComponent:SetSeasonPointRanking(nPointRanking, nParticipants)
    if self.tbSeasonSummary ~= nil then
        self.tbSeasonSummary.season_point_ranking = nPointRanking
        self.tbSeasonSummary.season_participants = nParticipants
    else
        log("SetSeasonPointRanking not season summary")
    end
end

function SeasonComponent:SetSeasonBattlePass(tbSeasonBattlePass)
    self.tbBattlePass = tbSeasonBattlePass
    self.tbSeasonPrimary.active_battle_pass = tbSeasonBattlePass.is_active
    self.tbBattlePass.battle_max_tier = GetMaxBattleTier()
    self.tbBattlePass.battle_tier_award_status = GetBattleTierAwards(tbSeasonBattlePass.battle_tier_award_status)
end

function SeasonComponent:SetSeasonChallenge(tbSeasonChallenge)
    self.tbChallenge[tbSeasonChallenge.type] = tbSeasonChallenge
end

function SeasonComponent:ClearSeasonChallenge()
    self.tbChallenge = {}
end

function SeasonComponent:SetNewSeasonStatus(status)
    self.tbSeasonPrimary.status = status
end

local function SortRank(tbRank)
    local fnSort = function(a, b)
        if a.mode < b.mode then
            return true
        else
            return false
        end
    end
    table.sort(tbRank, fnSort)
end

function SeasonComponent:SetCurSeasonRank(tbSeasonRank)
    SortRank(tbSeasonRank.rank)
    self.tbCurRank = tbSeasonRank
end

function SeasonComponent:SetLastSeasonRank(tbSeasonRank)
    SortRank(tbSeasonRank.rank)
    self.tbLastRank = tbSeasonRank
end

function SeasonComponent:SetRankMode(tbRank)
    local tbRankMode, nIndex = self:GetCurRankByMode(tbRank.mode)
    if tbRankMode then
        self.tbCurRank.rank[nIndex] = tbRank
    end
end

function SeasonComponent:SetSeasonPoint(nSeasonPoint)
    if self.tbSeasonSummary ~= nil then
        self.tbSeasonSummary.season_point = nSeasonPoint
    else
        logerror("SeasonComponent:SetSeasonPoint not season summary")
    end
end

function SeasonComponent:GetSeasonId()
    return self.tbSeasonPrimary.season_id
end

function SeasonComponent:GetStartTime()
    return self.nStartTime
end

function SeasonComponent:IsPassActive()
    return self.tbSeasonPrimary.active_battle_pass
end

function SeasonComponent:GetNewSeasonStatus()
    return self.tbSeasonPrimary.status
end

function SeasonComponent:GetBattlePass()
    return self.tbBattlePass
end

function SeasonComponent:GetLastRank()
    return self.tbLastRank
end

function SeasonComponent:GetCurRank()
    return self.tbCurRank
end

function SeasonComponent:GetCurRankByMode(nMode)
    for i, v in ipairs(self.tbCurRank.rank) do
        if v.mode == nMode then
            return v, i
        end
    end
end

function SeasonComponent:SetPassActive()
    self.tbSeasonPrimary.active_battle_pass = true
end

function SeasonComponent:SetBattleStar(nValue)
    self.tbBattlePass.battle_star = nValue
end

function SeasonComponent:SetBattleTier(nValue)
    self.tbBattlePass.battle_tier = nValue
end

function SeasonComponent:SetReceiveBattleTierAward(nTier)
    self.tbBattlePass.battle_tier_award_status[nTier] = 1
    log("set season battle tier award ", nTier)
    -- self.tbBattlePass.battle_tier_award_status = GetBattleTierAwards()
end

function SeasonComponent:SetReceiveBattleTierAllAwards()
    local nCurTier = self.tbBattlePass.battle_tier
    for i = 1, nCurTier do
        self.tbBattlePass.battle_tier_award_status[i] = 1
    end
    log("set season battle tier award all get ", nCurTier)
end

function SeasonComponent:HasBattleTierAwards()
    local bHas = false
    if not self.tbBattlePass then
        return bHas
    end
    local nCurTier = self.tbBattlePass.battle_tier
    local tbTemp

    for i = 1, nCurTier do
        if self.tbBattlePass.battle_tier_award_status[i] <= 0 then
            tbTemp = BattleTierRewardDataTable:GetTemplate(i)
            if tbTemp and tbTemp.nWarriorAwardId > 0 then
                bHas = true
                break
            end
        end
    end
    return bHas
end

function SeasonComponent:SetRankDailyTime(nValue)
    self.tbCurRank.rank_daily_chest = nValue
end

function SeasonComponent:GetRankDailyTime()
    return self.tbCurRank and self.tbCurRank.rank_daily_chest or 0
end

function SeasonComponent:IsHasDailyChest()
    if self.tbCurRank == nil then
        return false
    end
    return TimeUtil.CalRefreshRemainSeconds(self.tbCurRank.rank_daily_chest) <= 0
end

function SeasonComponent:SetSeasonStats(nSeasonId, tbStats)
    if self.tbStats == nil then
        self.tbStats = {}
    end
    self.tbStats[nSeasonId] = tbStats
end

function SeasonComponent:GetSeasonStats()
    return self.tbStats
end

function SeasonComponent:ClearCurSeasonStats()
    if self.tbStats ~= nil then
        self.tbStats[self:GetSeasonId()] = nil
    end
end

function SeasonComponent:SetGetChallengeAward(nType, nSubId)
    local tbChallengeSub = self.tbChallenge[nType]
    for i, v in ipairs(tbChallengeSub.challenge_sub) do
        if v.sub_id == nSubId then
            table.remove(tbChallengeSub.challenge_sub, i)
        end
    end
    table.insert(tbChallengeSub.completed_sub, nSubId)
end

function SeasonComponent:SetChallengeWeekAward(nType)
    local tbChallengeSub = self.tbChallenge[nType]
    tbChallengeSub.is_award = true
end

function SeasonComponent:IsGetChallengeWeekAward(nType)
    local tbChallengeSub = self.tbChallenge[nType]
    return tbChallengeSub.is_award
end

function SeasonComponent:GetSeasonChallenge(nType)
    return self.tbChallenge[nType]
end

function SeasonComponent:GetSeasonChallengeById(nType, nSubId)
    local tbChallengeSub = self.tbChallenge[nType]
    if tbChallengeSub then
        for i, v in ipairs(tbChallengeSub.challenge_sub) do
            if v.sub_id == nSubId then
                return v
            end
        end
    end
end

function SeasonComponent:SetCurWeek(nValue)
    self.nCurWeek = nValue
end

function SeasonComponent:GetCurWeek()
    return self.nCurWeek
end

function SeasonComponent:SetChallengeAwardStatus(tbStatus)
    for i, v in ipairs(tbStatus) do
        log("SeasonComponent:SetChallengeAwardStatus ", self.tbChallengeAwardStatus, v.type, v.has_award)
        self.tbChallengeAwardStatus[v.type] = v.has_award
    end
end

function SeasonComponent:SetSeasonHistorySummaries(tbSummaries)
    self.tbHistorySummaries = {}
    for i, v in ipairs(tbSummaries) do
        self.tbHistorySummaries[v.season_id] = v
    end
end

function SeasonComponent:SetSeasonHistoryDetail(nSeasonId, nSeasonPoint, nSeasonPointRanking, nSeasonParticipants, tbDetail)
    if self.tbHistorySummaries == nil then
        logerror("SeasonComponent:SetSeasonHistoryDetail failed: summaries is nil")
        return
    end
    local tbHistorySummary = self.tbHistorySummaries[nSeasonId]
    if tbHistorySummary == nil then
        logerror("SeasonComponent:SetSeasonHistoryDetail failed: summary is nil ", nSeasonId)
        return
    end
    tbHistorySummary.seted = true
    tbHistorySummary.detail = tbDetail
    tbHistorySummary.season_point = nSeasonPoint
    tbHistorySummary.season_point_ranking = nSeasonPointRanking
    tbHistorySummary.season_participants = nSeasonParticipants
end

function SeasonComponent:GetChallengeAwardStatus(nType)
    if nType == nil then
        for k, v in pairs(self.tbChallengeAwardStatus) do
            log("SeasonComponent:GetChallengeAwardStatus ", k, v)
            if v ~= nil and v == true then
                return v
            end
        end
        log("SeasonComponent:GetChallengeAwardStatus false")

        return false
    end
    if self.tbChallengeAwardStatus[nType] ~= nil then
        return self.tbChallengeAwardStatus[nType]
    else
        return false
    end
end

function SeasonComponent:GetSeasonHistorySummaries()
    return self.tbHistorySummaries
end

function SeasonComponent:GetSeasonHistorySummary(nSeasonId)
    return self.tbHistorySummaries ~= nil and self.tbHistorySummaries[nSeasonId]
end

function SeasonComponent:GetSeasonSummary()
    return self.tbSeasonSummary
end

function SeasonComponent:GetMaxRank()
    local nResult = 0
    if self.tbCurRank ~= nil then
        for i, v in ipairs(self.tbCurRank.rank) do
            if v.rank > nResult then
                nResult = v.rank
            end
        end
    end
    return nResult
end

return SeasonComponent