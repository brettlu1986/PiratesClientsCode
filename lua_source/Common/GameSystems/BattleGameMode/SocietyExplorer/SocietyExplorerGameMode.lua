local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local SocietyExplorerGameMode = luaclass("SocietyExplorerGameMode", BattleGameModeBaseClass)

local BattleTimerStepClass = require("BattleTimerStep")
local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")
local SocietyExplorerStepClass = dynamic_require("SocietyExplorerStep")
local SocietyExplorerDataTable = require("SocietyExplorerDataTable")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BattleObjectiveHelper = require("BattleObjectiveHelper")

function SocietyExplorerGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if not SocietyExplorerGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile) then
        return false
    end

    local tbTemplateData = SocietyExplorerDataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("SocietyExplorerGameMode init failed, can not find id", nSubDungonId)
        return false
    end

    self:AddSteps(tbTemplateData, tbGameState)
    return true
end

function SocietyExplorerGameMode:AddSteps(tbTemplateData, tbGameState)    
    local tbStep

    tbStep = self:CreateStep(BattleTimerStepClass, tbGameState.nCountDownStepId)
    tbStep:SetParams(tbGameState.rBattleTimerStepInfo, nil, tbTemplateData.nCountDownTime)

    tbStep = self:CreateStep(SocietyExplorerStepClass, tbGameState.nSocietyExplorerId)
    tbStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)

    tbStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    tbStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, true)

end

function SocietyExplorerGameMode:Uninit()
    SocietyExplorerGameMode.super.Uninit(self)
end

function SocietyExplorerGameMode:FindPlayerNewJsonStart()
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    if(tbJsonStarts == nil) then
        error("SocietyExplorerGameMode:FindPlayerNewJsonStart failed")
        return
    end
    return tbJsonStarts[1]
end

function SocietyExplorerGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbJsonStart = self:FindPlayerNewJsonStart()
    if(tbJsonStart == nil) then
        error("SocietyExplorerGameMode:FindPlayerStartJsonData failed")
        return
    end

    return tbJsonStart
end

-- 玩家死亡重生
function SocietyExplorerGameMode:OnPostDestroyPlayerPawn(GamePlayerSelf)
    self:RebornPlayer(GamePlayerSelf)
end

function SocietyExplorerGameMode:GetQuitDungeonDialogType()
    log("SocietyExplorerGameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.SocietyExplorer
end

function SocietyExplorerGameMode:StartFirstStep()
    SocietyExplorerGameMode.super.StartFirstStep(self)
    BattleObjectiveHelper:ObjectiveStepForward()
end

return SocietyExplorerGameMode
