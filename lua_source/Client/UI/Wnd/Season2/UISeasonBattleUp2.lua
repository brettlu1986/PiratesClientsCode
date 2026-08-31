-----------------------------------------------------
--File Name    : UISeasonBattlePassAdvanceSuccess.lua
--Author       : Chen Jing
--Create Time  : 2019-03-13
--Description  : 赛季通行证进阶成功界面
-----------------------------------------------------
local luaclass  = require("luaclass")
local WndBase   = require("WndBase")
local UISeasonBattleUp2 = luaclass("UISeasonBattleUp2", WndBase)
local UISetUtils = require("UISetUtils")
local SeasonSystem = require("SeasonSystem")
-- local SeasonDataTable = require("SeasonDataTable")
local L10N = require("L10N")
-- local UIResourceDef = require("UIResourceDef")

local function RefreshUI(self)
    local pWidgetRef = self.pWidgetRef
    local Component = SeasonSystem:GetComponent()
    if self.tbOpenArgs.bIsBattlePass then
        pWidgetRef.ktxtTitle:SetText(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_PASS_SUCCESS"))
        -- UISetUtils.SetImageBrushColor(pWidgetRef.imgSeasonRank, UIResourceDef.COLOR.YELLOW1)
        pWidgetRef.ktxtContent:SetText(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_HERO"))
    elseif self.tbOpenArgs.nBattleTier then
        pWidgetRef.ktxtTitle:SetText(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_TIER_UP_SUCCESS"))
        if Component:IsPassActive() then
            -- UISetUtils.SetImageBrushColor(pWidgetRef.imgSeasonRank, UIResourceDef.COLOR.YELLOW1)
            pWidgetRef.ktxtContent:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_PASS_TIER"), UISetUtils.GetL10NTextByKey("SEASON_BATTLE_HERO"), self.tbOpenArgs.nBattleTier))
        else
            -- UISetUtils.SetImageBrushColor(pWidgetRef.imgSeasonRank, UIResourceDef.COLOR.WHITE)
            pWidgetRef.ktxtContent:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SEASON_BATTLE_PASS_TIER"), UISetUtils.GetL10NTextByKey("SEASON_BATTLE_NORMAL"), self.tbOpenArgs.nBattleTier))
        end
    end
end

local function OnClickedOk(self)
    self:CloseSelf() 
end

function UISeasonBattleUp2:OnLoad()
end

function UISeasonBattleUp2:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnYes.OnClicked,  self, OnClickedOk)
end

function UISeasonBattleUp2:OnShow()
    RefreshUI(self)
    if self.tbOpenArgs.bIsBattlePass then
        self:PlayAnimation("animBattlePassBuy", 0, 1, EUMGSequencePlayMode.Forward, 1)
    else
        local Component = SeasonSystem:GetComponent()
        if Component:IsPassActive() then
            self:PlayAnimation("animBattlePassHeroUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
        else
            self:PlayAnimation("animBattlePassWarriorUp", 0, 1, EUMGSequencePlayMode.Forward, 1)
        end
    end
end

function UISeasonBattleUp2:OnDestroy()
end

return UISeasonBattleUp2