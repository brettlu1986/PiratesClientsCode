local luaclass  = require("luaclass")
local WndBase   = require("WndBase")
local UISeasonShare = luaclass("UISeasonShare", WndBase)
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local UIUtils = require("UIUtils")
local DelayTimer = require("DelayTimer")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local PlayerInfoSystem = require("PlayerInfoSystem")
local ScoreResDataTable = require("ScoreResDataTable")
local SeasonSystem = require("SeasonSystem")
local SeasonDataTable = require("SeasonDataTable")
local ScreenCaptureHelper = require("ScreenCaptureHelper")

UISeasonShare.nMode = nil
UISeasonShare.tbStats = nil
UISeasonShare.nSeasonId = nil
UISeasonShare.pbBaseStats = nil
UISeasonShare.tbDelayHandle = nil
UISeasonShare.pbPlayHead = nil
UISeasonShare.pbFiveDimen = nil

local SHOT_DELAY = 0.2

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

local DIMENSIONAL_FIELD = {
    "dimensional_survivals",
    "dimensional_damages",
    "dimensional_kills",
    "dimensional_assists",
    "dimensional_items"
}

local function RefreshBaseStats(self, nMode, tbModeStats)
    for i, v in ipairs(self.pbBaseStats) do
        local szValue = STATS_BASE[i].fnGetValue(nMode, tbModeStats)
        v:RefreshValue(szValue)
    end
end

local function RefreshPlayerInfo(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local tbBasicInfo = PlayerInfoSystem:GetPlayerBasicInfo(PlayerSelf.nPlayerId)
    self.pbPlayHead:SetPlayerHead(tbBasicInfo.nAvatarId)
    self.pWidgetRef.txtPlayerName:SetText(tbBasicInfo.szName)
end

local function DestroyTimer(self)
    if self.tbDelayHandle ~= nil then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

local function RefreshFiveDimen(self)
    local tbScores = {}
    local nScore = 0
    local nCount = self.tbStats.matches > 0 and self.tbStats.matches or 1
    for i, v in ipairs(DIMENSIONAL_FIELD) do
        nScore = self.tbStats[v]
        nScore = tonumber(string.format("%.1f", nScore / nCount))
        table.insert(tbScores, nScore)
    end
    self.pbFiveDimen:OnRefresh(tbScores)
end

local function OnScreenShotCaptureFinished(self, Width, Height, ShotTexture)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    pWidgetRef.cvsInfo:SetVisibility(Collapsed)
    pWidgetRef.cvsCamer:SetVisibility(Visible)

    local pBrush = pWidgetRef.imgShotResult.Brush
    pBrush.ResourceObject = ShotTexture
    local fViewportScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    fViewportScale = fViewportScale * 1.15
    pBrush.ImageSize = Vector2D{X= Width/fViewportScale, Y=Height/fViewportScale}
    pWidgetRef.imgShotResult:SetBrush(pBrush)

    self:PlayAnimation("animIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local Visible, Collapsed = ESlateVisibility.Visible, ESlateVisibility.Collapsed
    pWidgetRef.cvsInfo:SetVisibility(Visible)
    pWidgetRef.cvsCamer:SetVisibility(Collapsed)
    local tbModeData = MatchmakingTeamModeDataTable:GetTemplate(self.nMode)
    if tbModeData then
        pWidgetRef.txtMode:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_MODE"), tbModeData.l10nDesc))
    else
        pWidgetRef.txtMode:SetText("")
    end
    -- to do
    local nScore = self.tbStats.battle_points or 0
    local nCount = self.tbStats.matches > 0 and self.tbStats.matches or 1
    local szScore = string.format("%.1f", nScore / nCount)
    pWidgetRef.txtScore:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_SCORE"), szScore))
    local szImg = ScoreResDataTable:GetImage(nScore)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgScore, szImg:load())

    RefreshBaseStats(self, self.nMode, self.tbStats)
    RefreshPlayerInfo(self)
    RefreshFiveDimen(self)

    local CameraShot = function()
        ScreenCaptureHelper.Capture(OnScreenShotCaptureFinished, self)
        DestroyTimer(self)
    end

    self.tbDelayHandle = DelayTimer:DelayRun(CameraShot, SHOT_DELAY)

    local Component = SeasonSystem:GetComponent()
    local l10nTile
    if Component:GetSeasonId() == self.nSeasonId  then
        l10nTile = UISetUtils.GetL10NTextByKey("UI_SEASON_CURRENT")
    else
        local tbSeasonData = SeasonDataTable:GetTemplate(self.nSeasonId)
        l10nTile = tbSeasonData.l10nName
    end
    pWidgetRef.txtSeason:SetText(l10nTile)
end

local function OnSaveClicked(self)
    ClientShell.GetClient(GWorld):GetCameraShotShell():SaveScreenShot()
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("UICAMERASHOTRESULT_L10N_SAVE_PICTURE"), 1)
    self:CloseSelf()
end

local function OnCloseClicked(self)
    self:CloseSelf()
end

function UISeasonShare:OnLoad()
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef

    local pbBaseStats = {}
    local l10nTitle
    for i, v in ipairs(STATS_BASE) do
        local pbBase = PrefabHelper:BindPrefab(pWidgetRef["pbPlayerStatsBase"..i])
        l10nTitle = v.fnGetKey(i)
        pbBase:RefreshTitle(l10nTitle)
        table.insert(pbBaseStats, pbBase)
    end
    self.pbBaseStats = pbBaseStats

    self.pbPlayHead = self.PrefabHelper:BindPrefab(pWidgetRef.pbPlayHead)
    self.pbFiveDimen = self.PrefabHelper:BindPrefab(pWidgetRef.pbFiveDimensionalGraph)
end

function UISeasonShare:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSave.OnClicked, self, OnSaveClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, OnCloseClicked)
end

function UISeasonShare:OnShow()
    UIUtils.BottomMenuHide(true)

    self.nMode = self.tbOpenArgs.nMode
    self.tbStats = self.tbOpenArgs.tbStats
    self.nSeasonId = self.tbOpenArgs.nSeasonId
    RefreshUI(self)
end

function UISeasonShare:OnHide()
    UIUtils.BottomMenuHide(false)
end

function UISeasonShare:OnDestroy()
    self.nMode = nil
    self.tbStats = nil
    self.pbBaseStats = nil
    self.pbPlayHead = nil
    self.pbFiveDimen = nil

    DestroyTimer(self)
end

return UISeasonShare