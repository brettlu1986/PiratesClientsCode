local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPlayerSeasonUp = luaclass("UPPlayerSeasonUp", PrefabBase)
local RankDataTable = require("RankDataTable")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local L10N = require("L10N")
local SeasonIni = require("SeasonIni")
local UISetUtils = require("UISetUtils")
local SeasonHelper = require("SeasonHelper")

-- message Rank {
--     int32 mode           = 1;  // 游戏模式 - 单人、双人、小队
--     int32 rank           = 2;  // 段位
--     int32 rank_point     = 3;  // 段位积分
-- }

UPPlayerSeasonUp.tbData = nil

local RANK_SUB_MAX = 5

local function TransformationSubRank(nSubRank)
    if nSubRank == 0 then
        return nSubRank
    else
        return RANK_SUB_MAX - nSubRank + 1
    end
end

local function GetStar(nPoint)
    if nPoint == nil then
        return 1
    end
    local nMinPoint = SeasonIni.tbRank.nDefaultStarRankPoint
    local nStar = math.modf((nPoint - nMinPoint) / 100) + 1
    return nStar
end

local function RefreshUI(self)
    local tbData = self.tbData
    local pWidgetRef = self.pWidgetRef
    local Collapsed, Visible = ESlateVisibility_Collapsed, ESlateVisibility_Visible

    local tbModeData = MatchmakingTeamModeDataTable:GetTemplate(tbData.mode)
    if tbModeData and not tbData.bHidePoint then
        pWidgetRef.txtMode:SetText(tbModeData.l10nDesc)
    else
        pWidgetRef.txtMode:SetText("")
    end

    if tbData.rank_point == nil or tbData.bHidePoint then
         pWidgetRef.txtScore:SetText("")
    else
        pWidgetRef.txtScore:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_RANK_SCORE"), tbData.rank_point))
    end

    local nSubRank = math.fmod(tbData.rank, 10)
    nSubRank = TransformationSubRank(nSubRank)
    -- local nRank = math.modf(tbData.rank / 10)
    local tbRankData = RankDataTable:GetTemplate(tbData.rank)
    local szImg, szImgBg, szSubImg = SeasonHelper.GetImage(tbData.rank)
    if nSubRank == 0 then--最高段位
        pWidgetRef.sbSubRank:SetVisibility(Collapsed)
        pWidgetRef.hbStar:SetVisibility(Visible)
        
        if tbData.hide_rank then
            pWidgetRef.txtRank:SetText("")
        else
            pWidgetRef.txtRank:SetText(tbRankData.l10nName)
        end
        pWidgetRef.txtStar:SetText(GetStar(tbData.rank_point))
    else
        nSubRank = math.min(nSubRank, RANK_SUB_MAX)
        pWidgetRef.sbSubRank:SetVisibility(Visible)
        pWidgetRef.hbStar:SetVisibility(Collapsed)
        -- pWidgetRef.hbStarAll:SetVisibility(Visible)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgRankSub_1, szSubImg:load())
        if tbData.hide_rank then
            pWidgetRef.txtRank:SetText("")
        else
            local l10nSubRank = UISetUtils.GetL10NTextByKey("SEASON_RANK_"..nSubRank)
            pWidgetRef.txtRank:SetText(L10N:Format(l10nSubRank, tbRankData.l10nName))
        end
    end

    UISetUtils.SetImageBrushRes(pWidgetRef.imgRank, szImg:load())
    UISetUtils.SetImageBrushRes(pWidgetRef.imgBgS, szImgBg:load())
end

function UPPlayerSeasonUp:OnRefresh(tbData)
    self.tbData = tbData
    RefreshUI(self)
end

function UPPlayerSeasonUp:OnLoad()
    -- if self.tbData.rank
end

function UPPlayerSeasonUp:PlayCurAnimation()
    local nMainRank = math.modf(self.tbData.rank / 10)
    if nMainRank <= 7 then
        self:PlayAnimation("animRankUpBaseFx", 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        self:PlayAnimation("animRankUpBaseTopFx", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
    self:PlayAnimation("animRankMask_0"..nMainRank, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPPlayerSeasonUp:PlaySubAnimation(bUp)
    if bUp then
        self:PlayAnimation("animRankUpLevelUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        self:PlayAnimation("animRankUpLevelDown", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end
end

return UPPlayerSeasonUp