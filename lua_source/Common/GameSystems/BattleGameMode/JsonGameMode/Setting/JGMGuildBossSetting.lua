local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMGuildBossSetting = luaclass("JGMGuildBossSetting", JGMCommonSetting)

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
local BattleResultStep = dynamic_require("BattleGuildbossResultStep")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
local D2CHelper = require("D2CHelper")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

JGMGuildBossSetting.tbRestartTimer = nil
JGMGuildBossSetting.nRebornCountdown = 0
JGMGuildBossSetting.ReviveAction = nil
JGMGuildBossSetting.tbPlayerWaitRevive = nil         -- 玩家死亡等待复活

function JGMGuildBossSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMGuildBossSetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
  
    self.tbPlayerWaitRevive = {}

    return true
end

local function ClearReviveData(self)
    if self.tbPlayerWaitRevive == nil then 
        return
    end
    for _, tbPlayerTimer in ipairs(self.tbPlayerWaitRevive) do
        if tbPlayerTimer.tbTimer ~= nil then
            DelayTimer:ClearTimer(tbPlayerTimer.tbTimer)
            tbPlayerTimer.tbTimer = nil
        end
    end
    self.tbPlayerWaitRevive = nil
end

local function ClearRestartTimer(self)
    if self.tbRestartTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRestartTimer)
        self.tbRestartTimer = nil
    end
end

function JGMGuildBossSetting:Uninit()
    JGMGuildBossSetting.super.Uninit(self)
    ClearRestartTimer(self)
    ClearReviveData(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
end

function JGMGuildBossSetting:Parse(tbJsonData)
    JGMGuildBossSetting.super.Parse(self, tbJsonData)
    
    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState
    self.nRebornCountdown = tbJsonData.RebornCountdown

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

function JGMGuildBossSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.GuildBoss
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

    -- 设置独自复活失效
    ClearReviveData(self)

    return true
end

function JGMGuildBossSetting:OnStartStep(tbStep)
    if self.ResultStep == tbStep then
        ClearRestartTimer(self)
        ClearReviveData(self)
    end
    JGMGuildBossSetting.super.OnStartStep(self, tbStep)
end

function JGMGuildBossSetting:OnPawnDead(tbDeadActor)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
        local nTeamId = BattleTeamSystem:FindTeamId(tbDeadActor)
        local tbPlayerList = BattleTeamSystem:GetTeamMembers(nTeamId)
        if CheckRestart(self, tbPlayerList) then
            return
        end

        if self.tbPlayerWaitRevive == nil then
            self.tbPlayerWaitRevive = {}
        end

        local tbTransform = tbDeadActor:GetLocation()
        local tbReviveTimer
        local fnRestart = function()
            -- revieve
            DelayTimer:ClearTimer(tbReviveTimer)
            tbReviveTimer = nil
    
            tbDeadActor:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
            D2CHelper:PlayerSetCameraYaw(tbDeadActor, tbTransform.Yaw)
    
            EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, tbDeadActor)
        end

        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, tbDeadActor)
        local tbPacket = {}
        tbPacket.countdown = self.nRebornCountdown 
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbDeadActor:GetUEControllerUniqueId(), ProtoDC.d2c_Countdown, tbPacket)
        tbReviveTimer = DelayTimer:DelayRun(fnRestart, self.nRebornCountdown)
    
        local bInTable = false
        for _, tbPlayerRevive in ipairs(self.tbPlayerWaitRevive) do
            if tbPlayerRevive.tbPlayer == tbDeadActor then
                if tbPlayerRevive.tbTimer ~= nil then
                    DelayTimer:ClearTimer(tbPlayerRevive.tbTimer)
                    tbPlayerRevive.tbTimer = nil
                end
                tbPlayerRevive.tbTimer = tbReviveTimer
                bInTable = true
            end
        end
        if not bInTable then
            local tbPlayerReviveInfo = {}
            tbPlayerReviveInfo.tbPlayer = tbDeadActor
            tbPlayerReviveInfo.tbTimer = tbReviveTimer
            -- tbPlayerReviveInfo.tbPoint = NewPoint
            table.insert(self.tbPlayerWaitRevive, tbPlayerReviveInfo)    
        end
    end

end

function JGMGuildBossSetting:OnBatterReviveSuccess(tbPlayer)
    if tbPlayer == nil then
        logerror(" BattlePlayerStateComponent is NULL")
        return false
    end
     -- reset player battle statistics data
     BattleDataStatisticsSystem:ResetPlayer(tbPlayer.nPlayerId)

    if self.ReviveAction ~= nil and self.bStartedStep then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.ReviveAction:Execute()) then
            error("ReviveAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end
end

function JGMGuildBossSetting:OnPlayerLogout(tbPlayer)
    JGMGuildBossSetting.super.OnPlayerLogout(self, tbPlayer)

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


return JGMGuildBossSetting