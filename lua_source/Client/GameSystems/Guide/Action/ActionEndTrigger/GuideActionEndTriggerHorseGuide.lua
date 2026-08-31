-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionEndTriggerBase               = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerHorseGuide       = luaclass("GuideActionEndTriggerHorseGuide", GuideActionEndTriggerBase)

local ClientEventDef = require("ClientEventDef")
-----------------------------------------------------

function GuideActionEndTriggerHorseGuide:BindEvent(tbParam)
    GuideActionEndTriggerHorseGuide.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ON_HORSE_BTN_DOWN, self, self.Triggered)
end

return GuideActionEndTriggerHorseGuide
