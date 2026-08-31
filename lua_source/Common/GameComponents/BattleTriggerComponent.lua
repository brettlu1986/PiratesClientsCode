local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattleTriggerComponent = luaclass("BattleTriggerComponent", GameComponentBaseClass)

local SelfEventHelperClass = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local ProtoDC = require("DungeonCommonProtoNames")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

BattleTriggerComponent.EventHelper = nil
BattleTriggerComponent.fnActorEnterFunc = nil
BattleTriggerComponent.fnActorLeaveFunc = nil
BattleTriggerComponent.bEnabledCollision = true

local function OnActorEnter(self, pUEActor, nTriggerId)
    local fnActorEnterFunc = self.fnActorEnterFunc
    if (fnActorEnterFunc ~= nil) then
        fnActorEnterFunc(self.Owner, pUEActor, nTriggerId)
    end
    if GlobalVariableSystem:IsClient() then
        if GlobalVariableSystem.bPrintSceneItem then
            local pLocation = self.Owner:GetLocation()
            log(string.format("Trigger OnActorEnter InstanceId = %d, posX = %f, posY = %f", self.Owner.nServerInstanceId, pLocation.X, pLocation.Y))
        end
    end
    local tbGameObject = GameObjectSystem:FindByUniqueId(EngineExtActorShell.GetActorUniqueId(pUEActor))
    if(tbGameObject and tbGameObject.pUEActor) then
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_TRIGGER_ENTER, self.Owner, tbGameObject) 
    end
end

local function OnActorLeave(self, pUEActor, nTriggerId)
    local fnActorLeaveFunc = self.fnActorLeaveFunc
    if (fnActorLeaveFunc ~= nil) then
        fnActorLeaveFunc(self.Owner, pUEActor, nTriggerId)
    end

    if GlobalVariableSystem:IsClient() then
        if GlobalVariableSystem.bPrintSceneItem then
            log("Trigger OnActorLeave ", self.Owner.nServerInstanceId)
        end
    end

    local tbGameObject = GameObjectSystem:FindByUniqueId(EngineExtActorShell.GetActorUniqueId(pUEActor))
    if(tbGameObject and tbGameObject.pUEActor) then
        EventManager:OnFireEvent(CommonEventDef.EV_GAME_TRIGGER_LEAVE, self.Owner, tbGameObject)
    end
end

local function Init(self, pUEActor)
    local EventHelper = SelfEventHelperClass()
    EventHelper:RegisterCppDelegate(pUEActor.OnActorEnter, self, OnActorEnter)
    EventHelper:RegisterCppDelegate(pUEActor.OnActorLeave, self, OnActorLeave)
    self.EventHelper = EventHelper
    self.fnActorEnterFunc = nil
    self.fnActorLeaveFunc = nil

    pUEActor:SetCollisionEnabled(self.bEnabledCollision)
end

function BattleTriggerComponent:OnCreate(Owner, tbParams)
    BattleTriggerComponent.super.OnCreate(self, Owner, tbParams)
    local tbCollisionType = ProtoDC.TriggerActorInitData_ECollisionType
    if GlobalVariableSystem:IsClient() then
        self.bEnabledCollision = tbParams.nCollisionType == tbCollisionType.ONLY_CLIENT or tbParams.nCollisionType == tbCollisionType.ALL
    else
        self.bEnabledCollision = tbParams.nCollisionType == tbCollisionType.ONLY_SERVER or tbParams.nCollisionType == tbCollisionType.ALL
    end
end

function BattleTriggerComponent:OnActorCreated(pUEActor)
    BattleTriggerComponent.super.OnActorCreated(self, pUEActor)

    if(pUEActor) then
        Init(self, pUEActor)
        -- log("BattleTriggerComponent:OnActorCreated", self.Owner.nServerInstanceId)
    else
        logerror("BattleTriggerComponent:OnActorCreated no PUEActor", self.Owner.nServerInstanceId)
    end
end

function BattleTriggerComponent:OnActorDestroyed(pUEActor)
    if self.EventHelper ~= nil then
        self.EventHelper:UnregisterAll()
    else
        logerror("BattleTriggerComponent:OnActorDestroyed no init", self.Owner.nServerInstanceId)
    end
    BattleTriggerComponent.super.OnActorDestroyed(self, pUEActor)
end

function BattleTriggerComponent:SetActorEnterCallback(fnCallback)
    self.fnActorEnterFunc = fnCallback
end

function BattleTriggerComponent:SetActorLeaveCallback(fnCallback)
    self.fnActorLeaveFunc = fnCallback
end

function BattleTriggerComponent:EnableTriggerShot(bEnable)
    if(self.Owner.pUEActor) then
        self.Owner.pUEActor:EnableTriggerShot(bEnable)
    end
end

return BattleTriggerComponent
