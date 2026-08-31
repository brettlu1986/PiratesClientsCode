local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSeasonRankRecordDetail2 = luaclass("UPSeasonRankRecordDetail2", ListItemBase)
local ClientEventDef = require("ClientEventDef")
local SeasonSystem = require("SeasonSystem")
local UIUtils = require("UIUtils")
local SeasonDataTable = require("SeasonDataTable")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local TimeUtil = require("TimeUtil")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local SeasonIni = require("SeasonIni")
local UIResourceDef = require("UIResourceDef")

local L10N_TIME_FORMAT = UISetUtils.GetL10NTextByKey("L10N_YMDTIME_FORMAT")

UPSeasonRankRecordDetail2.bExtend = nil
UPSeasonRankRecordDetail2.nSeasonId = nil
UPSeasonRankRecordDetail2.tbData = nil
UPSeasonRankRecordDetail2.pbPlayerSeason = nil
UPSeasonRankRecordDetail2.pbModes = nil

local DEFAULT_RANK = 11
local DEFAULT_COLOR_TABLE = {Normal = UIResourceDef.COLOR.WHITE.SLATE_COLOR, Gray = UIResourceDef.COLOR.GREY2.SLATE_COLOR}
local TXT_ARRAY = {
    ["kmtxtTitle"]  = DEFAULT_COLOR_TABLE,
    ["txtTime"]     = {Normal = UIResourceDef.COLOR.WHITE.SLATE_COLOR, Gray = UIResourceDef.COLOR.GREY2.SLATE_COLOR},
    ["txtExtend"]   = {Normal = UIResourceDef.COLOR.GREY3.SLATE_COLOR, Gray = UIResourceDef.COLOR.GREY2.SLATE_COLOR},
    ["txtMaxRank"]  = {Normal = UIResourceDef.COLOR.WHITE.SLATE_COLOR, Gray = UIResourceDef.COLOR.GREY2.SLATE_COLOR},
    ["pbPlayerSeason"] = {
        ["txtMode"] = DEFAULT_COLOR_TABLE,
        ["txtScore"] = DEFAULT_COLOR_TABLE,
        ["txtRank"] = DEFAULT_COLOR_TABLE
    }
}

local function RefreshSummary(self, tbData)
    local pWidgetRef = self.pWidgetRef
    local tbSeasonData = SeasonDataTable:GetTemplate(self.nSeasonId)
    pWidgetRef.kmtxtTitle:SetText(tbSeasonData.l10nName)

    local szTimeFormat = L10N:ToString(L10N_TIME_FORMAT)
    local szStartTime = TimeUtil.GetTimeFormatString(tbData.season_start_time, szTimeFormat)
    local nSeasonEndTime = tbSeasonData.nDurationDay *24 * 60 * 60 + tbData.season_start_time
    local szEndTime = TimeUtil.GetTimeFormatString(nSeasonEndTime, szTimeFormat)
    local l10nTime = L10N:Format(UISetUtils.GetL10NTextByKey("YMDTIME_TO_YMDTIME"), szStartTime, szEndTime)
    pWidgetRef.txtTime:SetText(l10nTime)

    self.pbPlayerSeason:OnRefresh({
        mode = tbData.season_highest_rank_mode,
        rank_point = tbData.season_highest_rank_point,
        rank = tbData.season_highest_rank
    })
end

local function RefreshPointRanking(self, nSeasonPointRanking, nSeasonParticipants)
    local nSeasonRanking = SeasonIni.tbRanking.nSeasonRanking
    local nRanking = nSeasonPointRanking
    local nCount = nSeasonParticipants
    local txtSeasonRank = self.pWidgetRef.txtSeasonRank
    if nRanking == 0 then
        txtSeasonRank:SetText("99%")
    elseif nRanking <= nSeasonRanking then
        txtSeasonRank:SetText(nRanking)
    else
        local szRanking = string.format("%.2f", nRanking / nCount)
        txtSeasonRank:SetText(szRanking)
    end
end

local function RefreshDetail(self, tbData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtSeasonPoint:SetText(tbData.season_point or 0)

    RefreshPointRanking(self, tbData.season_point_ranking or 1, tbData.season_participants or 1)

    local fnGetModeDetail = function(nMode)
        local fnBuildDetail = function()
            return {
                mode = nMode,
                rank = DEFAULT_RANK,
                rank_point = 0,
                matches = 0,
                wins = 0,
                top_ten = 0,
                kill_death_rate = 0,
            }
        end
        if tbData.detail == nil then
            return fnBuildDetail()
        else
            for i, v in ipairs(tbData.detail) do
                if v.mode == nMode then
                    if v.death == 0 then
                        v.kill_death_rate = 0
                    else
                        local nRate = v.kill / v.death
                        nRate = string.format("%.2f", nRate)
                        v.kill_death_rate = nRate
                    end 
                    if v.rank < DEFAULT_RANK then
                        v.rank = DEFAULT_RANK
                    end
                    return v
                end
            end
            return fnBuildDetail()
        end
    end
    for i, v in ipairs(self.pbModes) do
        v:OnRefresh(fnGetModeDetail(v.nMode))
    end 
end

local function RefreshWidgetColorAndOpacity(self, szWidgetName, tbColorData, bNormal)
    if tbColorData.Normal ~= nil then
        self.pWidgetRef[szWidgetName]:SetColorAndOpacity(bNormal and tbColorData.Normal or tbColorData.Gray)
    else
        for k, v in pairs(tbColorData) do
            RefreshWidgetColorAndOpacity(self[szWidgetName], k, v, bNormal)
        end
    end
end

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local SelfHitTestInvisible, Collapsed = ESlateVisibility.SelfHitTestInvisible, ESlateVisibility.Collapsed
    pWidgetRef.vbDetail:SetVisibility(self.bExtend 
        and SelfHitTestInvisible or Collapsed)

    local tbData = self.tbData
    RefreshSummary(self, tbData)
    if self.bExtend then
        RefreshDetail(self, tbData)
    end

    -- local CHECKED, UNCHECKED, UNDETERMINED = ECheckBoxState.Checked, ECheckBoxState.Unchecked, ECheckBoxState.Undetermined
    if tbData.no_jion then
        pWidgetRef.ovlNothing:SetVisibility(SelfHitTestInvisible)
        self.pbPlayerSeason.pWidgetRef:SetVisibility(Collapsed)
        pWidgetRef.txtMaxRank:SetVisibility(Collapsed)
        pWidgetRef.imgExtend:SetVisibility(Collapsed)
        pWidgetRef.imgBG:SetVisibility(Collapsed)
        pWidgetRef.imgBG2:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.txtExtend:SetText(UISetUtils.GetL10NTextByKey("UI_SEASON_RANK_RECORD_NOJOIN"))
    elseif self.bExtend then
        pWidgetRef.ovlNothing:SetVisibility(Collapsed)
        self.pbPlayerSeason.pWidgetRef:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.txtMaxRank:SetVisibility(SelfHitTestInvisible)
        -- pWidgetRef.cbExtend:SetCheckedState(CHECKED)
        pWidgetRef.imgExtend:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgExtend:SetRenderTransformAngle(0)
        pWidgetRef.imgBG:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgBG2:SetVisibility(Collapsed)
        pWidgetRef.txtExtend:SetText(UISetUtils.GetL10NTextByKey("UI_SEASON_RANK_RECORD_EXTEND"))
    else
        pWidgetRef.ovlNothing:SetVisibility(Collapsed)
        self.pbPlayerSeason.pWidgetRef:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.txtMaxRank:SetVisibility(SelfHitTestInvisible)
        -- pWidgetRef.cbExtend:SetCheckedState(UNCHECKED)
        pWidgetRef.imgExtend:SetRenderTransformAngle(180)
        pWidgetRef.imgExtend:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgBG:SetVisibility(SelfHitTestInvisible)
        pWidgetRef.imgBG2:SetVisibility(Collapsed)
        pWidgetRef.txtExtend:SetText(UISetUtils.GetL10NTextByKey("UI_SEASON_RANK_RECORD_EXTEND"))
    end

    for k, v in pairs(TXT_ARRAY) do
        RefreshWidgetColorAndOpacity(self, k, v, not tbData.no_jion)
    end        
end

local function SetExtend(self, bExtend)
    self.bExtend = bExtend
    
    if self.bExtend then
        if self.tbData == nil then
            local Component = SeasonSystem:GetComponent()
            self.tbData = Component:GetSeasonHistorySummary(self.nSeasonId)
        end
        if self.tbData == nil or self.tbData.seted == nil then
            UIUtils.ShowWaitingPacket()
            SeasonSystem:RequestGetSeasonHistoryDetails(self.nSeasonId)
        else
            UIUtils.HideWaitingPacket()
        end 
    end
    RefreshUI(self)
end

local function OnClickExtend(self)
    if not self.tbData.no_jion then
        SetExtend(self, not self.bExtend)
        self.EventHelper:FireEvent(ClientEventDef.EV_SEASON_HISTRORY_SUMMARIES, self.bExtend)
    end
end

local function OnRecvHistoryDetail(self, nSeasonId)
    if nSeasonId == self.nSeasonId then
        SetExtend(self, true)
    end
end

local function OnRefreshCurSeasonPointRanking(self, nSeasonPointRanking, nSeasonParticipants)
    local Component = SeasonSystem:GetComponent()
    local nSeasonId = Component:GetSeasonId()
    if nSeasonId == self.nSeasonId then
        RefreshPointRanking(self, nSeasonPointRanking, nSeasonParticipants)
    end
end

function UPSeasonRankRecordDetail2:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper

    self.pbPlayerSeason = PrefabHelper:BindPrefab(pWidgetRef.pbPlayerSeason)
    
    self.pbModes = {}
    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    for i, v in ipairs(tbModes) do
        local pModeWidgetRef = pWidgetRef["pRank"..v.nId]
        if pModeWidgetRef ~= nil then
            local pbMode = PrefabHelper:BindPrefab(pModeWidgetRef)
            pbMode.nMode = v.nId
            table.insert(self.pbModes, pbMode)
        else
            logerror("UPSeasonRankRecordDetail2:OnLoad invalid mode ", v.nId)
        end
    end
end

function UPSeasonRankRecordDetail2:OnUnload()
end

function UPSeasonRankRecordDetail2:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_HISTRORY_DETAILS, self, OnRecvHistoryDetail)     
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_POINT_RANKING, self, OnRefreshCurSeasonPointRanking)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnExtend.OnClicked,  self, OnClickExtend)
end

function UPSeasonRankRecordDetail2:OnRefresh(tbData)
    self.nSeasonId = tbData.season_id
    SetExtend(self, tbData.bDefaultExtend ~= nil and tbData.bDefaultExtend or false)
end

function UPSeasonRankRecordDetail2:OnDestroy()
    self.nSeasonId = nil
    self.tbData = nil
end

return UPSeasonRankRecordDetail2