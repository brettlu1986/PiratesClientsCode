local luaclass = require("luaclass")
local LogEventRegister = require("LogEventRegister")
local LogEventRegister_C = luaclass("LogEventRegister_C", LogEventRegister)

function LogEventRegister_C:Register(System)
    LogEventRegister_C.super.Register(self, System)

    System:Register("ClientDefaultLogEventOp")
    System:Register("LoadingTransformLogEventOp")
    System:Register("GuideLogEventOp")
    System:Register("PerformanceLogEventOp")
end

return LogEventRegister_C