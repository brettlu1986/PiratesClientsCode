-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerStepNotFinish    = luaclass("GuideActionEndTriggerStepNotFinish", GuideActionEndTriggerBase)

local GuideSystem = require("GuideSystem")
-----------------------------------------------------

function GuideActionEndTriggerStepNotFinish:BindEvent(tbParam)
    GuideActionEndTriggerStepNotFinish.super.BindEvent(self, tbParam)
    local nModuleId = tonumber(tbParam[1])
    local nGroupId = tonumber(tbParam[2])
    local nStepId = tonumber(tbParam[3])
    local nStatus = GuideSystem:GetStepStatus(nModuleId, nGroupId, nStepId)
    self:DebugLog("stepnotfinish, nStatus = " .. tostring(nStatus))
    if nStatus == 1 then
        self:Triggered()
    end
end

return GuideActionEndTriggerStepNotFinish
