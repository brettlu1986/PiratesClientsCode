local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleSetStepRemainTimeBbAction = luaclass("BattleSetStepRemainTimeBbAction", BattleActionBase)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleBlackboard = require("BattleBlackboard")

BattleSetStepRemainTimeBbAction.szStepRemainTimeKey = 0
BattleSetStepRemainTimeBbAction.nStageId = 0
BattleSetStepRemainTimeBbAction.nUpdateInterval = 0

function BattleSetStepRemainTimeBbAction:Parse(tbJsonData)
    self.szStepRemainTimeKey = tbJsonData.StepRemainTimeKey
    self.nStageId = tbJsonData.StageId
    self.nUpdateInterval = tbJsonData.UpdateInterval

    return true
end

function BattleSetStepRemainTimeBbAction:Execute()
    BattleOperationHelper:PrintLog(self, "StepRemainTimeKey: "..self.szStepRemainTimeKey..
        ", StageId: "..self.nStageId..
        ", UpdateInterval: "..self.nUpdateInterval)

    if self.szStepRemainTimeKey and string.len(self.szStepRemainTimeKey) > 0 then
        local nStepRemainTime = BattleBlackboard:GetNumber(self.szStepRemainTimeKey)
        local tbGameMode = BattleGameModeSystem:GetGameMode()
        local tbGameState = BattleGameModeSystem:GetGameState()
        local tbSetting = tbGameMode.Setting
        if tbSetting.StepRemainTimeSync then
            tbSetting:StepRemainTimeSync(nStepRemainTime, self.nUpdateInterval)
        end
        
        local rJsonMainStepInfo = tbGameState.rJsonMainStepInfo
        rJsonMainStepInfo.nStageId = self.nStageId
        rJsonMainStepInfo.Rep()
    end
    return true
end

return BattleSetStepRemainTimeBbAction