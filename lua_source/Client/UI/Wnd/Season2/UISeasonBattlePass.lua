-----------------------------------------------------
--File Name    : UISeasonBattlePass.lua
--Description  : 赛季通行证界面
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISeasonBattlePass = luaclass("UISeasonBattlePass", WndBase)
local ClientEventDef = require("ClientEventDef")
local SeasonSystem = require("SeasonSystem")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
-- local UISetUtils = require("UISetUtils")
local Proto = require("ClientProtoNames")
local CHALLENGETYPEDEF = Proto.ChallengeType

-- local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE["SLATE_COLOR"]
-- local SLATE_COLOR_BLACK = UIResourceDef.COLOR.BLACK["SLATE_COLOR"]
-- local IMG_HAS_AWARD = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonMYellow_Normal.Spr_ButtonMYellow_Normal'"
-- local IMG_NO_AWARD = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_ButtonM_Normal.Spr_ButtonM_Normal'"

UISeasonBattlePass.pbWindowFrame = nil
UISeasonBattlePass.ulSeasonBattleTier = nil
-------------------------------------------------------------------------------------------------------
local function OnClickedBack(self)
    self:CloseSelf()
    UIUtils.BottomMenuSelect(1, true)
    if self.tbOpenArgs.szFrom then
        UIManager:OpenWnd(UIDef.UI_SCHEDULE)
    end 
end

local function RefreshSeasonAwardTip(self)
    local Component = SeasonSystem:GetComponent()
    if Component:HasBattleTierAwards() then
        self.pWidgetRef.btnGetAward:SetVisibility(ESlateVisibility_Visible)
        -- self:PlayAnimation("anim_GetAward", 0, 0, EUMGSequencePlayMode.Forward, 1)
        -- self.pWidgetRef.btnGetAward:HideTipIcon(false)
        -- UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnGetAward, IMG_HAS_AWARD:load())
    else
        self.pWidgetRef.btnGetAward:SetVisibility(ESlateVisibility_Collapsed)
        -- self:StopAnimation("anim_GetAward")
        -- self.pWidgetRef.btnGetAward:HideTipIcon(true)
        -- UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnGetAward, IMG_NO_AWARD:load())
    end
end

local function RefreshSeasonChallengeAwardTip(self)
    local Component = SeasonSystem:GetComponent()
    self.pWidgetRef.btnChallenge:HideTipIcon(not Component:GetChallengeAwardStatus())
end

local function RefreshTip(self)
    RefreshSeasonChallengeAwardTip(self)
    RefreshSeasonAwardTip(self)
end

function UISeasonBattlePass:OnLoad()
    local UILogicHelper = self.UILogicHelper
    self.ulSeasonBattleTier = UILogicHelper:CreateUILogic("ULSeasonBattleTier")

    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(OnClickedBack, self)
end

function UISeasonBattlePass:OnUnload()
end

function UISeasonBattlePass:OnBindEvent(EventHelper)
    --local pWidgetRef = self.pWidgetRef
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked,  self, OnClickedBack)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE_AWARD_STATUS, self, RefreshSeasonChallengeAwardTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS, self, RefreshSeasonAwardTip)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_BATTLE_TIER_AWARD, self, RefreshSeasonAwardTip)
end

function UISeasonBattlePass:OnShow()
    -- UIUtils.BottomMenuHide(true)
    log("UISeasonBattlePass:OnShow")
    SeasonSystem:RequestGetChallenge(CHALLENGETYPEDEF.DAILY)
    SeasonSystem:RequestGetChallenge(CHALLENGETYPEDEF.WEEKLY)
    SeasonSystem:RequestGetChallenge(CHALLENGETYPEDEF.SEASONAL)    

    self.ulSeasonBattleTier:Activate(self.tbOpenArgs.tbExtendData)

    RefreshTip(self)
    if self.tbOpenArgs.tbExtendData == nil then
        local SeasonComponent = SeasonSystem:GetComponent()
        local bActive = SeasonComponent:IsPassActive()
        if bActive then    
            self:PlayAnimation("anim_SeasonBattlePass_HeroIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self:PlayAnimation("anim_SeasonBattlePass_WarriorIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
    end
    self:PlayAnimation("anim_BuyHeroBattle", 0, 0, EUMGSequencePlayMode.Forward, 1)

    log("UISeasonBattlePass:OnShow end")
end

function UISeasonBattlePass:OnHide()
    self.ulSeasonBattleTier:Deactivate()
    -- UIUtils.BottomMenuHide(false)
end

return UISeasonBattlePass