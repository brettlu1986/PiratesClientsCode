-- 管理所有GameObject
local luaclass = require("luaclass")
local GameObjectSystem = luaclass("GameObjectSystem")

local GameObjectTypeDef = require("GameObjectTypeDef")
local UEActorHelper = require("UEActorHelper")
local GOCreateDataHelper = dynamic_require("GOCreateDataHelper")
local GOCustomDataHelper = dynamic_require("GOCustomDataHelper")
local GameComponentCreateHelper = require("GameComponentCreateHelper")
local Json = require("dkjson")
local DungeonCommonProtoNames = require("DungeonCommonProtoNames")
local GameNpcType = require("GameNpcType")
local EventManager = require("EventManager")
local LinkedList = require("LinkedList")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


local tbClassMap = {}
tbClassMap[GameObjectTypeDef.PlayerSelf] = dynamic_require("GamePlayerSelf")
tbClassMap[GameObjectTypeDef.PlayerOther] = dynamic_require("GamePlayerOther")
tbClassMap[GameObjectTypeDef.Npc] = dynamic_require("GameNpc")
tbClassMap[GameObjectTypeDef.Trigger] = dynamic_require("GameTrigger")
tbClassMap[GameObjectTypeDef.Dummy] = dynamic_require("GameDummy")
tbClassMap[GameObjectTypeDef.Horse] = dynamic_require("GameHorse")
tbClassMap[GameObjectTypeDef.DestructibleObject] = dynamic_require("GameDestructibleObject")
--tbClassMap[GameObjectTypeDef.AtmoSphereNpc] = dynamic_require("GameAtmoSphereNpc")
--tbClassMap[GameObjectTypeDef.AtmoSphereShipNpc] = dynamic_require("GameAtmoSphereShipNpc")

GameObjectSystem.tbMapByInstanceId = nil
GameObjectSystem.tbMapByUniqueId = nil
GameObjectSystem.pDungeonCommonActorShell = nil

GameObjectSystem.tbMapByObjectType = {} -- 为了优化访问速度单独为每个类型建个map


local DungeonInstanceId = 0


------------------------------------------------------------------------------------
-- Event
local Dispatcher = {}
local AllEvents = nil
Dispatcher.System = nil

local function InitEventDispatcher(self)
    Dispatcher.System = self
    self.EventDispatcher = Dispatcher
    AllEvents = {}
    EventManager:RegisterDispatcher("Object", Dispatcher)
end

local function UninitEventDispatcher(self)
    AllEvents = nil
    self.EventDispatcher = nil
    EventManager:UnregisterDispatcher("Object", Dispatcher)
end

function Dispatcher:BindEvent(nEvent, tbGameObject, fnCallBack)
    self:BindEventMethod(nEvent, tbGameObject, nil, fnCallBack)
end

function Dispatcher:BindEventMethod(nEvent, tbGameObject, tbClass, fnCallBack)
    if(AllEvents) then
        local tbNode = AllEvents[nEvent]
        if(tbNode) then
            tbNode = LinkedList.Add(tbNode)
        else
            tbNode = LinkedList.New()
            AllEvents[nEvent] = tbNode
        end

        tbNode.tbObject = tbGameObject
        tbNode.tbClass = tbClass
        tbNode.fnCallBack = fnCallBack
    end
end

local function EventRemoveCallbackEqualFunc(tbNode, tbGameObject, tbClass, fnCallBack)
    return tbNode.tbGameObject == tbGameObject
        and tbNode.tbClass == tbClass
        and tbNode.fnCallBack == fnCallBack
end

function Dispatcher:UnBindEvent(nEvent, tbGameObject, fnCallBack)
    self:UnBindEventMethod(nEvent, tbGameObject, nil, fnCallBack)
end

function Dispatcher:UnBindEventMethod(nEvent, tbGameObject, tbClass, fnCallBack)
    if(AllEvents) then
        AllEvents[nEvent] = LinkedList.RemoveWithEqualFunc(AllEvents[nEvent],
            EventRemoveCallbackEqualFunc, tbGameObject, tbClass, fnCallBack)
    end
end

local function EventIterate(tbNode, tbGameObject, ...)
    if(tbNode.tbObject == tbGameObject) then
        if(tbNode.tbClass) then
            tbNode.fnCallBack(tbNode.tbClass, ...)
        else
            tbNode.fnCallBack(...)
        end
    end
end

function Dispatcher:Fire(nEvent, tbGameObject, ...)
    if(AllEvents) then
        LinkedList.Iterate(AllEvents[nEvent], EventIterate, tbGameObject, ...)
    end
end

local function EventRemoveObjectEqualFunc(tbNode, tbGameObject)
    return tbNode.tbGameObject == tbGameObject
end

function Dispatcher:OnDestroyObject(tbGameObject)
    if(AllEvents) then
        local tbKeyToRemove = {}
        for k, v in pairs(AllEvents) do
            LinkedList.RemoveAllWithEqualFunc(v, EventRemoveObjectEqualFunc, tbGameObject)
            if(next(v) == nil) then
                table.insert(tbKeyToRemove, k)
            end
        end

        for _, v in ipairs(tbKeyToRemove) do
            AllEvents[v] = nil
        end
    end
end

------------------------------------------------------------------------------------
-- local function PrintTable(szTitle, tbTable)
--     local Json = require("dkjson")
--     log(szTitle..": "..Json.encode(tbTable))
-- end

function GameObjectSystem:GetGameObjectClass(Type)
    return tbClassMap[Type]
end

function GameObjectSystem:AddByServerInstanceId(nServerInstanceId, NewGameObject)
    -- if(self:FindByInstanceId(nServerInstanceId) ~= nil) then
    --     logerror("Duplicated GameObject:", nServerInstanceId)
    --     return nil
    -- end
    self.tbMapByInstanceId[nServerInstanceId] = NewGameObject
    self.tbMapByObjectType[NewGameObject.ObjectType][NewGameObject] = true
    return true
end

function GameObjectSystem:RemoveByServerInstanceId(nServerInstanceId)
    local tbGameObject = self.tbMapByInstanceId[nServerInstanceId]
    if(not tbGameObject) then
        log("GameObjectSystem RemoveByServerInstanceId failed:", nServerInstanceId)
        return
    end
    self.tbMapByInstanceId[nServerInstanceId] = nil
    self.tbMapByObjectType[tbGameObject.ObjectType][tbGameObject] = nil

    local tbUniqueIdMap = self.tbMapByUniqueId
    if(tbUniqueIdMap) then
        local nUniqueId, tbTempObject = next(tbUniqueIdMap)
        local nSavedId, tbSavedObject
        while(nUniqueId ~= nil) do
            nSavedId = nUniqueId
            tbSavedObject = tbTempObject
            nUniqueId, tbTempObject = next(tbUniqueIdMap, nUniqueId)

            if(tbSavedObject == tbGameObject) then
                tbUniqueIdMap[nSavedId] = nil
            end
        end
    end
end

function GameObjectSystem:Init()
    self.tbMapByInstanceId = {}
    self.tbMapByUniqueId = {}
    self.pDungeonCommonActorShell = CommonShell.GetCommon(GWorld):GetCommonActorShell()

    local tbMapByObjectType = self.tbMapByObjectType
    local TYPE_UNDEFINED = GameObjectTypeDef.Undefined
    for k, v in pairs(GameObjectTypeDef) do
        if(v ~= TYPE_UNDEFINED) then
            tbMapByObjectType[v] = {}
        end
    end

    GameComponentCreateHelper:Init()
    InitEventDispatcher(self)
    return true
end

function GameObjectSystem:Uninit()
    self:DestroyAll()
    GameComponentCreateHelper:Uninit()
    self.pDungeonCommonActorShell = nil
    UninitEventDispatcher(self)
end

function GameObjectSystem:Create(Type, tbCreateData, tbCustomData)
    if(tbCreateData == nil) then
        logerror("GameObjectSystem:Create failed, the tbCreateData is nil ")
        return nil
    end

    local nServerInstanceId = tbCreateData.nServerInstanceId
    if(nServerInstanceId == nil) then
        logerror("GameObjectSystem:Create failed, the nServerInstanceId is nil ")
        return nil
    end

    if(self:FindByInstanceId(nServerInstanceId) ~= nil) then
        logerror(string.format("GameObjectSystem:Create failed, duplicated GameObject: %d, info: %s", nServerInstanceId, t2s(tbCreateData)))
        return nil
    end

    local NewGameObject = nil
    local NewGameObjectClass = self:GetGameObjectClass(Type)
    if (NewGameObjectClass == nil) then
        logerror("GameObjectSystem:Create failed, cannot find gameobject class: " .. Type)
        return nil
    end

    NewGameObject = NewGameObjectClass()
    NewGameObject.ObjectType = Type

    self:AddByServerInstanceId(nServerInstanceId, NewGameObject)

    if(not NewGameObject:Create(tbCreateData, tbCustomData)) then
        self:RemoveByServerInstanceId(nServerInstanceId)
        logerror("GameObjectSystem Create failed: " .. nServerInstanceId)
        return nil
    end

    -- 会在PreBeginPlay里bindActor
    -- local nUniqueId = NewGameObject:GetUEActorUniqueId()
    -- if(nUniqueId) then
    --     self.tbMapByUniqueId[nUniqueId] = NewGameObject
    -- end
    return NewGameObject
end

function GameObjectSystem:DestroyAll()
    local tbObjectMap = self.tbMapByInstanceId
    if(tbObjectMap ~= nil) then
        local tbDeleted = {}
        for k, v in pairs(tbObjectMap) do
            table.insert(tbDeleted, k)
        end

        for _, Id in ipairs(tbDeleted) do
            self:DestroyByInstanceId(Id)
        end
    end
end

function GameObjectSystem:DestroyByInstanceId(nServerInstanceId)
    local tbObject = self:FindByInstanceId(nServerInstanceId)
    if(tbObject) then
        tbObject:Destroy()
        self.EventDispatcher:OnDestroyObject(tbObject)
        self:RemoveByServerInstanceId(nServerInstanceId)
        if GlobalVariableSystem:IsClient() then
            log("DestroyByInstanceId", tbObject.szName, nServerInstanceId)
        end
        return true
    end
    return false
end

function GameObjectSystem:DestroyByUniqueId(nUniqueId)
    local tbObject = self:FindByUniqueId(nUniqueId)
    if(tbObject) then
        return self:DestroyByInstanceId(tbObject:GetServerInstanceId())
    end
    return false
end

function GameObjectSystem:BindUniqueId(nUniqueId, tbGameObject)
    if(nUniqueId == nil) then
        return false
    end
    local tbObject = self:FindByUniqueId(nUniqueId)
    if(tbObject) then
        if(tbObject == tbGameObject) then
            logwarning("GameObjectSystem:BindUniqueId failed, the uniqueid is duplicated "..nUniqueId)
        else
            error(string.format("GameObjectSystem:BindUniqueId failed, the unique id is duplicated %d, old %s, instanceid: %d, type: %d, new %s, instanceid: %d, type: %d",
                nUniqueId,
                tbObject.szName or "None",
                tbObject:GetServerInstanceId() or -1,
                tbObject.ObjectType or -1,
                tbGameObject.szName or "None",
                tbGameObject:GetServerInstanceId() or -1,
                tbGameObject.ObjectType or -1))
        end
        return false
    end
    self.tbMapByUniqueId[nUniqueId] = tbGameObject
    return true
end

function GameObjectSystem:UnbindUniqueId(nUniqueId)
    if(nUniqueId ~= nil) then
        -- log("UnbindUniqueId nUniqueId:",nUniqueId)
        self.tbMapByUniqueId[nUniqueId] = nil
    end
end

-- 这里应该有好多个find函数，可以提供给外部使用
function GameObjectSystem:FindByInstanceId(nServerInstanceId)
    return self.tbMapByInstanceId[nServerInstanceId]
end

function GameObjectSystem:FindByUniqueId(nUniqueId)
    return self.tbMapByUniqueId[nUniqueId]
end

function GameObjectSystem:FindByUEActor(pUEActor)
    if(not pUEActor) then
        logerror("pUEActor is nil", debug.traceback(  ))
        return nil
    end
    local nUniqueId = UEActorHelper:GetActorUniqueId(pUEActor)
    return self:FindByUniqueId(nUniqueId)
end

-- 因为服务器船和人用的是两个actor，但客户端是一个，所以进主城后需要把主角的actorid换了
function GameObjectSystem:ChangeServerInstanceId(nOldServerInstanceId, nNewServerInstanceId)
    if(nOldServerInstanceId == nNewServerInstanceId) then
        return
    end
    local tbObject = self:FindByInstanceId(nOldServerInstanceId)
    if(tbObject) then
        log("GameObjectSystem:ChangeServerInstanceId", nOldServerInstanceId, nNewServerInstanceId)
        if(nOldServerInstanceId) then
            self.tbMapByInstanceId[nOldServerInstanceId] = nil
        end
        tbObject.nServerInstanceId = nNewServerInstanceId
        self.tbMapByInstanceId[nNewServerInstanceId] = tbObject
    else
        log("GameObjectSystem:ChangeServerInstanceId failed, can not find id", nOldServerInstanceId, nNewServerInstanceId, debug.traceback( ))
    end
end

function GameObjectSystem:PrintDebugInfo()
    local tbContainer = self.tbMapByInstanceId
    log("GameObjectSystem:PrintDebugInfo start...................")
    if(tbContainer) then
        for k, v in pairs(tbContainer) do
            logerror(Json.encode(v:GetDebugInfo()))
        end
    end
    log("GameObjectSystem:PrintDebugInfo end...................")
end

function GameObjectSystem:BindUEActor(tbGameObject, pUEActor)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem:BindUEActor failed, the gameobject is nil")
        return nil
    end
    if(pUEActor == nil) then
        logerror("GameObjectSystem:BindUEActor failed, the pUEActor is nil")
        return nil
    end

    tbGameObject:BindUEActor(pUEActor)
    self:BindUniqueId(tbGameObject.nUniqueId, tbGameObject)
    return tbGameObject
end

function GameObjectSystem:UnbindUEActor(tbGameObject, nUniqueId)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem:UnbindUEActor failed, the gameobject is ni")
        return nil
    end

    self:UnbindUniqueId(tbGameObject.nUniqueId or nUniqueId)

    if(tbGameObject.nUniqueId ~= nil) then
        --log("GameObjectSystem:UnbindUEActor", tbGameObject.nUniqueId)
        tbGameObject:UnbindUEActor()
    end
    return tbGameObject
end

function GameObjectSystem:RestoreUEActor(tbGameObject, tbCreateData, tbCustomData)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem:RestoreUEActor failed, the gameobject is nil")
        return nil
    end
    if(tbGameObject:GetModelActor()) then
        self:UnbindUniqueId(tbGameObject:GetUEActorUniqueId())
    end

    if(not tbGameObject:RestoreUEActor(tbCreateData, tbCustomData)) then
        return nil
    end

    -- 会在beginplay里bind，所以这里不再bind了
    -- if(tbGameObject:GetUEActorUniqueId()) then
    --     self:BindUniqueId(tbGameObject:GetUEActorUniqueId(), tbGameObject)
    -- end
    return tbGameObject
end

function GameObjectSystem:DestroyUEActorByServerId(nServerInstanceId)
    local tbGameObject = self:FindByInstanceId(nServerInstanceId)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem:DestroyUEActorByServerId failed, cannot find gameobject by id,", nServerInstanceId)
        return nil
    end
    return self:DestroyUEActor(tbGameObject)
end

function GameObjectSystem:DestroyUEActor(tbGameObject)
    if(tbGameObject == nil) then
        logerror("GameObjectSystem:DestroyUEActor failed, object is nil")
        return nil
    end
    log("GameObjectSystem:DestroyUEActor, UniqueId = ", tbGameObject:GetUEActorUniqueId())
    self:UnbindUniqueId(tbGameObject:GetUEActorUniqueId())
    tbGameObject:DestroyUEActor()
    return tbGameObject
end

function GameObjectSystem:BindPlayerUEController(tbGamePlayerSelf, pController,
    nControllerNetGuid, nControllerUniqueId, tbInitProtoData)

    self:UnbindPlayerUEController(tbGamePlayerSelf)
    log("GameObjectSystem:BindPlayerUEController", nControllerNetGuid, nControllerUniqueId)
    tbGamePlayerSelf:BindUEController(pController, nControllerNetGuid, nControllerUniqueId, tbInitProtoData)
    self:BindUniqueId(nControllerUniqueId, tbGamePlayerSelf)
end

function GameObjectSystem:UnbindPlayerUEController(tbGamePlayerSelf)
    local nControllerUniqueId = tbGamePlayerSelf:GetUEControllerUniqueId()
    log("GameObjectSystem:UnbindPlayerUEController", nControllerUniqueId)
    self:UnbindUniqueId(nControllerUniqueId)
    tbGamePlayerSelf:UnbindUEController()
end

function GameObjectSystem:GetAllGameObjects()
    return self.tbMapByInstanceId
end

function GameObjectSystem:GetAllByObjectType(nGameObjectType)
    return self.tbMapByObjectType[nGameObjectType]
end

function GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
    -- local tbMap = self.tbMapByInstanceId
    -- for _, tbObject in pairs(tbMap) do
    --     if(tbObject.nPlayerId == nPlayerId) then
    --         return tbObject
    --     end
    -- end
    local tbObjects
    tbObjects = self.tbMapByObjectType[GameObjectTypeDef.PlayerSelf]
    for tbObject, _ in pairs(tbObjects) do
        if(tbObject.nPlayerId == nPlayerId) then
            return tbObject
        end
    end
    tbObjects = self.tbMapByObjectType[GameObjectTypeDef.PlayerOther]
    for tbObject, _ in pairs(tbObjects) do
        if(tbObject.nPlayerId == nPlayerId) then
            return tbObject
        end
    end
    return nil
end

local function GenerateDungeonInstanceId()
    DungeonInstanceId = DungeonInstanceId + 1
    return DungeonInstanceId
end

------------------------------------------------------------------------------------
-- Player
function GameObjectSystem:CreatePlayerSelfInGameMode(tbPrepareInfo, pController,
    nControllerNetGuid, nControllerUniqueId, bIsSpectator)

    -- local tbPlayerSelf = self:FindByInstanceId(nControllerNetGuid)
    -- if(tbPlayerSelf) then
    --     logerror("GameObjectSystem:CreatePlayerSelfInGameMode failed, duplicated controller netguid,", nControllerNetGuid)
    --     return nil
    -- end

    local nServerInstanceId = GenerateDungeonInstanceId()
    log("GameObjectSystem:CreatePlayerSelfInGameMode", nControllerNetGuid, nServerInstanceId)
    -- OnlyServerMode，永远是新PlayerSelf
    local tbSpawnInfo = {}
    tbSpawnInfo.bCreateUEActor = false
    local tbCreateData = GOCreateDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, nServerInstanceId, tbSpawnInfo)
    local tbCustomData = GOCustomDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbCreateData.tbInitProtoData)

    local tbPlayerSelf = self:Create(GameObjectTypeDef.PlayerSelf, tbCreateData, tbCustomData)
    if(tbPlayerSelf == nil) then
        logerror("GameObjectSystem:CreatePlayerSelfInGameMode failed to create player self,", nControllerNetGuid)
        return nil
    end

    self:BindPlayerUEController(tbPlayerSelf, pController, nControllerNetGuid, nControllerUniqueId)

    -- 在spawncontroller这帧写入，这样第一次replicate到客户端会带上这些
    local tbPlayerControllerInitData =
    {
        script_type = GameObjectTypeDef.PlayerController,
        player_id = tbPrepareInfo.nPlayerId,
    }
    GOCustomDataHelper:ParsePlayerSelfControllerData(tbPlayerSelf, tbPlayerControllerInitData)

    self.pDungeonCommonActorShell:SetControllerReplicatedInitData(pController,
        DungeonCommonProtoNames.PlayerControllerInitData,
        exposetable(tbPlayerControllerInitData),
        nServerInstanceId)
    return tbPlayerSelf
end

function GameObjectSystem:RestorePlayerSelf(tbPlayer,pController,nControllerNetGuid,nControllerUniqueId)
    self:BindPlayerUEController(tbPlayer, pController, nControllerNetGuid, nControllerUniqueId)

    local tbPlayerControllerInitData =
    {
        script_type = GameObjectTypeDef.PlayerController,
        player_id = tbPlayer.nPlayerId
    }
    local nServerInstanceId = tbPlayer.nServerInstanceId
    local tbTemp = self:FindByInstanceId(nServerInstanceId)

    log("RestorePlayerSelf nControllerUniqueId:",nControllerUniqueId,",player_id:",tbPlayer.nPlayerId)
    log("RestorePlayerSelf nControllerNetGuid:",nControllerNetGuid,",nServerInstanceId:",nServerInstanceId,",FindObject:",(tbTemp and "True" or "False"))
    GOCustomDataHelper:ParsePlayerSelfControllerData(tbPlayer, tbPlayerControllerInitData)

    self.pDungeonCommonActorShell:SetControllerReplicatedInitData(pController,
        DungeonCommonProtoNames.PlayerControllerInitData,
        exposetable(tbPlayerControllerInitData),
        nServerInstanceId)
end

function GameObjectSystem:DestroyPlayerSelfInGameMode(nServerInstanceId)
    log("GameObjectSystem:DestroyPlayerSelfInGameMode", nServerInstanceId)
    self:DestroyByInstanceId(nServerInstanceId)
end

-- SpawnDefaultPawn时用
function GameObjectSystem:SpawnPlayerSelfUEActorInGameMode(tbPlayerSelf, tbPrepareInfo, tbSpawnInfo, bPossess)
    if(tbPlayerSelf == nil) then
        logerror("GameObjectSystem:RestoreUEActorInGameMode failed, the player self is nil")
        return false
    end

    log("GameObjectSystem:RestoreUEActorInGameMode")
    local tbCreateData = GOCreateDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, tbPlayerSelf:GetServerInstanceId(), tbSpawnInfo)
    local tbCustomData = GOCustomDataHelper:ParsePlayerSelfGameModeData(tbPrepareInfo, tbSpawnInfo, tbCreateData.tbInitProtoData)
    if(not self:RestoreUEActor(tbPlayerSelf, tbCreateData, tbCustomData)) then
        return false
    end

    if(bPossess) then
        self:PossessPlayerSelf(tbPlayerSelf)
    end

    return true
end

function GameObjectSystem:PossessPlayerSelf(tbPlayerSelf)
    local pController = tbPlayerSelf:GetUEController()
    if(pController == nil) then
        logerror("GameObjectSystem:SpawnPlayerSelfUEActorInGameMode failed, the controller is nil", tbPlayerSelf.nPlayerId, debug.traceback( ))
        return false
    end

    log("GameObjectSystem:PossessPlayerSelf", tbPlayerSelf.nPlayerId)
    pController:Possess(tbPlayerSelf:GetModelActor())
    return true
end

------------------------------------------------------------------------------------
-- Npc bCreateAI - nil 默认创建; szName - nil 使用配置表中名称; bCreateUEActor - nil 默认创建
--function GameObjectSystem:CreateNpcInGameMode(nTemplateId, nX, nY, nZ, nYaw, nGroupIndex, szTag, tbJsonData, bCreateAI, szName, bCreateUEActor)
function GameObjectSystem:CreateNpcInGameMode(tbSpawnInfo)
    local nServerInstanceId = GenerateDungeonInstanceId()
    log("GameObjectSystem:CreateNpcInGameMode", nServerInstanceId, tbSpawnInfo.nTemplateId, tbSpawnInfo.nGroupIndex, tbSpawnInfo.szTag, tbSpawnInfo.szName)
    local tbCreateData = GOCreateDataHelper:ParseNpcGameModeData(nServerInstanceId, tbSpawnInfo)
    local tbCustomData = GOCustomDataHelper:ParseNpcGameModeData(tbSpawnInfo, tbCreateData.tbInitProtoData)
    local tbGameObject = self:Create(GameObjectTypeDef.Npc, tbCreateData, tbCustomData)
    return tbGameObject
end

function GameObjectSystem:DestroyNpcInGameMode(nUniqueId)
    log("GameObjectSystem:DestroyNpcInGameMode", nUniqueId)
    self:DestroyByUniqueId(nUniqueId)
end

function GameObjectSystem:SpawnNpcUEActorInGameMode(tbNpc, tbSpawnInfo, tbCustomData)
    log("GameObjectSystem:SpawnNpcUEActorInGameMode")
    local nServerInstanceId = tbNpc:GetServerInstanceId()
    local tbCreateData = GOCreateDataHelper:ParseNpcGameModeData(nServerInstanceId, tbSpawnInfo)
    if(tbCustomData == nil) then
        tbCustomData = GOCustomDataHelper:ParseNpcGameModeData(tbSpawnInfo, tbCreateData.tbInitProtoData)
    end
    return self:RestoreUEActor(tbNpc, tbCreateData, tbCustomData)
end

-- function GameObjectSystem:SpawnNpcUEActorInGameMode(tbNpc, nX, nY, nZ, nYaw, tbJsonData, bCreateAI)
--     if(tbNpc == nil) then
--         logerror("GameObjectSystem:SpawnNpcUEActorInGameMode failed, npc is nil")
--         return false
--     end

--     log("GameObjectSystem:SpawnNpcUEActorInGameMode")
--     local tbCreateData = GOCreateDataHelper:ParseNpcGameModeData(tbNpc:GetServerInstanceId(), tbNpc.nTemplateId, nX, nY, nZ, nYaw, tbNpc.nGroupIndex, tbNpc.szTag, tbJsonData, tbNpc.szName)
--     local tbCustomData = GOCustomDataHelper:ParseNpcGameModeData(tbNpc.nTemplateId, tbJsonData, tbCreateData.tbInitProtoData, bCreateAI)
--     if(not self:RestoreUEActor(tbNpc, tbCreateData, tbCustomData)) then
--         return false
--     end
--     return true
-- end

function GameObjectSystem:DestroyNpcInGameModeByInstanceId(nInstanceId)
    log("GameObjectSystem:DestroyNpcInGameModeByInstanceId", nInstanceId)
    self:DestroyByInstanceId(nInstanceId)
end

------------------------------------------------------------------------------------
-- Trigger
function GameObjectSystem:CreateTriggerInGameMode(tbSpawnInfo)
    --log("GameObjectSystem:CreateTriggerInGameMode")
    local tbCreateData = GOCreateDataHelper:ParseTriggerGameModeData(GenerateDungeonInstanceId(), tbSpawnInfo)
    local tbCustomData = GOCustomDataHelper:ParseTriggerGameModeData(tbSpawnInfo, tbCreateData.tbInitProtoData)
    local tbGameObject = self:Create(GameObjectTypeDef.Trigger, tbCreateData, tbCustomData)
    return tbGameObject
end

function GameObjectSystem:DestroyTriggerInGameMode(nUniqueId)
    log("GameObjectSystem:DestroyTriggerInGameMode", nUniqueId)
    self:DestroyByUniqueId(nUniqueId)
end

function GameObjectSystem:DestroyTriggerInGameModeByInstanceId(nInstanceId)
    log("GameObjectSystem:DestroyTriggerInGameModeByInstanceId", nInstanceId)
    self:DestroyByInstanceId(nInstanceId)
end

------------------------------------------------------------------------------------
-- Dummy
function GameObjectSystem:CreateDummyInGameMode(nTemplateId, tbTransform, tbScale, szTag, tbJsonData)
    log("GameObjectSystem:CreateDummyInGameMode", nTemplateId)
    local tbCreateData = GOCreateDataHelper:ParseDummyGameModeData(GenerateDungeonInstanceId(), nTemplateId, tbTransform, tbScale, szTag)
    local tbCustomData = GOCustomDataHelper:ParseDummyGameModeData(nTemplateId, tbJsonData, tbCreateData.tbInitProtoData)
    local GameDummy = self:Create(GameObjectTypeDef.Dummy, tbCreateData, tbCustomData)
    return GameDummy
end

function GameObjectSystem:DestroyDummyInGameMode(nUniqueId)
    log("GameObjectSystem:DestroyDummyInGameMode", nUniqueId)
    self:DestroyByUniqueId(nUniqueId)
end

function GameObjectSystem:DestroyDummyInGameModeByInstanceId(nInstanceId)
    log("GameObjectSystem:DestroyDummyInGameModeByInstanceId", nInstanceId)
    self:DestroyByInstanceId(nInstanceId)
end

function GameObjectSystem:CreateVehicleInGameMode(nTemplateId, VehicleType, tbTransform, tbScaleg, tbJsonData)
    local tbCreateData = GOCreateDataHelper:ParseVehicleGameModeData(GenerateDungeonInstanceId(), nTemplateId, VehicleType, tbTransform)
    local tbCustomData = GOCustomDataHelper:ParseDummyGameModeData(nTemplateId, tbJsonData, tbCreateData.tbInitProtoData)
    local GameVehicle = self:Create(VehicleType, tbCreateData, tbCustomData)
    return GameVehicle
end


------------------------------------------------------------------------------------
-- Destructible
function GameObjectSystem:CreateDestructibleObjectInGameMode(nTemplateId, tbTransform, tbScale, tbJsonData)
    log("GameObjectSystem:CreateDestructibleObjectInGameMode", nTemplateId)
    local tbCreateData = GOCreateDataHelper:ParseDestructibleObjectGameModeData(GenerateDungeonInstanceId(), nTemplateId, tbTransform, tbScale, tbJsonData)
    local tbCustomData = GOCustomDataHelper:ParseDestructibleObjectGameModeData(nTemplateId, tbJsonData, tbCreateData.tbInitProtoData)
    local GameDestructibleObject = self:Create(GameObjectTypeDef.DestructibleObject, tbCreateData, tbCustomData)
    return GameDestructibleObject
end

function GameObjectSystem:DestroyDestructibleObjectInGameModeByInstanceId(nInstanceId)
    log("GameObjectSystem:DestroyDestructibleObjectnGameModeByInstanceId", nInstanceId)
    self:DestroyByInstanceId(nInstanceId)
end

------------------------------------------------------------------------------------
-- Util Function
function GameObjectSystem:IsCharacter(tbObject)
    if tbObject
    and ((tbObject.ObjectType == GameObjectTypeDef.PlayerSelf)
    or (tbObject.ObjectType == GameObjectTypeDef.Npc and (tbObject:GetNpcType() ~= GameNpcType.BattleCollection))
    or (tbObject.ObjectType == GameObjectTypeDef.PlayerOther)) then
        return true
    end
    return false
end

function GameObjectSystem:IsVehicle(tbObject)
    if tbObject
    and ((tbObject.ObjectType == GameObjectTypeDef.Horse)) then
        return true
    end
    return false
end

return GameObjectSystem
