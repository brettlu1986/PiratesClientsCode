local luaclass = require("luaclass")
local CommonAwardSession = require("CommonAwardSession")
local ScheduleRouletteAwardSession = luaclass("ScheduleRouletteAwardSession", CommonAwardSession)
local AwardSystem = require("AwardSystem")
local ScheduleSystem = require("ScheduleSystem")

function ScheduleRouletteAwardSession:OnStarted(tbPacket)
    ScheduleSystem:GetScheduleAward(tbPacket)
end

function ScheduleRouletteAwardSession:OnFinished()
    ScheduleRouletteAwardSession.super.OnFinished(self)
    AwardSystem:ShowCacheAward()
end

function ScheduleRouletteAwardSession:OnCanceled()
    self:FinishSelf()
end

function ScheduleRouletteAwardSession:FinishSelf()
    ScheduleRouletteAwardSession.super.OnFinished(self)
    AwardSystem:ShowCacheAward()
end

function ScheduleRouletteAwardSession:TryFinish()
end

function ScheduleRouletteAwardSession:CheckShowAward(nSourceType)
    return false
end

return ScheduleRouletteAwardSession