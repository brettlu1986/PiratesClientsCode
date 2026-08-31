local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local TutorialGameState = luaclass("TutorialGameState", BattleGameStateBaseClass)

function TutorialGameState:DefineStepIds()
    TutorialGameState.super.DefineStepIds(self)

    self:DefineStepId("nTutorialShip1BattleId")
    self:DefineStepId("nTutorialOctopusBattleId")

end

function TutorialGameState:DefineProperties()
    TutorialGameState.super.DefineProperties(self)
end

return TutorialGameState