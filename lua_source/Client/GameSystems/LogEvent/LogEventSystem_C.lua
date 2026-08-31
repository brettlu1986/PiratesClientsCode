local luaclass = require("luaclass")
local LogEventSystem = require("LogEventSystem")
local LogEventSystem_C = luaclass("LogEventSystem_C", LogEventSystem)

local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")

function LogEventSystem_C:Init()
    LogEventSystem_C.super.Init(self)

    self.EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_WAIT_STAGE_STATE_CHANGED, self, self.OnBattleBegin)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_DUNGEON_GAME_OVER, self, self.OnBattleEnd)
end

return LogEventSystem_C()