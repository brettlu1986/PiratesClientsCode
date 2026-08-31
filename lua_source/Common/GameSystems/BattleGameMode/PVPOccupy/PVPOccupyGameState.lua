local luaclass = require("luaclass")
local BattleGameStateBaseClass = require("BattleCommonGameState")
local PVPOccupyGameState = luaclass("PVPOccupyGameState", BattleGameStateBaseClass)

local Proto = require("DungeonRepProtoNames")

PVPOccupyGameState.tbPVPAllAreaState = nil  -- 给客户端用的

function PVPOccupyGameState:DefineStepIds()
    PVPOccupyGameState.super.DefineStepIds(self)

    self.tbPVPAllAreaState = {}

    self:DefineStepId("nWaitForPlayerJoinStepId")
    self:DefineStepId("nCountDownStepId")
    self:DefineStepId("nMatchStepId")
    self:DefineStepId("nTutorialResultStepId")
    self:DefineStepId("nShowResultStepId")
end

function PVPOccupyGameState:DefineProperties()
    PVPOccupyGameState.super.DefineProperties(self)    
    
    -- 定义完用法：直接self.rTeamInfos即可    
    self:DefineProtoProperty(Proto.rBattleTimerStepInfo)
    self:DefineProtoProperty(Proto.rPVPOccupyStepInfo)
    self:DefineProtoProperty(Proto.rTeamScores)
    self:DefineProtoProperty(Proto.rStepRemainTime)
    self:DefineProtoProperty(Proto.rBattlePlayerResultStep)
    self:DefineProtoProperty(Proto.rPVPOccupyChangedAreaState)
end

return PVPOccupyGameState