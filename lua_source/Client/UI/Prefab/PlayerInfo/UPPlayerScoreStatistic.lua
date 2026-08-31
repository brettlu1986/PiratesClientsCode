-----------------------------------------------------
--File Name    : UPPlayerScoreStatistic.lua
--Author       : WuJizhou
--Create Time  : 3/21/2019, 8:37:54 PM
--Description  : UPPlayerScoreStatistic
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayerScoreStatistic = luaclass("UPPlayerScoreStatistic", PrefabBase)
local ClientEventDef = require("ClientEventDef")
local SeasonSystem = require("SeasonSystem")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ScoreResDataTable = require("ScoreResDataTable")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local SeasonDataTable = require("SeasonDataTable")

local DEFAULT_MODE = 1
local MODES = {
    SINGLE_MODE = 1,
    COUPLE_MODE = 2,
    TEAM_MODE = 4,
}

local ONE_MIN = 60

UPPlayerScoreStatistic.bExtend = nil

local fnFormatRate = function(nValue)
    nValue = math.max(nValue, 0)
    nValue = math.min(nValue, 1)
    return string.format("%.1f%%", nValue * 100)
end

local fnFormatTime = function(nTime)
    local szTime = string.format("%.1f", nTime / ONE_MIN)
    return L10N:Format(UITextDef.COMMON_MIN, szTime)
end

local fnFormatDistance = function(nDistance)
    local szKm = string.format("%.1f", nDistance / 1000) 
    return L10N:Format(UITextDef.COMMON_KM, szKm)
end

local fnFormatAve = function(nValue)
    return string.format("%.1f", nValue) 
end

local STATS_BASE = {
    {   -- 场数
        fnGetKey = function()
            return UITextDef.STATISTIC_BASE_GAME_COUNT
        end,
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.matches
        end
    },
    {   -- 吃鸡场数
        fnGetKey = function()
            return UITextDef.STATISTIC_BASE_WIN_COUNT
        end,
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.wins
        end        
    },
    {
        -- 前十场数
        fnGetKey = function()
            return UITextDef.STATISTIC_BASE_RANKTOP10_COUNT
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.top_ten
        end  
    },
    {
        -- 击败数
        fnGetKey = function()
            return UITextDef.STATISTIC_BASE_KILL_COUNT
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.kill
        end  
    },
    {
        -- 击败/淘汰比例
        fnGetKey = function()
            return UITextDef.STATISTIC_BASE_KILLDEAD_COUNT
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return string.format("%d/%d", tbModeStats.kill, tbModeStats.death)
        end  
    },    
}
local STATS_BATTLE = {
    {
        -- 单局最高击败
        fnGetKey = function()
            return UITextDef.STATISTIC_BATTLE_MAX_KILL_COUNT
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.most_kills
        end  
    },
    {
        -- 单局最高伤害
        fnGetKey = function()
            return UITextDef.STATISTIC_BATTLE_MAX_DAMAGE_COUNT 
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.most_damage
        end  
    },
    {
        -- 场均伤害
        fnGetKey = function()
            return UITextDef.STATISTIC_BATTLE_AVE_DAMAGE_RATE
        end,
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.matches == 0 then
                return 0
            else
                local nValue = tbModeStats.damage / tbModeStats.matches
                return fnFormatAve(nValue)
            end
        end                 
    },
    {
        -- 命中率
        fnGetKey = function()
            return UITextDef.STATISTIC_BATTLE_HIT_RATE
        end,        
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.attacks == 0 then
                return 0
            else
                local nValue = tbModeStats.hits / tbModeStats.attacks
                return fnFormatRate(nValue)
            end
        end                 
    },
    {
        -- 暴击数
        fnGetKey = function()
            return UITextDef.STATISTIC_BATTLE_CRI_DAMAGE_COUNT
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return tbModeStats.critical
        end                 
    }, 
    {
        -- 暴击率
        fnGetKey = function()
            return UITextDef.STATISTIC_BATTLE_CRI_DAMAGE_RATE
        end,        
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.attacks == 0 then
                return 0
            else
                local nValue = tbModeStats.critical / tbModeStats.attacks
                return fnFormatRate(nValue)
            end
        end     
    },        
}
local STATS_SURVIVAL = {
    {
        -- 最长生存时间
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_MAX_SURVIVAL_TIME
        end,        
        fnGetValue = function(nMode, tbModeStats)
            return fnFormatTime(tbModeStats.total_duration)
        end     
    },  
    {
        -- 场均生存时间
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_AVE_SURVIVAL_TIME
        end,
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.matches == 0 then
                return fnFormatTime(0)
            else
                return fnFormatTime(tbModeStats.duration / tbModeStats.matches)
            end
        end                 
    },  
    {
        -- 最长移动距离
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_MAX_MOVE_DISTANCE
        end,
        fnGetValue = function(nMode, tbModeStats)
            return fnFormatDistance(tbModeStats.total_distance)
        end                
    }, 
    {
        -- 场均移动距离
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_AVE_MOVE_DISTANCE 
        end,
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.matches == 0 then
                return fnFormatDistance(0)
            else        
                return fnFormatDistance(tbModeStats.distance / tbModeStats.matches)
            end
        end                
    }, 
    {
        -- 吃鸡率
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_WIN_RATE
        end,        
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.matches == 0 then
                return 0
            else  
                return fnFormatRate(tbModeStats.wins / tbModeStats.matches)
            end
        end                
    }, 
    {
        -- 前十率
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_TOP10_RATE
        end,
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.matches == 0 then
                return 0
            else            
                return fnFormatRate(tbModeStats.top_ten / tbModeStats.matches)
            end
        end                
    }, 
    {
        -- 场均治疗
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_AVE_CURE
        end,        
        fnGetValue = function(nMode, tbModeStats)
            if tbModeStats.matches == 0 then
                return 0
            else
                return fnFormatAve(tbModeStats.heals / tbModeStats.matches)
            end
        end                
    }, 
    {
        -- 救助队友
        fnGetKey = function()
            return UITextDef.STATISTIC_SURVIVAL_CURE_TEAM_COUNT
        end,        
        fnGetValue = function(nMode, tbModeStats)
            if nMode ~= DEFAULT_MODE then
                return tbModeStats.rescues
            end
        end                
    }, 
}

local DIMENSIONAL_FIELD = {
    "dimensional_survivals",
    "dimensional_damages",
    "dimensional_kills",
    "dimensional_assists",
    "dimensional_items"
}

UPPlayerScoreStatistic.nPlayerId = nil
UPPlayerScoreStatistic.pbMode = nil
UPPlayerScoreStatistic.pbBaseStats = nil
UPPlayerScoreStatistic.pbFiveDimGraph = nil
UPPlayerScoreStatistic.tbBattleList = nil
UPPlayerScoreStatistic.tbSurvivalList = nil
UPPlayerScoreStatistic.nMode = nil
UPPlayerScoreStatistic.tbStats = nil
UPPlayerScoreStatistic.tbListHelper = nil
UPPlayerScoreStatistic.nSeasonId = nil

local function RefreshBaseStats(self, nMode, tbModeStats)
    for i, v in ipairs(self.pbBaseStats) do
        local szValue = STATS_BASE[i].fnGetValue(nMode, tbModeStats)
        v:RefreshValue(szValue)
    end
end

local function RefreshBattleStats(self, nMode, tbModeStats)
    local tbData = {}
    for i, v in ipairs(STATS_BATTLE) do
        local szKey = v.fnGetKey()
        local szValue = v.fnGetValue(nMode, tbModeStats)
        if szKey and szValue then
            table.insert(tbData, {szKey = szKey, szValue = szValue})
        end
    end
    self.tbBattleList:SetData(tbData)
end

local function RefreshSurvivalStats(self, nMode, tbModeStats)
    local tbData = {}
    for i, v in ipairs(STATS_SURVIVAL) do
        local szKey = v.fnGetKey()
        local szValue = v.fnGetValue(nMode, tbModeStats)
        if szKey and szValue then
            table.insert(tbData, {szKey = szKey, szValue = szValue})
        end
    end
    self.tbSurvivalList:SetData(tbData)
end

local function RefreshScoreStats(self, nMode, tbModeStats)
    local nCount = tbModeStats.matches > 0 and tbModeStats.matches or 1
    local pWidgetRef = self.pWidgetRef
    
    local nScore = tbModeStats.battle_points
    nScore = string.format("%.1f", nScore / nCount)
    pWidgetRef.txtScore:SetText(nScore)
    local szImg = ScoreResDataTable:GetImage(tonumber(nScore))
    UISetUtils.SetImageBrushRes(pWidgetRef.imgScore, szImg:load())

    local tbScores = {}
    for i, v in ipairs(DIMENSIONAL_FIELD) do
        nScore = tbModeStats[v]
        nScore = tonumber(string.format("%.1f", nScore / nCount))
        table.insert(tbScores, nScore)
    end 
    self.pbFiveDimGraph:OnRefresh(tbScores)
end

local function RefreshModeStats(self, nMode, tbModeStats)
    RefreshBaseStats(self, nMode, tbModeStats)
    RefreshBattleStats(self, nMode, tbModeStats)
    RefreshSurvivalStats(self, nMode, tbModeStats)
    RefreshScoreStats(self, nMode, tbModeStats)
end

local function SetModeStats(self, nMode)
    if self.nMode ~= nil then
        local pbOldMode = self.pbMode[self.nMode] 
        pbOldMode:OnUnselected()
    end
    self.pbMode[nMode]:OnSelected()

    self.nMode = nMode
    RefreshModeStats(self, nMode, self.tbStats[nMode])
end

local function OnRefreshSeasonStats(self, tbStats, bSuccess)
    -- if self.tbStats ~= nil then
    --     SetModeStats(self, DEFAULT_MODE)
    --     return 
    -- end

    local pWidgetRef = self.pWidgetRef
    if tbStats == nil then 
        -- or tbPacket.player_id ~= self.nPlayerId then
        UIUtils.ShowLoadingDialog()
        -- pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        SeasonSystem:RequestGetSeasonStats(self.nPlayerId, self.nSeasonId)
    else
        UIUtils.HideLoadingDialog()
        -- if bSuccess then
            -- pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            self.tbStats = {}
            for i, v in ipairs(tbStats) do
                self.tbStats[v.key] = v.value
            end
            SetModeStats(self, DEFAULT_MODE)
            pWidgetRef.btnShare:SetVisibility(self.nPlayerId == GamePlayerSelfHelper:Get().nPlayerId
                and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        -- end
    end        
end

local function SetCurSeason(self, nSeasonId)
    local Component = SeasonSystem:GetComponent()
    local nCurSeasonId = Component:GetSeasonId()

    self.nSeasonId = nSeasonId
    local tbSeasonData = SeasonDataTable:GetTemplate(nSeasonId)
    self.pWidgetRef.txtSeasonName:SetText(nCurSeasonId == nSeasonId and UISetUtils.GetL10NTextByKey("UI_SEASON_CURRENT")
        or tbSeasonData.l10nName)

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf.nPlayerId == self.nPlayerId then
        local tbStats = Component:GetSeasonStats()
        if tbStats ~= nil and tbStats[nSeasonId] ~= nil then
            OnRefreshSeasonStats(self, tbStats[nSeasonId], true)
        else
            OnRefreshSeasonStats(self)
        end
    else
        OnRefreshSeasonStats(self)
    end
end

local function SetExtend(self, bValue, bPlayAni)
    self.bExtend = bValue
    if bPlayAni then
        if self.bExtend then 
            self:PlayAnimation("animSeason", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self:PlayAnimation("animSeason", 0, 1, EUMGSequencePlayMode.Reverse, 1)
        end
    else
        local pWidgetRef = self.pWidgetRef 
        if not self.bExtend then 
            pWidgetRef.brSeasonList:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.imgTip:SetRenderTransformAngle(0)
        else
            pWidgetRef.brSeasonList:SetVisibility(ESlateVisibility.Visible)
            pWidgetRef.imgTip:SetRenderTransformAngle(180)
        end        
    end
end

local function BuildSeasonList(self)
    local Component = SeasonSystem:GetComponent()
    local nSeasonId = Component:GetSeasonId()
    local tbSeasonContainer = SeasonDataTable:GetContainer()
    local tbSeasons = {}
    for k, v in pairs(tbSeasonContainer) do
        if k <= nSeasonId then
            table.insert(tbSeasons, v)
        end
    end
    local fnSort = function(a, b)
        return a.nSeasonId > b.nSeasonId
    end
    table.sort(tbSeasons, fnSort)
    self.tbListHelper:SetData(tbSeasons)
end

local function OnButtonSelected(self, nMode)
    SetModeStats(self, nMode)
end

local function OnClickShare(self)
    UIManager:OpenWnd(UIDef.UI_SEASON_SHARE, {nMode = self.nMode, tbStats = self.tbStats[self.nMode], nSeasonId = self.nSeasonId})
end

local function OnClickSwitchSeason(self)
    -- local brSeasonList = self.pWidgetRef.brSeasonList 
    -- if brSeasonList:IsVisible() then
    -- if not self.bExtend then 
    --     brSeasonList:SetVisibility(ESlateVisibility.Collapsed)
    -- else
    --     brSeasonList:SetVisibility(ESlateVisibility.Visible)
    -- end
    SetExtend(self, not self.bExtend, true)
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    -- SetExtend(self, not self.bExtend, true)
    return WidgetBlueprintLibrary.Handled()
end

function UPPlayerScoreStatistic:OnEnter()
    self.nPlayerId = self.Owner.nPlayerId
end

function UPPlayerScoreStatistic:Activate()
    local Component = SeasonSystem:GetComponent()
    SetCurSeason(self, Component:GetSeasonId())
    -- self.pWidgetRef.brSeasonList:SetVisibility(ESlateVisibility.Collapsed)
    SetExtend(self, false, false)
end

function UPPlayerScoreStatistic:OnLoad()
    local pWidgetRef = self.pWidgetRef
    local PrefabHelper = self.PrefabHelper
    
    self.pbMode = {}
    for k, v in pairs(MODES) do
        local pbMode = PrefabHelper:BindPrefab(pWidgetRef["tbMode"..v])
        pbMode:Init(v)
        pbMode:OnUnselected()
        pbMode.OnClickedDelegated:Bind(function() OnButtonSelected(self, v) end)
        self.pbMode[v] = pbMode
    end

    local pbBaseStats = {}
    local l10nTitle
    for i, v in ipairs(STATS_BASE) do
        local pbBase = PrefabHelper:BindPrefab(pWidgetRef["pbPlayerStatsBase"..i])
        l10nTitle = v.fnGetKey(i)
        pbBase:RefreshTitle(l10nTitle)
        table.insert(pbBaseStats, pbBase)
    end
    self.pbBaseStats = pbBaseStats

    self.tbBattleList = SelfVerticalListHelper()
    self.tbBattleList:Init(self, pWidgetRef.kmBattleList)
    self.tbSurvivalList = SelfVerticalListHelper()
    self.tbSurvivalList:Init(self, pWidgetRef.kmSurvivalList)

    self.pbFiveDimGraph = PrefabHelper:BindPrefab(pWidgetRef.pbFiveDimGraph)

    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, pWidgetRef.kmSeasonList)   
    BuildSeasonList(self) 
end

function UPPlayerScoreStatistic:OnBindEvent( EventHelper )
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_STATS, self, OnRefreshSeasonStats)   
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnShare.OnClicked, self, OnClickShare)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSeason.OnClicked, self, OnClickSwitchSeason)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.brSeasonList.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

function UPPlayerScoreStatistic:OnDestroy()

end

function UPPlayerScoreStatistic:OnUnload()
    self.tbBattleList:Uninit()
    self.tbBattleList = nil
    self.tbSurvivalList:Uninit()
    self.tbSurvivalList = nil
    self.pbMode = nil
    self.pbBaseStats = nil
    self.pbFiveDimGraph = nil
    self.tbListHelper:Uninit()
    self.tbListHelper = nil    
end

function UPPlayerScoreStatistic:SetCurSeason(nSeasonId)
    -- self.pWidgetRef.brSeasonList:SetVisibility(ESlateVisibility.Collapsed)
    SetExtend(self, not self.bExtend, true)
    if nSeasonId ~= self.nSeasonId then
        SetCurSeason(self, nSeasonId)
    end
end

return UPPlayerScoreStatistic