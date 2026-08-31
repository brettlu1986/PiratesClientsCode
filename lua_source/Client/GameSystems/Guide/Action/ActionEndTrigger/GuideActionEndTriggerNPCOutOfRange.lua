-----------------------------------------------------
--File Name    : GuideActionEndTriggerNPCOutOfRange.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerNPCOutOfRange        = luaclass("GuideActionEndTriggerNPCOutOfRange", GuideActionEndTriggerBase)

local CommonEventDef            = require("CommonEventDef")
local ActorTriggerGroupHelper   = require("ActorTriggerGroupHelper")
local GamePlayerSelfHelper      = require("GamePlayerSelfHelper")
local GameObjectSystem          = dynamic_require("GameObjectSystem")
local GameObjectTypeDef         = require("GameObjectTypeDef")
-----------------------------------------------------
local TRIGGER_HEIGHT         = 200
local UPDATE_INTERVAL        = 1

GuideActionEndTriggerNPCOutOfRange.nCheckNpcDistanceTriggerGroupId = nil
-----------------------------------------------------

local function AddNpcTriggerInGroup(self, tbGameObject)
    if GameObjectTypeDef.Npc == tbGameObject.ObjectType then
        self:DebugLog("[NpcForceEndStep] AddNpcTriggerInGroup ".. tbGameObject:GetServerInstanceId()..", ".. tbGameObject.szName)
        ActorTriggerGroupHelper.AddTriggerInGroup(self.nCheckNpcDistanceTriggerGroupId, tbGameObject.pUEActor)
    end
end

local function OnActorCreate(self, tbGameObject)
    AddNpcTriggerInGroup(self, tbGameObject)
end

local function OnActorDestroy(self, tbGameObject)
    if self.nCheckNpcDistanceTriggerGroupId ~= nil and GameObjectTypeDef.Npc == tbGameObject.ObjectType then
        ActorTriggerGroupHelper.RemoveTriggerInGroup(self.nCheckNpcDistanceTriggerGroupId, tbGameObject.pUEActor)
        self:DebugLog("[NpcForceEndStep] OnActorDestroy RemoveTriggerInGroup")
    end
end

local function DestroyCheckNpcDistanceTriggerGroup(self)
    ActorTriggerGroupHelper.DestroyTriggerGroup(self.nCheckNpcDistanceTriggerGroupId)
    self.nCheckNpcDistanceTriggerGroupId = nil
    self:DebugLog("[NpcForceEndStep] DestroyCheckNpcDistanceTriggerGroup")
end

local function OnLeaveInteractionalTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if nGroupId == self.nCheckNpcDistanceTriggerGroupId
        and tbOwnerObject == GamePlayerSelfHelper:Get()
        and GameObjectTypeDef.Npc == tbTargetObject.ObjectType
        and tbTargetObject:IsAlive() then
            -- npc都离得很远，所以不用判断是之前触发的npc超出了距离
            DestroyCheckNpcDistanceTriggerGroup(self)
            self:DebugLog("[NpcForceEndStep] OnLeaveInteractionalTrigger".. tbTargetObject:GetServerInstanceId())
            self:Triggered()
    end
end

local function BeginCheckNpcDistance(self, nDistance)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    self.nCheckNpcDistanceTriggerGroupId = ActorTriggerGroupHelper.CreateTriggerGroup(PlayerSelf.pUEActor, nDistance, UPDATE_INTERVAL, TRIGGER_HEIGHT)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for _, v in pairs(tbObjects) do
        AddNpcTriggerInGroup(self, v)
    end
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_TRIGER_GROUP, self, OnLeaveInteractionalTrigger)
end

function GuideActionEndTriggerNPCOutOfRange:BindEvent(tbParam)
    GuideActionEndTriggerNPCOutOfRange.super.BindEvent(self, tbParam)
    local nDistance = tonumber(tbParam[1])
    self:DebugLog("[NpcForceEndStep] npcoutofrange ".. nDistance)
    BeginCheckNpcDistance(self, nDistance)
end

return GuideActionEndTriggerNPCOutOfRange
