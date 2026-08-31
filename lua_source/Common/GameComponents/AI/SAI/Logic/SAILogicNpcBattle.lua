local luaclass = require("luaclass")
local SAILogicBase = require("SAILogicBase")
local SAILogicNpcBattle = luaclass("SAILogicNpcBattle", SAILogicBase)
local NpcLevelDataTable = require("NpcLevelDataTable")
local SAISystemDef = require("SAISystemDef")
local NpcTemplateDataTable  = require("NpcTemplateDataTable")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local NpcTemplateGradeDataTable = require("NpcTemplateGradeDataTable")
local NpcWeaponDataTable    = require("NpcWeaponDataTable")
local SAIPerceptionDef      = require("SAIPerceptionDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local CommonEventDef        = require("CommonEventDef")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local AIHelper = require("AIHelper")
local NetworkManager        = dynamic_require("NetworkManager")
local Proto                 = require("DungeonCommonProtoNames")
local SAIBlackboradKey      = require("SAIBlackboradKey")
local NpcAIIni              = require("NpcAIIni")
local GameObjectTypeDef     = require("GameObjectTypeDef")

local function LOG(...)
    log("CJ->SAILogicNpcBattle:", ...)
end

local nSpeedBuff = 32001
local nInvincibleBuff = 32002
local nRecoverHpBuff  = 32003

local nM2CM = 100
local nAutoAttackEnmity = NpcAIIni.nTriggerEnmity

local COLLISION_PROFILE_NAME_HUMAN  = "OnlyOverlapPawn"
local COLLISION_PROFILE_NAME_SHIP   = "OnlyOverlapVehicle"

SAILogicNpcBattle.tbPerceptionEnmity = nil
SAILogicNpcBattle.tbPerceptionAlert = nil
SAILogicNpcBattle.tbWeaponSystem = nil
SAILogicNpcBattle.tbGoalSystem = nil
SAILogicNpcBattle.tbThreatSystem = nil
SAILogicNpcBattle.tbPatrolSystem = nil
SAILogicNpcBattle.tbOverlapStartDelegate = nil
SAILogicNpcBattle.tbOverlapEndDelegate = nil
SAILogicNpcBattle.pSphereComponent = nil
SAILogicNpcBattle.tbCppDelegates = nil
SAILogicNpcBattle.nAutoAttackRange = 0
SAILogicNpcBattle.tbAlertObject = nil
SAILogicNpcBattle.tbPerceptionSight = nil

local function GetNpcTemplateConfig(self)
    local tbNpcTemplateData = self.Owner.tbNpcTemplateData
    local nAITemplateGradeId = tbNpcTemplateData.nAITemplateGradeId
    local nDungeonGrade = BattleGameModeSystem:GetGameInitData().nDungeonNpcGrade or 1
    local nAITemplateId = NpcTemplateGradeDataTable:GetTemplate(nAITemplateGradeId, nDungeonGrade)
    return NpcTemplateDataTable:GetTemplate(nAITemplateId)
end

local function GetAILevel(self)
    return GetNpcTemplateConfig(self).nNpcLevel
end

local function GetNpcAILevelConfig(self)
    return NpcLevelDataTable:GetTemplate(GetAILevel(self))
end

local function OnAllPlayerLogout(self)
    if GlobalVariableSystem:IsServerLogic() then
        local AIComponent = self.SAIComponent
        if AIComponent then
            AIComponent:StopAI()
            AIComponent:DestroyAI()
        end
    end
end

local function SendResetMessage(self, nInstanceId, nTime)
    local tbFoundObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    if tbFoundObject and not AIHelper.IsAIControlled(tbFoundObject) then
        local tbPacket = {
            nInstanceId = self.Owner.nServerInstanceId,
            nTime = nTime,
        }
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbFoundObject:GetUEControllerUniqueId(),
        Proto.d2c_NotifyNpcReset, tbPacket)
    end
end

local function OnPendingReset(self, nTime)
    self.tbPerceptionEnmity:IterateEnemys(function (tbGameObject)
        SendResetMessage(self, tbGameObject, nTime)
    end)
end

local function OnStartReset(self)
    local tbOwner = self.Owner
    LOG("OnStartReset", tbOwner.szName)
    tbOwner.NpcAIStateComponent.rNpcAttackTarget:Set(0)
    local BuffComponentServer = tbOwner.BuffComponentServer
    BuffComponentServer:AddBuffById(nSpeedBuff)
    BuffComponentServer:AddBuffById(nInvincibleBuff)
    self.tbPerceptionAlert:Reset()
    self.tbPerceptionAlert:Stop()
    if tbOwner:IsHuman() then
        self.tbWeaponSystem:DropInWeapon()
    end
    self.tbWeaponSystem:Stop()
    self.tbPerceptionEnmity:Stop()
    self.tbThreatSystem:Stop()
    self.tbPerceptionSight:Stop()
end

local function OnEndReset(self)
    local tbOwner = self.Owner
    LOG("OnEndReset", tbOwner.szName)
    local tbNpcTemplateConfig = GetNpcTemplateConfig(self)
    local pAIController = self.pAIController
    local BuffComponentServer = tbOwner.BuffComponentServer
    BuffComponentServer:RemoveBuffById(nSpeedBuff)
    BuffComponentServer:RemoveBuffById(nInvincibleBuff)
    BuffComponentServer:AddBuffById(nRecoverHpBuff)
    self.tbPerceptionAlert:Start(pAIController)
    self.tbPerceptionAlert:SetRange(tbNpcTemplateConfig.nSightDistance, tbNpcTemplateConfig.nSightAngle * 0.5)
    self.tbPerceptionEnmity:Start(pAIController)
    self.pAIController:RefreshSight()
    self.tbThreatSystem:Start()
end

local function OnOutOfActiveRange(self)
    LOG("OnOutOfActiveRange", self.Owner.szName)
    self.tbPerceptionEnmity:ClearEnmity()
    self.tbPerceptionEnmity:Stop()
end

local function OnReachedGoal(self)
    if self.bStarted then
        self.tbPatrolSystem:ToNextWayPoint()
    end
end


function SAILogicNpcBattle:OnBindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT, self, OnAllPlayerLogout)
    local pAIController = self.pAIController
    self.tbCppDelegates = {}
    self.tbCppDelegates[1] = SelfEventHelper:RegisterCppDelegate(pAIController.OnPendingReset,    self, OnPendingReset)
    self.tbCppDelegates[2] = SelfEventHelper:RegisterCppDelegate(pAIController.OnStartReset,   self, OnStartReset)
    self.tbCppDelegates[3] = SelfEventHelper:RegisterCppDelegate(pAIController.OnEndReset,     self, OnEndReset)
    self.tbCppDelegates[4] = SelfEventHelper:RegisterCppDelegate(pAIController.OnOutOfActiveRange,     self, OnOutOfActiveRange)
    self.tbCppDelegates[5] = SelfEventHelper:RegisterCppDelegate(pAIController.OnReachedGoal,     self, OnReachedGoal)
end

function SAILogicNpcBattle:OnUnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterEvent(CommonEventDef.EV_GAME_MODE_ON_ALL_PLAYER_LOGOUT)
    if self.tbCppDelegates then
        for i,v in ipairs(self.tbCppDelegates) do
            SelfEventHelper:UnregisterCppDelegate(v)
        end
    end
    self.tbCppDelegates = nil
end

function SAILogicNpcBattle:OnCreatedAI()
    local tbNpcTemplateConfig = GetNpcTemplateConfig(self)
    self.tbConfig.Patrol = self.tbConfig.Patrol or {}
    self.tbConfig.Patrol.nPathId = tbNpcTemplateConfig.nPatrolPathId
    self.Owner.pUEActor.AISettingComponent.bNpc = true
end


function SAILogicNpcBattle:UnPossessed()
    self.tbGoalSystem:ClearAlert()
    AIHelper.UnregisterFromPerceptionSystem(self.Owner.pUEActor)
    self:DestroyAttackTrigger()
end

function SAILogicNpcBattle:Possessed()
    local tbOwner = self.Owner
    local tbAILevelConfig = GetNpcAILevelConfig(self)
    local tbNpcTemplateConfig = GetNpcTemplateConfig(self)
    local pAIController = self.pAIController
    local pBlackboard = pAIController.Blackboard
    local AIComponent = tbOwner.SAIComponent

    pBlackboard:SetValueAsFloat(SAIBlackboradKey.szMaxActiveRange,    tbNpcTemplateConfig.nMaxActiveRange * nM2CM)
    pBlackboard:SetValueAsFloat(SAIBlackboradKey.szMaxOutRangeTime,   tbNpcTemplateConfig.nLeaveActiveRangeTime)
    pBlackboard:SetValueAsFloat(SAIBlackboradKey.szMinAttackDistance, tbNpcTemplateConfig.nMinAttackDistance * nM2CM)

    -- alert range and speed
    local tbPerceptionSystem = AIComponent:GetSystem(SAISystemDef.Perception)
    local tbPerceptionAlert  = tbPerceptionSystem:GetPerception(SAIPerceptionDef.Alert)
    tbPerceptionAlert:SetRange(tbNpcTemplateConfig.nSightDistance, tbNpcTemplateConfig.nSightAngle * 0.5)
    tbPerceptionAlert:SetChangeSpeed(tbNpcTemplateConfig.nAlertChangeSpeed or 1)
    self.tbPerceptionAlert = tbPerceptionAlert

    local tbPerceptionSight = tbPerceptionSystem:GetPerception(SAIPerceptionDef.Sight)
    tbPerceptionSight:Stop()
    self.tbPerceptionSight = tbPerceptionSight

    -- enmity expire time
    local tbPerceptionEnmity  = tbPerceptionSystem:GetPerception(SAIPerceptionDef.Enmity)
    tbPerceptionEnmity:SetExpirationTime(tbNpcTemplateConfig.nExpirationTime or 40)
    self.tbPerceptionEnmity = tbPerceptionEnmity

    -- weapo system
    local nHitProb  = 0
    local szAimPart = ""
    if tbOwner:IsShip() then
        nHitProb  = tbAILevelConfig.nShipHitProbability
        szAimPart = tbAILevelConfig.nAimShipPart
    else
        nHitProb  = tbAILevelConfig.nHumanHitProbability
        szAimPart = tbAILevelConfig.szAimHumanPart
    end
    local tbWeaponSystem = AIComponent:GetSystem(SAISystemDef.Weapon)
    tbWeaponSystem:SetWeaponHitProb(nHitProb)
    tbWeaponSystem:SetAimPart(szAimPart)

    if tbOwner:IsHuman() then
        tbWeaponSystem:DropInWeapon()
    end
    self.tbWeaponSystem = tbWeaponSystem

    self.tbGoalSystem = AIComponent:GetSystem(SAISystemDef.Goal)
    self.tbPatrolSystem = AIComponent:GetSystem(SAISystemDef.Patrol)
    self.tbThreatSystem = AIComponent:GetSystem(SAISystemDef.Threat)

    self.nAutoAttackRange = tbNpcTemplateConfig.nAutoAttackRange * nM2CM
    if self.nAutoAttackRange > 0 then
        self:CreateAttackTrigger(self.nAutoAttackRange)
    end

    AIHelper.RegisterWithPerceptionSystem(self.Owner.pUEActor)
end


function SAILogicNpcBattle:CanUseWeapon(nTemplateId)
    return self:GetWeaponConfig(nTemplateId) ~= nil
end

function SAILogicNpcBattle:GetWeaponConfig(nTemplateId)
    return NpcWeaponDataTable:GetWeaponConfig(GetAILevel(self), self.Owner:IsShip(), nTemplateId)
end

function SAILogicNpcBattle:GetDamageParam()
    if self.Owner:IsShip() then
        return GetNpcAILevelConfig(self).nShipDamageParam
    else
        return GetNpcAILevelConfig(self).nHumanDamageParam
    end
end

-------------------------------------------------trigger--------------------------
local function OnPlayerEnterTrigger(self, _, pOtherActor)
    local tbPlayer = self.Owner
    local tbOtherPlayer = GameObjectSystem:FindByUEActor(pOtherActor)
    if tbOtherPlayer and tbOtherPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and
    (tbPlayer:IsShip() == tbOtherPlayer:IsShip()) and
    not AIHelper.IsAIControlled(tbOtherPlayer) and
    not tbOtherPlayer:IsDead() then
        -- if has enmity do not trigger
        local tbPerceptionEnmity = self.tbPerceptionEnmity
        if tbPerceptionEnmity:IsObjectHasEnmity(tbOtherPlayer) then
            return
        end
        LOG("enter trigger " .. tbOtherPlayer.szName)
        tbPerceptionEnmity:AddEnmity(tbOtherPlayer, nAutoAttackEnmity)
        tbPerceptionEnmity:SetKeepMinEnmity(tbOtherPlayer, nAutoAttackEnmity)
    elseif tbOtherPlayer then
        LOG("something enter npc triiger", tbOtherPlayer.ObjectType, tbOtherPlayer.szName)
    end
end

local function OnPlayerLeaveTrigger(self, _, pOtherActor)
    local tbOtherPlayer = GameObjectSystem:FindByUEActor(pOtherActor)
    if tbOtherPlayer then
        self.tbPerceptionEnmity:SetKeepMinEnmity(tbOtherPlayer, 0)
    end
end


function SAILogicNpcBattle:CreateAttackTrigger(nAutoAttackRange)
    if not self.pSphereComponent then
        LOG("create trigger ", nAutoAttackRange)
        local pUEActor = self.Owner.pUEActor
        local pSphereComponent = EngineExtActorShell.CreateActorComponent(pUEActor, SphereComponent)
        self.pSphereComponent  = pSphereComponent
        self.tbOverlapStartDelegate = self.EventHelper:RegisterCppDelegate(pSphereComponent.OnComponentBeginOverlap, self, OnPlayerEnterTrigger)
        self.tbOverlapEndDelegate = self.EventHelper:RegisterCppDelegate(pSphereComponent.OnComponentEndOverlap, self, OnPlayerLeaveTrigger)
        pSphereComponent:IgnoreActorWhenMoving(pUEActor, true)
        pSphereComponent:SetCollisionProfileName(self.Owner:IsHuman() and COLLISION_PROFILE_NAME_HUMAN or COLLISION_PROFILE_NAME_SHIP)
        pSphereComponent:K2_AttachToComponent(pUEActor:K2_GetRootComponent(), ""--[[SocketName]], EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, true)
        pSphereComponent:SetSphereRadius(nAutoAttackRange, true)
    end
end

function SAILogicNpcBattle:DestroyAttackTrigger()
    local pUEActor = self.Owner.pUEActor
    local EventHelper = self.EventHelper
    if self.pSphereComponent then
        EventHelper:UnregisterCppDelegate(self.tbOverlapStartDelegate)
        EventHelper:UnregisterCppDelegate(self.tbOverlapEndDelegate)
        self.pSphereComponent:K2_DestroyComponent(pUEActor)
        self.pSphereComponent = nil
    end
end
------------------------------trigger--------------------------

---------------------------------------------------------------

function SAILogicNpcBattle:OnPerceptionEvent_OnEnmityAdd()
    local rBattleState = self.Owner.NpcAIStateComponent.rBattleState
    if not rBattleState:Get() then
        rBattleState:Set(true)
        self.tbPerceptionAlert:Stop()
        self.tbWeaponSystem:Start()
        self.tbPerceptionSight:Start(self.pAIController)
    end
end

function SAILogicNpcBattle:OnPerceptionEvent_OnEnmityClear()
    self.Owner.NpcAIStateComponent.rBattleState:Set(false)
end



function SAILogicNpcBattle:OnPerceptionEvent_OnAlertMax()
    local tbPerceptionEnmity = self.tbPerceptionEnmity
    local tbPerceptionAlert  = self.tbPerceptionAlert
    for _,v in ipairs(tbPerceptionAlert:GetEnemys()) do
        tbPerceptionEnmity:AddEnmity(v, nAutoAttackEnmity)
    end
end

function SAILogicNpcBattle:OnPerceptionEvent_OnAlertLevelChanged(nLevel)
    self.Owner.NpcAIStateComponent.rRiskAlertLevel:Set(nLevel)
end

local function RefreshAlertTarget(self)
    local tbPerceptionAlert  = self.tbPerceptionAlert
    local NpcAIStateComponent = self.Owner.NpcAIStateComponent
    local tbGameObject = tbPerceptionAlert:FindAlertTarget()
    if tbGameObject then
        self.tbAlertObject = tbGameObject
        self.tbGoalSystem:SetAlertTarget(tbGameObject)
        NpcAIStateComponent.rRiskAlertTargetInstanceId:Set(tbGameObject:GetServerInstanceId())
        LOG("alert target ", tbGameObject.szName)
    else
        self.tbGoalSystem:ClearAlert()
        self.tbAlertObject = nil
        NpcAIStateComponent.rRiskAlertTargetInstanceId:Set(0)
        LOG("alert target nil")
    end
end

function SAILogicNpcBattle:OnPerceptionEvent_OnAlertFound(tbTarget)
    if self.pAIController then
        if not self.tbAlertObject then
            RefreshAlertTarget(self)
        end
    end
end

function SAILogicNpcBattle:OnPerceptionEvent_OnAlertLost(tbTarget)
    if self.pAIController then
        if self.tbAlertObject == tbTarget then
            RefreshAlertTarget(self)
        end
    end
end

function SAILogicNpcBattle:OnPerceptionEvent_OnAlertLevelReset()
    if self.pAIController then
        local NpcAIStateComponent = self.Owner.NpcAIStateComponent
        self.tbGoalSystem:ClearAlert()
        self.tbAlertObject = nil
        NpcAIStateComponent.rRiskAlertTargetInstanceId:Set(0)
        NpcAIStateComponent.rRiskAlertLevel:Set(0)
        LOG("alert reset")
    end
end

function SAILogicNpcBattle:OnThreatEvent_OnThreatChanged(nOldTargetInstanceId, nNewTargetInstanceId)
    local NpcAIStateComponent = self.Owner.NpcAIStateComponent
    if nNewTargetInstanceId > 0 then
        local tbTargetObject = GameObjectSystem:FindByInstanceId(nNewTargetInstanceId)
        NpcAIStateComponent.rNpcAttackTarget:Set(tbTargetObject:GetServerInstanceId())
    else
        NpcAIStateComponent.rNpcAttackTarget:Set(0)
    end
end

return SAILogicNpcBattle