-----------------------------------------------------
--File Name    : SelfTimerHelper.lua
--Author       : Song Fuhao
--Create Time  : 2016-12-14
--Description  : 用于UI等需要对Timer进行统一管理模块上的工具类
-----------------------------------------------------

local luaclass = require("luaclass")
local SelfTimerHelper = luaclass("SelfTimerHelper")

local Timer = require("Timer")

SelfTimerHelper.tbTimers = {}

local ONE_TICK_TIME = 1 / 60

function SelfTimerHelper:ClearAllTimer()
    for _,v in pairs(self.tbTimers) do
        v:Clear()
    end
    self.tbTimers = {}
end

-- function SelfTimerHelper:StopAllTimer()
--     for k,v in pairs(self.tbTimers) do
--         v:Stop()
--     end
-- end

function SelfTimerHelper:NewTimer(fnCallback, nTime, bLooping)
    local OneTimer = Timer.NewTimer(fnCallback, nTime, bLooping)
    self.tbTimers[OneTimer] = OneTimer
    return OneTimer
end

function SelfTimerHelper:StartTimer(OneTimer, fnCallback, nTime, bLooping)
    local TempTimer = Timer.StartTimer(OneTimer, fnCallback, nTime, bLooping)
    self.tbTimers[TempTimer] = TempTimer
    return TempTimer
end

function SelfTimerHelper:NewTimerMethod(tbSelf, fnCallback, nTime, bLooping)
    local OneTimer = Timer.NewTimerMethod(tbSelf, fnCallback, nTime, bLooping)
    self.tbTimers[OneTimer] = OneTimer
    return OneTimer
end

function SelfTimerHelper:ClearTimer(OneTimer)
    if OneTimer then
        OneTimer:Clear()
        self.tbTimers[OneTimer] = nil
    end
end

function SelfTimerHelper:RunNextTick(fnCallback)
    return self:NewTimer(fnCallback, ONE_TICK_TIME, false)
end

function SelfTimerHelper:RunNextTickMethod(tbSelf, fnCallback)
    return self:NewTimerMethod(tbSelf, fnCallback, ONE_TICK_TIME, false)
end

function SelfTimerHelper:NewDelayRunTimer(fnCallback, nDelayTime)
    return self:NewTimer(fnCallback, nDelayTime, false)
end

function SelfTimerHelper:NewDelayRunTimerMethod(tbSelf, fnCallback, nDelayTime)
    return self:NewTimerMethod(tbSelf, fnCallback, nDelayTime, false)
end


return SelfTimerHelper
