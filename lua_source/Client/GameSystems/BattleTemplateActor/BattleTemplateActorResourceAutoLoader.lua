local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local CommonEventDef = require("CommonEventDef")
local BattleItemDataTable = require("BattleItemDataTable")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local BattleTemplateActorResourceCollector = require("BattleTemplateActorResourceCollector")

local HUMAN_TRIGGER_RADIUS = 1500
local SHIP_TRIGGER_RADIUS  = 5000
local UPDATE_INTERVAL = 1

local BattleTemplateActorResourceAutoLoader = {}

BattleTemplateActorResourceAutoLoader.nTriggerGroupId  = nil
BattleTemplateActorResourceAutoLoader.tbTriggerDatas   = nil
BattleTemplateActorResourceAutoLoader.tbLoaders        = nil
BattleTemplateActorResourceAutoLoader.tbCameraFollower = nil

local function OnEnterLoaderTrigger(self, nGroupId, tbOwnerGameObject, tbTargetGameObject)
    if self.nTriggerGroupId ~= nGroupId then
        return
    end

    local tbData = self.tbTriggerDatas[tbTargetGameObject.nServerInstanceId]
    if tbData == nil then
        logerror("OnEnterLoaderTrigger not find target : ", tbTargetGameObject.nServerInstanceId)
        return
    end
    local pUEActor = tbData.pUEActor

    local tbPaths = {}
    BattleTemplateActorResourceCollector.CollectAll(self.tbCameraFollower, tbData.nTemplateId, tbPaths)
    if #tbPaths > 0 then
        pUEActor:AsyncLoadRelatedObjects(tbPaths)
    end
end

-- local function OnLeaveLoaderArea(self, nGroupId, tbOwnerGameObject, tbTargetGameObject)
--     if self.nTriggerGroupId ~= nGroupId then
--         return
--     end
    
--     local tbData = self.tbTriggerDatas[tbTargetGameObject.nServerInstanceId]
--     if tbData == nil then
--         logerror("OnLeaveLoaderTrigger not find target : ", tbTargetGameObject.nServerInstanceId)
--         return
--     end

--     local pUEActor = tbData.pUEActor
--     pUEActor:ClearRelatedObjects()
-- end

local function CreateTriggerGroup(self)
    if self.tbCameraFollower ~= nil and self.tbCameraFollower.pUEActor ~= nil then
        local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
        self.nTriggerGroupId = AreaTriggerManager:CreateTriggerGroup(self.tbCameraFollower.pUEActor, self.tbCameraFollower:IsHuman() and HUMAN_TRIGGER_RADIUS or SHIP_TRIGGER_RADIUS, UPDATE_INTERVAL)
        log("create template actor trigger group ", self.nTriggerGroupId)
    else
        logerror("BattleTemplateActorResourceAutoLoader CreateTriggerGroup Error: ", self.tbCameraFollower)
    end
end

local function DestroyTriggerGroup(self)
    if self.nTriggerGroupId ~= nil then
        log("destroy template actor trigger group ", self.nTriggerGroupId)
        local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
        AreaTriggerManager:DestroyTriggerGroup(self.nTriggerGroupId)
        self.nTriggerGroupId = nil
    end
end

local function OnActorCreate(self, tbGameObject)
    if tbGameObject == self.tbCameraFollower then
        DestroyTriggerGroup(self)
        CreateTriggerGroup(self)
        log("on camera follower create ", self.nTriggerGroupId)
        for k, v in pairs(self.tbLoaders) do
            self:OnTemplateActorCreated(v)
        end
    end
end

local function OnActorDestroy(self, tbGameObject)
    if tbGameObject == self.tbCameraFollower then
        log("on camera follower destroy ", self.nTriggerGroupId)
        DestroyTriggerGroup(self)
        self.tbTriggerDatas = {}
    end
end

local function OnWatchTargetChanged(self, tbWatchedTarget)
    log("OnWatchTargetChanged start ", self.tbCameraFollower.szName)
    OnActorDestroy(self, self.tbCameraFollower)
    self.tbCameraFollower = tbWatchedTarget
    log("OnWatchTargetChanged end ", self.tbCameraFollower.szName)
    OnActorCreate(self, self.tbCameraFollower)
end

function BattleTemplateActorResourceAutoLoader:OnTemplateActorCreated(tbGameObject)
    local nServerInstanceId = tbGameObject.nServerInstanceId
    if self.nTriggerGroupId == nil then
        self.tbLoaders[nServerInstanceId] = tbGameObject
        log("BattleTemplateActorResourceAutoLoader:OnTemplateActorCreated but trigger group is nil")
        return
    end
    local tbItemResInfo = tbGameObject.tbCustomProtoData and tbGameObject.tbCustomProtoData.scene_item_info
    if tbItemResInfo == nil then
        return
    end
    local tbItemResData = BattleItemDataTable:GetResTemplate(tbItemResInfo.template_id)
    if tbItemResData == nil then
        return
    end

    local pUEActor = tbGameObject.pUEActor
    local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
    if AreaTriggerManager:AddTriggerInGroup(self.nTriggerGroupId, tbGameObject.pUEActor) then
        self.tbLoaders[nServerInstanceId] = tbGameObject
        self.tbTriggerDatas[nServerInstanceId] = {pUEActor = pUEActor, nTemplateId = tbGameObject.nTemplateId}      
    else
        logwarning("BattleTemplateActorResourceAutoLoader:OnTemplateActorCreated add trigger in group failed ", self.nTriggerGroupId)
    end
end

function BattleTemplateActorResourceAutoLoader:OnTemplateActorDestroyed(tbGameObject)
    local nServerInstanceId = tbGameObject.nServerInstanceId
    if self.nTriggerGroupId == nil then
        self.tbLoaders[nServerInstanceId] = nil
        log("BattleTemplateActorResourceAutoLoader:OnTemplateActorDestroyed but trigger group is nil")
        return
    end

    local pUEActor = tbGameObject.pUEActor
    for k, v in pairs(self.tbTriggerDatas) do
        if v.pUEActor == pUEActor then
            local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorTriggerGroupManager()
            AreaTriggerManager:RemoveTriggerInGroup(self.nTriggerGroupId, pUEActor)
            pUEActor:ClearRelatedObjects()
            self.tbTriggerDatas[nServerInstanceId] = nil
            self.tbLoaders[nServerInstanceId] = nil
            break
        end
    end
end

function BattleTemplateActorResourceAutoLoader:Init()

    self.tbTriggerDatas = {}
    self.tbLoaders = {}
    self.tbCameraFollower = GamePlayerSelfHelper:Get()

    local EventHelper = SelfEventHelper()
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, self, OnEnterLoaderTrigger)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_AREA_LEAVE, self, OnLeaveLoaderArea)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_POST_ACTOR_CREATE, self, OnActorCreate)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_PRE_UNBIND_UEACTOR_DESTROY, self, OnActorDestroy)
    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnWatchTargetChanged)

    self.EventHelper = EventHelper

    return true
end

function BattleTemplateActorResourceAutoLoader:Uninit()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.tbLoaders = nil

    OnActorDestroy(self, self.tbCameraFollower)
    self.tbCameraFollower = nil
    self.tbTriggerDatas = nil
end

return BattleTemplateActorResourceAutoLoader