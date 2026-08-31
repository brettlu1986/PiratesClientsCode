local luaclass  = require("luaclass")
local WndBase   = require("WndBase")
local UISeasonRankUp = luaclass("UISeasonRankUp", WndBase)
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local RankDataTable = require("RankDataTable")
-- local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local DelayTimer = require("DelayTimer")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local SeasonIni = require("SeasonIni")
local ScreenCaptureHelper = require("ScreenCaptureHelper")
local SeasonHelper = require("SeasonHelper")
local SeasonSystem = require("SeasonSystem")

local SHOT_DELAY = 0.2
local ANI_DELAY = 1.1
local RANK_SUB_MAX = 5
UISeasonRankUp.pbPlayerSeason = nil

local BATTLE_MODES = {
    [1] = UISetUtils.GetL10NTextByKey("BATTLE_MODE_ONE"),
    [2] = UISetUtils.GetL10NTextByKey("BATTLE_MODE_TWO"),
    [4] = UISetUtils.GetL10NTextByKey("BATTLE_MODE_FOUR")
}

local function TransformationSubRank(nSubRank)
    if nSubRank == 0 then
        return nSubRank
    else
        return RANK_SUB_MAX - nSubRank + 1
    end
end

local function GetNextRankPoint(nRank, nPoint)
    local tbContainer = RankDataTable:GetContainer()
    local nTemp, nRet = 9999999, 0
    for k, v in pairs(tbContainer) do
        local nValue = v.nRankPoint - nPoint
        if nValue >= 0 and nValue < nTemp then
            nTemp = nValue
            nRet = v.nRankPoint
        end
    end

    if nRet == 0 then
        nRet = SeasonIni.tbRank.nDefaultStarRankPoint
    end
    return nRet
end

local function GetLastNextStarPoint(nRank)
    local tbRankData = RankDataTable:GetTemplate(nRank)
    local nLastPoint = tbRankData.nRankPoint
    local tbNextRankData = RankDataTable:GetTemplateByRankLevel(tbRankData.nRankLevel + 1)
    local nNextPoint = tbNextRankData.nRankPoint
    return nLastPoint, nNextPoint
end

local function RefreshOldRankUI(self)
    local tbData = self.tbOpenArgs
    local Collapsed, Visible = ESlateVisibility_Collapsed, ESlateVisibility_Visible

    self.pbPlayerSeason:OnRefresh({mode = tbData.mode, rank_point = tbData.rank_point, rank = tbData.old_rank})
    local pPlayerWidget = self.pbPlayerSeason.pWidgetRef
    pPlayerWidget.hbScore:SetVisibility(Collapsed)
    pPlayerWidget.txtRank:SetVisibility(Collapsed)

    local pWidgetRef = self.pWidgetRef

    local nSubRank = math.fmod(tbData.old_rank, 10)
    nSubRank = TransformationSubRank(nSubRank)
    local tbRankData = RankDataTable:GetTemplate(tbData.old_rank)
    local l10nRank
    if nSubRank == 0 then--最高段位
        l10nRank = tbRankData.l10nName
        pWidgetRef.kmtxtTitleName:SetText(tbRankData.l10nName)
        local nNextRankPoint = GetNextRankPoint(tbData.old_rank, tbRankData.nRankPoint)
        pWidgetRef.progressBattleStar:SetPercent((tbData.rank_point - tbRankData.nRankPoint) / (nNextRankPoint - tbRankData.nRankPoint))
    else
        nSubRank = math.min(nSubRank, RANK_SUB_MAX)
        local l10nSubRank = UISetUtils.GetL10NTextByKey("SEASON_RANK_"..nSubRank)
        l10nRank = L10N:Format(l10nSubRank, tbRankData.l10nName)
        pWidgetRef.kmtxtTitleName:SetText(l10nRank)
        local nLastPoint, nNextPoint = GetLastNextStarPoint(tbData.old_rank)
        pWidgetRef.progressBattleStar:SetPercent((tbData.rank_point - nLastPoint) / (nNextPoint - nLastPoint))
    end

    pWidgetRef.btnShow:SetVisibility(tbData.rank_change > 0 and Visible or Collapsed)
    --tbData.rank_change
    if tbData.rank_change ~= 0 then
        local szModeStr = BATTLE_MODES[tbData.mode]
        local szChange = ""
        if tbData.rank_change > 0 then
            szChange = string.format("+%d", tbData.rank_change)
        else
            szChange = string.format("-%d", math.abs(tbData.rank_change))
        end
        local nOldRankPoint = tbData.rank_point - tbData.point_change
        local szPointChange = ""
        if tbData.point_change > 0 then
            szPointChange = string.format("+%d", tbData.point_change)
        else
            szPointChange = string.format("-%d", math.abs(tbData.point_change))
        end
        local l10n = L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_UP_DESC"), szModeStr, nOldRankPoint, szPointChange, szChange)
        pWidgetRef.txtDesc:SetText(l10n)
    elseif tbData.protect_change ~= 0 then
        if tbData.point_change > 0 then
            pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAESON_RANK_PROTECT_RESET"), tbData.rank_protect))
        else
            -- 段位保护
            pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAESON_RANK_PROTECT_DESC"), tbData.rank_protect))
        end
    end
end

local function RefreshCurRankUI(self)
    local tbData = self.tbOpenArgs
    local Collapsed, Visible = ESlateVisibility_Collapsed, ESlateVisibility_Visible

    self.pbPlayerSeason:OnRefresh(tbData)
    local pPlayerWidget = self.pbPlayerSeason.pWidgetRef
    pPlayerWidget.hbScore:SetVisibility(Collapsed)
    pPlayerWidget.txtRank:SetVisibility(Collapsed)

    local pWidgetRef = self.pWidgetRef

    local nSubRank = math.fmod(tbData.rank, 10)
    nSubRank = TransformationSubRank(nSubRank)
    local tbRankData = RankDataTable:GetTemplate(tbData.rank)
    local l10nRank
    if nSubRank == 0 then--最高段位
        l10nRank = tbRankData.l10nName
        pWidgetRef.kmtxtTitleName:SetText(tbRankData.l10nName)
        local nNextRankPoint = GetNextRankPoint(tbData.rank, tbRankData.nRankPoint)
        pWidgetRef.progressBattleStar:SetPercent((tbData.rank_point - tbRankData.nRankPoint) / (nNextRankPoint - tbRankData.nRankPoint))
    else
        nSubRank = math.min(nSubRank, RANK_SUB_MAX)
        local l10nSubRank = UISetUtils.GetL10NTextByKey("SEASON_RANK_"..nSubRank)
        l10nRank = L10N:Format(l10nSubRank, tbRankData.l10nName)
        pWidgetRef.kmtxtTitleName:SetText(l10nRank)
        local nLastPoint, nNextPoint = GetLastNextStarPoint(tbData.rank)
        pWidgetRef.progressBattleStar:SetPercent((tbData.rank_point - nLastPoint) / (nNextPoint - nLastPoint))
    end

    pWidgetRef.btnShow:SetVisibility(tbData.rank_change > 0 and Visible or Collapsed)
    --tbData.rank_change
    if tbData.rank_change ~= 0 then
        local szModeStr = BATTLE_MODES[tbData.mode]
        local szChange = ""
        if tbData.rank_change > 0 then
            szChange = string.format("+%d", tbData.rank_change)
        else
            szChange = string.format("-%d", math.abs(tbData.rank_change))
        end
        local nOldRankPoint = tbData.rank_point - tbData.point_change
        local szPointChange = ""
        if tbData.point_change > 0 then
            szPointChange = string.format("+%d", tbData.point_change)
        else
            szPointChange = string.format("-%d", math.abs(tbData.point_change))
        end
        local l10n = L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_UP_DESC"), szModeStr, nOldRankPoint, szPointChange, szChange)
        pWidgetRef.txtDesc:SetText(l10n)
    elseif tbData.protect_change ~= 0 then
        if tbData.point_change > 0 then
            pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAESON_RANK_PROTECT_RESET"), tbData.rank_protect))
        else
            -- 段位保护
            pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAESON_RANK_PROTECT_DESC"), tbData.rank_protect))
        end
    end
end

local function DestroyTimer(self)
    if self.tbDelayHandle ~= nil then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

local function OnScreenShotCaptureFinished(self, Width, Height, ShotTexture)
    local tbOpenArg =
    {
        Width = Width,
        Height = Height,
        ShotTexture = ShotTexture,
    }
    UIManager:OpenWnd(UIDef.UI_FFA_BATTLE_SHARE, tbOpenArg)

    local Visible = ESlateVisibility.Visible
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnOk:SetVisibility(Visible)
    pWidgetRef.btnShow:SetVisibility(Visible)
end

local function OnClickedOk(self)
    self:CloseSelf()
end

local function OnClickedShow(self)
    local CameraShot = function()
        ScreenCaptureHelper.Capture(OnScreenShotCaptureFinished, self)
        DestroyTimer(self)
    end
    local Collapsed = ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnOk:SetVisibility(Collapsed)
    pWidgetRef.btnShow:SetVisibility(Collapsed)
    DestroyTimer(self)
    self.tbDelayHandle = DelayTimer:DelayRun(CameraShot, SHOT_DELAY)
end

function UISeasonRankUp:OnLoad()
    self.pbPlayerSeason = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerSeason)
end

function UISeasonRankUp:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnOk.OnClicked,  self, OnClickedOk)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnShow.OnClicked,  self, OnClickedShow)
end

function UISeasonRankUp:OnShow()
    RefreshOldRankUI(self)

    local bPlaySub = false
    local Component = SeasonSystem:GetComponent()
    local nOldSubRank, nOldMainRank = SeasonHelper:GetRank(self.tbOpenArgs.old_rank)
    local tbCurRank = Component:GetCurRankByMode(self.tbOpenArgs.mode)
    local nNewSubRank, nNewMainRank = SeasonHelper:GetRank(tbCurRank.rank)
    if nNewMainRank == nOldMainRank then
        if nOldSubRank ~= nNewSubRank then
            bPlaySub = true
            self:PlayAnimation("animRankLevelUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
            self.pbPlayerSeason:PlaySubAnimation(nNewSubRank < nOldSubRank)
        end
    end

    if not bPlaySub then
        local fnCurRank = function()
            RefreshCurRankUI(self)
            self.pbPlayerSeason:PlayCurAnimation()
        end

        if self.tbOpenArgs.rank_change > 0 then
            self:PlayAnimation("animRankUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self:PlayAnimation("animRankDown", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
        self.tbDelayHandle = DelayTimer:DelayRun(fnCurRank, ANI_DELAY)
    end
end

function UISeasonRankUp:OnDestroy()
    self.pbPlayerSeason = nil
    DestroyTimer(self)
end

return UISeasonRankUp