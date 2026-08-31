local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local PVE01GameState = luaclass("PVE01GameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

function PVE01GameState:DefineStepIds()
    PVE01GameState.super.DefineStepIds(self)

    self:DefineStepId("nEnterSceneMatineeId")
    self:DefineStepId("nBattleStepId")
    self:DefineStepId("nBossDieMatineeId")
    self:DefineStepId("nShowResultStepId")
end

function PVE01GameState:DefineProperties()
    PVE01GameState.super.DefineProperties(self)

    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end

return PVE01GameState
