local luaclass = require("luaclass")
local GameObjectSystem = require("GameObjectSystem")
local GameObjectSystem_C = luaclass("GameObjectSystem_C", GameObjectSystem)

local GameObjectTypeDef = require("GameObjectTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GOCreateDataHelper = require("GOCreateDataHelper_C")
local GOCustomDataHelper = require("GOCustomDataHelper_C")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local ResourceManager = require("ResourceManager")
local UEActorHelper = require("UEActorHelper")
--local TemplateTypeDef = require("TemplateTypeDef")

local bGlobalAsyncLoad = GlobalVariableSystem.bEnableAsyncLoadObject

GameObjectSystem_C.tbHubAsyncObjects = nil
GameObjectSystem_C.DelayPlayerReadyTimer = nil
GameObjectSystem_C.tbCachGameObjects = nil

local LocalInstanceId = -10000
function GameObjectSystem_C:GenerateLocalInstanceId()
    LocalInstanceId = LocalInstanceId - 1
    return LocalInstanceId
end

---------------------------------------------------------------------------------------
-- 异步加载
local function CollectHubObjectAsyncResources(self, nObjectType, tbCreateData, tbCustomData)
    local Class = self:GetGameObjectClass(nObjectType)
    if(Class.StaticCollectResources ~= nil) then
        return Class.StaticCollectResources(tbCreateData, tbCustomData)
    end
    return nil
end

local function VerifyHubObjectAsync(self, nServerInstanceId, bForceFlush)
    if(not bGlobalAsyncLoad) then
        return false
    end

    local tbData = self.tbHubAsyncObjects[nServerInstanceId]
    if(tbData) then
        if(bForceFlush) then
            log("ForceFlush VerifyHubObjectAsync, type:", tbData.nType, ", id:", nServerInstanceId)
        else
            log("VerifyHubObjectAsync, type:", tbData.nType, ", id:", nServerInstanceId)
        end
        self.tbHubAsyncObjects[nServerInstanceId] = nil
        tbData.tbCreateData.bCreateNativeComponentAsyn = not bForceFlush
        self:Create(tbData.nType, tbData.tbCreateData, tbData.tbCustomData)
        return true
    end
    return false
end

local function CreateHubObjectAsync(self, nObjectType, tbCreateData, tbCustomData)
    local nId = tbCreateData.nServerInstanceId
    local Resources = CollectHubObjectAsyncResources(self, nObjectType, tbCreateData, tbCustomData)
    if(Resources == nil) then
        logwarning("CreateHubObjectAsync failed, has no resources, type", nObjectType, ", id:", nId)
        self:Create(nObjectType, tbCreateData, tbCustomData)
        return
    end

    local tbNew = {}
    tbNew.nType = nObjectType
    tbNew.tbCreateData = tbCreateData
    tbNew.tbCustomData = tbCustomData
    self.tbHubAsyncObjects[nId] = tbNew

    local varType = type(Resources)
    if(varType == 'string') then
        tbNew.nHandle = ResourceManager:LoadAsync(Resources,
            function() VerifyHubObjectAsync(self, nId, false) end, false)
    elseif(varType == 'table') then
        local tbHandles = {}
        tbNew.tbHandles = tbHandles
        local fnCallback = function(szAssetName, pObject, nHandle)
            local nCount = #tbHandles
            for i=1, nCount do
                if(nHandle == tbHandles[i]) then
                    table.remove(tbHandles, i)
                    break
                end
            end -- end for

            if(#tbHandles == 0) then
                VerifyHubObjectAsync(self, nId, false)
            end
        end -- end fnCallback

        local nHandle
        for i=1, #Resources do
            nHandle = ResourceManager:LoadAsync(Resources[i], fnCallback, false)
            if(nHandle ~= nil) then
                table.insert(tbHandles, nHandle)
            end
        end
    end -- end elseif
end

local function DestroyHubAsyncData(tbData)
    if(not tbData) then
        return
    end

    if(tbData.nHandle ~= nil) then
        ResourceManager:CancelLoadAsync(tbData.nHandle)
    elseif(tbData.tbHandles ~= nil) then
        for _, v in ipairs(tbData.tbHandles) do
            ResourceManager:CancelLoadAsync(v)
        end
    end
end

local function DestroyHubAsyncObject(self, nServerInstanceId)
    local tbData = self.tbHubAsyncObjects[nServerInstanceId]
    if(tbData) then
        log("DestroyHubAsyncObject", nServerInstanceId)
        DestroyHubAsyncData(tbData)
        self.tbHubAsyncObjects[nServerInstanceId] = nil
        return true
    end
    return false
end

local function DestroyAllAsyncObjects(self)
    log("DestroyAllAsyncObjects")
    if(self.tbHubAsyncObjects) then
        for _, v in pairs(self.tbHubAsyncObjects) do
            DestroyHubAsyncData(v)
        end
        self.tbHubAsyncObjects = {}
    end
end

local function DisconnectedFromHubServer(self)
    DestroyAllAsyncObjects(self)
end

function GameObjectSystem_C:FindByInstanceIdWithoutVerify(nServerInstanceId)
    return GameObjectSystem_C.super.FindByInstanceId(self, nServerInstanceId)
end

function GameObjectSystem_C:FindByInstanceId(nServerInstanceId)
    VerifyHubObjectAsync(self, nServerInstanceId, true)
    local Ret = GameObjectSystem_C.super.FindByInstanceId(self, nServerInstanceId)
    if(bGlobalAsyncLoad and Ret and not Ret.bHasActorCreated) then
        UEActorHelper.TryCreateTemplateComponents(Ret:GetModelActor(), Ret.tbComponentTags, false, true)
    end
    return Ret
end

function GameObjectSystem_C:RestoreObject(tbProtoData)
    local tbCacheObject = self.tbCachGameObjects[tbProtoData.nServerInstanceId]
    if tbCacheObject then
        self:AddByServerInstanceId(tbProtoData.nServerInstanceId, tbCacheObject)
        self:BindUniqueId(tbCacheObject.nUniqueId, tbCacheObject)
        self.tbCachGameObjects[tbProtoData.nServerInstanceId]  = nil
        tbCacheObject:RestoreObject(tbProtoData)
        return tbCacheObject
    end
    return nil
end

function GameObjectSystem_C:DestroyByInstanceId(nServerInstanceId, bCache)
    if(DestroyHubAsyncObject(self, nServerInstanceId)) then
        return true
    end

    if bCache then
        local tbObject = self:FindByInstanceId(nServerInstanceId)
        if tbObject and tbObject:NeedCache() then
            tbObject:DelayDestroy()
            -- table.insert(self.tbCachGameObjects, tbObject)
            self.tbCachGameObjects[nServerInstanceId] = tbObject
            self:RemoveByServerInstanceId(nServerInstanceId)
        else
            return GameObjectSystem_C.super.DestroyByInstanceId(self, nServerInstanceId)
        end
        return true
    else
        return GameObjectSystem_C.super.DestroyByInstanceId(self, nServerInstanceId)
    end
end

function GameObjectSystem_C:DestroyCacheByInstanceId(nServerInstanceId)
    local tbObject = self.tbCachGameObjects[nServerInstanceId]
    if(tbObject) then
        tbObject:Destroy()
        self.EventDispatcher:OnDestroyObject(tbObject)
		self.tbCachGameObjects[nServerInstanceId] = nil
		return true
    end
    return false
end

-- function GameObjectSystem_C:DestroyAll()
--     GameObjectSystem_C.super.DestroyAll(self)
--     DestroyAllAsyncObjects(self)
-- end

---------------------------------------------------------------------------------------
-- 删除所有
function GameObjectSystem_C:DestroyAll()
    log("GameObjectSystem_C:DestroyAll")

    -- local GamePlayerSelf = GamePlayerSelfHelper:Get()
    -- local nPlayerSelfId = nil
    -- if(GamePlayerSelf) then
    --     nPlayerSelfId = GamePlayerSelf:GetServerInstanceId()
    --     if(bIncludePlayerSelfActor) then
    --         self:UnbindPlayerUEController(GamePlayerSelf)
    --         self:DestroyUEActorByServerId(nPlayerSelfId)
    --     end
    -- end

    -- -- 这里保险起见还是拷贝一份出来再删吧
    -- local tbMap = {}
    -- for k, _ in pairs(self.tbMapByInstanceId) do
    --     table.insert(tbMap, k)
    -- end

    -- local nId
    -- local nCount = #tbMap
    -- for i=1, nCount do
    --     nId = tbMap[i]
    --     if(nId ~= nPlayerSelfId) then
    --         self:DestroyByInstanceId(nId)
    --     end
    -- end

    self.tbReadyToDestroy = {}
    GameObjectSystem_C.super.DestroyAll(self)
    DestroyAllAsyncObjects(self)
    --self:PrintDebugInfo()

    if(self.tbCachGameObjects) then
        for k,v in pairs(self.tbCachGameObjects) do
            self:DestroyCacheByInstanceId(k)
        end
        self.tbCachGameObjects = {}
    end
end

function GameObjectSystem_C:Init()
    GameObjectSystem_C.super.Init(self)
    self.tbHubAsyncObjects = {}
    self.tbCachGameObjects = {}
    self.tbReadyToDestroy = {}
    GamePlayerSelfHelper:Init()

    EventManager:BindEventMethod(ClientEventDef.EV_DISCONNECTED, self, DisconnectedFromHubServer)
end

function GameObjectSystem_C:Uninit()
    EventManager:UnBindEventMethod(ClientEventDef.EV_DISCONNECTED, self, DisconnectedFromHubServer)

    GamePlayerSelfHelper:Uninit()
    if(self.DelayPlayerReadyTimer) then
        self.DelayPlayerReadyTimer:Clear()
        self.DelayPlayerReadyTimer = nil
    end

    for k,v in pairs(self.tbCachGameObjects) do
        self:DestroyCacheByInstanceId(k)
    end
    GameObjectSystem_C.super.Uninit(self)

    self.tbCachGameObjects = nil
    self.tbReadyToDestroy = nil
end

function GameObjectSystem_C:MarkReadyToDestroy(nInstanceId)
    self.tbReadyToDestroy[nInstanceId] = true
end

function GameObjectSystem_C:IsReadyToDestroy(tbGameObject)
    local nInstanceId = tbGameObject:GetServerInstanceId()
    if(tbGameObject:GetModelActor() ~= nil) then
        return false
    end

    local bReady = self.tbReadyToDestroy[nInstanceId]
    if(bReady) then
        return true
    end

    local ObjectType = tbGameObject.ObjectType
    return ObjectType ~= GameObjectTypeDef.PlayerOther
            and ObjectType ~= GameObjectTypeDef.PlayerSelf
            and ObjectType ~= GameObjectTypeDef.Npc
end

---------------------------------------------------------------------------------------
-- Player
-- 单机副本使用，只创建lua逻辑对象，不创建actor，restore时在创建
-- function GameObjectSystem_C:CreatePlayerSelfInGameMode(tbPrepareInfo, pController,
--     nControllerNetGuid, nControllerUniqueId, bIsSpectator)
--     log("GameObjectSystem_C:CreatePlayerSelfInGameMode", nControllerNetGuid, nControllerUniqueId)

--     local tbPlayerSelf = GamePlayerSelfHelper:Get()
--     if(tbPlayerSelf == nil) then
--         logerror("GameObjectSystem_C:CreatePlayerSelfInGameMode failed, the player self is not exsisted in client")
--         return nil
--     end

--     -- 重新绑定netguid等，不做任何事，restore时在做具体操作
--     tbPlayerSelf.tbPrepareInfo = tbPrepareInfo
--     self:BindPlayerUEController(tbPlayerSelf, pController, nControllerNetGuid, nControllerUniqueId)
--     self:ChangeServerInstanceId(tbPlayerSelf:GetServerInstanceId(), nControllerNetGuid)
--     return tbPlayerSelf
-- end

-- 单机副本SpawnDefaultPawn时用
function GameObjectSystem_C:SpawnPlayerSelfUEActorInGameMode(tbPlayerSelf, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(false == GameObjectSystem_C.super.SpawnPlayerSelfUEActorInGameMode(self,
        tbPlayerSelf, tbPrepareInfo, tbSpawnInfo, bPossess)) then
        return false
    end

    -- 这里返回后才会possess，要等possess完才能抛事件，所以下一帧抛
    local DelayTimer = require("DelayTimer")
    self.DelayPlayerReadyTimer = DelayTimer:RunNextTick(function()
        self.DelayPlayerReadyTimer = nil
        tbPlayerSelf:MarkPlayerSelfReady()
    end)

    return true
end

-- 单机副本使用
function GameObjectSystem_C:DestroyPlayerSelfInGameMode(nControllerNetGuid)
    log("GameObjectSystem_C:DestroyPlayerSelfInGameMode", nControllerNetGuid)

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if(tbPlayerSelf) then
        if(self.DelayPlayerReadyTimer) then
            self.DelayPlayerReadyTimer:Clear()
            self.DelayPlayerReadyTimer = nil
        end

        -- 客户端不删object，只删actor
        -- self:DestroyUEActorByServerId(tbPlayerSelf:GetServerInstanceId())
        -- self:ChangeServerInstanceId(tbPlayerSelf:GetServerInstanceId(), tbPlayerSelf.nHubServerId)
        -- tbPlayerSelf.nUEControllerNetGuid = nil
        self:DestroyByInstanceId(tbPlayerSelf:GetServerInstanceId())
    end
end

-- 从hubserver登录成功后使用
function GameObjectSystem_C:CreatePlayerSelfWithHubLoginData(tbProtoData)
    log("GameObjectSystem_C:CreatePlayerSelfWithHubLoginData")

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if(tbPlayerSelf) then
        logerror("GameObjectSystem_C:CreatePlayerSelfInHub failed, the player self has created")
        return nil
    end

    local tbCreateData = GOCreateDataHelper:ParsePlayerSelfHubData(tbProtoData)
    local tbCustomData = GOCustomDataHelper:ParsePlayerSelfHubData(tbCreateData.nTemplateType, tbProtoData)
    tbPlayerSelf = self:Create(GameObjectTypeDef.PlayerSelf, tbCreateData, tbCustomData)
    if(tbPlayerSelf) then
        tbPlayerSelf.nHubServerId = tbCreateData.nServerInstanceId
    end
    return tbPlayerSelf
end

-- -- 进出港口以及切出副本使用
function GameObjectSystem_C:RestorePlayerSelfUEActorInHub(bIsOcean, nNewServerInstanceId, tbTransform)
    log("GameObjectSystem_C:RestorePlayerSelfUEActorInHub", bIsOcean, nNewServerInstanceId)

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if(tbPlayerSelf == nil) then
        logerror("GameObjectSystem_C:RestorePlayerSelfUEActorInHub failed, the player self is nil")
        return false
    end

    tbPlayerSelf.nPlayerId = GlobalVariableSystem.nSelfLobbyPlayerId
    local nOldServerInstanceId = tbPlayerSelf:GetServerInstanceId()
    self:ChangeServerInstanceId(nOldServerInstanceId, nNewServerInstanceId)

    local tbCreateData = GOCreateDataHelper:ParsePlayerSelfHubRestoreData(bIsOcean, tbPlayerSelf,
        nNewServerInstanceId, tbTransform)
    local tbCustomData = tbPlayerSelf.tbHubCustomData
    if(not self:RestoreUEActor(tbPlayerSelf, tbCreateData, tbCustomData)) then
        return false
    end

    tbPlayerSelf.nHubServerId = tbPlayerSelf:GetServerInstanceId()
    log("HubPlayerSelfReady")
    tbPlayerSelf:MarkPlayerSelfReady()
    return true
end

-- 恢复PlayerSelfObject
function GameObjectSystem_C:RestorePlayerSelfObject(bIsShip, nNewServerInstanceId, tbTransform, bRestoreUEActor)
    log("GameObjectSystem_C:RestorePlayerSelfObject", bIsShip, nNewServerInstanceId)

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if(tbPlayerSelf ~= nil) then
        if(GlobalVariableSystem:IsInLobby()) then
            return self:RestorePlayerSelfUEActorInHub(bIsShip, nNewServerInstanceId, tbTransform)
        else
            return true
        end
    end

    assert(GamePlayerSelfHelper:HasSavedData())
    local tbCreateData = GOCreateDataHelper:ParsePlayerSelfObjectRestoreData(bIsShip,
        GamePlayerSelfHelper.szName,
        bIsShip and GamePlayerSelfHelper.nShipTemplateId or GamePlayerSelfHelper.nHumanTemplateId,
        nNewServerInstanceId or GamePlayerSelfHelper.nServerInstanceId,
        GlobalVariableSystem.nSelfLobbyPlayerId,
        tbTransform)
    local tbCustomData = GamePlayerSelfHelper.tbHubCustomData

    tbPlayerSelf = self:Create(GameObjectTypeDef.PlayerSelf, tbCreateData, tbCustomData)
    assert(tbPlayerSelf)

    tbPlayerSelf.bCreateUEActor = true
    tbPlayerSelf.nHubServerId = GamePlayerSelfHelper.nHubServerId

    if(bRestoreUEActor) then
        if(not self:RestoreUEActor(tbPlayerSelf, tbCreateData, tbCustomData)) then
            return false
        end
        log("Mark player self ready in hub")
        tbPlayerSelf:MarkPlayerSelfReady()
    end
    return true
end

-- 联网副本客户端专用
function GameObjectSystem_C:BindReplicatedPlayerSelfActor(pUEActor, nServerInstanceId, tbInitProtoData)
    log("GameObjectSystem_C:BindReplicatedPlayerSelfActor")
    local PlayerSelf = GamePlayerSelfHelper:Get()
    self:ChangeServerInstanceId(PlayerSelf:GetServerInstanceId(), nServerInstanceId)

    local tbCreateData = GOCreateDataHelper:ParsePlayerReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbCustomData = GOCustomDataHelper:ParsePlayerReplicatedData(pUEActor, tbInitProtoData)
    log("GameObjectSystem_C:BindReplicatedPlayerSelfActor ", tbCreateData.nLocationX, tbCreateData.nLocationY, tbCreateData.nLocationZ)

    if(PlayerSelf:GetUEActorUniqueId() ~= nil) then
        self:UnbindUniqueId(PlayerSelf:GetUEActorUniqueId())
    end
    PlayerSelf:BindReplicatedUEActor(pUEActor, tbCreateData, tbCustomData)
    if(PlayerSelf:GetUEActorUniqueId() ~= nil) then
        self:BindUniqueId(PlayerSelf:GetUEActorUniqueId(), PlayerSelf)
    end
    PlayerSelf:SetInitProtoData(tbInitProtoData)
    return PlayerSelf
end

---------------------------------------------------------------------------------------
-- Npc
function GameObjectSystem_C:CreateAtmoSphereInHub(tbProtoData, bAsync)
    -- local tbRestoreObject = self:RestoreObject(tbProtoData)
    -- if tbRestoreObject then
    --     return tbRestoreObject
    -- end
    if(bAsync and bGlobalAsyncLoad) then
        log("GameObjectSystem_C:CreateNpcInHub async, id:", tbProtoData.nServerInstanceId)
        return CreateHubObjectAsync(self, GameObjectTypeDef.AtmoSphereNpc, tbProtoData)
    end

    log("GameObjectSystem_C:CreateNpcInHub, id:", tbProtoData.nServerInstanceId)
    return self:Create(GameObjectTypeDef.AtmoSphereNpc, tbProtoData)
end

function GameObjectSystem_C:CreateAtmoSphereShipInHub(tbProtoData, bAsync)
    if(bAsync and bGlobalAsyncLoad) then
        log("GameObjectSystem_C:CreateAtmoSphereShipNpcInHub async, id:", tbProtoData.nServerInstanceId)
        return CreateHubObjectAsync(self, GameObjectTypeDef.AtmoSphereShipNpc, tbProtoData)
    end

    log("GameObjectSystem_C:CreateAtmoSphereShipInHub, id:", tbProtoData.nServerInstanceId)
    return self:Create(GameObjectTypeDef.AtmoSphereShipNpc, tbProtoData)
end

function GameObjectSystem_C:CreateNpcInHub(tbProtoData, bAsync)
    local tbCreateData = GOCreateDataHelper:ParseNpcHubData(tbProtoData)
    local tbCustomData = GOCustomDataHelper:ParseNpcHubData(tbProtoData)

    local tbRestoreObject = self:RestoreObject(tbCreateData)
    if tbRestoreObject then
        return tbRestoreObject
    end

    if(bAsync and bGlobalAsyncLoad) then
        log("GameObjectSystem_C:CreateNpcInHub async, id:", tbCreateData.nServerInstanceId)
        return CreateHubObjectAsync(self, GameObjectTypeDef.Npc, tbCreateData, tbCustomData)
    end

    log("GameObjectSystem_C:CreateNpcInHub, id:", tbCreateData.nServerInstanceId)
    return self:Create(GameObjectTypeDef.Npc, tbCreateData, tbCustomData)
end

function GameObjectSystem_C:DestroyNpcInHub(nServerInstanceId, bCache)
    log("GameObjectSystem_C:DestroyNpcInHub, id:", nServerInstanceId)
    self:DestroyByInstanceId(nServerInstanceId, bCache)
end

function GameObjectSystem_C:BindNpcByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    log("GameObjectSystem_C:BindNpcByReplicatedData")
    local tbGameObject = self:FindByInstanceId(nServerInstanceId)
    if(tbGameObject) then
        self:UnbindUEActor(tbGameObject)
    else
        local tbCreateData = GOCreateDataHelper:ParseNpcReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
        local tbCustomData = GOCustomDataHelper:ParseNpcReplicatedData(pUEActor, tbInitProtoData)
        tbCreateData.bCreateUEActor = false

        tbGameObject = self:Create(GameObjectTypeDef.Npc, tbCreateData, tbCustomData)
        if(tbGameObject == nil) then
            logerror("GameObjectSystem_C:BindNpcByReplicatedData failed")
            return nil
        end
    end
    return self:BindUEActor(tbGameObject, pUEActor)
end

---------------------------------------------------------------------------------------
-- PlayerOther
function GameObjectSystem_C:CreatePlayerOtherInHub(tbProtoData, bAsync)
    local tbCreateData = GOCreateDataHelper:ParsePlayerOtherHubData(tbProtoData)
    local tbCustomData = GOCustomDataHelper:ParsePlayerOtherHubData(tbProtoData)

    if(bAsync and bGlobalAsyncLoad) then
        log("GameObjectSystem_C:CreatePlayerOtherInHub async id:", tbCreateData.nServerInstanceId)
        return CreateHubObjectAsync(self, GameObjectTypeDef.PlayerOther, tbCreateData, tbCustomData)
    end

    log("GameObjectSystem_C:CreatePlayerOtherInHub, id:", tbCreateData.nServerInstanceId)
    return self:Create(GameObjectTypeDef.PlayerOther, tbCreateData, tbCustomData)
end

function GameObjectSystem_C:DestroyPlayerOtherInHub(nServerInstanceId)
    log("GameObjectSystem_C:DestroyPlayerOtherInHub, id:", nServerInstanceId)
    self:DestroyByInstanceId(nServerInstanceId)
end

-- 客户端进入副本被动创建
function GameObjectSystem_C:BindPlayerOtherByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    log("GameObjectSystem_C:BindPlayerOtherByReplicatedData")
    local tbCreateData = GOCreateDataHelper:ParsePlayerReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbCustomData = GOCustomDataHelper:ParsePlayerReplicatedData(pUEActor, tbInitProtoData)

    local tbGameObject = self:FindByInstanceId(nServerInstanceId)
    if(tbGameObject) then
        if(tbGameObject:GetUEActorUniqueId() ~= nil) then
            self:UnbindUniqueId(tbGameObject:GetUEActorUniqueId())
        end
        tbGameObject:BindReplicatedUEActor(pUEActor, tbCreateData, tbCustomData)
        if(tbGameObject:GetUEActorUniqueId() ~= nil) then
            self:BindUniqueId(tbGameObject:GetUEActorUniqueId(), tbGameObject)
        end
    else
        tbCreateData.bCreateUEActor = false
        tbGameObject = self:Create(GameObjectTypeDef.PlayerOther, tbCreateData, tbCustomData)

        if(tbGameObject == nil) then
            logerror("GameObjectSystem_C:BindPlayerOtherByReplicatedData failed")
            return nil
        end
        self:BindUEActor(tbGameObject, pUEActor)
    end

    return tbGameObject
end

---------------------------------------------------------------------------------------
-- 创建Trigger
function GameObjectSystem_C:CreateTriggerInHub(tbProtoData, bAsync)
    local tbCreateData = GOCreateDataHelper:ParseTriggerHubData(tbProtoData)
    local tbCustomData = GOCustomDataHelper:ParseTriggerHubData(tbProtoData)

    local tbRestoreObject = self:RestoreObject(tbCreateData)
    if tbRestoreObject then
        return tbRestoreObject
    end

    if(bAsync and bGlobalAsyncLoad) then
        log("GameObjectSystem_C:CreateTriggerInHub async, id:", tbCreateData.nServerInstanceId)
        return CreateHubObjectAsync(self, GameObjectTypeDef.Trigger, tbCreateData, tbCustomData)
    end

    log("GameObjectSystem_C:CreateTriggerInHub, id:", tbCreateData.nServerInstanceId)
    return self:Create(GameObjectTypeDef.Trigger, tbCreateData, tbCustomData)
end

function GameObjectSystem_C:DestroyTriggerInHub(nServerInstanceId, bRestore)
    log("GameObjectSystem_C:DestroyTriggerInHub, id:", nServerInstanceId)
    if bRestore == nil then
        bRestore = true
    end
    self:DestroyByInstanceId(nServerInstanceId, bRestore)
end

-- 客户端进入副本被动创建
function GameObjectSystem_C:BindTriggerByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData, bCreateComponents)
    log("GameObjectSystem_C:BindGameTriggerByReplicatedData", tbInitProtoData.res_id, nServerInstanceId, UEActorHelper:GetActorUniqueId(pUEActor))
    local tbCreateData = GOCreateDataHelper:ParseTriggerReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbCustomData = GOCustomDataHelper:ParseTriggerReplicatedData(pUEActor, tbInitProtoData)
    tbCreateData.bCreateUEActor = false
    if(bCreateComponents ~= nil) then
        tbCreateData.bCreateComponents = bCreateComponents
    end
    local tbGameObject = self:Create(GameObjectTypeDef.Trigger, tbCreateData, tbCustomData)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem_C:BindTriggerByReplicatedData failed")
        return nil
    end
    return self:BindUEActor(tbGameObject, pUEActor)
end

---------------------------------------------------------------------------------------
-- 创建Dummy
function GameObjectSystem_C:CreateDummyInHub(tbProtoData, bAsync)
    local tbCreateData = GOCreateDataHelper:ParseDummyHubData(tbProtoData)
    local tbCustomData = GOCustomDataHelper:ParseDummyHubData(tbProtoData)

    local tbRestoreObject = self:RestoreObject(tbCreateData)
    if tbRestoreObject then
        return tbRestoreObject
    end

    if(bAsync and bGlobalAsyncLoad) then
        log("GameObjectSystem_C:CreateDummyInHub async, id:", tbCreateData.nServerInstanceId)
        return CreateHubObjectAsync(self, GameObjectTypeDef.Dummy, tbCreateData, tbCustomData)
    end

    log("GameObjectSystem_C:CreateDummyInHub, id:", tbCreateData.nServerInstanceId)
    return self:Create(GameObjectTypeDef.Dummy, tbCreateData, tbCustomData)
end

function GameObjectSystem_C:DestroyDummyInHub(nServerInstanceId)
    log("GameObjectSystem_C:DestroyDummyInHub, id:", nServerInstanceId)
    self:DestroyByInstanceId(nServerInstanceId, true)
end

-- 客户端进入副本被动创建
function GameObjectSystem_C:BindDummyByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    log("GameObjectSystem_C:BindDummyByReplicatedData")
    local tbCreateData = GOCreateDataHelper:ParseDummyReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbCustomData = GOCustomDataHelper:ParseDummyReplicatedData(pUEActor, tbInitProtoData)
    tbCreateData.bCreateUEActor = false
    local tbGameObject = self:Create(GameObjectTypeDef.Dummy, tbCreateData, tbCustomData)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem_C:BindDummyByReplicatedData failed")
        return nil
    end
    return self:BindUEActor(tbGameObject, pUEActor)
end

function GameObjectSystem_C:BindHorseByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    log("GameObjectSystem_C:BindHorseByReplicatedData")
    local tbCreateData = GOCreateDataHelper:ParseDummyReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbCustomData = GOCustomDataHelper:ParseDummyReplicatedData(pUEActor, tbInitProtoData)
    tbCreateData.bCreateUEActor = false
    local tbGameObject = self:Create(GameObjectTypeDef.Horse, tbCreateData, tbCustomData)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem_C:BindHorseByReplicatedData failed")
        return nil
    end
    return self:BindUEActor(tbGameObject, pUEActor)
end


function GameObjectSystem_C:BindDestructibleObjectByReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    log("GameObjectSystem_C:BindDestructibleObjectByReplicatedData")
    local tbCreateData = GOCreateDataHelper:ParseDestructibleObjectReplicatedData(pUEActor, nServerInstanceId, tbInitProtoData)
    local tbCustomData = GOCustomDataHelper:ParseDestructibleObjectReplicatedData(pUEActor, tbInitProtoData)
    tbCreateData.bCreateUEActor = false
    local tbGameObject = self:Create(GameObjectTypeDef.DestructibleObject, tbCreateData, tbCustomData)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem_C:BindDestructibleObjectByReplicatedData failed")
        return nil
    end
    return self:BindUEActor(tbGameObject, pUEActor)
end

return GameObjectSystem_C()
