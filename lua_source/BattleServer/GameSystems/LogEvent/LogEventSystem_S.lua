local luaclass = require("luaclass")
local LogEventSystem = require("LogEventSystem")
local LogEventSystem_S = luaclass("LogEventSystem_S", LogEventSystem)

local CommonEventDef = require("CommonEventDef")

function LogEventSystem_S:Init()
    LogEventSystem_S.super.Init(self)

    self.EventHelper:RegisterEvent(CommonEventDef.EV_LOG_BATTLE_BEGIN, self, self.OnBattleBegin)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_LOG_BATTLE_END, self, self.OnBattleEnd)
end

return LogEventSystem_S()