local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSeasonRank = luaclass("ULSeasonRank", UILogicBase)
local SeasonSystem = require("SeasonSystem")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local ClientEventDef = require("ClientEventDef")
local TimeUtil = require("TimeUtil")
local UIDef = require("UIDef")

ULSeasonRank.pbModes = nil

local function RefreshSeasonRank(self, nIndex, tbRankData)
    self.pbModes[nIndex]:OnRefresh(tbRankData)
end

local function RefreshAward(self)
    -- local Component = SeasonSystem:GetComponent()
    -- local bHas = Component:IsHasDailyChest()
    -- local pWidgetRef = self.pWidgetRef
    -- local Collapsed, SelfHitTestInvisible = ESlateVisibility.Collapsed, ESlateVisibility.SelfHitTestInvisible
    -- if bHas then
    --     pWidgetRef.bdrNeed:SetVisibility(Collapsed)
    --     pWidgetRef.btnAward:HideTipIcon(false)
    --     pWidgetRef.imgBoxGlow:SetVisibility(SelfHitTestInvisible)
    -- else
    --     pWidgetRef.bdrNeed:SetVisibility(SelfHitTestInvisible)
    --     pWidgetRef.btnAward:HideTipIcon(true)
    --     pWidgetRef.imgBoxGlow:SetVisibility(Collapsed)
    -- end
end

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local Component = SeasonSystem:GetComponent()
    local tbCurRank = Component:GetCurRank()
    if tbCurRank == nil then
        -- self.pWidgetRef.cpPanel:SetVisibility(ESlateVisibility.Collapsed)
        UIUtils.ShowLoadingDialog()
        return
    end

    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    for i, v in ipairs(tbModes) do
        local txtMode = pWidgetRef["txtMode"..v.nId]
        if txtMode ~= nil then
            txtMode:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_MODE"), v.l10nDesc))
        end
        RefreshSeasonRank(self, i, tbCurRank.rank[i])
    end

    RefreshAward(self)
end

local function OnRefreshSeasonRank(self, nMode)
    local Component = SeasonSystem:GetComponent()
    local tbCurRank = Component:GetCurRank()
    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
    for i, v in ipairs(tbModes) do
        if v.nId == nMode then
            RefreshSeasonRank(self, i, tbCurRank.rank[i])
            break
        end
    end   
    RefreshAward(self) 
end

local function OnRecvSeasonData(self)
    -- self.pWidgetRef.cpPanel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    RefreshUI(self)
    UIUtils.HideLoadingDialog()
end

local function OnClickedAward(self)
    local Component = SeasonSystem:GetComponent()
    local tbCurRank = Component:GetCurRank()
    local nTime = tbCurRank ~= nil and tbCurRank.rank_daily_chest or 0
    local nRemainTime = TimeUtil.CalRefreshRemainSeconds(nTime)
    if nRemainTime <= 0 then
        SeasonSystem:RequestCollectRankDailyChest()
    else
        UIUtils.ShowToast(UITextDef.SEASON_ALREADY_GET_DAILYAWARD)
    end
end

local function OnClickedChest(self)
    local brChestDesc = self.pWidgetRef.brChestDesc
    if brChestDesc:IsVisible() then
        brChestDesc:SetVisibility(ESlateVisibility_Collapsed)
    else
        brChestDesc:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    end
end

function ULSeasonRank:Activate()
    RefreshUI(self)
end

function ULSeasonRank:Deactivate()
end

function ULSeasonRank:OnLoad()
    self.pbModes = {}
    local tbModes = MatchmakingTeamModeDataTable:GetAllMode()

    local pWidgetRef = self.pWidgetRef
    for i, v in ipairs(tbModes) do
        local pModeWidgetRef = pWidgetRef["pbRankSub"..v.nId]
        if pModeWidgetRef ~= nil then
            local pbMode = self.PrefabHelper:BindPrefab(pModeWidgetRef, UIDef.UP_SEASON_RANK_MODE)
            table.insert(self.pbModes, pbMode)
        else
            logerror("ULSeasonRank:OnLoad invalid mode ", v.nId)
        end
    end
end

function ULSeasonRank:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAward.OnClicked,  self, OnClickedAward)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnChest.OnClicked,  self, OnClickedChest)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, OnRefreshSeasonRank)   
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_GET_SEASON_DATA, self, OnRecvSeasonData)     
end

return ULSeasonRank