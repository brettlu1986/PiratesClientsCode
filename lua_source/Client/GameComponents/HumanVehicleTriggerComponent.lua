local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local HumanVehicleTriggerComponent = luaclass("HumanVehicleTriggerComponent", GameComponentBaseClass)
local SelfEventHelperClass = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local ActorTriggerGroupHelper = require("ActorTriggerGroupHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local ClientEventDef = require("ClientEventDef")

local TRIGGER_RADIUS = 150
local UPDATE_INTERVAL= 0.3
local TRIGGER_TYPE = {
    NONE = 0,
    LEFT = 1,
    RIGHT= 2 
}

HumanVehicleTriggerComponent.EventHelper = nil
HumanVehicleTriggerComponent.nTriggerGroupId = nil

local function AddTriggerInGroup(self, pUEActor)
    if self.nTriggerGroupId ~= nil and pUEActor ~= nil then
        ActorTriggerGroupHelper.AddTriggerInGroup(self.nTriggerGroupId, pUEActor)    
    end    
end

local function RemoveTriggerInGroup(self, pUEActor)
    if self.nTriggerGroupId ~= nil and pUEActor ~= nil then
        ActorTriggerGroupHelper.RemoveTriggerInGroup(self.nTriggerGroupId, pUEActor)
    end
end

local function DestroyTriggerGroup(self)
    log("clear vehicle trigger group ", self.nTriggerGroupId)
    if self.nTriggerGroupId ~= nil then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nTriggerGroupId)
        self.nTriggerGroupId = nil
    end
end

local function CreateTriggerGroup(self)
    DestroyTriggerGroup(self)

    self.nTriggerGroupId = ActorTriggerGroupHelper.CreateTriggerGroup(self.Owner.pUEActor, TRIGGER_RADIUS, UPDATE_INTERVAL)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for k, v in pairs(tbObjects) do
        if GameObjectSystem:IsVehicle(v) then
            AddTriggerInGroup(self, v.pUEActor)
        end
    end
end

local function OnActorCreate(self, tbGameObject)
    if GameObjectSystem:IsVehicle(tbGameObject) then
        AddTriggerInGroup(self, tbGameObject.pUEActor)
    end
end

local function OnActorDestroy(self, tbGameObject)
    if GameObjectSystem:IsVehicle(tbGameObject) then
        RemoveTriggerInGroup(self, tbGameObject.pUEActor)
    end
end

local function GetTriggerType(self, tbVehicleObject)
    local pUEActor = tbVehicleObject.pUEActor
    local pVehicleTransform = pUEActor:GetTransform()
    local pSelfLocation  = self.Owner:GetLocation()
    local pLeftLocation  = KismetMathLibrary.TransformLocation(pVehicleTransform, pUEActor.LeftPoint)
    local nDistanceLeft  = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pLeftLocation)
    local pRightLocation = KismetMathLibrary.TransformLocation(pVehicleTransform, pUEActor.RightPoint)
    local nDistanceRight = ExtendBlueprintFunctions.GetVectorToVectorDistance(pSelfLocation, pRightLocation)
    
    if nDistanceLeft < nDistanceRight then
        return TRIGGER_TYPE.LEFT
    else
        return TRIGGER_TYPE.RIGHT
    end
end

local function OnEnterTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if self.nTriggerGroupId == nGroupId then
        if tbTargetObject.pUEActor ~= nil then        
            local nTriggerType = GetTriggerType(self, tbTargetObject)
            -- log("[Vehicle log] VehicleMovementComponent_C: OnSelfEnterVehicleArea", nTriggerType)
            self.EventHelper:FireEvent(ClientEventDef.EV_IN_VEHICLE_AREA, true, tbTargetObject, nTriggerType)
        end
    end
end

local function OnLeaveTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if self.nTriggerGroupId == nGroupId then
        if tbTargetObject.pUEActor ~= nil then        
            local nTriggerType = GetTriggerType(self, tbTargetObject)
            log("[Vehicle log] VehicleMovementComponent_C: OnSelfLeaveVehicleArea", nTriggerType)
            self.EventHelper:FireEvent(ClientEventDef.EV_IN_VEHICLE_AREA, false, tbTargetObject, nTriggerType)
        end
    end
end

local function OnActorDead(self, tbVehicleObject, nDriverId)
    if GameObjectSystem:IsVehicle(tbVehicleObject) then
        RemoveTriggerInGroup(self, tbVehicleObject.pUEActor)
    end
end

local function Init(self, pUEActor)
    local EventHelper = SelfEventHelperClass()
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, self, OnEnterTrigger)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_TRIGER_GROUP, self, OnLeaveTrigger)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_DEAD, self, OnActorDead)
    self.EventHelper = EventHelper

    CreateTriggerGroup(self)
end

local function Uninit(self)
    DestroyTriggerGroup(self)
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end
end

function HumanVehicleTriggerComponent:OnCreate(Owner, tbParams)

    return HumanVehicleTriggerComponent.super.OnCreate(self, Owner, tbParams)
end

function HumanVehicleTriggerComponent:OnDestroy()
    HumanVehicleTriggerComponent.super.OnDestroy(self)
end

function HumanVehicleTriggerComponent:OnActorPreCreated(pUEActor)
    HumanVehicleTriggerComponent.super.OnActorCreated(self, pUEActor)

    log("HumanVehicleTriggerComponent:OnActorPreCreated", pUEActor)
    if(pUEActor) then
        Init(self, pUEActor)
    end
end

function HumanVehicleTriggerComponent:OnActorDestroyed(pUEActor)
    log("HumanVehicleTriggerComponent:OnActorDestroyed")
    Uninit(self)
    HumanVehicleTriggerComponent.super.OnActorDestroyed(self, pUEActor)
end

return HumanVehicleTriggerComponent
