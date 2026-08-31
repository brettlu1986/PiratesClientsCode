local luaclass = require("luaclass")
local DestructibleObjectInteractionalSystem = require("DestructibleObjectInteractionalSystem")
local DestructibleObjectInteractionalSystem_C = luaclass("DestructibleObjectInteractionalSystem_C", DestructibleObjectInteractionalSystem)
local CommonEventDef  = require("CommonEventDef")
local ClientEventDef  = require("ClientEventDef")
local GameObjectSystem= dynamic_require("GameObjectSystem")
local NetworkManager  = dynamic_require("NetworkManager")
local ProtoDC         = require("DungeonCommonProtoNames")
local GameObjectTypeDef         = require("GameObjectTypeDef")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local DestructibleObjectIni     = require("DestructibleObjectIni")
local ActorTriggerGroupHelper   = require("ActorTriggerGroupHelper")
local GameDestructibleObjectType= require("GameDestructibleObjectType")
local DestructibleObjectNewDataTable = require("DestructibleObjectNewDataTable")
local SettingSystemNew= require("SettingSystemNew")
local SettingKeyDef   = require("SettingKeyDef")
local DelayTimer = require("DelayTimer")
local HumanMovementStateType = require("HumanMovementStateType")
-- local GameplayUtilityHelper = require("GameplayUtilityHelper")

local SWITCH_STATE = {
    CLOSED = 0,
    OUT_OPEN = 1,
    IN_OPEN = 2
}

local UPDATE_INTERVAL = 0.3
local TRIGGER_HEIGHT = 200

-- local TempVector = Vector()

DestructibleObjectInteractionalSystem_C.nManualSwitchDoorGroupId = nil
DestructibleObjectInteractionalSystem_C.nAutoSwitchDoorGroupId = nil
DestructibleObjectInteractionalSystem_C.nInteractionalId  = nil
DestructibleObjectInteractionalSystem_C.pAutoOpenLocation = nil
DestructibleObjectInteractionalSystem_C.tbDelayTimer = nil

local function DestroyInteractionTriggerGroup(self)
    log("clear switch door trigger group ")
    if self.nManualSwitchDoorGroupId ~= nil then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nManualSwitchDoorGroupId)
        self.nManualSwitchDoorGroupId = nil
    end
    if self.nAutoSwitchDoorGroupId ~= nil then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nAutoSwitchDoorGroupId)
        self.nAutoSwitchDoorGroupId = nil
    end
end

local function OnPlayerSelfReady(self, tbPlayerSelf)
    if tbPlayerSelf:IsShip() then
        return
    end
    DestroyInteractionTriggerGroup(self)

    local tbInteractional = DestructibleObjectIni.tbInteractional
    self.nManualSwitchDoorGroupId = ActorTriggerGroupHelper.CreateTriggerGroup(tbPlayerSelf.pUEActor, tbInteractional.nManualSwitchDoorDistance, UPDATE_INTERVAL, TRIGGER_HEIGHT, true)
    log("destructible manual switch door trigger group id ", self.nManualSwitchDoorGroupId)
    self.nAutoSwitchDoorGroupId = ActorTriggerGroupHelper.CreateTriggerGroup(tbPlayerSelf.pUEActor, tbInteractional.nAutoSwitchDoorDistance, UPDATE_INTERVAL, TRIGGER_HEIGHT, true)
    log("destructible auto switch door trigger group id ", self.nAutoSwitchDoorGroupId)

    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.DestructibleObject)
    for v, _ in pairs(tbObjects) do
        local tbDestructibleData = DestructibleObjectNewDataTable:GetTemplate(v.nTemplateId)
        if tbDestructibleData ~= nil and tbDestructibleData.nType == GameDestructibleObjectType.Door then
            ActorTriggerGroupHelper.AddTriggerInGroup(self.nManualSwitchDoorGroupId, v.pUEActor)
            ActorTriggerGroupHelper.AddTriggerInGroup(self.nAutoSwitchDoorGroupId, v.pUEActor)
        end
    end
end

local function OnPlayerSelfUnready(self)
    DestroyInteractionTriggerGroup(self)
end

local function OnActorCreate(self, tbGameObject)
    if tbGameObject == GamePlayerSelfHelper:Get() then
        OnPlayerSelfReady(self, tbGameObject)
    elseif tbGameObject.ObjectType == GameObjectTypeDef.DestructibleObject then
        local tbDestructibleData = DestructibleObjectNewDataTable:GetTemplate(tbGameObject.nTemplateId)
        if tbDestructibleData ~= nil and tbDestructibleData.nType == GameDestructibleObjectType.Door then
            ActorTriggerGroupHelper.AddTriggerInGroup(self.nManualSwitchDoorGroupId, tbGameObject.pUEActor)
            ActorTriggerGroupHelper.AddTriggerInGroup(self.nAutoSwitchDoorGroupId, tbGameObject.pUEActor)
        end
    end
end

local function OnActorDestroy(self, tbGameObject)
    if tbGameObject == GamePlayerSelfHelper:Get() then
        OnPlayerSelfUnready(self, tbGameObject)
    elseif tbGameObject.ObjectType == GameObjectTypeDef.DestructibleObject then
        local tbDestructibleData = DestructibleObjectNewDataTable:GetTemplate(tbGameObject.nTemplateId)
        if tbDestructibleData ~= nil and tbDestructibleData.nType == GameDestructibleObjectType.Door then
            if self.nManualSwitchDoorGroupId ~= nil then
                ActorTriggerGroupHelper.RemoveTriggerInGroup(self.nManualSwitchDoorGroupId, tbGameObject.pUEActor)
            end
            if self.nAutoSwitchDoorGroupId ~= nil then
                ActorTriggerGroupHelper.RemoveTriggerInGroup(self.nAutoSwitchDoorGroupId, tbGameObject.pUEActor)
            end
            if self.nInteractionalId == tbGameObject.nServerInstanceId then
                self.nInteractionalId = nil
                self.pAutoOpenLocation = nil
                log("destructible OnActorDestroy", tbGameObject.nServerInstanceId)
                self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, false)                        
            end
        end
    end
end

local function IsSettingAutoOpenDoor(self)
    local nValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.AUTO_OPEN_DOOR)
    return nValue > 0
end

local function IsInProgressing(self)
    local bResult = false

    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsHuman() and tbPlayer.ProgressBarComponent:IsInProgress() then
        bResult = true
    end
    return bResult
end

local function CanSwitchDoor(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
    if tbPlayer:IsShip() then
        return false
    end

    local HumanMovementComponent = tbPlayer.HumanMovementStateComponent
    if HumanMovementComponent == nil then
        return false
    end

    local nMovementState = HumanMovementComponent:GetCurrentState()
    if nMovementState == HumanMovementStateType.Crawl_State
        or nMovementState == HumanMovementStateType.Dying_State
        or nMovementState == HumanMovementStateType.Vehicle then
        return false
    end 

    return true
end

local function IsMutipleAutoSwitchDoor(self)
    if self.tbDelayTimer ~= nil then
        return true
    end

    if self.pAutoOpenLocation == nil then
        return false
    end 
    local pCurLocation = GamePlayerSelfHelper:Get():GetLocation()
    local nDistance = ExtendBlueprintFunctions.GetVectorToVectorDistance(pCurLocation, self.pAutoOpenLocation)

    return nDistance <= DestructibleObjectIni.tbInteractional.nAutoSwitchDoorDistance 
end


local function IsFaceToDoor(self)
    local tbGameObject = GameObjectSystem:FindByInstanceId(self.nInteractionalId) 
    if tbGameObject == nil then
        return false
    end
    return true

    -- local tbPlayerSelf = GamePlayerSelfHelper:Get()
    -- local pRotationA = tbPlayerSelf:GetRotation()
    -- local nX, nY, nZ  = tbPlayerSelf:GetLocationXYZ()
    -- local pForward = KismetMathLibrary.GetForwardVector(pRotationA)
    -- local pEndVector = KismetMathLibrary.Multiply_VectorInt(pForward, DestructibleObjectIni.tbInteractional.nManualSwitchDoorDistance)
    -- pEndVector = KismetMathLibrary.Add_VectorVector(TempVector, pEndVector)
    --     TempVector.X = nX
    --     TempVector.Y = nY
    --     TempVector.Z = nZ
    -- local bRet, pHitResult = GameplayUtilityHelper.TraceActor(GWorld, 
    --     TempVector,
    --     pEndVector, 
    --     {tbPlayerSelf.pUEActor}, 
    --     false, 
    --     false, 
    --     false, 
    --     false, 
    --     false,
    --     true,
    --     GWorld)
    -- if not bRet then
    --     log("destructible no face to door")
    --     return false
    -- end
    -- local nUniqueId = EngineExtActorShell.GetActorUniqueId(pHitResult.Actor)
    -- return tbGameObject.nUniqueId == nUniqueId 
end

local function VerifyAutoSwitchDoor(self, pUEActor, nState)
    if nState ~= SWITCH_STATE.CLOSED then
        return false
    end

    -- 是否设置不自动开门
    if not IsSettingAutoOpenDoor(self) then
        return false
    end
    -- 读条过程中，不触发自动开门
    if IsInProgressing(self) then
        return false
    end
    -- 如果之前已经触发过自动开门，玩家关上门后还仍然处于自动开门触发范围内，则不会二次触发
    if IsMutipleAutoSwitchDoor(self) then
        return false
    end
       
    -- face to door
    if not IsFaceToDoor(self) then
        return false
    end

    self:RequestSwitchDoor(true)
    return true
end

local function DestroyDelayTimer(self)
    if self.tbDelayTimer ~= nil then  
        DelayTimer:ClearTimer(self.tbDelayTimer)
        self.tbDelayTimer = nil 
    end 
end

local function OnEnterInteractionalTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if nGroupId == self.nManualSwitchDoorGroupId then
        log("destructible OnEnterManualSwitchDoorTrigger", nGroupId, tbTargetObject.nServerInstanceId)
        self.nInteractionalId = tbTargetObject.nServerInstanceId
        if CanSwitchDoor(self) then
            local nState = enumtoint(tbTargetObject.pUEActor:GetCurState())
            self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, true, nState == SWITCH_STATE.CLOSED)
        end
    elseif nGroupId == self.nAutoSwitchDoorGroupId then
        log("destructible OnEnterAutoSwitchDoorTrigger", nGroupId, tbTargetObject.nServerInstanceId)
        self.nInteractionalId = tbTargetObject.nServerInstanceId

        if CanSwitchDoor(self) then
            local nState = enumtoint(tbTargetObject.pUEActor:GetCurState())
            if not VerifyAutoSwitchDoor(self, tbOwnerObject.pUEActor, nState) then
                self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, true, nState == SWITCH_STATE.CLOSED)
            end
        end
    end
end

local function OnLeaveInteractionalTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if nGroupId == self.nManualSwitchDoorGroupId then
        log("destructible OnLeaveManualSwitchDoorTrigger", nGroupId)
        self.nInteractionalId = nil
        self.pAutoOpenLocation = nil
        self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, false)        
    elseif nGroupId == self.nAutoSwitchDoorDistance then
        log("destructible OnLeaveAutoSwitchDoorTrigger", nGroupId)
        self.nInteractionalId = nil
    end
end

local function OnHumanMovmentStateChanged(self, tbCharacter, nOldState, nNewState)
    if self.nInteractionalId == nil then
        return
    end
    if not tbCharacter or tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local tbGameObject = GameObjectSystem:FindByInstanceId(self.nInteractionalId) 
    if tbGameObject == nil then
        return
    end

    if (nOldState == HumanMovementStateType.Crawl_State
        or nOldState == HumanMovementStateType.Dying_State
        or nOldState == HumanMovementStateType.Vehicle) 
        and (nNewState ~= HumanMovementStateType.Crawl_State
        or nNewState ~= HumanMovementStateType.Dying_State
        or nNewState ~= HumanMovementStateType.Vehicle) then
        
        local nState = enumtoint(tbGameObject.pUEActor:GetCurState())
        self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, true, nState == SWITCH_STATE.CLOSED)
    elseif (nNewState == HumanMovementStateType.Crawl_State
        or nNewState == HumanMovementStateType.Dying_State
        or nNewState == HumanMovementStateType.Vehicle) then
        
        self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, false)
    end
end

local function OnDoorSwitched(self, tbGameObject, nCauserId)
    if self.nInteractionalId == nil or self.nInteractionalId ~= tbGameObject.nServerInstanceId then
        log("destructible OnDoorSwitched not interactional ", tbGameObject and tbGameObject.nServerInstanceId)
        return
    end

    DestroyDelayTimer(self)
    local fnComplete = function()
        DestroyDelayTimer(self)
    end
    self.tbDelayTimer = DelayTimer:DelayRun(fnComplete, 1)
    log("destructible OnDoorSwitched", self.nInteractionalId)
    local nState = enumtoint(tbGameObject.pUEActor:GetCurState())
    self.EventHelper:FireEvent(ClientEventDef.EV_SHOW_DOOR_SWITCH, true, nState == SWITCH_STATE.CLOSED, nCauserId)
end

function DestructibleObjectInteractionalSystem_C:Init()
    DestructibleObjectInteractionalSystem_C.super.Init(self)

    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
    
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, self, OnEnterInteractionalTrigger)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_TRIGER_GROUP, self, OnLeaveInteractionalTrigger)
    EventHelper:RegisterEvent(CommonEventDef.EV_DOOR_SWITCHED, self, OnDoorSwitched)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovmentStateChanged)

    return true
end

function DestructibleObjectInteractionalSystem_C:Uninit()
    DestroyDelayTimer(self)
    self.nManualSwitchDoorGroupId = nil
    self.nAutoSwitchDoorGroupId = nil
    DestructibleObjectInteractionalSystem_C.super.Uninit(self)
end

function DestructibleObjectInteractionalSystem_C:RequestSwitchDoor(bAutoRequest)
    local tbGameObject = GameObjectSystem:FindByInstanceId(self.nInteractionalId) 
    if tbGameObject == nil then
        logerror("DestructibleObjectInteractionalSystem_C:RequestSwitchDoor ", self.nInteractionalId)
        return
    end
    local pUEActor = tbGameObject.pUEActor
    if not isvalidhandle(pUEActor) then
        logerror("DestructibleObjectInteractionalSystem_C:RequestSwitchDoor: uninvalidhandle")
        return
    end
    local nCurState = enumtoint(pUEActor:GetCurState())
    local nState
    if nCurState == SWITCH_STATE.CLOSED then
        local pDoorTransform = pUEActor:GetTransform()
        local pSelfLocation  = GamePlayerSelfHelper:Get():GetLocation()
        local pOutLocation   = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.OutPoint)
        local nDistanceOut   = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pOutLocation)
        local pInLocation    = KismetMathLibrary.TransformLocation(pDoorTransform, pUEActor.InPoint)
        local nDistanceIn    = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pInLocation)
        if nDistanceOut < nDistanceIn then
            nState = SWITCH_STATE.OUT_OPEN
        else
            nState = SWITCH_STATE.IN_OPEN
        end

        if bAutoRequest then
            self.pAutoOpenLocation = pSelfLocation
        else
            self.pAutoOpenLocation = nil
        end
    else
        nState = SWITCH_STATE.CLOSED
    end

    log("[door] destructible request switch door ", nState)
    local c2d_SwitchDoor =
    {
        nInstanceId = tbGameObject.nServerInstanceId,
        nState = nState
    }

    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_SwitchDoor, c2d_SwitchDoor)
        
end

function DestructibleObjectInteractionalSystem_C:GetInteractionObjectState()
    if self.nInteractionalId == nil then
        return false
    end 
    local tbGameObject = GameObjectSystem:FindByInstanceId(self.nInteractionalId)
    if tbGameObject == nil or tbGameObject.pUEActor == nil then
        return false
    end
    local nX1, nY1  = GamePlayerSelfHelper:Get():GetLocationXYZ()
    local nX2, nY2  = tbGameObject:GetLocationXYZ()
    local nDisSqure = DestructibleObjectIni.tbInteractional.nManualSwitchDoorDistance
    nDisSqure = nDisSqure * nDisSqure
    if (nX1 - nX2) * (nX1 - nX2) + (nY1 - nY2) * (nY1 - nY2) <= nDisSqure then
        local nCurState = enumtoint(tbGameObject.pUEActor:GetCurState())
        return true, nCurState == SWITCH_STATE.CLOSED
    end

    return false
end

return DestructibleObjectInteractionalSystem_C()