local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local JsonGameState = luaclass("JsonGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

JsonGameState.bCanRetryGame = true
JsonGameState.tbPVPAllAreaState = nil  -- 给客户端用的

function JsonGameState:DefineStepIds()
    JsonGameState.super.DefineStepIds(self)
    
    self.tbPVPAllAreaState = {}
    
    self:DefineStepId("nWaitForPlayStepId")
    self:DefineStepId("nCountDownStepId")
    self:DefineStepId("nMatchStepId")
    self:DefineStepId("nShowResultStepId") 
end

function JsonGameState:DefineProperties()
    JsonGameState.super.DefineProperties(self)

    self:DefineProtoProperty(Proto.rJsonSetting)
    self:DefineProtoProperty(Proto.rJsonMainStepInfo)
    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rStepRemainTime)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)

    self:DefineProtoProperty(Proto.rTeamScores)
    self:DefineProtoProperty(Proto.rPVPOccupyChangedAreaState)
    self:DefineProtoProperty(Proto.rBattleFlagState)
    
end

return JsonGameState
