-----------------------------------------------------
--File Name    : HomelandItemSystem.lua
--Author       : zhiyuan
--Create Time  : 2019-05-10
--Description  : 家园的道具相关的system
-----------------------------------------------------
local HomelandItemSystem = {}

local PlayerSelfHelper = require("GamePlayerSelfHelper")
local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local ItemDataTable = require("ItemDataTable")
local DelayTimer = require("DelayTimer")

HomelandItemSystem.tbItemResearchTimers = nil

-----------------------------------------logic local function---------------------------------------------
local function GetHomelandComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local HomelandComponent = PlayerSelf.HomelandComponent
    if HomelandComponent == nil then
        error("GetHomelandComponent failed!HomelandComponent == nil!")
    end
    return HomelandComponent
end

local function GetAllItemOnBlockInCurrentScene()
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetAllItemOnBlockInCurrentScene()
end

local function fnSortBlockIds(nBlockId1, nBlockId2)
    return nBlockId1 < nBlockId2
end

local function RemoveItemBuilding(self, nItemInstanceId)
    local HomelandComponent = GetHomelandComponent()
    local tbItemOnBlocks = HomelandComponent:GetAllItemInstanceIdOnBlock()
    local tbBlocksNeedClear = {}
    for _, v1 in pairs(tbItemOnBlocks) do
        for k2, v2 in pairs(v1) do
            if k2 == nItemInstanceId then
                table.insert(tbBlocksNeedClear, v2)
            end
        end
    end
    for _, v in ipairs(tbBlocksNeedClear) do
        for _, blockId in ipairs(v) do
            self.OwnerSystem:RemoveItemBuildingOnBlock(blockId)
        end
    end
end

local function OnRemoveItem(self, nInstanceId, nTemplateId)
    local tbItemTemplate = ItemDataTable:GetTemplate(nTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.DECORATIVE_BUILDING then
        RemoveItemBuilding(self, nInstanceId)
    end
end

local function OnChangeItemCount(self, nInstanceId, nStackCount, bIsMore)
    local Item = ItemSystem:GetItem(nInstanceId)
    if Item:GetCategory() ~= ItemCategoryDef.DECORATIVE_BUILDING or bIsMore then
        return
    end

    local tbBlockIds = {}
    local HomelandComponent = GetHomelandComponent()
    local tbItemOnBlocks = HomelandComponent:GetAllItemInstanceIdOnBlock()
    for _, v1 in pairs(tbItemOnBlocks) do
        for k2, v2 in pairs(v1) do
            if k2 == nInstanceId then
                local nNeedCount = #v2
                if nNeedCount > nStackCount then
                    local nNeedRemoveCount = nNeedCount - nStackCount
                    table.sort(v2, fnSortBlockIds)
                    for i = 1, nNeedRemoveCount do
                        table.insert(tbBlockIds, v2[nNeedCount - i + 1])
                    end
                end
            end
        end
    end

    for _, v in ipairs(tbBlockIds) do
        self.OwnerSystem:RemoveItemBuildingOnBlock(v)
    end
end

local function AddItemResearchTimer(self, nTemplateId, nRemainSeconds)
    if self.tbItemResearchTimers[nTemplateId] ~= nil then
        return
    end
    local FunResearchCompleteCallback = function()
        self:RequestResearchItemComplete(nTemplateId)
    end
    local DelayHandle = DelayTimer:DelayRun(FunResearchCompleteCallback, nRemainSeconds)
    self.tbItemResearchTimers[nTemplateId] = DelayHandle
end

local function ClearAllItemResearchTimer(self)
    if self.tbItemResearchTimers ~= nil then
        for k, v in pairs(self.tbItemResearchTimers) do
            if v then
                DelayTimer:ClearTimer(v)
                self.tbItemResearchTimers[k] = nil
            end
        end
    end
    self.tbItemResearchTimers = {}
end

-----------------------------------------System Init UnInit---------------------------------------------

function HomelandItemSystem:Init()
    self.tbItemResearchTimers = {}
    EventManager:BindEventMethod(ClientEventDef.EV_REMOVE_LOBBY_ITEM, self, OnRemoveItem)
    EventManager:BindEventMethod(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnChangeItemCount)
end

function HomelandItemSystem:Uninit()
    ClearAllItemResearchTimer(self)
    EventManager:UnBindEventMethod(ClientEventDef.EV_REMOVE_LOBBY_ITEM, self, OnRemoveItem)
    EventManager:UnBindEventMethod(ClientEventDef.EV_CHANGE_LOBBY_ITEM_STACK_COUNT, self, OnChangeItemCount)
end

function HomelandItemSystem:OnEnterHomeland()
end

function HomelandItemSystem:OnLeaveHomeland()
end

-----------------------------------------给外部模块的调用接口---------------------------------------------

function HomelandItemSystem:GetAllAvailableItems()
    local tbItemsOnBlock = GetAllItemOnBlockInCurrentScene()
    local tbItems = ItemSystem:GetItemsByCategory(ItemCategoryDef.DECORATIVE_BUILDING)

    local tbAvailableItems = {}
    for _, v in pairs(tbItems) do
        local nTotalCount = v:GetStackCount()
        local nItemInstanceId = v:GetInstanceId()
        local tbBlocks = tbItemsOnBlock[nItemInstanceId]
        local nUsedCount = 0
        if tbBlocks ~= nil then
            nUsedCount = #tbBlocks
        end
        local nAvailableCount = nTotalCount - nUsedCount
        if nAvailableCount > 0 then
            local tbItemData = {}
            tbItemData.Item = v
            tbItemData.nAvailableCount = nAvailableCount
            table.insert(tbAvailableItems, tbItemData)
        end
    end
    return tbAvailableItems
end

-- 获得某个类型道具可以用的数量和instanceId的列表
function HomelandItemSystem:GetAvailableItemCount(nItemTemplateId)
    local tbItemsOnBlock = GetAllItemOnBlockInCurrentScene()
    local tbItems = ItemSystem:GetItemsByCategory(ItemCategoryDef.DECORATIVE_BUILDING)

    local nTotalAvailableCount = 0
    local tbItemInstanceIds = {}
    for _, v in pairs(tbItems) do
        if nItemTemplateId == v:GetTemplateId() then
            local nTotalCount = v:GetStackCount()
            local nItemInstanceId = v:GetInstanceId()
            local tbBlocks = tbItemsOnBlock[nItemInstanceId]
            local nUsedCount = 0
            if tbBlocks ~= nil then
                nUsedCount = #tbBlocks
            end
            local nAvailableCount = nTotalCount - nUsedCount
            if nAvailableCount > 0 then
                nTotalAvailableCount = nTotalAvailableCount + nAvailableCount
                table.insert(tbItemInstanceIds, nItemInstanceId)
            end
        end
    end
    return nTotalAvailableCount, tbItemInstanceIds
end

-- 道具数量够不够
function HomelandItemSystem:IsAvailableItemEnough(nItemTemplateId, nItemCount)
    local nTotalAvailableCount, _ = HomelandItemSystem:GetAvailableItemCount(nItemTemplateId)
    return nTotalAvailableCount >= nItemCount
end

-- 获得正在研发的道具数据
function HomelandItemSystem:GetResearchingItemData(nItemTemplateId)
    local HomelandComponent = GetHomelandComponent()
    return HomelandComponent:GetResearchingItemData(nItemTemplateId)
end

-- 是否有同一个大类型的道具正在研发
function HomelandItemSystem:HasSameCategoryItemResearching(nItemTemplateId)
    local HomelandComponent = GetHomelandComponent()
    local tbResearchingDatas = HomelandComponent:GetAllResearchingItemDatas()
    if tbResearchingDatas == nil then
        return false
    end

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    for k, _ in pairs(tbResearchingDatas) do
        local tbResearchingItemTemplate = ItemDataTable:GetTemplate(k)
        if tbResearchingItemTemplate.nCategory == nCategory then
            return true
        end
    end

    return false
end

-----------------------------------------玩家不同的操作的方法---------------------------------------------

-- 请求出售仓库里的道具
function HomelandItemSystem:RequestSellBuildingItem(nInstanceId, nCount)
    local c2s_SellDecorativeBuilding =
    {
        instance_id = nInstanceId,
        count = nCount
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SellDecorativeBuilding, c2s_SellDecorativeBuilding)
end

-- 请求研发道具
function HomelandItemSystem:RequestResearchItem(nTemplateId)
    local c2s_ResearchItem =
    {
        item_id = nTemplateId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ResearchItem, c2s_ResearchItem)
end

-- 请求道具研发完成
function HomelandItemSystem:RequestResearchItemComplete(nTemplateId)
    local c2s_ResearchItemComplete =
    {
        item_id = nTemplateId
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ResearchItemComplete, c2s_ResearchItemComplete)
end

-----------------------------------------处理server发过来的道具数据同步---------------------------------------------------

-- 研发道具
function HomelandItemSystem:OnResearchItem(nTemplateId, nRemainSeconds)
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:AddResearchingItemData(nTemplateId, nRemainSeconds)
    AddItemResearchTimer(self, nTemplateId, nRemainSeconds)
    EventManager:OnFireEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_BEGIN, nTemplateId)
end

-- 研发道具完成
function HomelandItemSystem:OnResearchItemComplete(nInstanceId)
    local Item = ItemSystem:GetItem(nInstanceId)
    local nTemplateId = Item:GetTemplateId()
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:ClearResearchingItemData(nTemplateId)
    EventManager:OnFireEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_COMPLETE, nTemplateId)
end

-- 同步所有的正在研发数据
function HomelandItemSystem:OnSyncResearchItems(tbResearchingItems)
    if tbResearchingItems == nil then
        return
    end
    ClearAllItemResearchTimer(self)
    local HomelandComponent = GetHomelandComponent()
    HomelandComponent:ClearAllResearchingItemDatas()

    for _, v in ipairs(tbResearchingItems) do
        local nTemplateId = v.item_id
        local nRemainSeconds = v.remain_seconds
        if nRemainSeconds > 0 then
            HomelandComponent:AddResearchingItemData(nTemplateId, nRemainSeconds)
            AddItemResearchTimer(self, nTemplateId, nRemainSeconds)
        else
            self:RequestResearchItemComplete(nTemplateId)
        end
    end
end

return HomelandItemSystem
