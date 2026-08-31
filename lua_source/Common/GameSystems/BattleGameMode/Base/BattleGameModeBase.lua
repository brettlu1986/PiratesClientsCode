local luaclass = require("luaclass")
local BattleGameModeBase = luaclass("BattleGameModeBase")

local SelfEventHelperClass = require("SelfEventHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local DelayTimer = require("DelayTimer")

BattleGameModeBase.tbSteps = nil
BattleGameModeBase.nCurrentStepIndex = 0
BattleGameModeBase.SelfEventHelper = nil
BattleGameModeBase.tbGameState = nil
BattleGameModeBase.pGameMode = nil
BattleGameModeBase.rCurrentStepInfo = nil
BattleGameModeBase.tbJsonTableFile = nil
BattleGameModeBase.tbPlayers = nil
BattleGameModeBase.tbDungeonData = nil
BattleGameModeBase.nSubDungonId = nil
BattleGameModeBase.AllLogoutTimer = nil

function BattleGameModeBase:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    log("BattleGameModeBase:Init")
    if(tbGameState == nil) then
        error("BattleGameModeBase:Init failed, the gamestate is nil")
        return false
    end

    self.tbSteps = {}
    self.tbPlayers = {}
    self.nSubDungonId = nSubDungonId
    self.pGameMode = pGameMode
    self.tbGameState = tbGameState
    self.tbJsonTableFile = tbJsonTableFile
    self.rCurrentStepInfo = tbGameState.rCurrentStepInfo
    self.SelfEventHelper = SelfEventHelperClass()
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_NO_PLAYER_ENTER, self, self.OnNoPlayerEnter)
    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_RELEASE_DUNGEON, self, self.OnReleaseDungeon)

    return true
end

function BattleGameModeBase:SetDungeonData(tbDungeonData)
    self.tbDungeonData = tbDungeonData
end

function BattleGameModeBase:GetGameState()
    return self.tbGameState
end

local function ClearLogoutTimerHandle(self)
    local AllLogoutTimer = self.AllLogoutTimer
    if(AllLogoutTimer) then
        AllLogoutTimer:Clear()
        self.AllLogoutTimer = nil
    end
end

function BattleGameModeBase:Uninit()
    self.SelfEventHelper:UnregisterAll()
    self:DestroyAllSteps()
    self.tbGameState = nil
    self.tbSteps = nil
    self.SelfEventHelper = nil
    self.pGameMode = nil
    self.tbTemplateData = nil
    self.tbPlayers = nil

    ClearLogoutTimerHandle(self)
end

function BattleGameModeBase:CreateStep(StepClass, nStepId)
    if(nStepId == nil or nStepId < 0) then
        error("BattleGameModeBase:CreateStep failed, invalid step info".. nStepId)
        return nil
    end

    local tbSteps = self.tbSteps
    local nCount = #tbSteps
    for i=1, nCount do
        if(tbSteps[i].nStepId == nStepId) then
            error("BattleGameModeBase:CreateStep failed, duplicated step id".. nStepId)
            return nil
        end
    end

    local Step = StepClass()
    Step.nStepId = nStepId
    Step:Init()
    Step:SetReplicatedStepInfo(self.rCurrentStepInfo)
    Step:SetCompleteCallback(function(TempStep) self:OnStepComplete(TempStep) end)
    table.insert(self.tbSteps, Step)
    return Step
end

function BattleGameModeBase:DestroyAllSteps()
    local tbSteps = self.tbSteps
    local nCount = #tbSteps
    for i=1, nCount do
        tbSteps[i]:Uninit()
    end
    self.tbSteps = {}
end

function BattleGameModeBase:GetCurrentStep()
    local tbSteps = self.tbSteps
    local nCurrentStepIndex = self.nCurrentStepIndex
    if(nCurrentStepIndex >= 1 and nCurrentStepIndex <= #tbSteps) then
        return tbSteps[nCurrentStepIndex]
    end
    return nil
end

function BattleGameModeBase:StartFirstStep()
    self.nCurrentStepIndex = 0
    self:GoToNextStep()
end

function BattleGameModeBase:OnAllStepFinished()
    log("BattleGameModeBase:OnFinished")
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_FINISHED, self)
end

function BattleGameModeBase:GoToNextStep()
    local tbSteps = self.tbSteps
    local tbCurrentStep = self:GetCurrentStep()
    if(tbCurrentStep ~= nil and not tbCurrentStep:IsCompleted()) then
        tbCurrentStep:ForceStop()
    end

    local nNewStepIndex = self.nCurrentStepIndex + 1
    if(nNewStepIndex >= 1 and nNewStepIndex <= #tbSteps) then
        self.nCurrentStepIndex = nNewStepIndex
        self:OnStartStep(tbSteps[nNewStepIndex])
    else
        self:OnAllStepFinished()
    end
end

function BattleGameModeBase:OnStartStep(Step)
    Step:Start()
end

function BattleGameModeBase:OnStepComplete(Step)
    if(self:GetCurrentStep() == Step) then
        self:GoToNextStep()
    -- 有可能target完成调后,action又调一次完成,不处理即可
    -- else
    --     logerror("BattleGameModeBase:OnStepComplete error, the completed step is not current step",
    --         self:GetCurrentStep().szName, Step.szName)
    end
end

function BattleGameModeBase:SetReplicatedStepInfo(rCurrentStepInfo)
    self.rCurrentStepInfo = rCurrentStepInfo
end

function BattleGameModeBase:SnapshotGameState()
    log("BattleGameModeBase:SnapshotGameState")
    local tbCurrentStep = self:GetCurrentStep()
    if(tbCurrentStep == nil) then
        logerror("BattleGameModeBase:SnapshotGameStateToNewPlayer failed, current step is nil")
        return
    end

    local tbGameState = self.tbGameState
    tbGameState.rGameStateBaseInfo.Rep()

    if(not tbCurrentStep:SnapshotToReplicatedProperty()) then
        local Json = require("dkjson")
        logerror("BattleGameModeBase:SnapshotGameStateToNewPlayer failed, current step snapshot error",
            Json.encode(tbCurrentStep:GetDebugInfo()))
        return
    end
end

-------------------------------------------------------------------------------------------
function BattleGameModeBase:CreatePlayerSelf(tbPrepareInfo, pController,
        nControllerNetGuid, nControllerUniqueId)

    -- 这个根据逻辑需要修改
    local bIsSpectator = false

    -- 这里只创建壳子，并不创建actor，actor在OnSpawnDefaultPawnForController创建
    return GameObjectSystem:CreatePlayerSelfInGameMode(tbPrepareInfo, pController,
        nControllerNetGuid, nControllerUniqueId, bIsSpectator)
end

function BattleGameModeBase:SpawnPlayerPawn(tbGamePlayer, bPossess)
    local tbStartJsonData = self:FindPlayerStartJsonData(tbGamePlayer)
    if(tbStartJsonData == nil) then
        logerror("BattleGameModeBase:OnPlayerSpawnPawn failed, FindPlayerStartJsonData is invalid", tbGamePlayer.nPlayerId)
        return false
    end

    local tbSpawnInfo = {}
    tbSpawnInfo.tbStartJsonData = tbStartJsonData
    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local bRet = GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbGamePlayer, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(not bRet) then
        logerror("BattleGameModeBase:OnPlayerSpawnPawn failed, the returned gameobject is nil", tbGamePlayer.nPlayerId)
        return false
    end

    return true
end

function BattleGameModeBase:OnPlayerLogin(tbGamePlayer)
    local tbStep = self:GetCurrentStep()
    if(tbStep) then
        tbStep:OnPlayerLogin(tbGamePlayer)
    end

    local bFind = false
    for nIndex, tbPlayer in ipairs(self.tbPlayers) do
        if(tbPlayer == tbGamePlayer) then
            bFind = true
            break
        end
    end
    if(not bFind) then
        table.insert(self.tbPlayers, tbGamePlayer)
    end
end

function BattleGameModeBase:OnPlayerReLogin(tbGamePlayer)
    local tbStep = self:GetCurrentStep()
    if(tbStep) then
        tbStep:OnPlayerReLogin(tbGamePlayer)
    end

    local bFind = false
    for nIndex, tbPlayer in ipairs(self.tbPlayers) do
        if(tbPlayer == tbGamePlayer) then
            bFind = true
            break
        end
    end
    if(not bFind) then
        table.insert(self.tbPlayers, tbGamePlayer)
    end
end

function BattleGameModeBase:OnPlayerLogout(tbGamePlayer)
end

function BattleGameModeBase:OnAllPlayerLogoutWithEvent()
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_PRE_ON_ALL_PLAYER_LOGOUT)
    self:OnAllPlayerLogout()

    -- 这里特意在OnAllPlayerLogout外发送这个消息，因为OnAllPlayerLogout会触发UninitGameMode
    -- 这里要延迟一帧 因为在BattleGameModeSystem要删除GamePlayerState
    ClearLogoutTimerHandle(self)
    self.AllLogoutTimer = DelayTimer:RunNextTick(function()
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT)
    end)
end

function BattleGameModeBase:OnAllPlayerLogout()
    log("BattleGameModeBase:OnAllPlayerLogout")
    for i, Step in ipairs(self.tbSteps) do
        Step:SetCompleteCallback(nil)
    end

    local tbStep = self:GetCurrentStep()
    if(tbStep) then
        tbStep:ForceStop()
    end
end

function BattleGameModeBase:OnNoPlayerEnter()
    log("BattleGameModeBase:OnNoPlayerEnter")
    self:OnAllPlayerLogoutWithEvent()
end

function BattleGameModeBase:OnReleaseDungeon()
    self:OnAllPlayerLogoutWithEvent()
end

-- 子类必须重载
-- 具体内容见从编辑器导出的PlayerStarts.json
function BattleGameModeBase:FindPlayerStartJsonData(tbGamePlayer)
    error('BattleGameModeBase:FindPlayerStartJsonData() must be overwrite by sub class ')
    return nil
end

function BattleGameModeBase:OnPawnDead(tbDeadObject)
    self:DestroyDeadPawn(tbDeadObject)
end

function BattleGameModeBase:DestroyDeadPawn(tbDeadObject)
    local nObjectType = tbDeadObject.ObjectType
    local nUniqueId = tbDeadObject:GetUEActorUniqueId()
    if(nObjectType == GameObjectTypeDef.PlayerSelf) then
        -- 这里只删除玩家的actor，还保留玩家的object
        -- GameObjectSystem:DestroyUEActor(tbDeadObject)
        self:OnPostDestroyPlayerPawn(tbDeadObject)
    elseif(nObjectType == GameObjectTypeDef.Npc) then
        GameObjectSystem:DestroyNpcInGameMode(nUniqueId)
    else
        logerror("BattleGameModeBase:DestroyDeadPawn failed, the object type is invalid", nUniqueId)
    end
end

function BattleGameModeBase:OnPostDestroyPlayerPawn(GamePlayerSelf)
    -- GamePlayerSelf:OnBeginSpectating()
end

function BattleGameModeBase:RebornPlayer(GamePlayerSelf)
    local tbTransform = self:FindPlayerStartJsonData(GamePlayerSelf).Transform
    GamePlayerSelf:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
end

-- 退出副本，副本未完时
function BattleGameModeBase:QuitDungeon(tbPlayer, nQuitReason)
    log("BattleGameModeBase:QuitDungeon")
end

-- 离开副本，副本完成时，通常是显示结果时用于玩家提前退出
function BattleGameModeBase:LeaveDungeon(tbPlayer)
    log("BattleGameModeBase:LeaveDungeon")
end

function BattleGameModeBase:TryResetAllSteps(nSenderUniqueId)
end

function BattleGameModeBase:OnPawnsPaused()
end

function BattleGameModeBase:ApproveLogin(szOptions)
    return ""
end

function BattleGameModeBase:OnKickPlayer(tbPlayer)
end

function BattleGameModeBase:ReLoginPossessGamePlayer(tbPlayer)
end

function BattleGameModeBase:NotifyPlayerLeave(tbPlayer)
    log("BattleGameModeBase:NotifyPlayerLeave")
end

return BattleGameModeBase
