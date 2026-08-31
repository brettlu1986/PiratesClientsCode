-----------------------------------------------------
--File Name    : UISeasonRank.lua
--Description  : 赛季段位界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonRank2 = luaclass("UISeasonRank2", WndBase)
local SeasonSystem = require("SeasonSystem")
-- local UIResourceDef = require("UIResourceDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local SelfTabBarHelper = require("SelfTabBarHelper")

local TAB = {
    "ULSeasonRank",
    "ULSeasonRecord"
}

local WIDGET_NAME = {
    "cpRank",
    "kmList"
}

local DEFAULT_TAB = 1
local HAS_CHEST_RES = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeasonBoxNormal.Spr_LobbySeasonBoxNormal'"
local NOHAS_CHEST_RES = "PaperSprite'/Game/UI/Textures/UI_LobbySeason/Frames/Spr_LobbySeasonBoxPressed.Spr_LobbySeasonBoxPressed'" 
-- local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE["SLATE_COLOR"]
-- local SLATE_COLOR_BLACK = UIResourceDef.COLOR.BLACK["SLATE_COLOR"]

UISeasonRank2.tbTabBarHelper = nil
UISeasonRank2.pbWindowFrame = nil
-------------------------------------------------------------------------------------------------------

local function RefreshChest(self)
    local Component = SeasonSystem:GetComponent()
    local bHas = Component:IsHasDailyChest()
    local pWidgetRef = self.pWidgetRef
    --pWidgetRef.cbRank1:HideTipIcon(not bHas)
    self.tbTabBarHelper:SetTipIconVisible(1, bHas)
    UISetUtils.SetButtonBrushRes(pWidgetRef.btnAward, bHas and HAS_CHEST_RES:load() or NOHAS_CHEST_RES:load())
    if bHas then
        pWidgetRef.img_SeasonBoxGlow02:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pWidgetRef.img_SeasonBoxGlow03:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self:PlayAnimation("anim_SeasonBoxGlow", 0, 0, EUMGSequencePlayMode.Forward)
        pWidgetRef.btnAward:HideTipIcon(false)
    else
        pWidgetRef.img_SeasonBoxGlow02:SetVisibility(ESlateVisibility_Collapsed)
        pWidgetRef.img_SeasonBoxGlow03:SetVisibility(ESlateVisibility_Collapsed)
        self:StopAnimation("anim_SeasonBoxGlow")
        pWidgetRef.btnAward:HideTipIcon(true)
    end
end

local function OnClickTab(self, nIndex)
    local pWidgetRef = self.pWidgetRef
    local tbUL = self.UILogicHelper.tbUILogicList
    for i = 1, #TAB do
        if i == nIndex then
            pWidgetRef[WIDGET_NAME[i]]:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
            --pWidgetRef["cbRank"..i]:SetCheckedState(CHECKED)
            -- pWidgetRef["txtName"..i]:SetColorAndOpacity(SLATE_COLOR_BLACK)
            tbUL[i]:Activate()
        else
            pWidgetRef[WIDGET_NAME[i]]:SetVisibility(ESlateVisibility_Collapsed)
            --pWidgetRef["cbRank"..i]:SetCheckedState(UNCHECKED)
            -- pWidgetRef["txtName"..i]:SetColorAndOpacity(SLATE_COLOR_WHITE)
            tbUL[i]:Deactivate()
        end
    end
end

local function OnClickedBack(self)
    self:CloseSelf()
    UIUtils.BottomMenuSelect(1, true)
end

function UISeasonRank2:OnLoad()
    local UILogicHelper = self.UILogicHelper

    for i = 1, #TAB do
        UILogicHelper:CreateUILogic(TAB[i])
    end

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnClickedBack, self)
    self.tbTabBarHelper = SelfTabBarHelper()
    self.tbTabBarHelper:Init(self, self.pWidgetRef.vboxTab, -1)
    self.tbTabBarHelper.OnSelectedChangedDelegate:Bind(OnClickTab, self)
end

function UISeasonRank2:OnUnload()
    if self.tbTabBarHelper then
        self.tbTabBarHelper:Uninit()
        self.tbTabBarHelper = nil
    end
end

function UISeasonRank2:OnBindEvent(EventHelper)
    --local pWidgetRef = self.pWidgetRef
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked,  self, OnClickedBack)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, self, RefreshChest)   
    
end

function UISeasonRank2:OnShow()
    -- UIUtils.BottomMenuHide(true)
    LobbySystem:GetSub(LobbySubTypeDef.SEASON):SetViewTarget(nil)
    self:PlayAnimation("anim_SeasonRankIn", 0, 1, EUMGSequencePlayMode.Forward, 1)

    local Component = SeasonSystem:GetComponent()

    SeasonSystem:RequestGetSeasonPointRanking()
    
    local tbStats = Component:GetSeasonStats()
    local nCurSeasonId = Component:GetSeasonId()
    if tbStats == nil or tbStats[nCurSeasonId] == nil then    
        SeasonSystem:RequestGetSeasonStats()
    end
    local tbSummaries = Component:GetSeasonHistorySummaries()
    
    if tbSummaries == nil then
        SeasonSystem:RequestGetSeasonHitorySummaries()
    end
    RefreshChest(self)
    --OnClickTab(self, DEFAULT_TAB)
    self.tbTabBarHelper:SelectByIndex(DEFAULT_TAB, true)
end

function UISeasonRank2:OnHide()
    -- UIUtils.BottomMenuHide(false)
end

return UISeasonRank2