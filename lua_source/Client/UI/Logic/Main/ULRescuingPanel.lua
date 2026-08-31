-----------------------------------------------------
--File Name    : ULRescuingPanel.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-08
--Description  : 救援面板
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULRescuingPanel = luaclass("ULRescuingPanel", UILogicBase)

local ClientEventDef = require("ClientEventDef")
local ProgressBarHelper = require("ProgressBarHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function OnEnterRescuingTrigger(self)
    self.pWidgetRef.btnRescue:SetVisibility(ESlateVisibility.Visible)
end

local function OnExitRescuingTrigger(self)
    self.pWidgetRef.btnRescue:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnClickedBtnRescue(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not ProgressBarHelper.CanStartHumanProgressBar(PlayerSelf) then
        return
    end
    PlayerSelf.BattleRescuingComponent:RequestRescueTeammate()
end

function ULRescuingPanel:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_ENTER_RESCUING_TRIGGER, self, OnEnterRescuingTrigger)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_EXIT_RESCUING_TRIGGER, self, OnExitRescuingTrigger)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnRescue.OnClicked, self, OnClickedBtnRescue)
end

function ULRescuingPanel:OnEnter()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf
    and PlayerSelf.BattleRescuingComponent
    and PlayerSelf.BattleRescuingComponent:IsExistValidRescuingTarget() then
        OnEnterRescuingTrigger(self)
    end
end

return ULRescuingPanel