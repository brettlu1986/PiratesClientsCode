-----------------------------------------------------
--File Name    : GuideActionForceEndGroup.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionForceEndBase       = require("GuideActionForceEndBase")
local GuideActionForceEndStep       = luaclass("GuideActionForceEndStep", GuideActionForceEndBase)
-----------------------------------------------------

--member veriable
-----------------------------------------------------

function GuideActionForceEndStep:OnTriggered()
    GuideActionForceEndStep.super.OnTriggered(self)
    self:ForceEndCurrentStep()
end

return GuideActionForceEndStep
