local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPlayerRecentGameScoreSub = luaclass("UPPlayerRecentGameScoreSub", ListItemBase)
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local RankDataTable = require("RankDataTable")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local StatsSystem = require("StatsSystem")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local TimeUtil = require("TimeUtil")
local ScoreResDataTable = require("ScoreResDataTable")
local UIResourceDef = require("UIResourceDef")

local ONE_MIN = 60
local RANK_SUB_MAX = 5

UPPlayerRecentGameScoreSub.tbData = nil
-- message HistoryStatsBase {
--     string dungeon_id                   = 1;
--     int32 team_id                       = 2;
--     int32 team_mode                     = 3;
--     fixed32 start_time                  = 4; // 战绩时间（该场次开始时间，以选点结束时间计算）
--     int32 rank                          = 5;
--     int32 kill                          = 6;
--     int32 season_rank                   = 7; // 赛季段位
--     int32 rank_point                    = 8; // 赛季段位积分
--     int32 rank_point_change             = 9; // 赛季段位积分变化
-- }

local function TransformationSubRank(nSubRank)
    if nSubRank == 0 then
        return nSubRank
    else
        return RANK_SUB_MAX - nSubRank + 1
    end
end

local function RefreshSeasonRank(self, tbData)
    local nSubRank = math.fmod(tbData.season_rank, 10)
    nSubRank = TransformationSubRank(nSubRank)
    local tbRankData = RankDataTable:GetTemplate(tbData.season_rank)
    local szRank
    if nSubRank == 0 then--最高段位
        szRank = L10N:ToString(tbRankData.l10nName)
    else
        nSubRank = math.min(nSubRank, RANK_SUB_MAX)
        local l10nSubRank = UISetUtils.GetL10NTextByKey("SEASON_RANK_"..nSubRank)
        local l10nRank = L10N:Format(l10nSubRank, tbRankData.l10nName)
        szRank = L10N:ToString(l10nRank)
    end

    local szSeasonRank = string.format("%s %d (%d)", szRank, tbData.rank_point, tbData.rank_point_change)
    self.pWidgetRef.txtSeasonRank:SetText(szSeasonRank)
end

local function RefreshUI(self)
    local tbData = self.tbData
    local pWidgetRef = self.pWidgetRef
    local SelfHitTestInvisible, Collapsed = ESlateVisibility_SelfHitTestInvisible, ESlateVisibility_Collapsed
    pWidgetRef.imgWin:SetVisibility(tbData.rank <= 10 and SelfHitTestInvisible or Collapsed)
    pWidgetRef.txtWin:SetVisibility(tbData.rank <= 10 and SelfHitTestInvisible or Collapsed)
    if tbData.rank == 1 then
        UISetUtils.SetImageBrushColor(pWidgetRef.imgWin, UIResourceDef.COLOR.PINK)
        pWidgetRef.txtWin:SetText(UISetUtils.GetL10NTextByKey("UI_BATTLE_HISTORY_WIN"))
    elseif tbData.rank <= 10 then
        UISetUtils.SetImageBrushColor(pWidgetRef.imgWin, UIResourceDef.COLOR.GREEN)
        pWidgetRef.txtWin:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("UI_BATTLE_HISTORY_RANK"), UISetUtils.GetL10NTextByKey("COMMON_NUMBER_10")))
    end
    local tbModeData = MatchmakingTeamModeDataTable:GetTemplate(tbData.team_mode)
    pWidgetRef.txtMode:SetText(tbModeData and tbModeData.l10nDesc or "")
    pWidgetRef.txtRank:SetText(tbData.rank)
    pWidgetRef.txtKill:SetText(tbData.kill)
    pWidgetRef.txtBattleTime:SetText(TimeUtil.GetTimeFormatString(tbData.battle_time, "%m-%d %H:%M"))
    local szTime = string.format("%.1f", tbData.duration / ONE_MIN)
    local l10nTime = L10N:Format(UISetUtils.GetL10NTextByKey("SELFTIMECALCULATEHELPER_L10N_MIN"), szTime)
    pWidgetRef.txtTime:SetText(l10nTime)

    local nBattlePoint = 0
    for i, v in ipairs(self.tbData.teamMembers) do
        if v.summary.id == self.nPlayerId then
            nBattlePoint = v.battle_point
            break
        end
    end    
    local szImg = ScoreResDataTable:GetImage(nBattlePoint)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgScore, szImg:load())

    RefreshSeasonRank(self, tbData)
end

local function BuildBattleResultDatas(self, nMVPPlayerId, tbDetail)
    local tbData = self.tbData
    local tbBattleResult = {
        nMode = tbData.team_mode,
        bTeamDead = true,
        nTeamRank = tbData.rank,
        nMVPPlayerId = nMVPPlayerId,
        nPlayerCount = tbData.player_count,
        nTeamCount = tbData.team_count
    }
    return tbBattleResult
end

local function GetMemberInfo(self, nPlayerId)
    for i, v in ipairs(self.tbData.teamMembers) do
        if v.summary.id == nPlayerId then
            return v.summary.name, v.summary.avatar_id
        end
    end
    if nPlayerId == self.nPlayerId then
        local tbBasicInfo = self.ulPlayerInfo:GetPlayerBasicInfo(nPlayerId)
        return tbBasicInfo.szName, tbBasicInfo.nAvatarId
    end
end

local function BuildBattleResultTeamMemberDatas(self, tbDetail)
    local tbBattleResults = {}
    local nAvatarId = 0
    local szName = ""
    local nTeamRank, nExtraScore = 0, 0
    for i, v in ipairs(tbDetail) do
        local szMemberName, nMemberAvatarId = GetMemberInfo(self, v.player_id)
        local tbBattleResult = {
            name = szMemberName,
            nAvatarId = nMemberAvatarId,
            nPlayerRank = self.tbData.rank,
            nKillCount  = v.kill,
            nSurvivalTime = v.survival_time,
            nApplyDamageToShip = v.ship_damage,
            nApplyDamageToHuman = v.human_damage,
            nApplyCureToShip = v.ship_cure,
            nApplyCureToHuman = v.human_cure,
            nMoveDistance = v.move_distance,
            nShipLaunchCount = v.ship_launch,
            nShipHitCount = v.ship_hit,
            nHumanLaunchCount = v.human_launch,
            nHumanHitCount = v.human_hit,
            nHitShipCoreCount = v.ship_hit_core,
            nHitHumanCoreCount = v.human_hit_core,
            nSaveTeamateCount = v.rescues,
            nPlayerId = v.player_id,
            nExtraScore = v.boss_point,
            nBattleScore = v.battle_point,
            nSurvivalScore = v.survival_point,
            nKillScore = v.kill_point,
            nGradeScore = self.tbData.rank_point_change,
            nExp = v.exp or 0,
            nCurrency = v.currency or 0,
            nAssistCount = v.assist or 0,
            nDimensionalSurvival = v.dimensional_survival,
            nDimensionalDamage   = v.dimensional_damage,
            nDimensionalKill     = v.dimensional_kill,
            nDimensionalAssist   = v.dimensional_assist,
            nDimensionalItem     = v.dimensional_item,
            nShipAppliedDamage   = v.ship_suffer or 0,
            nHumanAppliedDamage  = v.human_suffer or 0
        }
        table.insert(tbBattleResults, tbBattleResult)

        if v.player_id == self.nPlayerId then
            nAvatarId = nMemberAvatarId
            szName = szMemberName
            nTeamRank = self.tbData.rank
            nExtraScore = v.boss_point
        end
    end
    return tbBattleResults, nAvatarId, szName, nTeamRank, nExtraScore
end

local function RefreshDetailUI(self, tbDetail, nMVPPlayerId)
    local tbParams = {}
    tbParams.tbTeamInfo = BuildBattleResultDatas(self, nMVPPlayerId, tbDetail)
    tbParams.tbSortTeamMemberData, tbParams.nAvatarId, tbParams.szName, tbParams.nTeamRank, tbParams.nExtraScore
        = BuildBattleResultTeamMemberDatas(self, tbDetail)
    tbParams.bOpenDetail = true
    tbParams.bInLobby = true
    tbParams.nSelfPlayerId = self.nPlayerId
    UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_STATISTICS, tbParams)
end

local function OnClickInfo(self)
    local Component = StatsSystem:GetComponent()
    local tbDetail, nMVPPlayerId = Component:GetHistoryStatsDetail(self.tbData.dungeon_id, self.tbData.team_id)
    if tbDetail and nMVPPlayerId then
        RefreshDetailUI(self, tbDetail, nMVPPlayerId)
    else
        StatsSystem:RequestGetHistoryStatsDetail(self.tbData.dungeon_id, self.tbData.team_id, self.tbData.team_mode)
    end
end

local function OnRefreshStatsDetail(self, szDungeonId, nTeamId, nMVPPlayerId, tbDetail)
    if self.tbData and self.tbData.dungeon_id == szDungeonId and self.tbData.team_id == nTeamId then
        RefreshDetailUI(self, tbDetail, nMVPPlayerId)
    end
end

function UPPlayerRecentGameScoreSub:OnEnter()
    self.nPlayerId = self.Owner.nPlayerId
end

function UPPlayerRecentGameScoreSub:OnCreate()
    self.ulPlayerInfo = self.Owner.ulPlayerInfo
end

function UPPlayerRecentGameScoreSub:OnDestroy()
    self.nPlayerId = nil
    self.ulPlayerInfo = nil
end

function UPPlayerRecentGameScoreSub:OnLoad()

end

function UPPlayerRecentGameScoreSub:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnInfo.OnClicked, self, OnClickInfo)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_HISTORY_STATS_DETAIL, self, OnRefreshStatsDetail)
end

function UPPlayerRecentGameScoreSub:OnRefresh(tbData)
    self.tbData = tbData
    RefreshUI(self)
end

return UPPlayerRecentGameScoreSub