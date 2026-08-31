local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local SmuggleGameState = luaclass("SmuggleGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

SmuggleGameState.bWin = nil

function SmuggleGameState:DefineStepIds()
    SmuggleGameState.super.DefineStepIds(self)

    self:DefineStepId("nSmuggleId")
    self:DefineStepId("nShowResultStepId")
end

function SmuggleGameState:DefineProperties()
    SmuggleGameState.super.DefineProperties(self)    
    
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end

return SmuggleGameState