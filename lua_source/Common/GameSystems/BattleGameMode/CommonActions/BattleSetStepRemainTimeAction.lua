local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetStepRemainTimeAction = luaclass("BattleSetStepRemainTimeAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")

BattleSetStepRemainTimeAction.fStepRemainTime = 0
BattleSetStepRemainTimeAction.nStageId = 0
BattleSetStepRemainTimeAction.nUpdateInterval = 0

function BattleSetStepRemainTimeAction:Parse(tbJsonData)
    self.fStepRemainTime = tbJsonData.StepRemainTime
    self.nStageId = tbJsonData.StageId
    self.nUpdateInterval = tbJsonData.UpdateInterval

    return true
end

function BattleSetStepRemainTimeAction:Execute()
    BattleOperationHelper:PrintLog(self, "Time: "..self.fStepRemainTime..
        ", StageId: "..self.nStageId..
        ", UpdateInterval: "..self.nUpdateInterval)

    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbGameState = BattleGameModeSystem:GetGameState()
    local tbSetting = tbGameMode.Setting
    if tbSetting.StepRemainTimeSync then
        tbSetting:StepRemainTimeSync(self.fStepRemainTime, self.nUpdateInterval)
    end
    
    local rJsonMainStepInfo = tbGameState.rJsonMainStepInfo
    rJsonMainStepInfo.nStageId = self.nStageId
    rJsonMainStepInfo.Rep()

    return true
end

return BattleSetStepRemainTimeAction