local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMAssociationSetting = luaclass("JGMAssociationSetting", JGMCommonSetting)

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleResultStep = dynamic_require("BattleAssociationResultStep")
local BattleBlackboard = require("BattleBlackboard")
local BattlePrepareSystem = require("BattlePrepareSystem")
local BattleResultDef = require("BattleResultDef")
local BattleTeamSystem = require("BattleTeamSystem")
-- local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
-- local Timer = require("Timer")

JGMAssociationSetting.szCaptainIdKey = nil          -- 队长
JGMAssociationSetting.nChangeShipId = nil
-- JGMAssociationSetting.RemainTimeTimer = nil            -- BattleSetStepRemainTimeAction中同步处理

-- local UPDATE_INTERVAL = 10                             -- 同步间隔
local CAPTAIN_INDEX = 1         -- 队长标记位

function JGMAssociationSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMAssociationSetting.super.Init(self, tbGameMode)) then
        return false
    end

    return true
end

-- local function ClearStepRemainTimer(self)
--     if self.RemainTimeTimer then
--         self.RemainTimeTimer:Clear()
--         self.RemainTimeTimer = nil
--     end
-- end

function JGMAssociationSetting:Uninit()
    JGMAssociationSetting.super.Uninit(self)
    -- ClearStepRemainTimer(self)
end

function JGMAssociationSetting:Parse(tbJsonData)
    JGMAssociationSetting.super.Parse(self, tbJsonData)

    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState

    self.nChangeShipId = tbJsonData.ChangeShipId

    local nShowResultTime = tbJsonData.ShowResultTime
    self.szCaptainIdKey = tbJsonData.CaptainIdKey
    if self.szCaptainIdKey ~= nil and string.len(self.szCaptainIdKey) > 0 then
        BattleBlackboard:DefineNumber(self.szCaptainIdKey, 0)
    end
    if(nShowResultTime ~= nil and nShowResultTime > 0) then
        tbStep = tbGameMode:CreateStep(BattleResultStep, tbGameState.nShowResultStepId)
        tbStep:SetParams(tbGameState.rBattlePlayerResultStep, nShowResultTime, true)
        self.ResultStep = tbStep
    end

    return true
end

local function CheckCaptain(tbPlayer)
    local tbPrepareInfo = BattlePrepareSystem:GetPlayerPrepareInfo(tbPlayer.nPlayerId)
    if tbPrepareInfo and tbPrepareInfo.nIndex then
        if tbPrepareInfo.nIndex == CAPTAIN_INDEX then
            return true
        end
    end
    return false
end

function JGMAssociationSetting:OnFindPlayerStart(tbPlayer)
    -- 存入队长ID
    if CheckCaptain(tbPlayer) then
        if self.szCaptainIdKey ~= nil and string.len(self.szCaptainIdKey) > 0 then
            local nCaptainIdId = BattleBlackboard:GetNumber(self.szCaptainIdKey)
            if nCaptainIdId <= 0 then
                local nInstanceId = tbPlayer:GetServerInstanceId()
                BattleBlackboard:SetNumber(self.szCaptainIdKey, nInstanceId)
            end
        end
    end

    return JGMAssociationSetting.super.OnFindPlayerStart(self, tbPlayer)
end

function JGMAssociationSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.Association
end

function JGMAssociationSetting:OnPlayerLogout(tbPlayer)
    if CheckCaptain(tbPlayer) then
        local tbGameMode = self.tbGameMode
        local tbGameState = tbGameMode.tbGameState

        local rStep = tbGameState.rBattlePlayerResultStep
        rStep.Results = {}
        local tbResults  = rStep.Results

        local tbAllTeamsInfo = BattleTeamSystem:GetAllTeamInfo()
        for _, tbTeamInfo in pairs(tbAllTeamsInfo) do
            for _, GameObject in pairs(tbTeamInfo.tbGameObjects) do
                if tbPlayer.nPlayerId ~= GameObject.nPlayerId then
                    local tbResult = {}
                    tbResult.nPlayerId = GameObject.nPlayerId
                    tbResult.nResult = BattleResultDef.LOSE
                    table.insert(tbResults, tbResult)
                end
            end
        end

        local tbStep = tbGameMode:GetCurrentStep()
        tbStep:Complete()
    end

    JGMAssociationSetting.super.OnPlayerLogout(self, tbPlayer)
end

function JGMAssociationSetting:SetPlayerSelfInfo(tbPrepareInfo)
    JGMAssociationSetting.super.SetPlayerSelfInfo(self, tbPrepareInfo)
    if self.nChangeShipId ~= nil and self.nChangeShipId > 0 then
        tbPrepareInfo.tbShipInfo.nTypeId = self.nChangeShipId
    end
end

-- function JGMAssociationSetting:StepRemainTimeSync(nRemainTime)
--     local tbGameState = BattleGameModeSystem:GetGameState()
--     local rStepRemainTime = tbGameState.rStepRemainTime
--     rStepRemainTime.nTime = nRemainTime
--     rStepRemainTime.Rep()

--     local Update = function()
--         rStepRemainTime.nTime = rStepRemainTime.nTime - UPDATE_INTERVAL
--         if rStepRemainTime.nTime < 0 then
--             ClearStepRemainTimer(self)
--         else
--             rStepRemainTime.Rep()
--         end
--     end
--     ClearStepRemainTimer(self)
--     self.RemainTimeTimer = Timer.NewTimerMethod(nil, Update, UPDATE_INTERVAL, true)
-- end

-- function JGMAssociationSetting:OnStartStep(tbStep)
--     if self.ResultStep == tbStep then
--         ClearStepRemainTimer(self)
--     end
--     JGMAssociationSetting.super.OnStartStep(self, tbStep)
-- end

return JGMAssociationSetting