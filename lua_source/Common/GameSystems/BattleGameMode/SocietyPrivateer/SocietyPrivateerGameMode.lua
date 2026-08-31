local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local SocietyPrivateerGameMode = luaclass("SocietyPrivateerGameMode", BattleGameModeBaseClass)

local BattleTimerStepClass = require("BattleTimerStep")
local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")
local SocietyPrivateerStepClass = dynamic_require("SocietyPrivateerStep")
local SocietyPrivateerDataTable = require("SocietyPrivateerDataTable")
-- local CommonEventDef = require("CommonEventDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BattleObjectiveHelper = require("BattleObjectiveHelper")

SocietyPrivateerGameMode.tbShowResultStep = nil

function SocietyPrivateerGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if not SocietyPrivateerGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile) then
        return false
    end

    local tbTemplateData = SocietyPrivateerDataTable:GetTemplate(nSubDungonId)
    if tbTemplateData == nil then
        logerror("SocietyPrivateerGameMode init failed, can not find id", nSubDungonId)
        return false
    end

    self:AddSteps(tbTemplateData, tbGameState)
    return true
end

function SocietyPrivateerGameMode:AddSteps(tbTemplateData, tbGameState)    
    local tbStep

    tbStep = self:CreateStep(BattleTimerStepClass, tbGameState.nCountDownStepId)
    tbStep:SetParams(tbGameState.rBattleTimerStepInfo, nil, tbTemplateData.nCountDownTime)

    tbStep = self:CreateStep(SocietyPrivateerStepClass, tbGameState.nSocietyPrivateerId)
    tbStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)
    
    self.tbShowResultStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    self.tbShowResultStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, false)
 
    -- self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_STEP_START, self, self.OnBattleStepStart)
   
end

function SocietyPrivateerGameMode:Uninit()
    SocietyPrivateerGameMode.super.Uninit(self)
end

function SocietyPrivateerGameMode:FindPlayerNewJsonStart()
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    local nJsonCount = #tbJsonStarts
    log("SocietyPrivateerGameMode:FindPlayerNewJsonStart nJsonCount ",nJsonCount)
   
    -- assert(tbJsonStarts[1] ~= nil)
    return tbJsonStarts[1]
end

function SocietyPrivateerGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbJsonStart = self:FindPlayerNewJsonStart()
    if tbJsonStart == nil then
        error("SocietyPrivateerGameMode:FindPlayerStartJsonData failed")
        return
    end
    return tbJsonStart
end

function SocietyPrivateerGameMode:GetQuitDungeonDialogType()
    log("SocietyPrivateerGameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.SocietyPrivateer
end

function SocietyPrivateerGameMode:StartFirstStep()
    SocietyPrivateerGameMode.super.StartFirstStep(self)
    BattleObjectiveHelper:ObjectiveStepForward()
end

return SocietyPrivateerGameMode
