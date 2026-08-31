-----------------------------------------------------
--File Name    : GuideAction.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionForceEndGroup      = require("GuideActionForceEndGroup")
local GuideActionForceEndHorseGuide = luaclass("GuideActionForceEndHorseGuide", GuideActionForceEndGroup)

local ClientEventDef    = require("ClientEventDef")
-----------------------------------------------------
--member veriable
-----------------------------------------------------
function GuideActionForceEndHorseGuide:BindEvent(tbTemplate)
    self:DebugLog("GuideActionForceEndHorseGuide:BindEvent")
    GuideActionForceEndHorseGuide.super.BindEvent(self, tbTemplate)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_ON_HORSE_BTN_DOWN, self, self.ForceEndCurrentGroup)
end

return GuideActionForceEndHorseGuide
