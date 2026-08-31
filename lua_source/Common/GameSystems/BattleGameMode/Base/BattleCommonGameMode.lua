local luaclass = require("luaclass")
local BattleGameModeBase = dynamic_require("BattleGameModeBase")
local BattleCommonGameMode = luaclass("BattleCommonGameMode", BattleGameModeBase)

local D2CHelper = require("D2CHelper")
local DelayTimer = require("DelayTimer")
local BattleTeamSystem = require("BattleTeamSystem")
local BattleTargetTrackHelper = require("BattleTargetTrackHelper")
local BattleSpecialToastHelper = require("BattleSpecialToastHelper")
local BattleNpcChangeInfoHelper = require("BattleNpcChangeInfoHelper")
local BattleObjectiveHelper = require("BattleObjectiveHelper")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local UEActorHelper = require("UEActorHelper")
-- local SpawnerSystem = require("SpawnerSystem")
-- local ShipUtilityHelper = require("ShipUtilityHelper")
local CampSystem = require("CampSystem")
local NetworkManager = dynamic_require("NetworkManager")
local SessionSystem = require("SessionSystem")
local SessionType = require("SessionType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanVehicleHelper = require("HumanVehicleHelper")

local DELAY_DESTORY_NPC_TIME = 30

BattleCommonGameMode.tbDelayDestroyNpcTimerList = nil
BattleCommonGameMode.bRepBaseInfoWhenSnapshot = true
BattleCommonGameMode.fnCheckAllPlayerLogout = nil
BattleCommonGameMode.tbNotDestroyDeadList = nil
--战斗开始的时间戳，不同玩法对于“战斗开始”的定义并不一致，吃鸡战斗开始是在开始跳伞的时候，mmo战斗开始是在进对局后，所以提供了Set接口供不同玩法调用
BattleCommonGameMode.nBattleStartTimestamp = 0

function BattleCommonGameMode:Init(nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)
    if(not BattleCommonGameMode.super.Init(self, nSubDungonId, pGameMode, tbGameState, tbJsonTableFile)) then
        return false
    end

    local nDungeonId = tbGameState.rGameStateBaseInfo.nDungeonId
    self.tbDelayDestroyNpcTimerList = {}
    self.tbNotDestroyDeadList = {}
    pGameMode.CollisionDamage = self.tbDungeonData.bCollisionDamage
    pGameMode.TeammateDamage = self.tbDungeonData.bTeammateDamage

    tbGameState.rGameStateBaseInfo.nQuitDungeonType = self:GetQuitDungeonDialogType()
    tbGameState.rGameStateBaseInfo.bCanQuit = true

    BattleObjectiveHelper:Init(nDungeonId, tbGameState.rCurrentObjective)
    BattleTargetTrackHelper:Init(tbGameState.rTargetTrackInfoAndIsShow)
    BattleSpecialToastHelper:Init(tbGameState.rBattleSpecialToast)
    BattleNpcChangeInfoHelper:Init(tbGameState.rBattleNpcInteraction)

    self.SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_RESET_PLAYER_POSITION, self, self.OnResetPlayerPosition)

    self:SetBattleStartTimestamp()
    return true
end

function BattleCommonGameMode:Uninit()
    for k,v in pairs(self.tbDelayDestroyNpcTimerList) do
        if v then
            DelayTimer:ClearTimer(v)
        end
    end
    self.tbDelayDestroyNpcTimerList = {}
    self.tbNotDestroyDeadList = {}
    BattleTeamSystem:Clear()
    BattleObjectiveHelper:Uninit()
    BattleTargetTrackHelper:Uninit()
    BattleSpecialToastHelper:Uninit()
    BattleNpcChangeInfoHelper:Uninit()

    BattleCommonGameMode.super.Uninit(self)
end

function BattleCommonGameMode:SnapshotGameState()
    -- 把所有角色身上的状态内属性同步一次，如身上拥有的Buff等
    -- local tbGameObjects = GameObjectSystem:GetAllGameObjects()
    -- for i,v in ipairs(tbGameObjects) do
    --     if (v.ObjectType == GameObjectTypeDef.PlayerSelf) or (v.ObjectType == GameObjectTypeDef.Npc) then
    --     logdebug("BattleCommonGameMode:SnapshotGameState", v.szName)
    --         v.BattlePropertyRepComponent:RepAllStatusProperty()
    --     end
    -- end

    log("BattleCommonGameMode:SnapshotGameState")
    local tbCurrentStep = self:GetCurrentStep()
    if(tbCurrentStep == nil) then
        logerror("BattleCommonGameMode:SnapshotGameStateToNewPlayer failed, current step is nil")
        return
    end

    local tbGameState = self.tbGameState
    if(self.bRepBaseInfoWhenSnapshot) then
        tbGameState.rGameStateBaseInfo.Rep()
    end

    -- to do string to id array by fangjing
    -- local rRes = tbGameState.rNeededResources
    -- if(rRes) then
    --     if(rRes.tbResources == nil) then
    --         rRes.tbResources = {}
    --         rRes.tbHumanNpcIds = {}
    --         rRes.tbShipNpcIds = {}
    --         rRes.tbDummyNpcIds = {}
    --     end
    --     SpawnerSystem:CollectResources(rRes.tbResources)
    --     if(#rRes.tbResources > 0) then
    --         rRes.Rep()
    --     end
    -- end

    if tbGameState.rCurrentObjective.nId ~= nil then
        tbGameState.rCurrentObjective.Rep()
    end
    local rTargetTrack = tbGameState.rTargetTrackInfoAndIsShow
    if rTargetTrack.nServerInstanceId ~= nil or
        ( rTargetTrack.nX ~= nil and rTargetTrack.nY ~= nil and rTargetTrack.nZ ~= nil )
        or rTargetTrack.bIsVisible ~= nil then
        rTargetTrack.Rep()
    end
    if tbGameState.rBattleSpecialToast.nId ~= nil then
        tbGameState.rBattleSpecialToast.Rep()
    end
    if tbGameState.rBattleNpcInteraction.nServerInstanceId ~= nil then
        tbGameState.rBattleNpcInteraction.Rep()
    end
    if tbGameState.rBotInfo.tbBotIds ~= nil then
        tbGameState.rBotInfo.Rep()
    end

    if(not tbCurrentStep:SnapshotToReplicatedProperty()) then
        local Json = require("dkjson")
        logerror("BattleCommonGameMode:SnapshotGameStateToNewPlayer failed, current step snapshot error",
            Json.encode(tbCurrentStep:GetDebugInfo()))
        return
    end
end

function BattleCommonGameMode:CreateTeam(tbGamePlayer, nGroupIndex)
    BattleTeamSystem:AddMember(tbGamePlayer, nGroupIndex)
end

function BattleCommonGameMode:CreatePlayerSelf(tbPrepareInfo, pController,
        nControllerNetGuid, nControllerUniqueId)
    if(tbPrepareInfo.tbInitItems == nil or next(tbPrepareInfo.tbInitItems) == nil) then
        -- 设置初始道具
        tbPrepareInfo:SetInitItemsByGroupId(self.tbDungeonData.nInitItem)
    end

    local tbGamePlayer = BattleCommonGameMode.super.CreatePlayerSelf(self, tbPrepareInfo, pController,
        nControllerNetGuid, nControllerUniqueId)
    if(tbGamePlayer == nil) then
        return nil
    end

    self:CreateTeam(tbGamePlayer, tbPrepareInfo.nGroupIndex)
    return tbGamePlayer
end

function BattleCommonGameMode:OnPlayerLogout(tbGamePlayer)
    BattleCommonGameMode.super.OnPlayerLogout(self, tbGamePlayer)

    local tbStep = self:GetCurrentStep()
    if(tbStep) then
        tbStep:OnPlayerLogout(tbGamePlayer)
    end

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_PLAYER_LOGOUT, tbGamePlayer)

    local nPlayerId = tbGamePlayer.nPlayerId
    local tbPrepareInfo = tbGamePlayer.tbPrepareInfo
    local nGroupIndex = tbPrepareInfo.nGroupIndex
    local nTeamId = BattleTeamSystem:FindTeamId(tbGamePlayer)

    if nTeamId and nTeamId ~= -1 and nGroupIndex ~= nTeamId then
        nGroupIndex = nTeamId
    end

    GameObjectSystem:UnbindPlayerUEController(tbGamePlayer)
    --tbGamePlayer
--[[
    BattleTeamSystem:RemoveMember(tbGamePlayer, nGroupIndex)
    GameObjectSystem:DestroyPlayerSelfInGameMode(tbGamePlayer:GetServerInstanceId())
]]
    for nIndex, tbPlayer in ipairs(self.tbPlayers) do
        if(tbPlayer == tbGamePlayer) then
            table.remove(self.tbPlayers, nIndex)
            break
        end
    end

    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_PLAYER_POST_LOGOUT, nPlayerId, nGroupIndex)

    if(self:CheckAllPlayerLogout()) then
        self:OnAllPlayerLogoutWithEvent()
    end
end

function BattleCommonGameMode:SetCheckAllPlayerLogoutFunc(fnFunc)
    self.fnCheckAllPlayerLogout = fnFunc
end

function BattleCommonGameMode:CheckAllPlayerLogout()
    if(self.fnCheckAllPlayerLogout) then
        return self.fnCheckAllPlayerLogout()
    end
    return #self.tbPlayers == 0
end

function BattleCommonGameMode:AddNotDestroyDead(nUniqueId)
    if self.tbNotDestroyDeadList[nUniqueId] == nil then
        self.tbNotDestroyDeadList[nUniqueId] = true
    end
end

function BattleCommonGameMode:DestroyDeadPawn(tbDeadObject)
    local nObjectType = tbDeadObject.ObjectType
    local nUniqueId = tbDeadObject:GetUEActorUniqueId()
    if(GameObjectSystem:FindByUniqueId(nUniqueId) == nil) then
        -- 被别的人删掉了，这里就不处理了
        return
    end

    log("BattleCommonGameMode:DestroyDeadPawn, nUniqueId =", nUniqueId)
    if(nObjectType == GameObjectTypeDef.PlayerSelf) then
        -- tbDeadObject.BattleAIComponent:SetEnable(false)
        BattleCommonGameMode.super.DestroyDeadPawn(self, tbDeadObject)
    elseif(nObjectType == GameObjectTypeDef.Npc) then
        -- tbDeadObject.BattleAIComponent:DestroyAI()
        -- 延迟销毁NPC Actor
        local fnDelayDestroyNpc = function()
            GameObjectSystem:DestroyNpcInGameMode(nUniqueId)
            log("Delay Destroy Npc, nUniqueId =", nUniqueId)
        end
        if self.tbNotDestroyDeadList[nUniqueId] == nil then
            self.tbDelayDestroyNpcTimerList[nUniqueId] = DelayTimer:DelayRun(fnDelayDestroyNpc, DELAY_DESTORY_NPC_TIME)
        end
    else
        logerror("BattleCommonGameMode:OnPawnDie failed, the object type is invalid", nUniqueId)
    end
end

-- 显示退出副本对话框
function BattleCommonGameMode:GetQuitDungeonDialogType()
    log("BattleCommonGameMode:GetQuitDungeonDialogType. Please override GetQuitDungeonDialogType function in GameMode class.")
    return nil
end

function BattleCommonGameMode:OnResetPlayerPosition(tbPlayer)
    if (not tbPlayer) or (tbPlayer.ObjectType ~= GameObjectTypeDef.PlayerSelf) then
        logerror("BattleCommonGameMode:OnResetPlayerPosition failed. Player", tbPlayer, " type failed.")
        return
    end

    local tbTransform = self:FindPlayerStartJsonData(tbPlayer).Transform
    if tbTransform == nil then
        logerror("BattleCommonGameMode:OnResetPlayerPosition failed. TeamMember transform not found.")
        return
    end

    local pLocation = Vector{X = tbTransform.X, Y = tbTransform.Y, Z = tbTransform.Z}
    if not UEActorHelper:TeleportShip(tbPlayer.pUEActor, pLocation, tbTransform.Yaw, true) then
        logwarning("BattleCommonGameMode:OnResetPlayerPosition Teleport ship failed.")
        return
    end

    D2CHelper:PlayerSetCameraYaw(tbPlayer, tbTransform.Yaw)
end

function BattleCommonGameMode:OnPawnsPaused()
    BattleCommonGameMode.super.OnPawnsPaused(self)

    local tbAllGameObjectMap = GameObjectSystem:GetAllGameObjects()
    for nInstanceId, GameObject in pairs(tbAllGameObjectMap) do
        if GameObject.ObjectType == GameObjectTypeDef.Npc or GameObject.ObjectType == GameObjectTypeDef.PlayerSelf then

            GameObject:SetPaused(true)

            local tbBuffComponentServer = GameObject.BuffComponentServer
            if tbBuffComponentServer then
                tbBuffComponentServer:RemoveAllBuff()
            end

            local AIComponent = GameObject.BattleAIComponent
            if AIComponent then
                if GameObject.ObjectType == GameObjectTypeDef.PlayerSelf then
                    AIComponent:SetEnable(false)
                else
                    AIComponent:DestroyAI()
                end
            end

        end
    end
end

function BattleCommonGameMode:SendRPCToAllTeammate(tbSender, szMessageType, tbMessageBody, bWithSelf)
    local tbRPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbObject,_ in pairs(tbObjects) do
        if CampSystem:IsFriendRelation(tbSender, tbObject)         -- 队友关系
        and (bWithSelf or (tbObject ~= tbObject)) then              -- 如果需要发给自己的话
            tbRPCNetworkProxy:SendToClient(tbObject:GetUEControllerUniqueId(), szMessageType, tbMessageBody)
        end
    end
end

function BattleCommonGameMode:SendRPCToAllEnemy(tbSender, szMessageType, tbMessageBody)
    local tbRPCNetworkProxy = NetworkManager:GetRPCNetworkProxy()
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for tbObject,_ in pairs(tbObjects) do
        if CampSystem:IsEnemyRelation(tbSender, tbObject) then     -- 敌对关系
            tbRPCNetworkProxy:SendToClient(tbObject:GetUEControllerUniqueId(), szMessageType, tbMessageBody)
        end
    end
end

function BattleCommonGameMode:ChangeToShip(tbGameObject, nShipId, tbTransform)
    local tbParams = {}
    tbParams.tbGameObject = tbGameObject
    tbParams.nShipId = nShipId
    tbParams.tbTransform = tbTransform
    SessionSystem:StartSession(SessionType.ChangeToShip, tbParams)
end

function BattleCommonGameMode:ChangeToHuman(tbGameObject, nHumanId, tbTransform)
    local tbParams = {}
    tbParams.tbGameObject = tbGameObject
    tbParams.nHumanId = nHumanId
    tbParams.tbTransform = tbTransform
    SessionSystem:StartSession(SessionType.ChangeToHuman, tbParams)
end

--强制回收副本，先杀死所有真实玩家，然后发送回收副本通知
function BattleCommonGameMode:OnForceReleaseDungeon()
end

function BattleCommonGameMode:SetBattleStartTimestamp()
    self.nBattleStartTimestamp = GlobalVariableSystem:GetLocalTime()
end

function BattleCommonGameMode:GetBattleStartTimestamp()
    return self.nBattleStartTimestamp
end

--如果玩家在载具上的话需要绑定到载具上
function BattleCommonGameMode:ReLoginPossessGamePlayer(tbPlayer)
    if tbPlayer:IsHuman() then
        local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
        if HumanMovementStateComponent and HumanMovementStateComponent:IsInVehicle() then
            local nVehicleInstanceId = HumanMovementStateComponent:GetVehicleInstanceId()
            local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
            HumanVehicleHelper.AttachToVehicle(tbPlayer, nVehicleInstanceId)
            return tbVehicle
        end
    end

    GameObjectSystem:PossessPlayerSelf(tbPlayer)
    return tbPlayer
end

return BattleCommonGameMode
