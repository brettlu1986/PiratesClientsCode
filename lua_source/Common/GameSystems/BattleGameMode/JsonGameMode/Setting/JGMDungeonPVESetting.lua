local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMDungeonPVESetting = luaclass("JGMDungeonPVESetting", JGMCommonSetting)

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleBlackboard = require("BattleBlackboard")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local DelayTimer = require("DelayTimer")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleResultStep = dynamic_require("BattlePVEResultStep")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
--local ShipDataTable = require("ShipDataTable")
--local ShipSkillDataTable = require("ShipSkillDataTable")


JGMDungeonPVESetting.tbRestartTimer = nil
-- JGMDungeonPVESetting.nResetStepIndex = nil
-- JGMDungeonPVESetting.nPlayerStartGroupIndex = nil
JGMDungeonPVESetting.nRebornCountdown = 0
JGMDungeonPVESetting.ReviveAction = nil
JGMDungeonPVESetting.nChangeShipId = nil

function JGMDungeonPVESetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMDungeonPVESetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_DUNGEON_END, self, self.OnBatterDungeonEnd)
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)

    return true
end

function JGMDungeonPVESetting:ClearRestartTimer()
    if self.tbRestartTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRestartTimer)
        self.tbRestartTimer = nil
    end
end

function JGMDungeonPVESetting:Uninit()
    JGMDungeonPVESetting.super.Uninit(self)
    self:ClearRestartTimer()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_DUNGEON_END, self, self.OnBatterDungeonEnd)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
end

function JGMDungeonPVESetting:Parse(tbJsonData)
    JGMDungeonPVESetting.super.Parse(self, tbJsonData)

    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState
    self.nRebornCountdown = tbJsonData.RebornCountdown
    self.nChangeShipId = tbJsonData.ChangeShipId

    local tbReviveAction = tbJsonData.ReviveAction
    if tbReviveAction then
        self.ReviveAction = BattleOperationHelper:Create(nil, tbReviveAction)
    end

    local nShowResultTime = tbJsonData.ShowResultTime
    if(nShowResultTime ~= nil and nShowResultTime > 0) then
        tbStep = tbGameMode:CreateStep(BattleResultStep, tbGameState.nShowResultStepId)
        tbStep:SetParams(tbGameState.rBattlePlayerResultStep, nShowResultTime, true)
        self.ResultStep = tbStep
    end

    return true
end

function JGMDungeonPVESetting:SetPlayerSelfInfo(tbPrepareInfo)
    JGMDungeonPVESetting.super.SetPlayerSelfInfo(self, tbPrepareInfo)
    if self.nChangeShipId ~= nil and self.nChangeShipId > 0 then
        tbPrepareInfo.tbShipInfo.nTypeId = self.nChangeShipId
    end
end

function JGMDungeonPVESetting:OnBatterDungeonEnd(nResult)
    self.tbGameMode:OnAllStepFinished()
end

function JGMDungeonPVESetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.DungeonPVE
end

local function CheckRestart(self, tbPlayerList)
    if self.tbRestartTimer ~= nil or tbPlayerList == nil then
        return false
    end

    local bAllTeamMemberDead = true
    for k, tbPlayer in pairs(tbPlayerList) do
        if tbPlayer:IsDead() == false then
            bAllTeamMemberDead = false
        end
    end

    if bAllTeamMemberDead == false then
        return false
    end

    local fnRestart = function()
        self.tbRestartTimer = nil
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_STEP_RESET)
    end

    NetworkManager:GetRPCNetworkProxy():Multicast(ProtoDC.d2c_ReviveCountdown, { countdown = self.nRebornCountdown })
    self.tbRestartTimer = DelayTimer:DelayRun(fnRestart, self.nRebornCountdown)

    return true
end

function JGMDungeonPVESetting:OnStartStep(tbStep)
    if self.ResultStep == tbStep then
        self:ClearRestartTimer()
    end
    JGMDungeonPVESetting.super.OnStartStep(self, tbStep)
end

function JGMDungeonPVESetting:OnPawnDead(tbDeadActor)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then
        -- 挑战副本死亡处理
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.WaitAllAndNow, tbDeadActor, BattleReviveModeTypeDef.REVIVE_UI_TIME)
        local nTeamId = BattleTeamSystem:FindTeamId(tbDeadActor)
        local tbPlayerList = BattleTeamSystem:GetTeamMembers(nTeamId)
        CheckRestart(self, tbPlayerList)
    end
end

function JGMDungeonPVESetting:OnBatterReviveSuccess(tbPlayer)
    if tbPlayer == nil then
        logerror(" BattlePlayerStateComponent is NULL")
        return false
    end

    if self.ReviveAction ~= nil and self.bStartedStep then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.ReviveAction:Execute()) then
            error("ReviveAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end
end

function JGMDungeonPVESetting:OnPlayerLogout(tbPlayer)
    JGMDungeonPVESetting.super.OnPlayerLogout(self, tbPlayer)

    local tbPlayers = {}
    local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
    local tbPlayerList = BattleTeamSystem:GetTeamMembers(nTeamId)
    if tbPlayerList ~= nil then
        for _, v in ipairs(tbPlayerList) do
            if v ~= tbPlayer then
                table.insert(tbPlayers, v)
            end
        end
    end
    if #tbPlayers > 0 then
        CheckRestart(self, tbPlayers)
    end
end


return JGMDungeonPVESetting