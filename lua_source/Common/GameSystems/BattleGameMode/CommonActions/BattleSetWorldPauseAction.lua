local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetWorldPauseAction = luaclass("BattleSetWorldPauseAction", BattleActionBase)

BattleSetWorldPauseAction.bPause = false

function BattleSetWorldPauseAction:Parse(tbJsonData)
    self.bPause = tbJsonData.Pause
    return self.bPause ~= nil
end

function BattleSetWorldPauseAction:Execute()
    GameplayStatics.SetGamePaused(GWorld, self.bPause)
    return true
end

return BattleSetWorldPauseAction