-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerPoisonCircleCountdown = luaclass("GuideTriggerPoisonCircleCountdown", GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
local Proto             = require("DungeonRepProtoNames")
-----------------------------------------------------

function GuideTriggerPoisonCircleCountdown:OnFFAPoisonCircleTimerUpdate(tbInfo)
    local nState = tbInfo ~= nil and tbInfo.nState
    self:DebugLog("OnFFAInfoChnaged, nState = " .. tbInfo.nState)
    if nState == Proto.rFFAPoisonCircleInfo_EStageState.WAIT then
        self:Trigger()
    else
        self:Break()
    end
end

--override
function GuideTriggerPoisonCircleCountdown:Begin()
    GuideTriggerPoisonCircleCountdown.super.Begin(self)
end

function GuideTriggerPoisonCircleCountdown:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_TIMERUPDATE, self, self.OnFFAPoisonCircleTimerUpdate)
end

return GuideTriggerPoisonCircleCountdown
