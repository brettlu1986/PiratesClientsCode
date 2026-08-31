--强制转动摄像机镜头到追尾视角 –>定住镜头不再跟随玩家船，并锁定玩家操作 -> 隐藏UI –> 玩家船继续行驶 -> 弹出副本胜利结算界面。

local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattleLocalEscapeResultAction = luaclass("BattleLocalEscapeResultAction", BattleActionBase)
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleResultDef = require("BattleResultDef")
local BattleOperationHelper = require("BattleOperationHelper")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

BattleLocalEscapeResultAction.bResult = nil

function BattleLocalEscapeResultAction:Parse(tbJsonData)
    self.bResult = tbJsonData.Result
    return true
end

function BattleLocalEscapeResultAction:Execute()
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
    tbResult.nBalanceType = BattleResultDef.ReslutType.Escape
    table.insert(tbResults, tbResult)

    -- action调用step的Complete.完成此step
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbStep = tbGameMode:GetCurrentStep()
    tbStep:Complete()
    return true
end

return BattleLocalEscapeResultAction