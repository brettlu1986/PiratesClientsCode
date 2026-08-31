local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSeasonRankMode2 = luaclass("UPSeasonRankMode2", PrefabBase)
local RankDataTable = require("RankDataTable")
local SeasonIni = require("SeasonIni")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")

UPSeasonRankMode2.tbData = nil
UPSeasonRankMode2.pbPlayerSeason = nil

-- message Rank {
--     int32 mode           = 1;  // 游戏模式 - 单人、双人、小队
--     int32 rank           = 2;  // 段位
--     int32 rank_point     = 3;  // 段位积分
-- }

local BATTLE_MODES = {
    [1] = UISetUtils.GetL10NTextByKey("BATTLE_MODE_ONE"),
    [2] = UISetUtils.GetL10NTextByKey("BATTLE_MODE_TWO"),
    [4] = UISetUtils.GetL10NTextByKey("BATTLE_MODE_FOUR")
}

local function GetNextRankPoint(nRank, nPoint)
    local tbContainer = RankDataTable:GetContainer()
    local nTemp, nRet = 9999999, 0
    for k, v in pairs(tbContainer) do
        local nValue = v.nRankPoint - nPoint 
        if nValue > 0 and nValue < nTemp then
            nTemp = nValue
            nRet = v.nRankPoint
        end
    end

    if nRet == 0 then
        nRet = SeasonIni.tbRank.nDefaultRankPoint
    end
    return nRet
end

local function GetLastNextStarPoint(nPoint)
    local nMinPoint = SeasonIni.tbRank.nDefaultStarRankPoint
    local _, nTempPoint = math.modf((nPoint - nMinPoint) / 100)
    local nNextPoint = math.floor(nPoint + (100 - nTempPoint * 100))
    local nLastPoint = math.floor(math.max(nNextPoint - 100, nMinPoint))
    return nLastPoint, nNextPoint
end

local function RefreshUI(self)
    local tbData = self.tbData
    local pWidgetRef = self.pWidgetRef
    local tbRankData = RankDataTable:GetTemplate(tbData.rank)
    -- local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    local nSubRank = math.fmod(tbData.rank, 10)

    if nSubRank > 0 then
        local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_SCORE_TILE1"), BATTLE_MODES[tbData.mode])

        local nNextRankPoint = GetNextRankPoint(tbData.rank, tbRankData.nRankPoint)
        -- pWidgetRef.vbRank:SetVisibility(Visible)
        pWidgetRef.txtTitle:SetText(l10nTitle)
        pWidgetRef.txtPoint:SetText(string.format("%d/%d", tbData.rank_point, nNextRankPoint))    
        pWidgetRef.progressBattleStar:SetPercent((tbData.rank_point - tbRankData.nRankPoint) / (nNextRankPoint - tbRankData.nRankPoint))
    else
        local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_STAR_TILE"), BATTLE_MODES[tbData.mode])
        -- pWidgetRef.vbRank:SetVisibility(Collapsed)
        pWidgetRef.txtTitle:SetText(l10nTitle)
        local nLastPoint, nNextPoint = GetLastNextStarPoint(tbData.rank_point)
        pWidgetRef.txtPoint:SetText(string.format("%d/%d", tbData.rank_point, nNextPoint))    
        pWidgetRef.progressBattleStar:SetPercent((tbData.rank_point - nLastPoint) / (nNextPoint - nLastPoint))
    end

    tbData.bHidePoint = true
    self.pbPlayerSeason:OnRefresh(tbData)
end

function UPSeasonRankMode2:OnRefresh(tbData)
    self.tbData = tbData
    RefreshUI(self)
end

function UPSeasonRankMode2:OnLoad()
    self.pbPlayerSeason = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerSeason)
end

function UPSeasonRankMode2:OnDestroy()
    self.pbPlayerSeason = nil
end

return UPSeasonRankMode2