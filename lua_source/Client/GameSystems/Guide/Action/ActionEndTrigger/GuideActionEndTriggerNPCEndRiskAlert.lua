-----------------------------------------------------
--File Name    : GuideActionEndTriggerNPCEndRiskAlert.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerNPCEndRiskAlert    = luaclass("GuideActionEndTriggerNPCEndRiskAlert", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function CheckNpcEndRiskAlert(self, Owner, nNewRiskAlertTarget)
    self:DebugLog("[NpcForceEndStep] CheckNpcEndRiskAlert"..  nNewRiskAlertTarget..", ".. GamePlayerSelfHelper:GetServerInstanceId())
    if nNewRiskAlertTarget ~= GamePlayerSelfHelper:GetServerInstanceId()
        and Owner.NpcAIStateComponent:GetLastAlertTarget() == GamePlayerSelfHelper:GetServerInstanceId() then
        self:DebugLog("[NpcForceEndStep] CheckNpcEndRiskAlert end!".. Owner:GetServerInstanceId())
        self:Triggered()
    end
end

function GuideActionEndTriggerNPCEndRiskAlert:BindEvent(tbParam)
    GuideActionEndTriggerNPCEndRiskAlert.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NPC_RISKALERTTARGET_CHANGED, self, CheckNpcEndRiskAlert)
end

return GuideActionEndTriggerNPCEndRiskAlert
