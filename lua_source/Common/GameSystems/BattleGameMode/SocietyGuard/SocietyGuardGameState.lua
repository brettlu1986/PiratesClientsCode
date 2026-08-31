local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local SocietyGuardGameState = luaclass("SocietyGuardGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

function SocietyGuardGameState:DefineStepIds()
    SocietyGuardGameState.super.DefineStepIds(self)

    self:DefineStepId("nCountDownStepId")
    self:DefineStepId("nBattleStepId")
    self:DefineStepId("nShowResultStepId")
end

function SocietyGuardGameState:DefineProperties()
    SocietyGuardGameState.super.DefineProperties(self)

    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rSocietyGuardCountdownTipInfo)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end

return SocietyGuardGameState
