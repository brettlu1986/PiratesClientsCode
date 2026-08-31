local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local PVE02GameState = luaclass("PVE02GameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

function PVE02GameState:DefineStepIds()
    PVE02GameState.super.DefineStepIds(self)

    self:DefineStepId("nMatinee1StepId")
    self:DefineStepId("nBattle1StepId")

    self:DefineStepId("nMatinee2StepId")
    self:DefineStepId("nBattle2StepId")

    self:DefineStepId("nMatinee3StepId")
    self:DefineStepId("nBattle3StepId")

    self:DefineStepId("nMatinee4StepId")
    self:DefineStepId("nShowResultStepId")

end

function PVE02GameState:DefineProperties()
    PVE02GameState.super.DefineProperties(self)

    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)

end

return PVE02GameState