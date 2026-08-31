local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local SideQuest01GameMode = luaclass("SideQuest01GameMode", BattleGameModeBaseClass)
local SideQuest01DataTable = require("SideQuest01DataTable")

-- local LoadingEndStepClass = require("LoadingEndStep")
local SideQuest01TimerStepClass = require("BattleTimerStep")
local SideQuest01GameStepClass = require("SideQuest01GameStep")
local BattlePlayerResultStepClass = dynamic_require("BattlePVEResultStep")

local UIDef = require("UIDef")
local UIManager = require("UIManager")
-- local CommonEventDef = require("CommonEventDef")
local Proto = require("ClientProtoNames")

local NetworkManager = dynamic_require("NetworkManager")

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

SideQuest01GameMode.tbShowResultStep = nil

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

function SideQuest01GameMode:OnBattleStepStart(tbGameStep)
    if tbGameStep == self.tbShowResultStep then

        local nResult = nil
        if self.tbGameState.bWin == true then
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
        -- server will not send response currently. no award in side quest battle.
        local tbPlayerAward = {}
        tbPlayerAward.nResultType = nResult
        tbPlayerAward.tbAwardList = {}

        UIManager:OpenWnd(UIDef.UI_BATTLE_RESULT, tbPlayerAward)
    end
end

function SideQuest01GameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    SideQuest01GameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)

    local tbTemplateData = SideQuest01DataTable:GetTemplate(nSubDungonId)

    -- self:CreateStep(LoadingEndStepClass, tbGameState.nLoadingEndStepId)

    local tbCountDownStep = self:CreateStep(SideQuest01TimerStepClass, tbGameState.nCountDownStepId)
    tbCountDownStep:SetParams(tbGameState.rBattleTimerStepInfo, nil, tbTemplateData.nTimeout)

    local tbBattleStep = self:CreateStep(SideQuest01GameStepClass, tbGameState.nBattleStepId)
    tbBattleStep:SetParams(tbGameState, tbTemplateData, tbJsonTableFile)

    self.tbShowResultStep = self:CreateStep(BattlePlayerResultStepClass, tbGameState.nShowResultStepId)
    self.tbShowResultStep:SetParams(tbGameState.rBattlePlayerResultStep, tbTemplateData.nShowResultTime, false)

    -- self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_STEP_START, self, self.OnBattleStepStart)

    return true
end

function SideQuest01GameMode:FindPlayerNewJsonStart()
    local tbJsonStarts = self.tbJsonTableFile.tbContainer.DungeonPlayerStarts
    if(tbJsonStarts == nil or #tbJsonStarts < 1) then
        error("SideQuest01GameMode:FindPlayerNewJsonStart failed")
        return nil
    end
    return tbJsonStarts[1]
end

function SideQuest01GameMode:FindPlayerStartJsonData(tbGamePlayer)
    local tbJsonStart = self:FindPlayerNewJsonStart()
    if(tbJsonStart == nil) then
        error("SideQuest01GameMode:FindPlayerStartJsonData failed")
        return
    end

    local tbTans = tbJsonStart.Transform
    log("SideQuest01GameMode:FindPlayerStartJsonData",
        tbTans.X, tbTans.Y, tbTans.Z, tbTans.Yaw)
    return tbJsonStart
end

function SideQuest01GameMode:OnAllStepFinished()
    log("SideQuest01GameMode:OnFinished")

    log("SideQuest01GameMode send c2s_LeaveLocalDungeon "..self.nSubDungonId)
    SendPacket(Proto.c2s_LeaveLocalDungeon)

    SideQuest01GameMode.super.OnAllStepFinished()
end

function SideQuest01GameMode:GetQuitDungeonDialogType()
    log("SideQuest01GameMode:GetQuitDungeonDialogType")
    return DungeonQuitDialogType.SideQuest01
end

function SideQuest01GameMode:StartFirstStep()
    SideQuest01GameMode.super.StartFirstStep(self)
    BattleObjectiveHelper:ObjectiveStepForward()
end

return SideQuest01GameMode
