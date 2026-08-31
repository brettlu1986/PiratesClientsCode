-----------------------------------------------------
--File Name    : GuideActionForceEndGroup.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionForceEndBase       = require("GuideActionForceEndBase")
local GuideActionForceEndGroup      = luaclass("GuideActionForceEndGroup", GuideActionForceEndBase)
-----------------------------------------------------

--member veriable
-----------------------------------------------------

function GuideActionForceEndGroup:OnTriggered()
    GuideActionForceEndGroup.super.OnTriggered(self)
    self:ForceEndCurrentGroup()
end

return GuideActionForceEndGroup
