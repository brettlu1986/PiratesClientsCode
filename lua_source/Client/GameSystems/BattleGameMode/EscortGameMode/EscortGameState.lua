local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local EscortGameState = luaclass("EscortGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

function EscortGameState:DefineStepIds()
    EscortGameState.super.DefineStepIds(self)

    self:DefineStepId("nBattleStepId")
    self:DefineStepId("nShowResultStepId")
end

function EscortGameState:DefineProperties()
    EscortGameState.super.DefineProperties(self)    
    
    -- 定义完用法：直接self.rTeamInfos即可    
    self:DefineProtoProperty(Proto.rEscortFightResult)

    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end


return EscortGameState