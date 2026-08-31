-----------------------------------------------------
--File Name    : GuideActionLogEvent.lua
--Description  : 埋点
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionLogEvent       = luaclass("GuideActionLogEvent",GuideActionFunctional)

local Proto             = require("ClientProtoNames")
local NetworkManager    = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-----------------------------------------------------

function GuideActionLogEvent:DoAction(tbTemplate)
    GuideActionLogEvent.super.DoAction(self, tbTemplate)
    self:DebugLog("DoAction")
    
    local nStepId = tonumber(self.tbTemplate.tbParam[1])
    local bBegin  = (self.tbTemplate.tbParam[2] == "begin")
    local szKey   = ("LogEventKey_StepId_"..self.tbTemplate.tbParam[1])

    self:DebugLog("nStepId, bBegin, szKey:", nStepId, bBegin, szKey)

    if bBegin then
        self:SetModuleSharedInfo(szKey, GlobalVariableSystem:GetLocalTime())
    else
        local nBeginTime = self:GetModuleSharedInfo(szKey)
        local nSpentTime = 0
        if nBeginTime then
            nSpentTime = math.ceil(GlobalVariableSystem:GetLocalTime() - nBeginTime)
        end

        self:DebugLog("GuideActionLogEvent Send LogEvent Proc. nStepId, nSpentTime:",nStepId, nSpentTime)
        NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TutorialStep, {step = nStepId, spent_seconds = nSpentTime})
    end
end

return GuideActionLogEvent
