-----------------------------------------------------
--File Name    : GuideTriggerOpenUI.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerStepIsFinish      = luaclass("GuideTriggerStepIsFinish",GuideTrigger)

local GuideSystem           = require("GuideSystem")
-----------------------------------------------------
GuideTriggerStepIsFinish.nModuleId  = nil
GuideTriggerStepIsFinish.nGroupId   = nil
GuideTriggerStepIsFinish.nStepId    = nil
-----------------------------------------------------

local function IsStepFinish(self)
    local nStatus = GuideSystem:GetStepStatus(self.nModuleId, self.nGroupId, self.nStepId)
    self:DebugLog("IsStepFinish, nStatus = " .. tostring(nStatus))
    if nStatus == 1 then
        return true
    end
    return false
end

--override
function GuideTriggerStepIsFinish:Begin()
    GuideTriggerStepIsFinish.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.nModuleId = tonumber(tbParam[1])
    self.nGroupId = tonumber(tbParam[2])
    self.nStepId = tonumber(tbParam[3])
    if IsStepFinish(self) then
        self:Trigger()
    end
end

return GuideTriggerStepIsFinish
