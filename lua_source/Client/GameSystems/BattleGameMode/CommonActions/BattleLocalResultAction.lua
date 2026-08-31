local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleLocalResultAction = luaclass("BattleLocalResultAction", BattleActionBase)
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleResultDef = require("BattleResultDef")
local BattleOperationHelper = require("BattleOperationHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleResultSystem = dynamic_require("BattleResultSystem")

BattleLocalResultAction.bResult = nil

function BattleLocalResultAction:Parse(tbJsonData)
    self.bResult = tbJsonData.Result
    return true
end

function BattleLocalResultAction:Execute()
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
    tbResult.nBalanceType = BattleResultDef.ReslutType.Kill
    table.insert(tbResults, tbResult)

    -- action调用step的Complete.完成此step
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbStep = tbGameMode:GetCurrentStep()
    tbStep:Complete()

    -- 暂时放这里，未来副本多了在进行整理，看看真正放哪合适
    BattleResultSystem:EnterStandaloneResult(nResult)
    return true
end

return BattleLocalResultAction