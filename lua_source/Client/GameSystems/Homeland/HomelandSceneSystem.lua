-----------------------------------------------------
--File Name    : HomelandSceneSystem.lua
--Author       : Ran Jie
--Create Time  : 2019-04-15
--Description  : 家园场景系统
-----------------------------------------------------
local SelfEventHelper = require("SelfEventHelper")

local SpawnerSystem = dynamic_require("SpawnerSystem")
local HomelandSceneDataTable = require("HomelandSceneDataTable")
local SpawnerDef = require("SpawnerDef")
local SceneResDataTable = require("SceneResDataTable")
local HomelandSystem = require("HomelandSystem")
local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BuildingDataTable = require("BuildingDataTable")
local BlockTypeDataTable = require("BlockTypeDataTable")
local BuildingRotationDataTable = require("BuildingRotationDataTable")
local HomelandIni = require("HomelandIni")
local ResourceManager = require("ResourceManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local UEActorHelper = require("UEActorHelper")
local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local ShipSkinItemDataTableHelper = require("ShipSkinItemDataTableHelper")

local HomelandSceneSystem = {}

local HOMELAND_OBJ_START_ID = -10000
-- local BUILDING_ROTATOR = Rotator{Pitch = 0, Yaw = 0, Roll = 0}
local GET_ACTOR_UNIQUE_ID_FUNC = EngineExtActorShell.GetActorUniqueId
local BLOCK_COLOR_INDEX_NOT_BOUGHT = 0
local BLOCK_COLOR_INDEX_LANDMARK = 1
local BLOCK_COLOR_INDEX_DECORATION = 2
local DEFAULT_TRIGGER_BOX_Z = 20

HomelandSceneSystem.nGenerateInstanceId = HOMELAND_OBJ_START_ID
HomelandSceneSystem.tbDescriptor = nil
HomelandSceneSystem.tbAllSpawners = nil
HomelandSceneSystem.tbAllFieldMap = nil
HomelandSceneSystem.tbLoadedSubLevel = nil
HomelandSceneSystem.tbBuildingHandle = nil
HomelandSceneSystem.tbTriggerDelegates = nil

local pShipArtActor = nil

-------------------------私有方法------------------------------
local function SetPlayerStart(self, bSwitch)
    if not self.tbDescriptor or not self.tbDescriptor.tbPlayerStarts then
        return
    end
    local tbPlayerStartTransform

    if bSwitch then
        local tbPlayerStartData = self.tbDescriptor.tbHQPlayerStarts[1]
        tbPlayerStartTransform = tbPlayerStartData.Transform
    else
        local tbPlayerStartData = self.tbDescriptor.tbPlayerStarts[1]
        tbPlayerStartTransform = tbPlayerStartData.Transform
    end
    local tbSelfObj = GamePlayerSelfHelper:Get()
    tbSelfObj:SetLocation(tbPlayerStartTransform.X, tbPlayerStartTransform.Y, tbPlayerStartTransform.Z)
end

local function GetBlockActor(self, nBlockId)
    local tbBlockGameObj = self.tbAllFieldMap[nBlockId]
    if tbBlockGameObj then
        return tbBlockGameObj.pUEActor
    end
end

local function GenerateInstanceId(self)
    self.nGenerateInstanceId = self.nGenerateInstanceId + 1
    return self.nGenerateInstanceId
end

local function DestroyAllSpawner(self)
    if self.tbAllSpawners then
        for k, v in ipairs(self.tbAllSpawners) do
            SpawnerSystem:DestroySpawner(v)
        end
    end
    self.tbAllSpawners = {}
end

local function OnSubLevelLoaded(self)
    if self.pStreamingLevelLoadedDelegate then
        self.EventHelper:UnregisterCppDelegate(self.pStreamingLevelLoadedDelegate)
        self.pStreamingLevelLoadedDelegate = nil
    end
    log("HomelandSceneSystem:OnSubLevelLoaded")
end

local function LoadSubLevel(self, nHomelandSceneId)
    if self.tbLoadedSubLevel[nHomelandSceneId] or self.pStreamingLevelLoadedDelegate then
        return false
    end
    local tbHomelandTemplate = HomelandSceneDataTable:GetSceneTemplate(nHomelandSceneId)
    if not tbHomelandTemplate then
        return false
    end
    local tbSceneResTemplate = SceneResDataTable:GetTemplate(tbHomelandTemplate.nSubLevelResId)
    if not tbSceneResTemplate then
        return false
    end
    self.tbLoadedSubLevel[nHomelandSceneId] = true
    local pClientShell = ClientShell.GetClient(GWorld)
    self.pStreamingLevelLoadedDelegate = self.EventHelper:RegisterCppDelegate(pClientShell.OnSubLevelLoadEnd, self, OnSubLevelLoaded)
    --pClientShell:ToggleSceneRendering(true)
    LowEntryExtendedStandardLibrary.SetWorldRenderingEnabled(true)
    ClientShell.GetClient(GWorld):FlushAsyncLoading()
    local szLevelPath = tbSceneResTemplate.szPath
    szLevelPath:load()
    ClientShell.GetClient(GWorld):LoadStreamLevel(GWorld, szLevelPath)

    return true
end

local function OnActorEnter(self, pInUEActor, nInTriggerId, nBlockId)
    log("HomelandSceneSystem:OnActorEnter,nBlockId=",nBlockId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(GET_ACTOR_UNIQUE_ID_FUNC(pInUEActor))
    if tbGameObject and tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_BLOCK_ENTER, nBlockId)
    end
end

local function OnActorLeave(self, pInUEActor, nInTriggerId, nBlockId)
    log("HomelandSceneSystem:OnActorLeave,nBlockId=",nBlockId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(GET_ACTOR_UNIQUE_ID_FUNC(pInUEActor))
    if tbGameObject and tbGameObject:GetObjectType() == GameObjectTypeDef.PlayerSelf then
        self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_BLOCK_LEAVE, nBlockId)
    end
end

local function RegisterTriggerEvent(self, nBlockId, pUEActor)
    local tbBlockTriggerDelegates = self.tbTriggerDelegates[nBlockId]
    if tbBlockTriggerDelegates then
        return
    end
    tbBlockTriggerDelegates = {}
    self.tbTriggerDelegates[nBlockId] = tbBlockTriggerDelegates
    tbBlockTriggerDelegates.EnterDelegate = self.EventHelper:RegisterCppDelegateFunc(pUEActor.OnActorEnter, function(pInUEActor, nInTriggerId)
        OnActorEnter(self, pInUEActor, nInTriggerId, nBlockId)
    end)
    tbBlockTriggerDelegates.LeaveDelegate = self.EventHelper:RegisterCppDelegateFunc(pUEActor.OnActorLeave, function(pInUEActor, nInTriggerId)
        OnActorLeave(self, pInUEActor, nInTriggerId, nBlockId)
    end)
end

local function UnRegisterTriggerEvent(self, nBlockId)
    local tbBlockTriggerDelegates = self.tbTriggerDelegates[nBlockId]
    if tbBlockTriggerDelegates then
        self.EventHelper:UnregisterCppDelegate(tbBlockTriggerDelegates.EnterDelegate)
        self.EventHelper:UnregisterCppDelegate(tbBlockTriggerDelegates.LeaveDelegate)
        self.tbTriggerDelegates[nBlockId] = nil
    end
end

local function ClearEventRegister(self)
    self.EventHelper:UnregisterAll()
    self.tbTriggerDelegates = {}
end
-- tbBlockData.nBlockId = 1
-- tbBlockData.nBlockType = 1
-- tbBlockData.bIsLandmark = true
-- tbBlockData.bCanPlaceBuilding = true
-- tbBlockData.bUnlock = true
-- tbBlockData.bBought = true
-- tbBlockData.nBuildingId = 1
-- tbBlockData.nItemInstanceId = 1
-- tbBlockData.nRotationId = 1
local function LoadBlock(self, tbDescriptor, nHomelandSceneId)
    local tbHomelandBlock = tbDescriptor.HomelandBlock
    if not tbHomelandBlock then
        return
    end
    local tbCurSceneData = HomelandSystem:GetCurrentSceneData()
    for nBlockId, v in pairs(tbCurSceneData) do
        local tbBlockDescriptorData = tbHomelandBlock[nBlockId]
        if tbBlockDescriptorData then
            --地块
            local nLength = 1
            local nWidth = 1
            local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(v.nBlockType)
            if tbBlockTypeTemplate then
                nLength = tbBlockTypeTemplate.nLength
                nWidth = tbBlockTypeTemplate.nWidth
                local tbShapeData = tbBlockDescriptorData.Shape
                tbShapeData.BoxX = nLength * 100 / 2 + HomelandIni.tbScene.nTriggerExtension
                tbShapeData.BoxY = nWidth * 100 / 2 + HomelandIni.tbScene.nTriggerExtension
                tbShapeData.BoxZ = DEFAULT_TRIGGER_BOX_Z
            end
            tbBlockDescriptorData.nGenerateInstanceId = GenerateInstanceId(self)
            local tbSpawner, tbGameObj = SpawnerSystem:CreateSpawner(SpawnerDef.SpawnerType.HOMELAND_BLOCK, tbBlockDescriptorData, true)
            local pUEActor = tbGameObj.pUEActor
            pUEActor:SetScale(nLength, nWidth)

            if v.bUnlock then
                RegisterTriggerEvent(self, nBlockId, pUEActor)
            end
            self.tbAllFieldMap[nBlockId] = tbGameObj
            table.insert(self.tbAllSpawners, tbSpawner)
        else
            logerror("HomelandSceneSystem:LoadBlockAndBuildings, not find tbBlockDescriptorData, nBlockId= "..nBlockId)
        end
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_LOADED)
end

local function LoadBuilding(self, nBlockId, nBuildingTemplateId, bPreview)
    local pUEActor = GetBlockActor(self, nBlockId)
    if not pUEActor then
        logerror("HomelandSceneSystem:LoadBuilding, not find Block actor, "..nBlockId)
        return
    end
    local tbBuildingTemplate = BuildingDataTable:GetTemplate(nBuildingTemplateId)
    if tbBuildingTemplate then
        local tbBuildingHandle = self.tbBuildingHandle[nBlockId]
        if tbBuildingHandle then
            if tbBuildingHandle.nBuildingTemplateId == nBuildingTemplateId then
                pUEActor:SetBuildActorPreview(bPreview)
                return
            end
            local nHandle = tbBuildingHandle.nHandle
            ResourceManager:CancelLoadAsync(nHandle)
        else
            tbBuildingHandle = {}
            self.tbBuildingHandle[nBlockId] = tbBuildingHandle
        end
        local nHandle = ResourceManager:LoadAsync(tbBuildingTemplate.szModelRes, function(szTempAssetName, pBuildingObj, nHandle)
            pUEActor:SetBuildingActor(pBuildingObj, bPreview)
            pUEActor:SetBuildActorPreview(bPreview)
            self.EventHelper:FireEvent(ClientEventDef.EV_HOMELAND_BUILDING_LOADED, nBuildingTemplateId, nBlockId)
        end, true)
        tbBuildingHandle.nBuildingTemplateId = nBuildingTemplateId
        tbBuildingHandle.nHandle = nHandle
    end
end

local function LoadBuildings(self, tbDescriptor, nHomelandSceneId)
    local tbCurSceneData = HomelandSystem:GetCurrentSceneData()
    for nBlockId, v in pairs(tbCurSceneData) do
        LoadBuilding(self, nBlockId, v.nBuildingId, false)
        self:ChangeBuildingRotaion(nBlockId, v.nRotationId)
    end
end

local function RandomShip(self)
    local ShipPreparationComponent = GamePlayerSelfHelper:Get().ShipPreparationComponent
    local tbCandidateShipIds = {}
    local tbEquippedShipIds = ShipPreparationComponent:GetEquippedShipIds()
    for k, v in pairs(tbEquippedShipIds) do
        table.insert(tbCandidateShipIds, v)
    end

    local tbShipTemplateMap = ItemSystem:GetItemTemplatesByCategory(ItemCategoryDef.SHIP)
    for i, v in pairs(tbShipTemplateMap) do
        if v.bDefaultEquipped then
            table.insert(tbCandidateShipIds, v.nId)
        end
    end
    local nRandomIdx = math.random(1, #tbCandidateShipIds)
    local nTemplateId = tbCandidateShipIds[nRandomIdx]
    return nTemplateId
end

local function UpdateShipState(self)
    local tbDescriptor = self.tbDescriptor
    if not tbDescriptor.tbShipPosition or not tbDescriptor.tbShipPosition[1] then
        logwarning("tbShipPosition is nil")
        return
    end
    local tbShipPosition = tbDescriptor.tbShipPosition[1]
    local tbShipTransform = tbShipPosition.Transform
    local pLocation = Vector{X = tbShipTransform.X, Y = tbShipTransform.Y, Z = tbShipTransform.Z}
    UEActorHelper:SetActorLocation(pShipArtActor, pLocation)
    local pRotation = UEActorHelper:GetActorRotation(pShipArtActor)
    pRotation.Yaw = tbShipTransform.Yaw
    UEActorHelper:SetActorRotation(pShipArtActor, pRotation)
    pShipArtActor:SetPosture(EShipPosture.Reef)
end

local function SpawnShip(nTemplateId)
    local ShipPreparationComponent = GamePlayerSelfHelper:Get().ShipPreparationComponent
    local nSkinId = ShipPreparationComponent:GetEquippedShipSkinId(nTemplateId)
    local szModel = ShipSkinItemDataTableHelper.GetSkinModel(nSkinId)
    log(string.format("Homeland spawn ship, nTemplateId : %d, nSkinId : %d", nTemplateId, nSkinId))
    assert(szModel)
    local pModel = szModel:load()
    local pShipActor = UEActorHelper:CreateActorByClass(pModel, Transform(), nil)
    local pActor = UEActorHelper:CreateActorByClass(pShipActor.ShipModel.ChildActorClass, Transform(), nil)
    UEActorHelper:DestroyActor(pShipActor)
    return pActor
end

local function SpawnRandomShip(self)
    local nShipTemplateId = RandomShip(self)
    pShipArtActor = SpawnShip(nShipTemplateId)
    UpdateShipState(self)
    pShipArtActor:SetActorHiddenInGame(true)
end

local function OnHomelandEnterMatineeFinished(self)
    pShipArtActor:SetActorHiddenInGame(false)
end

function HomelandSceneSystem:GetRandomShipActor()
    return pShipArtActor
end

function HomelandSceneSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    self.nGenerateInstanceId = HOMELAND_OBJ_START_ID
    self.tbAllSpawner = {}
    self.tbAllFieldMap = {}
    self.tbLoadedSubLevel = {}
    self.tbBuildingHandle = {}
    self.tbTriggerDelegates = {}
    self.EventHelper:RegisterEvent(ClientEventDef.EV_HOMELAND_ENTER_MATINEE_FINISHED, self, OnHomelandEnterMatineeFinished)
    return true
end

function HomelandSceneSystem:Uninit()
    ClearEventRegister(self)
    for k, v in pairs(self.tbBuildingHandle) do
        ResourceManager:CancelLoadAsync(v)
    end
    self.tbAllSpawner = {}
    self.tbAllFieldMap = {}
    self.tbLoadedSubLevel = {}
    self.tbBuildingHandle = {}
end

------------------------------外部调用接口---------------------------------------
--加载家园场景数据
function HomelandSceneSystem:LoadSceneData(nHomelandSceneId, bSwitch)
    local nSceneId = nHomelandSceneId
    if not nSceneId then
        nSceneId = HomelandIni.tbScene.nDefaultSceneId
    end
    local tbDescriptor = HomelandSceneDataTable:GetSceneDescriptor(nSceneId)
    if not tbDescriptor then
        logerror("HomelandSceneSystem:LoadSceneData, tbDescriptor is nil, not find field export data, nHomelandSceneId=",nHomelandSceneId)
        return
    end
    self.tbDescriptor = tbDescriptor
    ClearEventRegister(self)
    --销毁旧的家园数据
    DestroyAllSpawner(self)
    --玩家初始位置
    SetPlayerStart(self, bSwitch)
    --加载家园sublevel
    LoadSubLevel(self, nSceneId)
    --加载地块
    LoadBlock(self, tbDescriptor, nHomelandSceneId)
    --加载建筑物、装饰物
    LoadBuildings(self, tbDescriptor, nHomelandSceneId)
    -- 码头随机船
    SpawnRandomShip(self)
end

--预览建筑物/装饰物
function HomelandSceneSystem:PreviewBuilding(nBlockId, nBuildingTemplateId)
    LoadBuilding(self, nBlockId, nBuildingTemplateId, true)
end

--建造建筑物/装饰物
function HomelandSceneSystem:CreateBuilding(nBlockId, nBuildingTemplateId)
    LoadBuilding(self, nBlockId, nBuildingTemplateId, false)
end

--移除地块上的建筑物
function HomelandSceneSystem:RemoveBuilding(nBlockId)
    local tbBuildingHandle = self.tbBuildingHandle[nBlockId]
    if tbBuildingHandle then
        ResourceManager:CancelLoadAsync(tbBuildingHandle.nHandle)
        self.tbBuildingHandle[nBlockId] = nil
    end
    local pUEActor = GetBlockActor(self, nBlockId)
    if pUEActor then
        pUEActor:SetBuildingActor(nil, false)
    end
end

--改变建筑物朝向
function HomelandSceneSystem:ChangeBuildingRotaion(nBlockId, nRotationId)
    local pUEActor = GetBlockActor(self, nBlockId)
    nRotationId = nRotationId == nil and 1 or nRotationId
    local tbTemplate = BuildingRotationDataTable:GetTemplate(nRotationId)
    if pUEActor then
        pUEActor:SetBuildingRotation(Rotator{Pitch = 0, Yaw = tbTemplate.nYaw, Roll = 0})
    end
end

--设置地块是否可交互
function HomelandSceneSystem:SetBlockEnable(nBlockId, bEnable)
    local pUEActor = GetBlockActor(self, nBlockId)
    if pUEActor then
        if bEnable then
            RegisterTriggerEvent(self, nBlockId, pUEActor)
        else
            UnRegisterTriggerEvent(self, nBlockId)
        end
        pUEActor:SetCollisionEnabled(bEnable)

    end
end

--设置地块是否可见
function HomelandSceneSystem:ShowBlock(nBlockId, bShow)
    local tbBlockData = HomelandSystem:GetBlockData(nBlockId)
    local pUEActor = GetBlockActor(self, nBlockId)
    if pUEActor and tbBlockData then
        pUEActor:ShowBlock(bShow)
        if tbBlockData.bCanPlaceBuilding then
            local nColorIndex = BLOCK_COLOR_INDEX_NOT_BOUGHT
            if not tbBlockData.bBought then
                nColorIndex = BLOCK_COLOR_INDEX_NOT_BOUGHT
            elseif tbBlockData.bIsLandmark then
                nColorIndex = BLOCK_COLOR_INDEX_LANDMARK
            else
                nColorIndex = BLOCK_COLOR_INDEX_DECORATION
            end
            pUEActor:SetColor(nColorIndex)
        end
    end
end

--进入家园场景时获得玩家默认位置
function HomelandSceneSystem:GetDefaultPlayerStart()
    local tbDescriptor = HomelandSceneDataTable:GetSceneDescriptor(HomelandIni.tbScene.nDefaultSceneId)
    if not tbDescriptor or not tbDescriptor.tbPlayerStarts then
        return
    end

    local tbPlayerStartData = tbDescriptor.tbPlayerStarts[1]
    local tbPlayerStartTransform = tbPlayerStartData.Transform
    local tbTransform = {}
    tbTransform.x = tbPlayerStartTransform.X
    tbTransform.y = tbPlayerStartTransform.Y
    tbTransform.z = tbPlayerStartTransform.Z
    tbTransform.yaw = tbPlayerStartTransform.Yaw
    return tbTransform
end

--获取某个地块
function HomelandSceneSystem:GetBlock(nBlockId)
    return self.tbAllFieldMap[nBlockId]
end

return HomelandSceneSystem