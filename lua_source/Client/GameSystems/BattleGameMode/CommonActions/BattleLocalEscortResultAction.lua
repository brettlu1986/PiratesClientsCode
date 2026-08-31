--则弹出特殊toast信息提示玩家目标存活达成，toast消失后弹出副本胜利结算界面
local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleLocalEscortResultAction = luaclass("BattleLocalEscortResultAction", BattleActionBase)
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleResultDef = require("BattleResultDef")
local BattleOperationHelper = require("BattleOperationHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

BattleLocalEscortResultAction.bResult = nil
BattleLocalEscortResultAction.nToastId = nil

function BattleLocalEscortResultAction:Parse(tbJsonData)
    self.bResult = tbJsonData.Result
    self.nToastId = tbJsonData.ToastId
    return true
end

function BattleLocalEscortResultAction:Execute()
    BattleOperationHelper:PrintLog(self, 
        "Result: "..(self.bResult and "true" or "false"))

    local nResult = BattleResultDef.LOSE
    if self.bResult then 
        nResult = BattleResultDef.WIN
    end

    local tbGameState = BattleGameModeSystem:GetGameState()
    local rStep = tbGameState.rBattlePlayerResultStep
    rStep.Results = {}    

    local tbResults  = rStep.Results
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nPlayerId = PlayerSelf.nPlayerId
    local tbResult = {}
    tbResult.nPlayerId = nPlayerId
    tbResult.nResult = nResult
    tbResult.nBalanceType = BattleResultDef.ReslutType.Escort
    tbResult.nToastId = self.nToastId
    table.insert(tbResults, tbResult)

    -- action调用step的Complete.完成此step
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbStep = tbGameMode:GetCurrentStep()
    tbStep:Complete()
    return true
end

return BattleLocalEscortResultAction