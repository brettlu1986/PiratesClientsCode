-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTriggerPoisonCircleCountdown = require("GuideTriggerPoisonCircleCountdown")
local GuideTriggerPoisonCircleCount     = luaclass("GuideTriggerPoisonCircleCount", GuideTriggerPoisonCircleCountdown)

local Proto             = require("DungeonRepProtoNames")
-----------------------------------------------------
GuideTriggerPoisonCircleCount.nPoisonCircleCount    = 0
GuideTriggerPoisonCircleCount.nCount                = 0
-----------------------------------------------------
function GuideTriggerPoisonCircleCount:OnFFAPoisonCircleTimerUpdate(tbInfo)
    local nState = tbInfo ~= nil and tbInfo.nState
    self:DebugLog("OnFFAPoisonCircleTimerUpdate, nState = " .. tbInfo.nState)
    if nState == Proto.rFFAPoisonCircleInfo_EStageState.WAIT then
        self.nPoisonCircleCount = self.nPoisonCircleCount + 1
        self:DebugLog("nPoisonCircleCount = " .. self.nPoisonCircleCount)
        if self.nPoisonCircleCount >= self.nCount then
            self:Execute()
        end
    end
end

function GuideTriggerPoisonCircleCount:Execute()
    self:Trigger()
end

--override
function GuideTriggerPoisonCircleCount:Begin()
    GuideTriggerPoisonCircleCount.super.Begin(self)
    local tbParam = self.tbTemplate.tbParam
    if not tbParam then
        return
    end
    self.nCount = tonumber(tbParam[1])
end

return GuideTriggerPoisonCircleCount
