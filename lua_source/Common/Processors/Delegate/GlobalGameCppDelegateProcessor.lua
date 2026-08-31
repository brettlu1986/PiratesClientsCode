local luaclass = require("luaclass")
local CppDelegateProcesserBaseClass = require("CPPDelegateProcessorBase")
local GlobalGameCppDelegateProcessor = luaclass("GlobalGameCppDelegateProcessor", CppDelegateProcesserBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local function OnPawnEnterArea(nInstanceId, nAreaId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    if(tbGameObject == nil) then
        logwarning("OnPawnEnterArea failed, gameobject is invalid " .. nInstanceId)
        return
    end
    log("OnPawnEnterArea", nInstanceId, nAreaId)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_AREA_ENTER, tbGameObject, nAreaId)
end

local function OnPawnLeaveArea(nInstanceId, nAreaId)
    local tbGameObject = GameObjectSystem:FindByInstanceId(nInstanceId)
    if(tbGameObject == nil) then
        logwarning("OnPawnLeaveArea failed, gameobject is invalid " .. nInstanceId)
        return
    end
    log("OnPawnLeaveArea", nInstanceId, nAreaId)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_AREA_LEAVE, tbGameObject, nAreaId)
end

local function OnPawnEnterTriggerGroup(nGroupId, nOwnerUniqueId, nTargetUniqueId)
    local tbOwnerGameObject = GameObjectSystem:FindByUniqueId(nOwnerUniqueId)
    if(tbOwnerGameObject == nil) then
        logwarning("OnPawnEnterTriggerGroup failed, owner gameobject is invalid " .. nOwnerUniqueId)
        return
    end
    local tbTargetGameObject = GameObjectSystem:FindByUniqueId(nTargetUniqueId)
    if(tbTargetGameObject == nil) then
        log("OnPawnEnterTriggerGroup failed, target gameobject is invalid " .. nTargetUniqueId)
        return
    end    
    -- log("ActorTriggerGroupHelper OnPawnEnterTriggerGroup", nGroupId, nOwnerUniqueId, nTargetUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, nGroupId, tbOwnerGameObject, tbTargetGameObject)
end

local function OnPawnLeaveTriggerGroup(nGroupId, nOwnerUniqueId, nTargetUniqueId)
    local tbOwnerGameObject = GameObjectSystem:FindByUniqueId(nOwnerUniqueId)
    if(tbOwnerGameObject == nil) then
        log("OnPawnLeaveTriggerGroup failed, owner gameobject is invalid " .. nOwnerUniqueId)
        return
    end
    local tbTargetGameObject = GameObjectSystem:FindByUniqueId(nTargetUniqueId)
    if(tbTargetGameObject == nil) then
        log("OnPawnLeaveTriggerGroup failed, target gameobject is invalid " .. nTargetUniqueId)
        return
    end    
    -- log("ActorTriggerGroupHelper OnPawnLeaveTriggerGroup", nGroupId, nOwnerUniqueId, nTargetUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_TRIGER_GROUP, nGroupId, tbOwnerGameObject, tbTargetGameObject)
end

-- local function OnActorEnterVolume(nUniqueId, tbVolumeIds)
--     local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
--     if(tbGameObject == nil) then
--         logwarning("OnActorEnterVolume failed, gameobject is invalid " .. nUniqueId)
--         return
--     end
--     log("OnActorEnterVolume", nUniqueId, table.concat( tbVolumeIds, ", "))
--     EventManager:OnFireEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_VOLUME, tbGameObject, tbVolumeIds)
-- end


-- local function OnActorLeaveVolume(nUniqueId, tbVolumeIds)
--     local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
--     if(tbGameObject == nil) then
--         logwarning("OnActorLeaveVolume failed, gameobject is invalid " .. nUniqueId)
--         return
--     end

--     log("OnActorLeaveVolume", nUniqueId, table.concat( tbVolumeIds, ", "))
--     EventManager:OnFireEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_VOLUME, tbGameObject, tbVolumeIds)
-- end

local function OnGridTypeChanged(nUniqueId, RegionType, nRegionId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if(tbGameObject == nil) then
        --logwarning("OnGridTypeChanged failed, gameobject is invalid " .. nUniqueId)
        return
    end

    EventManager:OnFireEvent(CommonEventDef.EV_GRID_TYPE_CHANGED, tbGameObject, RegionType, nRegionId)
end

local function OnSpawnSmoke(pLocation, nRadius, nExistTime)
    EventManager:OnFireEvent(CommonEventDef.EV_SPAWN_SMOKE, pLocation, nRadius, nExistTime)
end

function GlobalGameCppDelegateProcessor:Init()
    GlobalGameCppDelegateProcessor.super.Init(self)

    -- Register Gameplay Delegate
    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameMisc
    self:Register(DelegateMgr.OnActorEnterArea  , OnPawnEnterArea)
    self:Register(DelegateMgr.OnActorLeaveArea  , OnPawnLeaveArea)

    self:Register(DelegateMgr.OnActorEnterTriggerGroup  , OnPawnEnterTriggerGroup)
    self:Register(DelegateMgr.OnActorLeaveTriggerGroup  , OnPawnLeaveTriggerGroup)

    -- self:Register(DelegateMgr.OnActorEnterVolume  , OnActorEnterVolume)
    -- self:Register(DelegateMgr.OnActorLeaveVolume  , OnActorLeaveVolume)

    self:Register(DelegateMgr.OnActorGridTypeChanged  , OnGridTypeChanged)
    self:Register(DelegateMgr.OnSpawnSmoke  , OnSpawnSmoke)
    return true
end

return GlobalGameCppDelegateProcessor
