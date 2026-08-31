local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local SocietyExplorerGameState = luaclass("SocietyExplorerGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

function SocietyExplorerGameState:DefineStepIds()
    SocietyExplorerGameState.super.DefineStepIds(self)

    self:DefineStepId("nCountDownStepId")
    self:DefineStepId("nSocietyExplorerId")
    self:DefineStepId("nShowResultStepId")
end

function SocietyExplorerGameState:DefineProperties()
    SocietyExplorerGameState.super.DefineProperties(self)    
    
    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end

return SocietyExplorerGameState