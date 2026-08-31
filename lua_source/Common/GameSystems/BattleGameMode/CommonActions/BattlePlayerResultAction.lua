local luaclass = require("luaclass")
local BattleActionBase = require("BattleActionBase")
local BattlePlayerResultAction = luaclass("BattlePlayerResultAction", BattleActionBase)
local BattleOperationHelper = require("BattleOperationHelper")
local BattleResultDef = require("BattleResultDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTeamSystem = require("BattleTeamSystem")

BattlePlayerResultAction.nResult = nil
BattlePlayerResultAction.CampType = nil

function BattlePlayerResultAction:Parse(tbJsonData)
    self.nResult = tbJsonData.Result
    self.nCampType = tbJsonData.CampType
    
    return true
end

function BattlePlayerResultAction:Execute()
    BattleOperationHelper:PrintLog(self, "CampType"..self.nCampType.." Result"..self.nResult)
-- BattleResultDef.WIN = 0
-- BattleResultDef.LOSE = 1
-- BattleResultDef.TIE = 2

    local tbGameState = BattleGameModeSystem:GetGameState()
    local rStep = tbGameState.rBattlePlayerResultStep
    rStep.Results = {}    
    local tbResults  = rStep.Results
    local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
    for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
        for _, GameObject in pairs(tbTeamInfo.tbGameObjects) do
            local tbResult = {}
            tbResult.nPlayerId = GameObject.nPlayerId
            if self.nCampType and GameObject.BattleCampComponent:GetCampType() == self.nCampType then
                tbResult.nResult = self.nResult
            else
                if self.nResult == BattleResultDef.TIE then 
                    tbResult.nResult = BattleResultDef.TIE
                elseif self.nResult == BattleResultDef.WIN then 
                    tbResult.nResult = BattleResultDef.LOSE
                else
                    tbResult.nResult = BattleResultDef.WIN
                end
            end 
            table.insert(tbResults, tbResult)
        end
    end

    -- action调用step的Complete.完成此step
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbStep = tbGameMode:GetCurrentStep()
    tbStep:Complete()

    return true
end

return BattlePlayerResultAction