-----------------------------------------------------
--File Name    : GuideActionInterruptTouch.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionInterruptTouch = luaclass("GuideActionInterruptTouch",GuideActionFunctional)

local ClientEventDef = require("ClientEventDef")

-----------------------------------------------------
function GuideActionInterruptTouch:DoAction(tbTemplate)
    GuideActionInterruptTouch.super.DoAction(self, tbTemplate)
    self:DebugLog("GuideActionInterruptTouch:DoAction")
    self.EventHelper:FireEvent(ClientEventDef.EV_GUIDE_INTERRUPT_TOUCH)
end

return GuideActionInterruptTouch
