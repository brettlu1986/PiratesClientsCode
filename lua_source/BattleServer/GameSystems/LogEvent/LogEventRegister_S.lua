local luaclass = require("luaclass")
local LogEventRegister = require("LogEventRegister")
local LogEventRegister_S = luaclass("LogEventRegister_S", LogEventRegister)

function LogEventRegister_S:Register(System)
    LogEventRegister_S.super.Register(self, System)

    System:Register("FFAGamePlayLogEventOp")
    System:Register("FFAFightLogEventOp")
    System:Register("FFAHumanStateLogEventOp")
    System:Register("BattleItemLogEventOp")
end

return LogEventRegister_S