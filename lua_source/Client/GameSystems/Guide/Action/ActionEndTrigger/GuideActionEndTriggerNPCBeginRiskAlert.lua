-----------------------------------------------------
--File Name    : GuideActionEndTriggerNPCBeginRiskAlert.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerNPCBeginRiskAlert    = luaclass("GuideActionEndTriggerNPCBeginRiskAlert", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function CheckNpcBeginRiskAlert(self, Owner, nNewRiskAlertTarget)
    self:DebugLog("[NpcForceEndStep] CheckNpcBeginRiskAlert ".. nNewRiskAlertTarget..", ".. GamePlayerSelfHelper:GetServerInstanceId())
    if nNewRiskAlertTarget == GamePlayerSelfHelper:GetServerInstanceId() then
        self:DebugLog("[NpcForceEndStep] CheckNpcBeginRiskAlert end!".. Owner:GetServerInstanceId())
        self:Triggered()
    end
end

function GuideActionEndTriggerNPCBeginRiskAlert:BindEvent(tbParam)
    GuideActionEndTriggerNPCBeginRiskAlert.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NPC_RISKALERTTARGET_CHANGED, self, CheckNpcBeginRiskAlert)
end

return GuideActionEndTriggerNPCBeginRiskAlert
