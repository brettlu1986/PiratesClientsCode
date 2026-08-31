local luaclass = require("luaclass")
local JsonGameModeSettingBase = require("JsonGameModeSettingBase")
local JGMCommonSetting = luaclass("JGMCommonSetting", JsonGameModeSettingBase)

local BattleTimerStep = require("BattleTimerStep")
local JsonMainStep = require("JsonMainStep")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local BattleOperationHelper = require("BattleOperationHelper")
local BattleBlackboard = require("BattleBlackboard")
local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local BattleTeamSystem = require("BattleTeamSystem")
local Timer = require("Timer")

JGMCommonSetting.bCanReborn = false
JGMCommonSetting.PlayerStartAction = nil
JGMCommonSetting.RebornPointAction = nil
JGMCommonSetting.PlayerLoginAction = nil

JGMCommonSetting.CoundDownStep = nil
JGMCommonSetting.JsonMainStep = nil
-- 是否step已经执行
JGMCommonSetting.bStartedStep = false
-- BattleSetStepRemainTimeAction中同步处理
JGMCommonSetting.RemainTimeTimer = nil

local UPDATE_INTERVAL = 5                             -- 同步间隔

function JGMCommonSetting:Init(tbGameMode)
    if(not JGMCommonSetting.super.Init(self, tbGameMode)) then
        return false
    end

    BattleBlackboard:DefineTable(BattleOperationDef.CurrentObject, nil)
    BattleBlackboard:DefineTable(BattleOperationDef.CurrentPoint, nil)
    BattleBlackboard:DefineTable(BattleOperationDef.CurrentPlayerStart, nil)

    -- EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_START_NPC, self, self.OnCollectionStart)

    return true
end

function JGMCommonSetting:ClearStepRemainTimer()
    if self.RemainTimeTimer then
        self.RemainTimeTimer:Clear()
        self.RemainTimeTimer = nil
    end
end

function JGMCommonSetting:Uninit()
    self.tbGameMode:DestroyAllSteps()
    JGMCommonSetting.super.Uninit(self)
    self.bStartedStep = false
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_COLLECTION_START_NPC, self, self.OnCollectionStart)
    self:ClearStepRemainTimer()
end

local function ParseSteps(self, tbJsonData)
    local tbStep
    local tbGameMode = self.tbGameMode
    local tbGameState = tbGameMode.tbGameState
    tbGameState.rJsonSetting.bCanReborn = tbJsonData.CanReborn == true

    local nCountDownTime = tbGameMode.tbDungeonData.nCountDownTime
    if(nCountDownTime > 0) then
        tbStep = tbGameMode:CreateStep(BattleTimerStep, tbGameState.nCountDownStepId)
        tbStep:SetParams(tbGameState.rBattleTimerStepInfo, tbGameState.rStepRemainTime, nCountDownTime)
        self.CoundDownStep = tbStep
    end

    tbStep = tbGameMode:CreateStep(JsonMainStep, tbGameState.nMatchStepId)
    tbStep:Parse(tbGameMode:GetRootJsonData(), tbGameState)
    self.JsonMainStep = tbStep

end

function JGMCommonSetting:Parse(tbJsonData)
    ParseSteps(self, tbJsonData)

    local tbPlayerStartData = tbJsonData.PlayerStartAction
    if(tbPlayerStartData) then
        logdebug("player start action ??")
        self.PlayerStartAction = BattleOperationHelper:Create(nil, tbPlayerStartData)
    end

    local tbRebornPointData = tbJsonData.RebornPointAction
    if(tbRebornPointData) then
        self.RebornPointAction = BattleOperationHelper:Create(nil, tbRebornPointData)
    end

    local tbPlayerLogin = tbJsonData.PlayerLoginAction
    if(tbPlayerLogin) then
        self.PlayerLoginAction = BattleOperationHelper:Create(nil, tbPlayerLogin)
    end
    return true
end

function JGMCommonSetting:OnFindPlayerStart(tbPlayer)
    if(self.PlayerStartAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.PlayerStartAction:Execute()) then
            error("PlayerStartAction execute failed")
        end

        local tbPlayerStart = BattleBlackboard:GetTable(BattleOperationDef.CurrentPlayerStart)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPlayerStart, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbPlayerStart) then
            return tbPlayerStart
        end
    end

    return JGMCommonSetting.super.OnFindPlayerStart(self, tbPlayer)
end

function JGMCommonSetting:OnSpawnPlayerPawn(tbGamePlayer, bPossess)
    local tbStartJsonData = self:OnFindPlayerStart(tbGamePlayer)
    if(tbStartJsonData == nil) then
        logerror("JGMCommonSetting:OnPlayerSpawnPawn failed, OnFindPlayerStart is invalid", tbGamePlayer.nPlayerId)
        return false
    end

    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbStartJsonData
    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGamePlayer, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(not bRet) then
        logerror("JGMCommonSetting:OnPlayerSpawnPawn failed, the returned gameobject is nil", tbGamePlayer.nPlayerId)
        return false
    end

    return JGMCommonSetting.super.OnSpawnPlayerPawn(self, tbGamePlayer, bPossess)
end

function JGMCommonSetting:OnFindRebornPoint(tbPlayer)
    if(self.RebornPointAction ~= nil) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
        if(false == self.RebornPointAction:Execute()) then
            error("RebornPointAction execute failed")
        end

        local tbTransform = BattleBlackboard:GetTable(BattleOperationDef.CurrentPoint)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentPoint, nil)
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
        if(tbTransform) then
            return tbTransform
        end
    end

    return JGMCommonSetting.super.OnFindRebornPoint(self, tbPlayer)
end

function JGMCommonSetting:OnPlayerLogin(tbPlayer)
    if( self.PlayerLoginAction ~= nil and  self.bStartedStep ) then
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, tbPlayer)
         if(false == self.PlayerLoginAction:Execute()) then
            error("PlayerLoginAction execute failed")
        end
        BattleBlackboard:SetTable(BattleOperationDef.CurrentObject, nil)
    end
    JGMCommonSetting.super.OnPlayerLogin(self, tbPlayer)
end

function JGMCommonSetting:OnStartStep(tbStep)
    -- if self.JsonMainStep == tbStep and not self.bStartedStep then
    --     self.bStartedStep = true
    --     local tbObjects = GameObjectSystem:GetAllGameObjects()
    --     for nId, Object in pairs(tbObjects) do
    --         if(Object.ObjectType ==  GameObjectTypeDef.PlayerSelf)  then
    --             self:OnPlayerLogin(Object)
    --         end
    --     end
    -- end
    -- 结算阶段清除计时
    if self.ResultStep == tbStep then
        self:ClearStepRemainTimer()
    end

    JGMCommonSetting.super.OnStartStep(self, tbStep)
end

-- function JGMCommonSetting:OnCollectionStart(nNpcServerInstanceId, nPlayerServerInstanceId)
--     if self.bCollection == false then
--         return
--     end
--     BattleCollectionSystem:OnCollectionStart(nNpcServerInstanceId, nPlayerServerInstanceId)
-- end

function JGMCommonSetting:OnSnapshotGameState()
    JGMCommonSetting.super.OnSnapshotGameState(self)

    local rStepRemainTime = self.tbGameMode.tbGameState.rStepRemainTime
    if rStepRemainTime then
        rStepRemainTime.Rep()
    end
end

function JGMCommonSetting:StepRemainTimeSync(nRemainTime, nUpdateInterval)
    if nRemainTime <= 0 then
        return
    end

    if nUpdateInterval == nil or nUpdateInterval <= 0 then
        nUpdateInterval = UPDATE_INTERVAL
    end

    local tbGameState = BattleGameModeSystem:GetGameState()
    local rStepRemainTime = tbGameState.rStepRemainTime
    rStepRemainTime.nTime = nRemainTime
    rStepRemainTime.Rep()

    local Update = function()
        rStepRemainTime.nTime = rStepRemainTime.nTime - nUpdateInterval
        if rStepRemainTime.nTime < 0 then
            self:ClearStepRemainTimer()
        else
            rStepRemainTime.Rep()
        end
    end
    self:ClearStepRemainTimer()
    self.RemainTimeTimer = Timer.NewTimerMethod(nil, Update, nUpdateInterval, true)
end

function JGMCommonSetting:CreateTeam(tbGamePlayer, nGroupIndex)
    BattleTeamSystem:AddMember(tbGamePlayer, nGroupIndex)
end

function JGMCommonSetting:DefineGameStateByType(nGameStatePropType)
    local GameStatePropertyBinder = BattleGameModeSystem:GetGameStatePropertyBinder()
    if GameStatePropertyBinder then
        local tbGameState = BattleGameModeSystem:GetGameState()
        
        GameStatePropertyBinder:DefinePropertiesByType(tbGameState, nGameStatePropType)
    else
        error("JGMCommonSetting:DefineGameStateByType GameStatePropertyBinder is nil. ".. nGameStatePropType)
    end
end

return JGMCommonSetting
