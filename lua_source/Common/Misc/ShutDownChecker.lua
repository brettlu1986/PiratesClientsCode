local ShutDownChecker = {}

local Timer = require("Timer")

function ShutDownChecker.Check()
    Timer.CheckAndClearAllTimer()
end

return ShutDownChecker
