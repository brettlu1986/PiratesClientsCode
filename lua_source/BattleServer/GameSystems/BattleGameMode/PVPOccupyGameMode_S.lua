local luaclass = require("luaclass")
local BattleGameModeBaseClass = require("PVPOccupyGameMode")
local PVPOccupyGameMode_S = luaclass("PVPOccupyGameMode_S", BattleGameModeBaseClass)
local BattlePVPWaitResultStepClass = require("BattlePVPWaitResultStep_S")

local SHOW_RESULT_TIME = 100

function PVPOccupyGameMode_S:AddSteps(tbTemplateData, tbGameState)
    PVPOccupyGameMode_S.super.AddSteps(self, tbTemplateData, tbGameState)
    local tbStep = self:CreateStep(BattlePVPWaitResultStepClass, tbGameState.nShowResultStepId)
    tbStep:SetParams(SHOW_RESULT_TIME)
end

return PVPOccupyGameMode_S
