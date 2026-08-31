-----------------------------------------------------
--File Name    : GuideTriggerOpenUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideTrigger              = require("GuideTrigger")
local GuideActionStepStatus     = luaclass("GuideActionStepStatus", GuideTrigger)

-- local GuideSystem   = require("GuideSystem")
-----------------------------------------------------

-- function GuideActionStepStatus:StepStatus()
--     GuideSystem:GetStepStatus()
-- end
-- --override
-- function GuideActionStepStatus:Begin()
--     GuideActionStepStatus.super.Begin(self)
--     self:Trigger()
-- end

return GuideActionStepStatus
