local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local SideQuest01GameState = luaclass("SideQuest01GameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

SideQuest01GameState.bWin = nil

function SideQuest01GameState:DefineStepIds()
    SideQuest01GameState.super.DefineStepIds(self)

    -- self:DefineStepId("nLoadingEndStepId")
    self:DefineStepId("nCountDownStepId")
    self:DefineStepId("nBattleStepId")
    self:DefineStepId("nShowResultStepId")
end

function SideQuest01GameState:DefineProperties()
    SideQuest01GameState.super.DefineProperties(self)    
    
    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
end


return SideQuest01GameState