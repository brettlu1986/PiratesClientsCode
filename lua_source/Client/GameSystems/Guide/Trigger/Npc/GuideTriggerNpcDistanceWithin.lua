-----------------------------------------------------
--File Name    : GuideTriggerNpcDistanceWithin.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerNpcDistanceWithin = luaclass("GuideTriggerNpcDistanceWithin",GuideTrigger)


local CommonEventDef = require("CommonEventDef")
local ActorTriggerGroupHelper = require("ActorTriggerGroupHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GuideSharedInfoHelper = require("GuideSharedInfoHelper")

local UPDATE_INTERVAL = 0.3
local TRIGGER_HEIGHT = 200
local NPC_PEACE_STATE = 1

GuideTriggerNpcDistanceWithin.nNpcGroupTrigger = nil

local function DestroyPlayerSelfNpcTrigger(self)
    if self.nNpcGroupTriggerId then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nNpcGroupTriggerId)
        self.nNpcGroupTriggerId = nil
    end
end

local function CreatePlayerSelfNpcTrigger(self)
    DestroyPlayerSelfNpcTrigger(self)
    local tbSelfObj = GamePlayerSelfHelper:Get()
    local tbParam = self.tbTemplate.tbParam
    if not tbParam or #tbParam < 1 then 
        return
    end
    self.nNpcGroupTriggerId = ActorTriggerGroupHelper.CreateTriggerGroup(tbSelfObj.pUEActor, tonumber(tbParam[1]), UPDATE_INTERVAL, TRIGGER_HEIGHT)
    self:DebugLog("GuideTriggerNpcDistanceWithin:CreatePlayerSelfNpcTrigger,CreatePlayerSelfNpcTrigger,tbParam=",tbParam[1],self.nNpcGroupTriggerId)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for k, v in pairs(tbObjects) do
        local nObjType = v:GetObjectType()
        if nObjType == GameObjectTypeDef.Npc then
            self:DebugLog("GuideTriggerNpcDistanceWithin:CreatePlayerSelfNpcTrigger,ActorTriggerGroupHelper.AddTriggerInGroup",v:GetName())
            ActorTriggerGroupHelper.AddTriggerInGroup(self.nNpcGroupTriggerId, v.pUEActor)
        end
    end
end

local function OnActorCreate(self, tbGameObject)
    if tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        CreatePlayerSelfNpcTrigger(self)
    elseif tbGameObject:GetObjectType() == GameObjectTypeDef.Npc and self.nNpcGroupTriggerId then
        self:DebugLog("GuideTriggerNpcDistanceWithin:OnActorCreate,ActorTriggerGroupHelper.AddTriggerInGroup",tbGameObject:GetName())
        ActorTriggerGroupHelper.AddTriggerInGroup(self.nNpcGroupTriggerId, tbGameObject.pUEActor)
    end
end

local function OnActorDestroy(self, tbGameObject)
    if tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        DestroyPlayerSelfNpcTrigger(self)
    elseif tbGameObject:GetObjectType() == GameObjectTypeDef.Npc and self.nNpcGroupTriggerId then
        ActorTriggerGroupHelper.RemoveTriggerInGroup(self.nNpcGroupTriggerId, tbGameObject.pUEActor)
    end
end

local function IsTargetNpc(tbTargetGameObject)
    if tbTargetGameObject:GetObjectType() ~= GameObjectTypeDef.Npc then
        return false
    end
    if tbTargetGameObject:IsDead() then
        return false
    end
    local tbTemplateData = tbTargetGameObject:GetTemplateData()
    local nInitState = tbTemplateData.nInitState
    return nInitState ~= NPC_PEACE_STATE
end

local function OnEnterTriggerGroup(self, nGroupId, tbOwnerGameObject, tbTargetGameObject)
    self:DebugLog("GuideTriggerNpcDistanceWithin:OnEnterTriggerGroup,nGroupId,self.nNpcGroupTriggerId=",nGroupId,self.nNpcGroupTriggerId,tbTargetGameObject:GetName(), tbOwnerGameObject:GetName())
    if nGroupId == self.nNpcGroupTriggerId and IsTargetNpc(tbTargetGameObject) then
        self:DebugLog("GuideTriggerNpcDistanceWithin:OnEnterTriggerGroup")
        GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, tbTargetGameObject)
        self:Trigger()
    end
end

local function OnLeaveTriggerGroup(self, nGroupId, tbOwnerGameObject, tbTargetGameObject)
    if nGroupId == self.nNpcGroupTriggerId and tbTargetGameObject:GetObjectType() == GameObjectTypeDef.Npc then
        self.bIsTrigger = false
    end
end

--override
function GuideTriggerNpcDistanceWithin:Begin()
    GuideTriggerNpcDistanceWithin.super.Begin(self)
    CreatePlayerSelfNpcTrigger(self)
end

function GuideTriggerNpcDistanceWithin:End()
    GuideTriggerNpcDistanceWithin.super.End(self)
    DestroyPlayerSelfNpcTrigger(self, self.nNpcGroupTriggerId)
end

function GuideTriggerNpcDistanceWithin:BindEvent(EventHelper)
    GuideTriggerNpcDistanceWithin.super.BindEvent(self, EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, self, OnEnterTriggerGroup)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_TRIGER_GROUP, self, OnLeaveTriggerGroup)
    
end




return GuideTriggerNpcDistanceWithin
