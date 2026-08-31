local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonRankResult = luaclass("UISeasonRankResult", WndBase)
local SeasonSystem = require("SeasonSystem")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local SeasonDataTable = require("SeasonDataTable")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local DelayTimer = require("DelayTimer")
local UIUtils = require("UIUtils")

UISeasonRankResult.pbModes = nil
UISeasonRankResult.bIsLast = nil
UISeasonRankResult.tbDelayHandle = nil

local DELAY_TIME = {
    1.2,
    2.2,
    3.2
}
-------------------------------------------------------------------------------------------------------
local function ClearTimer(self)
    if self.tbDelayHandle ~= nil then
        for i, v in ipairs(self.tbDelayHandle) do
            DelayTimer:ClearTimer(v)
        end
    end
    self.tbDelayHandle = nil
end

local function RefreshSeasonRank(self, nIndex, tbRank, txtRank, bAppear)
    local Collapsed, SelfHitTestInvisible = ESlateVisibility.Collapsed, ESlateVisibility.SelfHitTestInvisible
    local pbMode = self.pbModes[nIndex] 
    pbMode:OnRefresh(tbRank, txtRank, bAppear)  
    pbMode.pWidgetRef.txtRank:SetText("")

    if bAppear then
        pbMode.pWidgetRef:SetVisibility(Collapsed)
        txtRank:SetVisibility(Collapsed)

        local fnShowRank = function()
            pbMode.pWidgetRef:SetVisibility(SelfHitTestInvisible)
            txtRank:SetVisibility(SelfHitTestInvisible)
        end
        if self.tbDelayHandle == nil then
            self.tbDelayHandle = {}
        end
        self.tbDelayHandle[nIndex] = DelayTimer:DelayRun(fnShowRank, DELAY_TIME[nIndex])
    else
        ClearTimer(self)
    end
end

local function RefreshUI(self, tbSeasonData, tbRanks, bAppear)
    local pWidgetRef = self.pWidgetRef

    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    for i, v in ipairs(tbModes) do
        local txtMode = pWidgetRef["txtMode"..v.nId]
        if txtMode ~= nil then
            txtMode:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_MODE"), v.l10nDesc))
        end
        RefreshSeasonRank(self, i, tbRanks[i], pWidgetRef["txtRank"..v.nId], bAppear)
    end
end

local function TestLastRankData()
    local tbRet = {}

    local tbRank = {}
    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    local a = {11, 21, 31}
    local b = {1200, 1700, 2200}
    for i, v in ipairs(tbModes) do
        table.insert(tbRank, {mode = v.nId, rank = a[i], rank_point = b[i], rank_protect = 0})
    end

    tbRet = {rank_daily_chest = 0, rank = tbRank}

    return tbRet
end

local function ShowLastSeason(self)
    self.bIsLast = true

    local Component = SeasonSystem:GetComponent()
    local tbLastRank = Component:GetLastRank()
    local nSeasonId = Component:GetSeasonId() - 1
    local tbSeasonData = SeasonDataTable:GetTemplate(nSeasonId)

    local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_RESULT"), tbSeasonData.l10nName)
    self.pWidgetRef.txtTitle:SetText(l10nTitle)

    if tbLastRank == nil then
        tbLastRank = TestLastRankData()
    end
    RefreshUI(self, tbSeasonData, tbLastRank.rank, true)
    self:PlayAnimation("animSeasonResult01", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function OnClickOk(self)
    if self.bIsLast then
        self.bIsLast = false

        local Component = SeasonSystem:GetComponent()
        local tbCurRank = Component:GetCurRank()
        local nSeasonId = Component:GetSeasonId()
        local tbSeasonData = SeasonDataTable:GetTemplate(nSeasonId)
        local fnComplete = function()
            local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_OPEN"), tbSeasonData.l10nName)
            self.pWidgetRef.txtTitle:SetText(l10nTitle)
            RefreshUI(self, tbSeasonData, tbCurRank.rank, true)
            self:PlayAnimation("animSeasonResult01", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end

        self:PlayAnimation("animSeasonResult02", 0, 1, EUMGSequencePlayMode.Forward, 1, fnComplete)
        RefreshUI(self, tbSeasonData, tbCurRank.rank, false)
    else
        self.EventHelper:FireEvent(ClientEventDef.EV_SEASON_RESULT_AWARD_GET)
        self:CloseSelf()
    end
end

function UISeasonRankResult:OnLoad()
    self.pbModes = {}
    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()

    local pWidgetRef = self.pWidgetRef
    for i, v in ipairs(tbModes) do
        local pModeWidgetRef = pWidgetRef["upRank"..v.nId]
        if pModeWidgetRef ~= nil then
            local pbMode = self.PrefabHelper:BindPrefab(pModeWidgetRef)
            table.insert(self.pbModes, pbMode)
        else
            logerror("UISeasonRankResult:OnLoad invalid mode ", v.nId)
        end
    end
end

function UISeasonRankResult:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnOk.OnClicked, self, OnClickOk)
end

function UISeasonRankResult:OnShow()
    UIUtils.BottomMenuHide(true)
    ShowLastSeason(self)
end

function UISeasonRankResult:OnHide()
    UIUtils.BottomMenuHide(false)
end

function UISeasonRankResult:OnDestroy()
    ClearTimer(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
end

return UISeasonRankResult