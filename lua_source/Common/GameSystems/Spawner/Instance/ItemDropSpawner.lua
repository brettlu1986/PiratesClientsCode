local luaclass = require("luaclass")
local SpawnerBaseClass = require("SpawnerBase")
local ItemDropSpawner = luaclass("ItemDropSpawner", SpawnerBaseClass)

local BattleTransformPointHelper = require("BattleTransformPointHelper")
local BattleItemSystemServer = require("BattleItemSystemServer")
local SelectionPointHelper = require("SelectionPointHelper")
local BattleItemDropSystem = require("BattleItemDropSystem")
local SceneItemActorDef = require("SceneItemActorDef")
local SceneItemHelper = require("SceneItemHelper")
local ResourceManager = require("ResourceManager")
local CDSpawnHelper = require("CDSpawnHelper")
local SpawnerDef = require("SpawnerDef")
local FFAItemIni = require("FFAItemIni")
local BaseUtil = require("BaseUtil")
local Timer = require("Timer")

ItemDropSpawner.nSpawnerId         = nil
ItemDropSpawner.nDropGroupId       = nil
ItemDropSpawner.bAutoSpawn         = nil
ItemDropSpawner.tbGroup            = nil
ItemDropSpawner.tbItemData         = nil
ItemDropSpawner.tbSceneItemDataMap = nil

--定时刷新物品
ItemDropSpawner.bCDSpawnEnable       = nil
ItemDropSpawner.nSpawnCDTime         = nil
ItemDropSpawner.tbSpawnedInstanceIds = nil
ItemDropSpawner.tbCDSpawnTimer       = nil

local szBPGameUtility = "/Game/Game/Misc/BP_GameUtility.BP_GameUtility_C"

local TYPE_OCEAN = EPiratesGridRegionType.Ocean
local TYPE_PORT = EPiratesGridRegionType.Port

local EMPTY_TABLE = {}
local TEMP_VECOTR = Vector()
local FLOOR_Z_MIN_OFFSET, FLOOR_Z_MAX_OFFSET = SceneItemHelper:GetFloorZMinOffset()
local GetLocationZOnStaticWorld = EngineExtActorShell.GetLocationZOnStaticWorld

local function ClearCDSpawnTimer(self)
    if self.tbCDSpawnTimer then
        self.tbCDSpawnTimer:Clear()
        self.tbCDSpawnTimer = nil
    end
end

local function CDSpawnTimeEnd(self)
    self:Spawn()
    ClearCDSpawnTimer(self)
end

local function OnItemPicked(self, nInstanceId)
    if self.tbSpawnedInstanceIds[nInstanceId] and not self.tbCDSpawnTimer then
        self.tbSpawnedInstanceIds[nInstanceId] = nil

        local bEmpty = (BaseUtil:GetTableCount(self.tbSpawnedInstanceIds) <= 0)
        if bEmpty then
            self.tbCDSpawnTimer = Timer.NewTimerMethod(self, CDSpawnTimeEnd, self.nSpawnCDTime, false)
        end
    end
end

-- tbParams 为JsonData
function ItemDropSpawner:OnCreate(tbParams)
    self.nType = SpawnerDef.SpawnerType.ITEMDROP
    self.nSpawnerId = tbParams.SpawnerId
    self.nDropGroupId = tbParams.DropGroupId
    -- self.bAutoSpawn = tbParams.AutoSpawn
    self.bAutoSpawn = false
    self.tbPointGroup = tbParams.Group
    self.tbDropGroupIdsWithCount = tbParams.DropGroupIdsWithCount
    self.nSpawnCDTime = tbParams.SpawnCDTime

    if self.nSpawnCDTime and self.nSpawnCDTime > 0 then
        self.tbSpawnedInstanceIds = {}
        self.bCDSpawnEnable = true
    end

    return true
end

function ItemDropSpawner:OnDestroy()
    ClearCDSpawnTimer(self)
    CDSpawnHelper:ItemUnBindAll(self)
end

-- 贴地，这里做是因为量比较少，如果放到SceneItemHelper那调用linecheck会太多，导致启动过慢
local function AdjustZ(tbTransform)
    if(SceneItemHelper:NeedAdjustZ(tbTransform)) then
        TEMP_VECOTR.X = tbTransform.X
        TEMP_VECOTR.Y = tbTransform.Y
        TEMP_VECOTR.Z = tbTransform.Z
        tbTransform.Z = GetLocationZOnStaticWorld(GWorld, TEMP_VECOTR, EMPTY_TABLE, FLOOR_Z_MAX_OFFSET, FLOOR_Z_MIN_OFFSET)
    end
end

-- 循环随机点，在点组中随机，随完了会重新随
local function SelectRandomPoint(self, tbRemainPoints)
    assert(tbRemainPoints ~= nil)
    if(#tbRemainPoints == 0) then
        for _, v in ipairs(self.tbPointGroup) do
            table.insert(tbRemainPoints, v)
        end
    end

    local nIndex = math.random(1, #tbRemainPoints)
    local nTransformId = tbRemainPoints[nIndex]
    table.remove(tbRemainPoints, nIndex)

    return self.tbSceneItemDataMap[nTransformId].tbItemInfos
end

-- 生成点上的道具，这里有两种规则
-- 1. 如果count为nil，则吧随出来的道具平铺到所有点上，如果铺满了一遍，那么重新再铺一遍，直到吧所有道具都分配到点上
-- 2. 如果count有值，那么先随出count个点，然后按照规则1将所有道具铺到这count个点上
local function GeneratePointItemInfos(self, tbRemainPoints, tbItemData, nCount)
    if tbItemData == nil or #tbItemData == 0 then
        return
    end

    local tbItemInfos
    if(nCount == nil) then
        -- 如果输入count为nil，那么把道具平铺到所有点上
        for _, tbItemSet in pairs(tbItemData) do
            tbItemInfos = SelectRandomPoint(self, tbRemainPoints)
            for _, ItemInfo in pairs(tbItemSet) do
                table.insert(tbItemInfos, ItemInfo)
            end
        end
    else
        local nItemCount = BaseUtil:GetTableCount(tbItemData)
        if(nItemCount < nCount) then
            nCount = nItemCount
        end

        -- 如果输入count有值，那么吧道具铺到count个点上
        -- 先随出count个点
        local tbSaved = {}
        for i=1, nCount do
            tbItemInfos = SelectRandomPoint(self, tbRemainPoints)
            table.insert(tbSaved, tbItemInfos)
        end

        -- 再把道具平铺到这些点上
        local tbRemain = {}
        for _, tbItemSet in pairs(tbItemData) do
            if(#tbRemain == 0) then
                for _, v in ipairs(tbSaved) do
                    table.insert(tbRemain, v)
                end
            end

            local nIndex = math.random(1, #tbRemain)
            tbItemInfos = tbRemain[nIndex]
            table.remove(tbRemain, nIndex)

            for _, ItemInfo in pairs(tbItemSet) do
                table.insert(tbItemInfos, ItemInfo)
            end
        end
    end
end

-- 每一个点的箱子都是分别随机的所有物品，有nCount就用，没有就用点的数量
local function GeneratePointBoxInfos(self, tbRemainPoints, nDropGroupId, nCount)
    if(nCount == nil) then
        nCount = #self.tbPointGroup
    end

    local tbItemInfos, tbItemData
    for i=1, nCount do
        tbItemInfos = SelectRandomPoint(self, tbRemainPoints)
        assert(tbItemInfos)

        tbItemData = BattleItemDropSystem:DropItems(nDropGroupId)
        if tbItemData == nil then
            error(string.format("DropItems is nill!, drop group id: %d", nDropGroupId))
        end

        for _, tbItemSet in pairs(tbItemData) do
            for _, ItemInfo in pairs(tbItemSet) do
                table.insert(tbItemInfos, ItemInfo)
            end
        end
    end
end

local function CheckSceneItemPos(GridTypeManager, pBPGameUtility, tbTransform)
    local nX, nY, nZ = tbTransform.X, tbTransform.Y, tbTransform.Z
    local nRegionType = GridTypeManager:GetRegionType(nX, nY)
    local bIsOcean =  nRegionType == TYPE_OCEAN or nRegionType == TYPE_PORT
    if bIsOcean then
        return
    end

    local bHit, pHitResult = pBPGameUtility.TraceActor(GWorld, 
        Vector{X=nX, Y=nY, Z=nZ + FFAItemIni.tbSceneItem.nCheckItemTop},
        Vector{X=nX, Y=nY, Z=nZ + 10}, 
        {},
        false, false, true, false, false, false, GWorld) 
    if bHit then
        local szName = KismetSystemLibrary.GetDisplayName(pHitResult.Actor)
        logerror(string.format("scene item valid: hit name = %s, srcpos(%f, %f, %f), hit pos(%f, %f, %f)", 
            szName,
            nX, nY, nZ,
            pHitResult.ImpactPoint.X, pHitResult.ImpactPoint.Y, pHitResult.ImpactPoint.Z))
    end            
end

local function CheckSceneItemsPos(tbSceneItemPos)
    if not FFAItemIni.tbSceneItem.bCheckItemPos then
        return
    end
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local pBPGameUtility = ResourceManager:LoadSync(szBPGameUtility, true)
    for _, v in ipairs(tbSceneItemPos) do
        CheckSceneItemPos(GridTypeManager, pBPGameUtility, v)
    end 
end

local function SpawnOnce(self, tbRemainPoints, tbItemData, nBoxTemplateId, nCount)
    local tbSceneItemDataMap = self.tbSceneItemDataMap
    for _, v in pairs(tbSceneItemDataMap) do
        v.tbItemInfos = {}
    end

    local tbSceneItemPos = {}
    if nBoxTemplateId then
        -- 宝箱
        GeneratePointBoxInfos(self, tbRemainPoints, self.nDropGroupId, nCount)
        local tbItem = nil
        for _, tbSceneItemData in pairs(tbSceneItemDataMap) do
            tbItem = BattleItemSystemServer:AddItemPackageToScene(tbSceneItemData, SceneItemActorDef.TREASURE_CHEST, nBoxTemplateId)
            if tbItem ~= nil then
                table.insert(tbSceneItemPos, tbSceneItemData.tbTransform)
            end
            SelectionPointHelper:AddResourceTransform(tbSceneItemData.tbTransform)
        end
    else
        -- 资源堆
        GeneratePointItemInfos(self, tbRemainPoints, tbItemData, nCount)
        local tbItems = nil
        for _, tbSceneItemData in pairs(tbSceneItemDataMap) do
            tbItems = BattleItemSystemServer:AddItemsToScene(tbSceneItemData)

            for _, tbItem in ipairs(tbItems) do
                if self.bCDSpawnEnable then
                    local nInstanceId = tbItem:GetInstanceId()
                    self.tbSpawnedInstanceIds[nInstanceId] = true
                    CDSpawnHelper:ItemBind(self, OnItemPicked, nInstanceId, true)
                end
                table.insert(tbSceneItemPos, tbSceneItemData.tbTransform)
            end
            SelectionPointHelper:AddResourceTransform(tbSceneItemData.tbTransform)
        end
    end

    CheckSceneItemsPos(tbSceneItemPos)
end

function ItemDropSpawner:Spawn()
    local tbPointGroup = self.tbPointGroup
    if tbPointGroup == nil or #tbPointGroup <= 0 then
        logerror("No TransformId in tbPointGroup!", self.nSpawnerId)
        return false
    end

    -- 整理transform
    local tbSceneItemDataMap = {}
    self.tbSceneItemDataMap = tbSceneItemDataMap
    for _, nTransformId in ipairs(tbPointGroup) do
        local tbTransform = BattleTransformPointHelper:Find(nTransformId)
        if(tbTransform == nil) then
            error(string.format("Invalid transform id: %d, spawnerid: %d", nTransformId, self.SpawnerId))
        end

        local tbSceneItemData = {}
        AdjustZ(tbTransform)
        tbSceneItemData = {}
        tbSceneItemData.tbTransform = tbTransform
        tbSceneItemDataMap[nTransformId] = tbSceneItemData
    end

    SceneItemHelper:SetEnableAutoAdjustLocation(false)

    local tbItemData, nBoxTemplateId
    local nDropGroupId = self.nDropGroupId
    local tbDropGroupIdsWithCount = self.tbDropGroupIdsWithCount

    local tbRemainPoints = {}
    if(nDropGroupId > 0) then
        tbItemData, nBoxTemplateId = BattleItemDropSystem:DropItems(nDropGroupId)
        SpawnOnce(self, tbRemainPoints, tbItemData, nBoxTemplateId)
    elseif(tbDropGroupIdsWithCount) then
        for _, v in ipairs(tbDropGroupIdsWithCount) do
            tbItemData, nBoxTemplateId = BattleItemDropSystem:DropItems(v.Id)
            SpawnOnce(self, tbRemainPoints, tbItemData, nBoxTemplateId, v.Count)
        end
    end

    SceneItemHelper:SetEnableAutoAdjustLocation(true)
    self.tbSceneItemDataMap = nil
    return true
end

return ItemDropSpawner
