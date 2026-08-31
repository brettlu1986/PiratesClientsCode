local DelayTimer = {}
local Timer = require("Timer")

function DelayTimer:DelayRun(fnExecute, fDelaySeconds, szInfo)
    return Timer.NewTimer(fnExecute, fDelaySeconds, false, szInfo)
end

function DelayTimer:RunNextTick(fnExecute, szInfo)
    return self:DelayRun(fnExecute, 0.0167, szInfo)
end

function DelayTimer:ClearTimer(tbTimerHandle)
    if(tbTimerHandle == nil) then
        return
    end
    tbTimerHandle:Clear()
end

return DelayTimer
