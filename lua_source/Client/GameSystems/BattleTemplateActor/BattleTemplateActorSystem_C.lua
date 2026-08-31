local luaclass = require("luaclass")
local BattleTemplateActorSystem = require("BattleTemplateActorSystem")
local BattleTemplateActorSystem_C = luaclass("BattleTemplateActorSystem_C", BattleTemplateActorSystem)

local PropName = require("PropName")
local GameObjectTypeDef = require("GameObjectTypeDef")
local SceneItemActorDef = require("SceneItemActorDef")
local ResourceManager = require("ResourceManager")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ActorTriggerGroupHelper = require("ActorTriggerGroupHelper")
-- local TriggerIni = require("TriggerIni")
local CommonEventDef = require("CommonEventDef")
-- 底下这仨因为循环包含的原因，init时在require
local GameObjectSystem
local GameTrigger
local SceneItemHelper
local BattleTemplateActorResourceAutoLoader

local MAX_CACHED_ACTOR_COUNT = 50
local TRIGGER_UPDATE_INTERVAL = 0.3
local TRIGGER_OFFSET_HEIGHT = 200
local TEMP_CREATE_DATA = {}
local TEMP_LOCATION = Vector()
local TEMP_ROTATION = Rotator()

local SpawnActorForScript_LR = EngineExtActorShell.SpawnActorForScript_LR
local DestroyActor = EngineExtActorShell.DestroyActor
-- local SetActorLocation = EngineExtActorShell.SetActorLocation
-- local SetActorRotation = EngineExtActorShell.SetActorRotation

BattleTemplateActorSystem_C.EventHelper = nil
BattleTemplateActorSystem_C.tbUnusedActors = nil
BattleTemplateActorSystem_C.tbClasses = nil
BattleTemplateActorSystem_C.tbLocalObjects = nil
BattleTemplateActorSystem_C.bDebug = false
BattleTemplateActorSystem_C.nTriggerGroupId = nil

local function LoadClass(self, szClassName)
    local pRet = self.tbClasses[szClassName]
    if(pRet) then
        return pRet
    end

    pRet = szClassName:load()
    ResourceManager:Hold(pRet)
    self.tbClasses[szClassName] = pRet
    return pRet
end

--local nTempSpawnCount = 0

-- local function SetCollisionEnabled(pUEActor, bEnabled)
--     pUEActor:SetCollisionEnabled(bEnabled)
-- end

local function AddTemplateActorTrigger(self, pUEActor)
    if self.nTriggerGroupId ~= nil then
        ActorTriggerGroupHelper.AddTriggerInGroup(self.nTriggerGroupId, pUEActor)
    end
end

local function RemoveTemplateActorTrigger(self, pUEActor)
    if self.nTriggerGroupId ~= nil then
        ActorTriggerGroupHelper.RemoveTriggerInGroup(self.nTriggerGroupId, pUEActor)
    end
end

local function OnPlayerSelfReady(self)
    if self.nTriggerGroupId ~= nil then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nTriggerGroupId)
    end
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    local nRadius
    if tbPlayerSelf:IsShip() then
        nRadius = tbPlayerSelf.ShipBattlePropertyComponent:GetProp(PropName.nShipPickupRange)
        self.nTriggerGroupId = ActorTriggerGroupHelper.CreateTriggerGroup(tbPlayerSelf.pUEActor, nRadius, TRIGGER_UPDATE_INTERVAL)
    else
        nRadius = tbPlayerSelf.HumanBattlePropertyComponent:GetProp(PropName.nHumanPickupRange)
        self.nTriggerGroupId = ActorTriggerGroupHelper.CreateTriggerGroup(tbPlayerSelf.pUEActor, nRadius, TRIGGER_UPDATE_INTERVAL, TRIGGER_OFFSET_HEIGHT)
    end
    log("ActorTriggerGroupHelper set pick up trigger groupid ", self.nTriggerGroupId)
    for k, v in pairs(self.tbLocalObjects) do
        local tbGameObject = GameObjectSystem:FindByInstanceId(v)
        if tbGameObject ~= nil then
            AddTemplateActorTrigger(self, tbGameObject.pUEActor)
        end
    end
end

local function OnPlayerSelfUnready(self)
    if self.nTriggerGroupId ~= nil then
        ActorTriggerGroupHelper.DestroyTriggerGroup(self.nTriggerGroupId)
        self.nTriggerGroupId = nil
        log("ActorTriggerGroupHelper set pick up trigger groupid nil")
    end
end

local function OnEnterTemplateActorTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if nGroupId == self.nTriggerGroupId then
        log("ActorTriggerGroupHelper OnEnterTemplateActorTrigger")
        self.EventHelper:FireEvent(CommonEventDef.EV_PLAYER_ENTER_TRIGGER, tbOwnerObject, tbTargetObject)
    end
end

local function OnLeaveTemplateActorTrigger(self, nGroupId, tbOwnerObject, tbTargetObject)
    if nGroupId == self.nTriggerGroupId then
        log("ActorTriggerGroupHelper OnLeaveTemplateActorTrigger")
        self.EventHelper:FireEvent(CommonEventDef.EV_PLAYER_LEAVE_TRIGGER, tbOwnerObject, tbTargetObject)
    end
end

local function CanCache(nResId, nTemplateId)
    if (nResId == SceneItemHelper:GetDefaultResId(SceneItemActorDef.AIR_DROP_BOX)) then
        return false
    end

    return true

    -- local tbItemResData = BattleItemDataTable:GetResTemplate(nTemplateId)
    -- if tbItemResData == nil then
    --     logerror("not find item res ", nTemplateId)
    --     return false
    -- end

    -- return tbItemResData.szDisplayClassName == nil or string.len(tbItemResData.szDisplayClassName) == 0
end

local function CreateUEActor(self, nResId, nTemplateId, pLocation, nYaw)
    TEMP_LOCATION.X = pLocation.X
    TEMP_LOCATION.Y = pLocation.Y
    TEMP_LOCATION.Z = pLocation.Z
    TEMP_ROTATION.Yaw = nYaw

    local bCache = CanCache(nResId, nTemplateId)
    if bCache then
        -- 这里只回收了非空投的掉落物ueactor，因为这些actor resid都一样，所以方便处理
        local tbUnusedActors = self.tbUnusedActors
        local nCount = #tbUnusedActors
        while(#tbUnusedActors > 0) do
            local pUEActor = tbUnusedActors[nCount]
            table.remove(tbUnusedActors, nCount)
            if(isvalidhandle(pUEActor)) then

                -- pUEActor:SetCollisionEnabled(true)
                -- pUEActor:SetActorHiddenInGame(false)
                -- SetActorLocation(pUEActor, TEMP_LOCATION)
                -- SetActorRotation(pUEActor, TEMP_ROTATION)
                pUEActor:SetEnabled(pLocation.X, pLocation.Y, pLocation.Z, nYaw)
                return pUEActor
            end
            nCount = #tbUnusedActors
        end
    end

    --nTempSpawnCount = nTempSpawnCount + 1
    TEMP_CREATE_DATA.nResId = nResId
    local szClassName = GameTrigger.StaticCollectResources(TEMP_CREATE_DATA)
    assert(szClassName)
    local pClass = LoadClass(self, szClassName)
    local pUEActor = SpawnActorForScript_LR(GWorld, pClass, TEMP_LOCATION, TEMP_ROTATION, nil)

    if pUEActor == nil then
        logerror("BattleTemplateActorSystem_C:CreateUEActor invallid classname: ", szClassName)
    end
    return pUEActor
end

local function DestoryUEActor(self, nResId, nTemplateId, pUEActor)
    if CanCache(nResId, nTemplateId) then
        local tbUnusedActors = self.tbUnusedActors
        local nCount = #tbUnusedActors
        if(nCount < MAX_CACHED_ACTOR_COUNT) then
            table.insert(tbUnusedActors, pUEActor)
            -- pUEActor:RemoveMesh()
            -- pUEActor:SetCollisionEnabled(false)
            -- pUEActor:SetActorHiddenInGame(true)
            pUEActor:SetDisabled()
            return
        end
    end

    DestroyActor(GWorld, pUEActor, false)
end

local function OnActorDestroyed(self, nItemInstanceId)
    local nServerInstanceId = self.tbLocalObjects[nItemInstanceId]
    if(nServerInstanceId == nil) then
        -- log("OnTemplateActorDestoryed failed", nItemInstanceId)
        return
    end

    self.tbLocalObjects[nItemInstanceId] = nil
    local tbGameObject = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    if(tbGameObject) then
        local pUEActor = tbGameObject.pUEActor
        local nResId = tbGameObject.nResId
        if(isvalidhandle(pUEActor)) then
            RemoveTemplateActorTrigger(self, tbGameObject.pUEActor)
            BattleTemplateActorResourceAutoLoader:OnTemplateActorDestroyed(tbGameObject)
            GameObjectSystem:UnbindUEActor(tbGameObject)
            GameObjectSystem:DestroyByInstanceId(nServerInstanceId)
            DestoryUEActor(self, nResId, tbGameObject.nTemplateId, pUEActor)
        end
    end

    -- log("OnTemplateActorDestoryed", nItemInstanceId)
end

local function OnMultiActorDestroyed(self, tbInstanceIds)
    for _, v in ipairs(tbInstanceIds) do
        OnActorDestroyed(self, v)
    end
end

local function OnActorCreated(self, nItemInstanceId, nTemplateId, pLocation, nZipYaw, nItemActorType)
    OnActorDestroyed(self, nItemInstanceId)
    -- if(self.tbLocalObjects[nItemInstanceId] ~= nil) then
    --     --log("OnTemplateActorCreated failed", nItemInstanceId)
    -- end

    SceneItemHelper:SetEnableAutoAdjustLocation(false)
    local _bIsAirDropItem, bIsOcean, pAdjustLocation, nRadius, nResId, nCollisionType =
        SceneItemHelper:GetCreateParam(nItemActorType, pLocation, nil, true)
    SceneItemHelper:SetEnableAutoAdjustLocation(true)

    local tbInitProto = {
        script_type = GameObjectTypeDef.Trigger,
        res_id = nResId,
        shape_type = 0,
        radius = nRadius,
        collision_type = nCollisionType,
        custom_data = {
            scene_item_info = {
                instance_id = nItemInstanceId,
                type = nItemActorType,
                template_id = nTemplateId,
            }
        }
    }
    local pUEActor = CreateUEActor(self, nResId, nTemplateId, pAdjustLocation, self:UnzipYaw(nZipYaw))
    assert(pUEActor)
    local nLocalServerInstanceId = GameObjectSystem:GenerateLocalInstanceId()
    local tbObject = GameObjectSystem:BindTriggerByReplicatedData(pUEActor, nLocalServerInstanceId, tbInitProto)
    assert(tbObject)
    tbObject.nTemplateId = nTemplateId
    self.tbLocalObjects[nItemInstanceId] = nLocalServerInstanceId
    AddTemplateActorTrigger(self, pUEActor)
    -- SetCollisionEnabled(pUEActor, true)
    SceneItemHelper:SetScale(tbObject, bIsOcean)
    pUEActor:OnRep_Scale()
    BattleTemplateActorResourceAutoLoader:OnTemplateActorCreated(tbObject)

    if(tbObject) then
        tbObject:OnActorPreCreated(pUEActor)
        --EventManager:OnFireEvent(ClientEventDef.EV_GAME_OBJECT_BEGIN_PLAY, tbObject)
        tbObject:OnActorCreated(pUEActor)
    end

    if(self.bDebug) then
        if(pUEActor.DebugCube) then
            pUEActor.DebugCube:SetHiddenInGame(false, false)
        end
    end
    -- log("OnTemplateActorCreated", nItemInstanceId, nTemplateId,
    --     pLocation.X, pLocation.Y, pLocation.Z,
    --     self:UnzipYaw(nZipYaw), nItemActorType, tbObject.nServerInstanceId)
end

local function OnMultiActorCreated(self, tbDatas)
    --logdebug("OnMultiActorCreated start", #tbDatas)
    --nTempSpawnCount = 0

    for _, v in ipairs(tbDatas) do
        OnActorCreated(self, v.InstanceId, v.TemplateId, v.Location, v.Yaw, v.CustomType)
    end
    --logdebug("OnMultiActorCreated end", nTempSpawnCount)
end

local function OnPickupUpdate(self, nInstanceId)
    local nLocalServerInstanceId = self.tbLocalObjects[nInstanceId]
    if nLocalServerInstanceId == nil then
        log("OnPickupUpdate invalid instance id", nInstanceId)
        return
    end
    local tbGameObject = GameObjectSystem:FindByInstanceId(nLocalServerInstanceId)
    if(tbGameObject and tbGameObject.pUEActor) then
        local nResId = tbGameObject.nResId
        if (nResId and nResId ~= SceneItemHelper:GetDefaultResId(SceneItemActorDef.AIR_DROP_BOX)) then
            tbGameObject.pUEActor:SetPickOut()
            tbGameObject.pUEActor:OnRep_IsPickOut()
        else
            log("OnPickupUpdate, no pick out func :", nResId)
        end
    end
end

local function OnMultiPickupUpdate(self, tbInstanceIds)
    for _, v in ipairs(tbInstanceIds) do
        OnPickupUpdate(self, v)
    end
end

local function OnWatchTargetChanged(self, tbWatchedTarget)
    self:SetWatchedTarget(GamePlayerSelfHelper:Get(), tbWatchedTarget)
end

function BattleTemplateActorSystem_C:Init()
    BattleTemplateActorSystem_C.super.Init(self)

    GameObjectSystem = dynamic_require("GameObjectSystem")
    GameTrigger = dynamic_require("GameTrigger")
    SceneItemHelper = require("SceneItemHelper")
    BattleTemplateActorResourceAutoLoader = require("BattleTemplateActorResourceAutoLoader")

    self.tbUsedActors = {}
    self.tbUnusedActors = {}
    self.tbClasses = {}
    self.tbLocalObjects = {}

    local pManager = self:GetDefaultRegionInfo().pManager
    assert(pManager)
    local EventHelper = self.EventHelper
    EventHelper:RegisterCppDelegate(pManager.OnActorCreated, self, OnActorCreated)
    EventHelper:RegisterCppDelegate(pManager.OnMultiActorCreated, self, OnMultiActorCreated)
    EventHelper:RegisterCppDelegate(pManager.OnActorDestroyed, self, OnActorDestroyed)
    EventHelper:RegisterCppDelegate(pManager.OnMultiActorDestroyed, self, OnMultiActorDestroyed)
    EventHelper:RegisterCppDelegate(pManager.OnPickupUpdate, self, OnPickupUpdate)
    EventHelper:RegisterCppDelegate(pManager.OnMultiPickupUpdate, self, OnMultiPickupUpdate)

    EventHelper:RegisterEvent(ClientEventDef.EV_REFRESH_WATCH_MATE, self, OnWatchTargetChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_WATCH_BOT, self, OnWatchTargetChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_UNREADY, self, OnPlayerSelfUnready)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_ENTER_TRIGER_GROUP, self, OnEnterTemplateActorTrigger)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_ACTOR_LEAVE_TRIGER_GROUP, self, OnLeaveTemplateActorTrigger)

    BattleTemplateActorResourceAutoLoader:Init()

    return true
end

function BattleTemplateActorSystem_C:Uninit()
    BattleTemplateActorSystem_C.super.Uninit(self)

    for _, v in pairs(self.tbClasses) do
        ResourceManager:Unhold(v)
    end

    -- Actor会跟着world自动销毁，所以这里没管
    self.tbUsedActors = nil
    self.tbUnusedActors = nil
    self.tbClasses = nil
    self.tbLocalObjects = nil

    BattleTemplateActorResourceAutoLoader:Uninit()
end

function BattleTemplateActorSystem_C:SetDebug(bDebug)
    self.bDebug = bDebug

    local bHidden = bDebug == false
    local pDebugCube, tbGameObject
    for _, v in pairs(self.tbLocalObjects) do
        tbGameObject = GameObjectSystem:FindByInstanceId(v)
        if(tbGameObject and tbGameObject.pUEActor) then
            pDebugCube = tbGameObject.pUEActor.DebugCube
            if(pDebugCube) then
                pDebugCube:SetHiddenInGame(bHidden, false)
            end
        end
    end
end

return BattleTemplateActorSystem_C()