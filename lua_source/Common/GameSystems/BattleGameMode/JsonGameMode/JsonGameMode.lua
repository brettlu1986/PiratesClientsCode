local luaclass = require("luaclass")
local BattleGameModeBaseClass = dynamic_require("BattleCommonGameMode")
local JsonGameMode = luaclass("JsonGameMode", BattleGameModeBaseClass)

local BattleOperationHelper = require("BattleOperationHelper")
local BattleTimerHelper = require("BattleTimerHelper")
local BattleBlackboard = require("BattleBlackboard")
local BattleTriggerHelper = require("BattleTriggerHelper")
local BattleTransformPointHelper = require("BattleTransformPointHelper")
local BattleOperationDef = dynamic_require("BattleOperationDef")
local DungeonQuitDialogType = require("DungeonQuitDialogType")
local BattleDummyHelper = require("BattleDummyHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattlePlayerHelper = require("BattlePlayerHelper")
local BattleSelectPlayerStartHelper = require("BattleSelectPlayerStartHelper")
local BattleVolumeHelper = require("BattleVolumeHelper")
local BattleTransporterHelper = require("BattleTransporterHelper")
local AsyncHelperSystem = require("AsyncHelperSystem")
JsonGameMode.Setting = nil

local szShotActorClass = "/Game/Game/Ships/Shot/ShotActors/BP_ShotActorBase.BP_ShotActorBase_C"

local function Parse(self, tbJsonData)
    local SettingData = tbJsonData.Setting
    if(SettingData == nil) then
        error("JsonGameMode has no setting")
        return false
    end
    self.Setting = BattleOperationHelper:Create(nil, SettingData, self)
    if(self.Setting == nil) then
        error("JsonGameMode create setting failed")
        return false
    end
    return true  
end

-- 初始化相关的都放到这里，reset时也会用到
local function InitGame(self)
    local tbContainer = self.tbJsonTableFile.tbContainer
    BattleTimerHelper:Init()
    BattleBlackboard:Init()
    BattleTransformPointHelper:Init(tbContainer)
    BattleTriggerHelper:Init(tbContainer.Triggers)
    BattleDummyHelper:Init()
    BattlePlayerHelper:Init()
    BattleSelectPlayerStartHelper:Init()
    BattleVolumeHelper:Init(tbContainer)
    BattleTransporterHelper:Init(tbContainer)
    return Parse(self, self:GetRootJsonData())
end

-- 初始化相关的都放到这里，reset时也会用到
local function UninitGame(self)
    if(self.Setting) then
        self.Setting:Uninit()
        self.Setting = nil
    end

    BattleTriggerHelper:Uninit()
    BattleTransformPointHelper:Uninit()
    BattleBlackboard:Uninit()
    BattleTimerHelper:Uninit()
    BattleDummyHelper:Uninit()
    BattlePlayerHelper:Uninit()
    BattleSelectPlayerStartHelper:Uninit()
    BattleVolumeHelper:Uninit()
    AsyncHelperSystem:Uninit()
    BattleTransporterHelper:Uninit()
end

function JsonGameMode:GetRootJsonData()
    return self.tbJsonTableFile.tbContainer.GameMode[1]
end

function JsonGameMode:OnPostInitGame()
    self.tbGameState.rGameStateBaseInfo.nQuitDungeonType = self.Setting:GetQuitDungeonDialogType()
end

function JsonGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    JsonGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)

    
    math.random(1, 100000)

    BattleOperationDef:RegisterAll()
    if(not InitGame(self)) then
        return false
    end

    self:OnPostInitGame()
    return true    
end

function JsonGameMode:Uninit()
    UninitGame(self)
    BattleOperationDef:UnregisterAll()

    JsonGameMode.super.Uninit(self)
end

function JsonGameMode:KillAll()
    local tbPlayers = {}
    local tbDestroys = {}
    local tbAll = GameObjectSystem:GetAllGameObjects()
    local PlayerSelfType = GameObjectTypeDef.PlayerSelf
    for nId, GameObject in pairs(tbAll) do
        if(PlayerSelfType == GameObject.ObjectType) then
            table.insert(tbPlayers, GameObject)
        else
            table.insert(tbDestroys, GameObject)
        end
    end

    local Type, nInstanceId
    for _, GameObject in ipairs(tbDestroys) do
        Type = GameObject.ObjectType
        nInstanceId = GameObject.nServerInstanceId
        if(Type == GameObjectTypeDef.Npc) then
            GameObjectSystem:DestroyNpcInGameModeByInstanceId(nInstanceId)
        elseif(Type == GameObjectTypeDef.Trigger) then
            GameObjectSystem:DestroyTriggerInGameModeByInstanceId(nInstanceId)
        elseif(Type == GameObjectTypeDef.Dummy) then
            GameObjectSystem:DestroyDummyInGameModeByInstanceId(nInstanceId)
        end
    end
    
    for _, GameObject in ipairs(tbPlayers) do
        GameObject:KillSelf()
    end

    local tbShotActors = GameplayStatics.GetAllActorsOfClass(GWorld, szShotActorClass:load())
    for _,v in ipairs(tbShotActors) do
        v:K2_DestroyActor()
    end
end

function JsonGameMode:RebornAllPlayers()
    local tbAll = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for GameObject, _ in pairs(tbAll) do
        self:RebornPlayer(GameObject)
        self:OnPlayerLogin(GameObject)
    end    
end

function JsonGameMode:TryResetAllSteps(nSenderUniqueId)
    self.Setting:TryResetAllSteps(nSenderUniqueId)
end

function JsonGameMode:ResetAllSteps(bStartFirstStep)
    log("JsonGameMode:ResetAllSteps", bStartFirstStep)
    for i, v in ipairs(self.tbSteps) do
        v:ForceStop()
    end

    self:KillAll()
    UninitGame(self)
    
    InitGame(self) 

    self:RebornAllPlayers()
       
    if(bStartFirstStep) then
        self:StartFirstStep()
    end

    -- if(self.Setting) then
    --     self.Setting:OnPostResetAllSteps()
    -- end
end

-- function JsonGameMode:CanResetAllSteps()
--     if(self.Setting) then
--         return self.Setting:CanResetAllSteps()
--     end
--     return false
-- end

function JsonGameMode:OnStepComplete(Step)
    if(self.Setting) then
        self.Setting:OnStepComplete(Step)
    end
    JsonGameMode.super.OnStepComplete(self, Step)
end

function JsonGameMode:OnStartStep(Step)
    JsonGameMode.super.OnStartStep(self, Step)
    if(self.Setting) then
        self.Setting:OnStartStep(Step)
    end    
end

function JsonGameMode:OnAllStepFinished()
    for i, v in ipairs(self.tbSteps) do
        v:ForceStop()
    end
    BattleTimerHelper:DestroyAllTimers()
    BattleBlackboard:Clear()
    self.Setting:OnAllStepFinished()
    JsonGameMode.super.OnAllStepFinished(self)
end

function JsonGameMode:StartFirstStep()
    self.Setting:StartFirstStep()
    JsonGameMode.super.StartFirstStep(self)
end

function JsonGameMode:FindPlayerStartJsonData(tbGamePlayer)
    return self.Setting:OnFindPlayerStart(tbGamePlayer)
end

function JsonGameMode:SpawnPlayerPawn(tbGamePlayer, bPossess)
    return self.Setting:OnSpawnPlayerPawn(tbGamePlayer, bPossess)
end

function JsonGameMode:OnPlayerLogin(tbGamePlayer)
    JsonGameMode.super.OnPlayerLogin(self, tbGamePlayer)
    self.Setting:OnPlayerLogin(tbGamePlayer)
end

function JsonGameMode:OnPlayerReLogin(tbGamePlayer)
    JsonGameMode.super.OnPlayerReLogin(self, tbGamePlayer)
    self.Setting:OnPlayerReLogin(tbGamePlayer)
end

function JsonGameMode:OnPlayerLogout(tbGamePlayer)
    self.Setting:OnPlayerLogout(tbGamePlayer)
    JsonGameMode.super.OnPlayerLogout(self, tbGamePlayer)
end

function JsonGameMode:QuitDungeon(tbPlayer,nQuitReason)
    self.Setting:QuitDungeon(tbPlayer,nQuitReason)
    JsonGameMode.super:QuitDungeon(tbPlayer, nQuitReason)
end

function JsonGameMode:NotifyPlayerLeave(tbPlayer)
    self.Setting:NotifyPlayerLeave(tbPlayer)
    JsonGameMode.super:NotifyPlayerLeave(tbPlayer)
end

function JsonGameMode:OnPawnDead(tbDeadObject)
    JsonGameMode.super.OnPawnDead(self, tbDeadObject)

    self.Setting:OnPlayerDead(tbDeadObject)
end

function JsonGameMode:OnKickPlayer(tbPlayer)
    JsonGameMode.super:OnKickPlayer(tbPlayer)
    self.Setting:OnKickPlayer(tbPlayer)
end

function JsonGameMode:RebornPlayer(GamePlayerSelf)
    local tbTransform = self.Setting:OnFindRebornPoint(GamePlayerSelf)
    if(tbTransform) then
        GamePlayerSelf:Reborn(tbTransform.X, tbTransform.Y, tbTransform.Z, tbTransform.Yaw)
        return
    end
    JsonGameMode.super.RebornPlayer(self, GamePlayerSelf)    
end

function JsonGameMode:SnapshotGameState()
    JsonGameMode.super.SnapshotGameState(self)
    self.Setting:OnSnapshotGameState()
end

function JsonGameMode:GetQuitDungeonDialogType()
    return DungeonQuitDialogType.JsonPVE
end

function JsonGameMode:CreateTeam(tbGamePlayer, nGroupIndex)
    self.Setting:CreateTeam(tbGamePlayer, nGroupIndex)
end

function JsonGameMode:CreatePlayerSelf(tbPrepareInfo, pController, 
        nControllerNetGuid, nControllerUniqueId)

    self.Setting:SetPlayerSelfInfo(tbPrepareInfo)

    return JsonGameMode.super.CreatePlayerSelf(self, tbPrepareInfo, pController, nControllerNetGuid, nControllerUniqueId)
end

function JsonGameMode:ApproveLogin(szOptions)
    return self.Setting:OnApproveLogin(szOptions)
end

function JsonGameMode:OnForceReleaseDungeon()
    self.Setting:OnForceReleaseDungeon()
end

return JsonGameMode