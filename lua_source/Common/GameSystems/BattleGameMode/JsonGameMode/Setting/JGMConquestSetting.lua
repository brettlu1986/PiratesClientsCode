local luaclass = require("luaclass")
local JGMCommonSetting = dynamic_require("JGMCommonSetting")
local JGMConquestSetting = luaclass("JGMConquestSetting", JGMCommonSetting)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleBlackboard = require("BattleBlackboard")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleResultStep = dynamic_require("BattleGroundResultStep")
local DelayTimer = require("DelayTimer")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
-- local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTargetTrackHelper = require("BattleTargetTrackHelper")
-- local Timer = require("Timer")

JGMConquestSetting.FirstGroupIndex = nil            -- 第一组id
JGMConquestSetting.AnotherPlayerStartAction = nil   -- 另一组StartAction 
JGMConquestSetting.tbPlayerWaitRevive = nil         -- 玩家死亡等待复活
JGMConquestSetting.ReviveAction = nil               -- 玩家复活执行Action
-- JGMConquestSetting.RemainTimeTimer = nil            -- BattleSetStepRemainTimeAction中同步处理
-- local UPDATE_INTERVAL = 10                           -- 同步间隔
-- local WAIT_FOR_PLAY = 5                          -- 等待游戏开始时间

function JGMConquestSetting:Init(tbGameMode)
    assert(not GlobalVariableSystem:IsClient(), "Enter Dungeon mode error")

    if(not JGMConquestSetting.super.Init(self, tbGameMode)) then
        return false
    end
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)

    self.tbPlayerWaitRevive = {}
    return true
end

function JGMConquestSetting:Parse(tbJsonData)
    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState
    -- 最开始添加等待游戏开始step, 用于保证客户端等初始化完成
    -- tbStep = tbGameMode:CreateStep(BattleTimerStep, tbGameState.nWaitForPlayStepId)
    -- tbStep:SetParams(tbGameState.rBattleTimerStepInfo, tbGameMode.rStepRemainTime, WAIT_FOR_PLAY)
   
    JGMConquestSetting.super.Parse(self, tbJsonData)

    local tbAnotherPlayerStartAction = tbJsonData.AnotherPlayerStartAction
    if(tbAnotherPlayerStartAction) then
        self.AnotherPlayerStartAction = BattleOperationHelper:Create(nil, tbAnotherPlayerStartAction)
    end    

    -- 副本加结算step 
    local nShowResultTime = tbJsonData.ShowResultTime
    if(nShowResultTime ~= nil and nShowResultTime > 0) then
        tbStep = tbGameMode:CreateStep(BattleResultStep, tbGameState.nShowResultStepId)
        tbStep:SetParams(tbGameState.rBattlePlayerResultStep, nShowResultTime, true)
        self.ResultStep = tbStep
    end

    local tbReviveAction = tbJsonData.ReviveAction
    if(tbReviveAction) then
        self.ReviveAction = BattleOperationHelper:Create(nil, tbReviveAction)
    end    

    return true
end

function JGMConquestSetting:OnFindPlayerStart(tbPlayer)
    local nGroupIndex = BattleTeamSystem:FindTeamId(tbPlayer)
    if self.FirstGroupIndex == nil then 
        self.FirstGroupIndex = nGroupIndex
    end 

    local StartAction = self.PlayerStartAction
    if self.FirstGroupIndex ~= nGroupIndex then 
        StartAction = self.AnotherPlayerStartAction
    end

    if(StartAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == StartAction:Execute()) then
            error("StartAction execute failed")
        end
        
        local tbTransform = BattleBlackboard:GetTable(BattleOperationDef.CurrentPlayerStart)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPlayerStart, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbTransform) then
            return tbTransform
        end
    end

    return JGMConquestSetting.super.OnFindPlayerStart(self, tbPlayer)
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

function JGMConquestSetting:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, self.OnPawnDead)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, self, self.OnBatterReviveSuccess)
    -- ClearStepRemainTimer(self)
    ClearReviveData(self)
    JGMConquestSetting.super.Uninit(self)
end

function JGMConquestSetting:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.Conquest
end

function JGMConquestSetting:OnPawnDead(tbDeadActor)
    if tbDeadActor.ObjectType == GameObjectTypeDef.PlayerSelf then 
        -- 死亡清除跟踪指引
        BattleTargetTrackHelper:SetTargetTrackVisible(tbDeadActor.nServerInstanceId, false)

        if self.tbPlayerWaitRevive == nil then
            self.tbPlayerWaitRevive = {}
        end
        -- 查找当前表如果玩家存在则死亡次数+1
        local bInTable = false
        for _, tbPlayerRevive in ipairs(self.tbPlayerWaitRevive) do
            if tbPlayerRevive.tbPlayer == tbDeadActor then
                tbPlayerRevive.nDeadCount = tbPlayerRevive.nDeadCount + 1
                bInTable = true
            end
        end
        if not bInTable then
            local tbPlayerReviveInfo = {}
            tbPlayerReviveInfo.tbPlayer = tbDeadActor
            tbPlayerReviveInfo.tbTimer = nil
            tbPlayerReviveInfo.tbPoint = nil
            tbPlayerReviveInfo.nDeadCount = 0
            table.insert(self.tbPlayerWaitRevive, tbPlayerReviveInfo)    
        end
    
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, BattleReviveModeTypeDef.Reset, tbDeadActor)
    end
end

function JGMConquestSetting:OnStartStep(tbStep)
    if self.ResultStep == tbStep then
        self.tbGameMode:OnPawnsPaused()
        ClearReviveData(self)
    end
    JGMConquestSetting.super.OnStartStep(self, tbStep)
end

function JGMConquestSetting:OnBatterReviveSuccess(tbPlayer)
    if tbPlayer == nil then
        logerror("OnBatterReviveSuccess tbPlayer is NULL")
        return false
    end

    if( self.ReviveAction ~= nil and self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.ReviveAction:Execute()) then
            error("ReviveAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end
end

-- function JGMConquestSetting:StepRemainTimeSync(nRemainTime)
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

return JGMConquestSetting