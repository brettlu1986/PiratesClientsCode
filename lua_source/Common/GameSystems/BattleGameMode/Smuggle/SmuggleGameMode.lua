local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local SmuggleGameMode = luaclass("SmuggleGameMode", BattleGameModeBaseClass)
-- local CommonEventDef = require("CommonEventDef")

local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")
local SmuggleStepClass = require("SmuggleStep")
local SmuggleDataTable = require("SmuggleDataTable")
local DungeonQuitDialogType = require("DungeonQuitDialogType")

SmuggleGameMode.tbShowResultStep = nil

function SmuggleGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if not SmuggleGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile) then
        return false
    end

    local tbTemplateData = SmuggleDataTable:GetTemplate(nSubDungonId)
    if(tbTemplateData == nil) then
        logerror("SmuggleGameMode init failed, can not find id", nSubDungonId)
        return false
    end

    self:AddSteps(tbTemplateData, tbGameState)
    return true
end

function SmuggleGameMode:AddSteps(tbTemplateData, tbGameState)    
    local tbStep

    tbStep = self:CreateStep(SmuggleStepClass, tbGameState.nSmuggleId)
    tbStep:SetParams(tbGameState, tbTemplateData, self.tbJsonTableFile)

    self.tbShowResultStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    self.tbShowResultStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, false)

    --  self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_STEP_START, self, self.OnBattleStepStart)
   
end

function SmuggleGameMode:Uninit()
    SmuggleGameMode.super.Uninit(self)
end

function SmuggleGameMode:FindPlayerNewJsonStart()
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    if(tbJsonStarts == nil) then
        error("SmuggleGameMode:FindPlayerNewJsonStart failed")
        return
    end
    return tbJsonStarts[1]
end

function SmuggleGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbJsonStart = self:FindPlayerNewJsonStart()
    if(tbJsonStart == nil) then
        error("SmuggleGameMode:FindPlayerStartJsonData failed")
        return
    end

    return tbJsonStart
end

-- 玩家死亡重生
-- function SmuggleGameMode:OnPostDestroyPlayerPawn(GamePlayerSelf)
--     self:SpawnPlayerPawn(GamePlayerSelf, true)
-- end

function SmuggleGameMode:GetQuitDungeonDialogType()
    log("SmuggleGameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.Smuggle
end

return SmuggleGameMode
