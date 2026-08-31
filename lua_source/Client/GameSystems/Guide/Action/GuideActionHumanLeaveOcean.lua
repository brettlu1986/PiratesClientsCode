-----------------------------------------------------
--File Name    : GuideActionHumanLeaveOcean.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionBase               = require("GuideActionBase")
local GuideActionHumanLeaveOcean    = luaclass("GuideActionHumanLeaveOcean", GuideActionBase)

local ClientEventDef    = require("ClientEventDef")
local HumanSwimmingIni  = require("HumanSwimmingIni")

function GuideActionHumanLeaveOcean:OnSwimingStaminaChange(nStamina, nPercent)
    self:DebugLog(" GuideActionHumanLeaveOcean:OnSwimingStaminaChange, nStamina = " .. nStamina .. " nPercent = " .. nPercent)
    if nStamina >= HumanSwimmingIni.nMaxStamina then
        self:EndAction()
    end
end

function GuideActionHumanLeaveOcean:DoAction(tbTemplate)
    GuideActionHumanLeaveOcean.super.DoAction(self, tbTemplate)
    local EventHelper = self.EventHelper
    EventHelper:UnregisterAll()
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_HUMAN_SWIMMING_STAMINA_CHANGE, self, self.OnSwimingStaminaChange)
end

function GuideActionHumanLeaveOcean:EndAction()
    self:DebugLog("EndAction")
    self:ForceEndCurrentStep()
end

return GuideActionHumanLeaveOcean
