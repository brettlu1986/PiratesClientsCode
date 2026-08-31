local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local SocietyGuardGameMode = luaclass("SocietyGuardGameMode", BattleGameModeBaseClass)

local BattleTimerStepClass = require("BattleTimerStep")
local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")
local SocietyGuardBattleStepClass = dynamic_require("SocietyGuardBattleStep")
local SocietyGuardDataTable = require("SocietyGuardDataTable")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BattleObjectiveHelper = require("BattleObjectiveHelper")

function SocietyGuardGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if not SocietyGuardGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile) then
        return false
    end

    local tbTemplateData = SocietyGuardDataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("SocietyGuardGameMode init failed, can not find id", nSubDungonId)
        return false
    end

    self:AddSteps(tbTemplateData, tbGameState)
    return true
end

function SocietyGuardGameMode:AddSteps(tbTemplateData, tbGameState)
    -- 倒计时阶段
    local tbStep = nil
    tbStep = self:CreateStep(BattleTimerStepClass, tbGameState.nCountDownStepId)
    tbStep:SetParams(tbGameState.rBattleTimerStepInfo, nil, tbTemplateData.nCountDownTime)

    -- 针对这个玩法，我们战斗只分一个step，三波怪，分多个target
    -- 因为该玩法不能做成一波怪一个step，因为目前step的设计为当一个setp全部结束后才能走到下一个setp
    -- 但是该玩法里不是这样的
    tbStep = self:CreateStep(SocietyGuardBattleStepClass, tbGameState.nBattleStepId)
    tbStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)
    
    -- 战斗结算阶段
    tbStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    tbStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, true)
    
end

function SocietyGuardGameMode:Uninit()
    self.tbUsedPlayerStarts = nil
    SocietyGuardGameMode.super.Uninit(self)
end

function SocietyGuardGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local DEFAULT_PLAYER_START = 1

    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    local nJsonCount = #tbJsonStarts

    if nJsonCount == 0 then
        error('SocietyGuardGameMode:FindPlayerStartJsonData() player start count empty.')
    end

    -- 没有的话直接用第一个
    local tbJsonStart = tbJsonStarts[DEFAULT_PLAYER_START]
    return tbJsonStart
end

-- 自己死亡后重生
function SocietyGuardGameMode:OnPostDestroyPlayerPawn(GamePlayerSelf)
    self:RebornPlayer(GamePlayerSelf)
end

function SocietyGuardGameMode:GetQuitDungeonDialogType()
    log("SocietyGuardGameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.SocietyGuard
end

function SocietyGuardGameMode:StartFirstStep()
    SocietyGuardGameMode.super.StartFirstStep(self)
    BattleObjectiveHelper:ObjectiveStepForward()
end

return SocietyGuardGameMode
