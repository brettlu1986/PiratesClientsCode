local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local EscortGameMode = luaclass("EscortGameMode", BattleGameModeBaseClass)
local EscortDataTable = require("EscortDataTable")

local EscortGameStepClass = require("EscortGameStep")
local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")

local UIDef = require("UIDef")
local UIManager = require("UIManager")
-- local CommonEventDef = require("CommonEventDef")
local Proto = require("ClientProtoNames")

local NetworkManager = dynamic_require("NetworkManager")

local BattleResultDef = require("BattleResultDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

EscortGameMode.tbShowResultStep = nil

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

function EscortGameMode:OnBattleStepStart(tbGameStep)
    if tbGameStep == self.tbShowResultStep then

        local nResult = nil
        if self.tbGameState.rEscortFightResult.nFightResult == BattleResultDef.WIN then
            nResult = Proto.FightResultType.WIN
        else
            nResult = Proto.FightResultType.LOSE
        end

        local c2s_LocalDungeonResult = 
        {
            result = nResult,
            die_count = BattleDataStatisticsSystem:GetPlayerStatsPropertyByPlayerId(GamePlayerSelfHelper:Get().nPlayerId, "Count_Sunk")
        }

        SendPacket(Proto.c2s_LocalDungeonResult, c2s_LocalDungeonResult)

        -- send result immediately
        -- server will not send response currently. no award in escort battle.
        local tbPlayerAward = {}
        tbPlayerAward.nResultType = nResult
        tbPlayerAward.tbAwardList = {}

        UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
    end
end

function EscortGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    EscortGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)

    local tbTemplateData = EscortDataTable:GetTemplate(nSubDungonId)

    local tbBattleStep = self:CreateStep(EscortGameStepClass, tbGameState.nBattleStepId)
    tbBattleStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)

    self.tbShowResultStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    self.tbShowResultStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, false)

    -- self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_STEP_START, self, self.OnBattleStepStart)

    return true
end

function EscortGameMode:FindPlayerNewJsonStart()
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    if(tbJsonStarts == nil or #tbJsonStarts < 1) then
        error("EscortGameMode:FindPlayerNewJsonStart failed")
        return nil
    end
    return tbJsonStarts[1]
end

function EscortGameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbJsonStart = self:FindPlayerNewJsonStart()
    if(tbJsonStart == nil) then
        error("EscortGameMode:FindPlayerStartJsonData failed")
        return
    end

    local tbTans = tbJsonStart.Transform
    log("EscortGameMode:FindPlayerStartJsonData",
        tbTans.X, tbTans.Y, tbTans.Z, tbTans.Yaw)
    return tbJsonStart
end

function EscortGameMode:OnAllStepFinished()
    log("EscortGameMode:OnFinished")

    log("EscortGameMode send c2s_LeaveLocalDungeon "..self.nSubDungonId)
    SendPacket(Proto.c2s_LeaveLocalDungeon)

    EscortGameMode.super.OnAllStepFinished()
end

function EscortGameMode:GetQuitDungeonDialogType()
    log("EscortGameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.Escort
end

return EscortGameMode
