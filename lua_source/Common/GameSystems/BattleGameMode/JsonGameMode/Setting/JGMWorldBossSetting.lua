local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMWorldBossSetting = luaclass("JGMWorldBossSetting", JGMCommonSetting)

local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleBlackboard = require("BattleBlackboard")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local DelayTimer = require("DelayTimer")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local BattleResultStep = dynamic_require("BattleWorldbossResultStep")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
local D2CHelper = require("D2CHelper")
-- local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
-- local Timer = require("Timer")
local GameObjectSystem = dynamic_require("GameObjectSystem")

JGMWorldBossSetting.nRebornCountdown = 0
JGMWorldBossSetting.ReviveAction = nil
JGMWorldBossSetting.tbPlayerWaitRevive = nil         -- 玩家死亡等待复活
-- JGMWorldBossSetting.RemainTimeTimer = nil            -- BattleSetStepRemainTimeAction中同步处理
JGMWorldBossSetting.bResult = false                  -- 是否结算
-- JGMWorldBossSetting.bPlayerAutoBattle = false        -- 自动战斗标记

-- local UPDATE_INTERVAL = 10                             -- 同步间隔

function JGMWorldBossSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMWorldBossSetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    -- EventManager:BindEventMethod(CommonEventDef.EV_PLAYER_AUTO_BATTLE_STATE_CHANGED, self, self.OnPlayerAutoBattleStateChanged)
    
    self.tbPlayerWaitRevive = {}
    -- self.bPlayerAutoBattle = false
    self.bResult = false
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

-- local function ClearStepRemainTimer(self)
--     if self.RemainTimeTimer then
--         self.RemainTimeTimer:Clear()
--         self.RemainTimeTimer = nil
--     end
-- end

function JGMWorldBossSetting:Uninit()
    JGMWorldBossSetting.super.Uninit(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_PLAYER_AUTO_BATTLE_STATE_CHANGED, self, self.OnPlayerAutoBattleStateChanged)
    -- ClearStepRemainTimer(self)
    ClearReviveData(self)
end

function JGMWorldBossSetting:Parse(tbJsonData)
    JGMWorldBossSetting.super.Parse(self, tbJsonData)
    
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

function JGMWorldBossSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.WorldBoss
end

function JGMWorldBossSetting:OnStartStep(tbStep)
    if self.ResultStep == tbStep then
        self.bResult = true
        ClearReviveData(self)
        -- ClearStepRemainTimer(self)
    end
    JGMWorldBossSetting.super.OnStartStep(self, tbStep)
end

function JGMWorldBossSetting:OnPawnDead(tbDeadActor)    
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
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

function JGMWorldBossSetting:OnBatterReviveSuccess(tbPlayer)
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
    -- if tbPlayer.BattleAIComponent and self.bPlayerAutoBattle then 
    --     tbPlayer.BattleAIComponent:SetEnable(self.bPlayerAutoBattle)
    -- end
end

-- 死亡会销毁AI设置为false
-- function JGMWorldBossSetting:OnPlayerAutoBattleStateChanged(bEnable)
--     self.bPlayerAutoBattle = bEnable
-- end

local function CheckAllPlayerLogout(tbPlayer)
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        if Object ~= tbPlayer then
            return false
        end
    end
    return true
end

function JGMWorldBossSetting:OnPlayerLogout(tbPlayer)
    JGMWorldBossSetting.super.OnPlayerLogout(self, tbPlayer)

    if not self.bResult and CheckAllPlayerLogout(tbPlayer) then
        self:SendPlayerResult()
    end

end

function JGMWorldBossSetting:SendPlayerResult()
end

-- function JGMWorldBossSetting:StepRemainTimeSync(nRemainTime)
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
    
return JGMWorldBossSetting