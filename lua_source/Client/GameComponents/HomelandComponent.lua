-----------------------------------------------------
--File Name    : HomelandComponent.lua
--Author       : zhiyuan
--Create Time  : 2019-04-16
--Description  : 家园的component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local HomelandComponent = luaclass("HomelandComponent", GameComponentBase)

local ItemSystem = require("ItemSystem")
local HomelandSceneDataTable = require("HomelandSceneDataTable")
local BuildingDataTable = require("BuildingDataTable")
local BlockTypeDataTable = require("BlockTypeDataTable")
local LandmarkStatusDef = require("LandmarkStatusDef")
local LandmarkBuildingUpgradeDataTable = require("LandmarkBuildingUpgradeDataTable")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

-- 当前场景id
HomelandComponent.nCurrentSceneId = nil

-- 是否第一次进入
HomelandComponent.bFirstEntry = nil

-- 所有场景数据
-- self.tbSceneDatas = {}
-- local nSceneId = 1
-- local tbSceneBlockDatas = {}
-- self.tbSceneDatas[nSceneId] = tbSceneBlockDatas
-- local nBlockId = 1
-- local tbBlockData = {}
-- tbSceneBlockDatas[nBlockId] = tbBlockData
-- tbBlockData.nBlockId = 1
-- tbBlockData.nBlockType = 1
-- tbBlockData.bIsLandmark = true
-- tbBlockData.bCanPlaceBuilding = true
-- tbBlockData.bUnlock = true
-- tbBlockData.bBought = true
-- tbBlockData.nBuildingId = 1
-- tbBlockData.nItemInstanceId = 1
-- tbBlockData.nRotationId = 1
-- tbBlockData.nStatus = 1
HomelandComponent.tbSceneDatas = nil

-- 标志性建筑数据
-- self.tbLandmarkDatas = {}
-- local nLandmartType = 1
-- local tbLandmarkData = {}
-- self.tbLandmarkDatas[nLandmartType] = tbLandmarkData
-- tbLandmarkData.nGrade = 1
-- tbLandmarkData.nStatus = 1
-- tbLandmarkData.nCompleteTime = 1
HomelandComponent.tbLandmarkDatas = nil

-- 建造上去的道具与地块的索引表
-- self.tbItemOnBlocks = {}
-- self.tbItemOnBlocks[nSceneId] = {}
-- local tbItemOnBlocksOnOneScene = self.tbItemOnBlocks[nSceneId]
-- tbItemOnBlocksOnOneScene[nItemInstanceId] = {}
HomelandComponent.tbItemOnBlocks = nil

-- 正在研发的道具数据
-- self.tbResearchingItemDatas = {}
-- local tbItemData = {}
-- tbItemData.nItemTemplateId = 1
-- tbItemData.nCompleteTime = 1
-- self.tbResearchingItemDatas[tbItemData.nItemTemplateId] = tbItemData
HomelandComponent.tbResearchingItemDatas = nil

-- 服务端初始化的数据
HomelandComponent.tbParams = nil

-- 标志性建筑初始等级
local LANDMARK_DEFAULT_GRADE = 0

-- 建筑默认朝向
local DEFAULT_ROTATION_ID = 1

-----------------------------------------local function---------------------------------------------

local function AddItemOnBlock(self, nBlockId, nItemInstanceId)
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    local nSceneId = tbBlockTemplate.nSceneId
    local tbItemOnBlocksOnOneScene = self.tbItemOnBlocks[nSceneId]
    if tbItemOnBlocksOnOneScene ==  nil then
        self.tbItemOnBlocks[nSceneId] = {}
        tbItemOnBlocksOnOneScene = self.tbItemOnBlocks[nSceneId]
    end
    local tbBlockIds = tbItemOnBlocksOnOneScene[nItemInstanceId]
    if tbBlockIds == nil then
        tbBlockIds = {}
        tbItemOnBlocksOnOneScene[nItemInstanceId] = tbBlockIds
    end
    table.insert(tbBlockIds, nBlockId)
end

local function RemoveItemOnBlock(self, nBlockId, nItemInstanceId)
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    local nSceneId = tbBlockTemplate.nSceneId
    local tbItemOnBlocksOnOneScene = self.tbItemOnBlocks[nSceneId]
    if tbItemOnBlocksOnOneScene ==  nil then
        self.tbItemOnBlocks[nSceneId] = {}
        tbItemOnBlocksOnOneScene = self.tbItemOnBlocks[nSceneId]
    end
    local tbBlockIds = tbItemOnBlocksOnOneScene[nItemInstanceId]
    if tbBlockIds ~= nil then
        local nIndex = nil
        for i, v in ipairs(tbBlockIds) do
            if v == nBlockId then
                nIndex = i
                break
            end
        end
        if nIndex ~= nil then
            table.remove( tbBlockIds, nIndex)
        end
    end
end

local function GetLandmarkBuildingTemplateId(self, nSceneId, nLandmarkType)
    local nLandmarkGrade = self:GetLandmarkGrade(nLandmarkType)
    local tbBuildingTemplate = BuildingDataTable:GetLandmarkTemplate(nSceneId, nLandmarkType, nLandmarkGrade)
    return tbBuildingTemplate.nId
end

local function GetItemBuildingId(nItemInstanceId)
    local Item = ItemSystem:GetItem(nItemInstanceId)
    local tbTemplate = Item:GetTemplate()
    return tbTemplate.nBuildingId
end

local function FillNormalBlockDataWhenRecordEmpty(self, tbBlockData, tbBlockTemplate)
    if tbBlockTemplate.bNeedUnlock then
        local nCurrentGrade = self:GetLandmarkGrade(tbBlockTemplate.nUnlockLandmarkType)
        if nCurrentGrade >= tbBlockTemplate.nUnlockLandmarkGrade then
            tbBlockData.bUnlock = true
            if tbBlockTemplate.bNeedBuy then
                tbBlockData.bBought = false
            else
                tbBlockData.bBought = true
            end
        else
            tbBlockData.bUnlock = false
            tbBlockData.bBought = false
        end
    else
        tbBlockData.bUnlock = true
        if tbBlockTemplate.bNeedBuy then
            tbBlockData.bBought = false
        else
            tbBlockData.bBought = true
        end
    end
    tbBlockData.nBuildingId = nil
end

local function FillNormalBlockDataWhenHasRecord(self, tbBlockData, tbBlockTemplate, tbBlockRecord)
    tbBlockData.bUnlock = true
    tbBlockData.bBought = true
    local nItemInstanceId = tbBlockRecord.instance_id
    if nItemInstanceId ~= nil and nItemInstanceId > 0 then
        tbBlockData.nBuildingId = GetItemBuildingId(nItemInstanceId)
        tbBlockData.nItemInstanceId = nItemInstanceId
        tbBlockData.nRotationId = tbBlockRecord.rotation_id
        AddItemOnBlock(self, tbBlockTemplate.nId, nItemInstanceId)
    end
end

local function FillLandmarkBlockData(self, tbBlockData, tbBlockTemplate, nSceneId)
    tbBlockData.bIsLandmark = true
    tbBlockData.bUnlock = true
    tbBlockData.bBought = true
    local nLandmarkType = tbBlockTemplate.nDefaultLandmarkType
    tbBlockData.nBuildingId = GetLandmarkBuildingTemplateId(self, nSceneId, nLandmarkType)
    tbBlockData.nStatus = self:GetLandmarkStatus(nLandmarkType)
end


local function FillNormalBlockData(self, tbBlockData, tbBlockTemplate, tbBlockRecord)
    tbBlockData.bIsLandmark = false
    if tbBlockRecord == nil then
        FillNormalBlockDataWhenRecordEmpty(self, tbBlockData, tbBlockTemplate)
    else
        FillNormalBlockDataWhenHasRecord(self, tbBlockData, tbBlockTemplate, tbBlockRecord)
    end
end

local function GetBlockRecord(nBlockId, tbSceneRecord)
    if tbSceneRecord == nil or tbSceneRecord.blocks == nil then
        return nil
    end
    for _, v in ipairs(tbSceneRecord.blocks) do
        if v.index == nBlockId then
            return v
        end
    end
    return nil
end

local function InitSceneData(self, nSceneId, tbSceneRecord)
    local tbSceneBlockDatas = {}
    self.tbSceneDatas[nSceneId] = tbSceneBlockDatas
    local tbSceneBlockTemplates = HomelandSceneDataTable:GetSceneBlockTemplates(nSceneId)
    for _, tbBlockTemplate in ipairs(tbSceneBlockTemplates) do
        local tbBlockData = {}
        local nBlockId = tbBlockTemplate.nId
        tbSceneBlockDatas[nBlockId] = tbBlockData
        tbBlockData.nBlockId = nBlockId
        local nBlockType = tbBlockTemplate.nBlockType
        tbBlockData.nBlockType = nBlockType

        local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)
        tbBlockData.bCanPlaceBuilding = tbBlockTypeTemplate.bCanPlaceBuilding

        if tbBlockTemplate.bHasDefaultLandmark then
            FillLandmarkBlockData(self, tbBlockData, tbBlockTemplate, nSceneId)
        else
            local tbBlockRecord = GetBlockRecord(nBlockId, tbSceneRecord)
            FillNormalBlockData(self, tbBlockData, tbBlockTemplate, tbBlockRecord)
        end
    end
end

local function InitLandmarkDataBySettings(self)
    self.tbLandmarkDatas = {}
    local tbLandmarkDatas = self.tbLandmarkDatas
    local tbLandmarkGradeDatas = LandmarkBuildingUpgradeDataTable:GetAllGradeData()
    for k, v in pairs(tbLandmarkGradeDatas) do
        local tbLandmarkData = {}
        tbLandmarkData.nType = k
        tbLandmarkData.nGrade = v.nMinGrade
        tbLandmarkData.nStatus = LandmarkStatusDef.NORMAL
        tbLandmarkData.nCompleteTime = 0
        tbLandmarkDatas[tbLandmarkData.nType] = tbLandmarkData
    end
end

local function InitLandmarkDataByRecord(self, tbLandmarkRecords)
    local tbLandmarkDatas = self.tbLandmarkDatas
    local now = GlobalVariableSystem:GetServerTimeUtc()
    for _, v in ipairs(tbLandmarkRecords) do
        local nLandmarkType = v.id
        local tbLandmarkData = tbLandmarkDatas[nLandmarkType]
        tbLandmarkData.nGrade = v.grade
        tbLandmarkData.nStatus = v.status
        tbLandmarkData.nCompleteTime = now + v.remain_seconds
    end
end

local function IsSceneUnlock(self, tbSceneTemplate)
    local bUnlock = false
    local nUnlockLandmarkType = tbSceneTemplate.nUnlockLandmarkType
    local nUnlockLandmarkGrade = tbSceneTemplate.nUnlockLandmarkGrade
    if nUnlockLandmarkGrade ~= nil and nUnlockLandmarkGrade > 0 then
        local nCurrentGrade = self:GetLandmarkGrade(nUnlockLandmarkType)
        if nCurrentGrade >= nUnlockLandmarkGrade then
            bUnlock = true
        end
    else
        bUnlock = true
    end
    return bUnlock
end

local function GetSceneRecord(tbSceneRecords, nSceneId)
    for _, v in ipairs(tbSceneRecords) do
        if v.id == nSceneId then
            return v
        end
    end
end

local function IsSceneCanUse(tbSceneTemplate, tbSceneRecords)
    local bCanUse = false
    local tbSceneRecord = nil
    if tbSceneTemplate.nPrice ~= nil and tbSceneTemplate.nPrice > 0 then
        tbSceneRecord = GetSceneRecord(tbSceneRecords, tbSceneTemplate.nId)
        if tbSceneRecord then
            bCanUse = true
        end
    else
        bCanUse = true
        tbSceneRecord = GetSceneRecord(tbSceneRecords, tbSceneTemplate.nId)
    end
    return bCanUse,tbSceneRecord
end

local function InitAllSceneBlocksByRecord(self, tbSceneRecords)
    self.tbSceneDatas = {}
    local tbAllSceneTemplates = HomelandSceneDataTable:GetAllSceneTemplates()
    for nSceneId, tbSceneTemplate in pairs(tbAllSceneTemplates) do
        local bUnlock = IsSceneUnlock(self, tbSceneTemplate)

        if bUnlock then
            local bCanUse, tbSceneRecord = IsSceneCanUse(tbSceneTemplate, tbSceneRecords)
            if bCanUse then
                InitSceneData(self, nSceneId, tbSceneRecord)
            end
        end
    end
end

local function InitAllSceneDatas(self, tbHomelandData)
    local tbData = tbHomelandData
    --local tbData = MockData(self)
    self.nCurrentSceneId = tbData.scene_id
    if self.nCurrentSceneId == 0 then
        self.nCurrentSceneId = 1
    end
    self.bFirstEntry = tbData.first_entry

    self.tbItemOnBlocks = {}

    InitLandmarkDataBySettings(self)
    InitLandmarkDataByRecord(self, tbData.landmarks)

    InitAllSceneBlocksByRecord(self, tbData.scenes)
end

local function GetSceneData(self, nSceneId)
    local tbSceneData = self.tbSceneDatas[nSceneId]
    -- logdebug("GetSceneData", nSceneId, require("dkjson").encode(tbSceneData))
    return tbSceneData
end

local function GetCurrentSceneData(self)
    return GetSceneData(self, self.nCurrentSceneId)
end

local function SetLandmarkBlockStatus(self, nLandmarkType, nStatus)
    for _, v1 in pairs(self.tbSceneDatas) do
        for k2, v2 in pairs(v1) do
            if v2.bIsLandmark then
                local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(k2)
                if tbBlockTemplate.nDefaultLandmarkType == nLandmarkType then
                    v2.nStatus = nStatus
                end
            end
        end
    end
end

local function SetLandmarkStatus(self, nLandmarkType, nStatus, nCompleteTime)
    local tbLandmarkData = self.tbLandmarkDatas[nLandmarkType]
    tbLandmarkData.nStatus = nStatus
    tbLandmarkData.nCompleteTime = nCompleteTime
    SetLandmarkBlockStatus(self, nLandmarkType, nStatus)
end

local function SetLandmarkData(self, nLandmarkType, nGrade, nStatus, nCompleteTime)
    local tbLandmarkData = self.tbLandmarkDatas[nLandmarkType]
    tbLandmarkData.nGrade = nGrade
    tbLandmarkData.nStatus = nStatus
    tbLandmarkData.nCompleteTime = nCompleteTime
    SetLandmarkBlockStatus(self, nLandmarkType, nStatus)
end

local function SetLandmarkBuilding(self, nBlockId, nBuildingId)
    local tbBlockData = self:GetBlockData(nBlockId)
    tbBlockData.nBuildingId = nBuildingId
end

-----------------------------------------初始化---------------------------------------------

function HomelandComponent:OnCreate(Owner, tbParams)
    HomelandComponent.super.OnCreate(self, Owner, tbParams)
    self.tbParams = tbParams
    self.tbResearchingItemDatas = {}
    return true
end

function HomelandComponent:InitData(tbHomelandData)
    InitAllSceneDatas(self, tbHomelandData)
end

-----------------------------------------家园数据操作的基础方法---------------------------------------------

function HomelandComponent:GetCurrentSceneData()
    return GetCurrentSceneData(self)
end

function HomelandComponent:GetSceneData(nSceneId)
    return GetSceneData(self, nSceneId)
end

function HomelandComponent:SetCurrentSceneId(nCurrentSceneId)
    self.nCurrentSceneId = nCurrentSceneId
end

function HomelandComponent:GetCurrentSceneId()
    return self.nCurrentSceneId
end

function HomelandComponent:IsSceneCanUse(nSceneId)
    return self.tbSceneDatas[nSceneId] ~= nil
end

function HomelandComponent:GetLandmarkGrade(nLandmarkType)
    local tbLandmarkData = self.tbLandmarkDatas[nLandmarkType]
    local nGrade = tbLandmarkData.nGrade
    if nGrade <= 0 then
        nGrade = LANDMARK_DEFAULT_GRADE
    end
    return nGrade
end

function HomelandComponent:GetLandmarkStatus(nLandmarkType)
    local tbLandmarkData = self.tbLandmarkDatas[nLandmarkType]
    return tbLandmarkData.nStatus
end

function HomelandComponent:GetLandmarkData(nLandmarkType)
    return self.tbLandmarkDatas[nLandmarkType]
end

function HomelandComponent:GetAllLandmarkData()
    return self.tbLandmarkDatas
end

function HomelandComponent:GetBlockData(nBlockId)
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    local tbBlocks = self.tbSceneDatas[tbBlockTemplate.nSceneId]
    return tbBlocks[nBlockId]
end

function HomelandComponent:SetBlockBought(nBlockId)
    local tbBlockData = self:GetBlockData(nBlockId)
    if tbBlockData == nil then
        error("Cannot find block data!"..nBlockId)
    end
    if tbBlockData.bBought == true then
        logerror("Block is already bought!", nBlockId)
    else
        tbBlockData.bBought = true
    end
end

function HomelandComponent:IsBlockBought(nBlockId)
    local tbBlockData = self:GetBlockData(nBlockId)
    if tbBlockData == nil then
        error("Cannot find block data!"..nBlockId)
    end
    return tbBlockData.bBought
end

function HomelandComponent:SetBlockUnlock(nBlockId)
    local tbBlockData = self:GetBlockData(nBlockId)
    if tbBlockData == nil then
        error("Cannot find block data!"..nBlockId)
    end
    if tbBlockData.bUnlock == true then
        logerror("Block is already bought!", nBlockId)
    else
        tbBlockData.bUnlock = true
    end
end

function HomelandComponent:IsBlockUnlock(nBlockId)
    local tbBlockData = self:GetBlockData(nBlockId)
    if tbBlockData == nil then
        error("Cannot find block data!"..nBlockId)
    end
    return tbBlockData.bUnlock
end

function HomelandComponent:PlaceItemBuilding(nBlockId, nItemInstanceId, nRotationId)
    if nRotationId == nil then
        nRotationId = DEFAULT_ROTATION_ID
    end
    local tbBlockData = self:GetBlockData(nBlockId)
    tbBlockData.nItemInstanceId = nItemInstanceId
    tbBlockData.nBuildingId = GetItemBuildingId(nItemInstanceId)
    tbBlockData.nRotationId = nRotationId

    AddItemOnBlock(self, nBlockId, nItemInstanceId)
end

function HomelandComponent:RemoveItemBuilding(nBlockId)
    local tbBlockData = self:GetBlockData(nBlockId)
    local nItemInstanceId = tbBlockData.nItemInstanceId
    if nItemInstanceId ~= nil then
        RemoveItemOnBlock(self, nBlockId, nItemInstanceId)
    end
    tbBlockData.nItemInstanceId = nil
    tbBlockData.nBuildingId = nil
    tbBlockData.nRotationId = nil
end

function HomelandComponent:LandmarkBeginUpgrade(nLandmarkType, nStatus, nCompleteTime)
    SetLandmarkStatus(self, nLandmarkType, nStatus, nCompleteTime)
end

function HomelandComponent:LandmarkUpgradeComplete(nLandmarkType, nGrade, nStatus, nCompleteTime)
    SetLandmarkData(self, nLandmarkType, nGrade, nStatus, nCompleteTime)
    local tbSceneAllBlockTemplates = HomelandSceneDataTable:GetAllSceneBlockTemplates()
    for nSceneId, tbSceneBlockTemplates in pairs(tbSceneAllBlockTemplates) do
        for _, tbBlockTemplate in ipairs(tbSceneBlockTemplates) do
            if tbBlockTemplate.bHasDefaultLandmark then
                local nDefaultLandmarkType = tbBlockTemplate.nDefaultLandmarkType
                if nDefaultLandmarkType == nLandmarkType then
                    local nBuildingId = GetLandmarkBuildingTemplateId(self, nSceneId, nLandmarkType)
                    SetLandmarkBuilding(self, tbBlockTemplate.nId, nBuildingId)
                    break
                end
            end
        end
    end
end

function HomelandComponent:GetAllItemInstanceIdOnBlock()
    return self.tbItemOnBlocks
end

function HomelandComponent:GetAllItemOnBlockInCurrentScene()
    local nCurrentSceneId = self.nCurrentSceneId
    local tbItemOnBlockInCurrentScene = self.tbItemOnBlocks[nCurrentSceneId]
    if tbItemOnBlockInCurrentScene == nil then
        return {}
    else
        return tbItemOnBlockInCurrentScene
    end
end

function HomelandComponent:InitSceneData(nSceneId, tbSceneRecord)
    InitSceneData(self, nSceneId, tbSceneRecord)
end

function HomelandComponent:GetAllResearchingItemDatas()
    return self.tbResearchingItemDatas
end

function HomelandComponent:ClearAllResearchingItemDatas()
    self.tbResearchingItemDatas = {}
end

function HomelandComponent:AddResearchingItemData(nItemTemplateId, nRemainSeconds)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nCompleteTime = now + nRemainSeconds
    local tbItemData = {}
    tbItemData.nItemTemplateId = nItemTemplateId
    tbItemData.nCompleteTime = nCompleteTime
    self.tbResearchingItemDatas[nItemTemplateId] = tbItemData
end

function HomelandComponent:ClearResearchingItemData(nItemTemplateId)
    self.tbResearchingItemDatas[nItemTemplateId] = nil
end

function HomelandComponent:GetResearchingItemData(nItemTemplateId)
    return self.tbResearchingItemDatas[nItemTemplateId]
end

function HomelandComponent:IsFirstEntry()
    return self.bFirstEntry
end

function HomelandComponent:SetNotFirstEntry()
    self.bFirstEntry = false
end

return HomelandComponent
