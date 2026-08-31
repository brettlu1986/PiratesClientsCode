local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local TestGameState = luaclass("TestGameState", BattleGameStateBaseClass)


function TestGameState:DefineStepIds()
    TestGameState.super.DefineStepIds(self)

    self:DefineStepId("nStepId")
end

return TestGameState