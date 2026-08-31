-----------------------------------------------------
--File Name    : GuideActionEndTriggerControlModeActive.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerControlModeActive    = luaclass("GuideActionEndTriggerControlModeActive", GuideActionEndTriggerBase)

local ClientEventDef = require("ClientEventDef")
-----------------------------------------------------

function GuideActionEndTriggerControlModeActive:BindEvent(tbParam)
    GuideActionEndTriggerControlModeActive.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, self.Triggered)
end

return GuideActionEndTriggerControlModeActive
