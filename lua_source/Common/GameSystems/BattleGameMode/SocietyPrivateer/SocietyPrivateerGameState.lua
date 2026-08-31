local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local SocietyPrivateerGameState = luaclass("SocietyPrivateerGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

SocietyPrivateerGameState.bWin = nil

function SocietyPrivateerGameState:DefineStepIds()
    SocietyPrivateerGameState.super.DefineStepIds(self)

    self:DefineStepId("nCountDownStepId")
    self:DefineStepId("nSocietyPrivateerId")
    self:DefineStepId("nShowResultStepId")
end

function SocietyPrivateerGameState:DefineProperties()
    SocietyPrivateerGameState.super.DefineProperties(self)    
    
    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end

return SocietyPrivateerGameState