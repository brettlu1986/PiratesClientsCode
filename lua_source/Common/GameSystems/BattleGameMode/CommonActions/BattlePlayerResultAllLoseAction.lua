local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerResultAllLoseAction = luaclass("BattlePlayerResultAllLoseAction", BattleActionBase)
local BattleOperationHelper = require("BattleOperationHelper")
local BattleResultDef = require("BattleResultDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTeamSystem = require("BattleTeamSystem")

function BattlePlayerResultAllLoseAction:Parse(tbJsonData)    
    return true
end

function BattlePlayerResultAllLoseAction:Execute()
    BattleOperationHelper:PrintLog(self, "")

    local tbGameState = BattleGameModeSystem:GetGameState()
    local rStep = tbGameState.rBattlePlayerResultStep
    rStep.Results = {}    
    local tbResults  = rStep.Results
    local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
        for _, GameObject in pairs(tbTeamInfo.tbGameObjects) do
            local tbResult = {}
            tbResult.nPlayerId = GameObject.nPlayerId
            tbResult.nResult = BattleResultDef.LOSE
            table.insert(tbResults, tbResult)
        end
    end

    -- action调用step的Complete.完成此step
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbStep = tbGameMode:GetCurrentStep()
    tbStep:Complete()

    return true
end

return BattlePlayerResultAllLoseAction