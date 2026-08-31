local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSeasonRecord = luaclass("ULSeasonRecord", UILogicBase)
local SelfListHelperNew = require("SelfListHelperNew")
local SeasonSystem = require("SeasonSystem")
local ClientEventDef = require("ClientEventDef")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")

ULSeasonRecord.ListHelper = nil
ULSeasonRecord.bActive = nil

local function BuildCurSeasonSummaryAndDetail(tbSummaries)
    local Component = SeasonSystem:GetComponent()
    local nCurSeasonId = Component:GetSeasonId()
    local tbSummary = Component:GetSeasonSummary()
    local tbRank = Component:GetCurRank().rank
    local fnGetHighestRank = function()
        local nMaxPoint = -1
        local tbHighestRank
        for i, v in ipairs(tbRank) do
            if v.rank_point > nMaxPoint then
                tbHighestRank = v
                nMaxPoint = v.rank_point
            end
        end
        return tbHighestRank
    end
    local tbHighestRank = fnGetHighestRank()

    local tbDetail = {}

    local tbData = {}
    tbData.season_id = nCurSeasonId
    tbData.season_start_time = Component:GetStartTime()
    tbData.season_highest_rank = tbHighestRank.rank
    tbData.season_highest_rank_mode = tbHighestRank.mode
    tbData.season_highest_rank_point = tbHighestRank.rank_point
    tbData.seted = true
    tbData.detail = tbDetail
    tbData.season_point = tbSummary.season_point
    tbData.season_point_ranking = tbSummary.season_point_ranking
    tbData.season_participants = tbSummary.season_participants

    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    local tbStatsMap = Component:GetSeasonStats()
    local tbStats = tbStatsMap and tbStatsMap[nCurSeasonId]
    
    local fnGetStats = function(nMode)
        for k, v in pairs(tbStats) do
            if v.key == nMode then
                return v.value
            end
        end
    end

    for i, v in ipairs(tbModes) do
        local tbMode = {}
        local tbStatsData = fnGetStats(v.nId)
        local tbRankData = tbRank[i]
        tbMode.mode = v.nId
        tbMode.rank = tbRankData.rank
        tbMode.rank_point = tbRankData.rank_point
        tbMode.matches = tbStatsData.matches
        tbMode.wins = tbStatsData.wins
        tbMode.top_ten = tbStatsData.top_ten
        tbMode.kill = tbStatsData.kill
        tbMode.death = tbStatsData.death
        table.insert(tbDetail, tbMode)
    end

    tbSummaries[nCurSeasonId] = tbData
end

local function OnRefresh(self, bExtend)
    if not self.bActive then
        log("ULSeasonRecord no activate")
        return
    end 
    local Component = SeasonSystem:GetComponent()
    local tbSummaries = Component:GetSeasonHistorySummaries()
    local tbStats = Component:GetSeasonStats()
    local nCurSeasonId = Component:GetSeasonId()
    if tbSummaries ~= nil and tbStats ~= nil and tbStats[nCurSeasonId] ~= nil then
        BuildCurSeasonSummaryAndDetail(tbSummaries)
        local tbDatas = tbSummaries
        local nMaxSeasonId = 0
        local tbMaxSeason
        local tbSeasons = {}
        for i = #tbDatas, 1, -1 do
        -- for i, v in ipairs(tbDatas) do
            if tbDatas[i].season_id > nMaxSeasonId and not tbDatas[i].no_jion then
                nMaxSeasonId = tbDatas[i].season_id
                tbMaxSeason = tbDatas[i]
            end
            table.insert(tbSeasons, tbDatas[i])
        end
        if nMaxSeasonId > 0 then
            if bExtend ~= nil then
                tbMaxSeason.bDefaultExtend = bExtend
            else
                tbMaxSeason.bDefaultExtend = true
            end
        end

        self.ListHelper:SetData(tbSeasons)
    end
end

local function OnRefreshSummaries(self, bExtend)
    OnRefresh(self, bExtend)
end

local function OnRefreshStats(self)
    OnRefresh(self)
end

function ULSeasonRecord:OnLoad()
    self.bActive = false
    local pWidgetRef = self.pWidgetRef

    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, pWidgetRef.kmList)
end

function ULSeasonRecord:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function ULSeasonRecord:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_HISTRORY_SUMMARIES, self, OnRefreshSummaries)   
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_STATS, self, OnRefreshStats)
end

function ULSeasonRecord:OnShow()
end

function ULSeasonRecord:Activate()
    self.bActive = true
    OnRefresh(self)
end

function ULSeasonRecord:Deactivate()
    self.bActive = false
end

return ULSeasonRecord