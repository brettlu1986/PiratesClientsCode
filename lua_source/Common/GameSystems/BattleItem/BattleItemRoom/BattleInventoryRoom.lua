local luaclass = require("luaclass")
local BattleItemRoomBase = require("BattleItemRoomBase")
local BattleInventoryRoom = luaclass("BattleInventoryRoom", BattleItemRoomBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemDataTable = require("BattleItemDataTable")

BattleInventoryRoom.nMaxInventorySlots = nil
BattleInventoryRoom.nInventoryCapacity = nil

local function GetItemsByTemplateId(self, bIsClient, nItemTemplateId)
    local tbItems = {}
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for _, v in pairs(self.tbItemList) do
        local Item = BattleItemSystem:GetItem(v)
        if Item:GetTemplateId() == nItemTemplateId then
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

local function CheckAddItemWhenHasEmptySlot(self, bIsClient, tbAddItemCheckResult, tbTemplate, nCount, nCanAddCount,
                                           nMaxInventorySlots, nInventorySlotsCount, nInventoryCapacity, nAllItemsWeight)
    local nItemTemplateId = tbTemplate.nId
    local tbStackItemDatas = {}
    local nStackCount = 0
    local nNeedAddSlotCount = 0
    if tbTemplate.bStackable then
        local Item = nil
        local nStackLimit = tbTemplate.nStackLimit
        local tbItems = GetItemsByTemplateId(self, bIsClient, nItemTemplateId)
        for _, v in ipairs(tbItems) do
            if v:GetStackCount() < nStackLimit then
                Item = v
                break
            end
        end
        if Item ~= nil then
            nStackCount = math.max(math.min(nStackLimit - Item:GetStackCount(), nCanAddCount), 0)
            local tbStackItemData = {}
            tbStackItemData.StackItem = Item
            tbStackItemData.nStackCount = nStackCount
            table.insert(tbStackItemDatas, tbStackItemData)
        end
        if nStackCount < nCanAddCount then
            nNeedAddSlotCount = math.max(math.ceil((nCanAddCount - nStackCount) / nStackLimit), 0)
            if nInventorySlotsCount + nNeedAddSlotCount > nMaxInventorySlots then
                nNeedAddSlotCount = math.max(nMaxInventorySlots - nInventorySlotsCount, 0)
                nCanAddCount = nStackCount + nNeedAddSlotCount * nStackLimit
            end
        end
    else
        if nInventorySlotsCount + nCanAddCount > nMaxInventorySlots then
            nCanAddCount = math.max(nMaxInventorySlots - nInventorySlotsCount, 0)
        end
        nNeedAddSlotCount = nCanAddCount
    end
    self:FillCheckResult(tbAddItemCheckResult, nCanAddCount, nCount, tbStackItemDatas, nNeedAddSlotCount)
end

local function CheckAddItemWhenNoEmptySlot(self, bIsClient, tbAddItemCheckResult, tbTemplate, nCount, nCanAddCount, nInventoryCapacity, nAllItemsWeight)
    local nItemTemplateId = tbTemplate.nId
    local tbStackItemDatas = {}
    local nStackCount = 0
    local nNeedAddSlotCount = 0
    if tbTemplate.bStackable then
        local Item = nil
        local nStackLimit = tbTemplate.nStackLimit
        local tbItems = GetItemsByTemplateId(self, bIsClient, nItemTemplateId)
        for _, v in ipairs(tbItems) do
            if v:GetStackCount() < nStackLimit then
                Item = v
                break
            end
        end
        if Item ~= nil then
            nStackCount = math.max(math.min(nStackLimit - Item:GetStackCount(), nCanAddCount), 0)
            nCanAddCount = nStackCount
            local tbStackItemData = {}
            tbStackItemData.StackItem = Item
            tbStackItemData.nStackCount = nStackCount
            table.insert(tbStackItemDatas, tbStackItemData)
        else
            nCanAddCount = 0
        end
    else
        nCanAddCount = 0
    end
    self:FillCheckResult(tbAddItemCheckResult, nCanAddCount, nCount, tbStackItemDatas, nNeedAddSlotCount)
end

-- need override
function BattleInventoryRoom:GetInventoryCapacity(bIsClient)
    return 0
end

-- need override
function BattleInventoryRoom:GetMaxInventorySlots(bIsClient)
    return 0
end

function BattleInventoryRoom:GetAllItemsWeight(bIsClient)
    local nTotalWeight = 0
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for _, v in pairs(self.tbItemList) do
        local Item = BattleItemSystem:GetItem(v)
        local nWeight = Item:GetWeight()
        nTotalWeight = nTotalWeight + nWeight
    end
    return nTotalWeight
end

function BattleInventoryRoom:GetInventorySlotsCount()
    local nCount = 0
    for _, v in pairs(self.tbItemList) do
        nCount = nCount + 1
    end
    return nCount
end

function BattleInventoryRoom:CanAddToInventoryRoom(nItemTemplateId, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nItemWeight = tbTemplate.nWeight

    local nInventoryCapacity = self:GetInventoryCapacity(bIsClient)
    local nWeight = self:GetAllItemsWeight(bIsClient)
    if nWeight + nItemWeight > nInventoryCapacity then
        return false
    end

    local nMaxInventorySlots = self:GetMaxInventorySlots(bIsClient)
    local nInventorySlotsCount = self:GetInventorySlotsCount()
    if nInventorySlotsCount < nMaxInventorySlots then
        return true
    end

    if not tbTemplate.bStackable then
        return false
    end

    local tbItems = GetItemsByTemplateId(self, bIsClient, nItemTemplateId)
    for _, v in ipairs(tbItems) do
        if v:GetStackCount() < tbTemplate.nStackLimit then
            return true
        end
    end
    return false
end

function BattleInventoryRoom:IsFull(bIsClient)
    local nInventoryCapacity = self:GetInventoryCapacity(bIsClient)
    local nWeight = self:GetAllItemsWeight(bIsClient)
    if nWeight >= nInventoryCapacity then
        return true
    end
    local nMaxInventorySlots = self:GetMaxInventorySlots(bIsClient)
    local nInventorySlotsCount = self:GetInventorySlotsCount()
    if nInventorySlotsCount >= nMaxInventorySlots then
        return true
    end
    return false
end

function BattleInventoryRoom:FillCheckResult(tbAddItemCheckResult, nCanAddCount, nCount, tbStackItemDatas, nNeedAddSlotCount)
    if nCanAddCount == 0 then
        tbAddItemCheckResult.bCanAddAll = false
        tbAddItemCheckResult.bCanAddAPart = false
    elseif nCanAddCount == nCount then
        tbAddItemCheckResult.bCanAddAll = true
        tbAddItemCheckResult.bCanAddAPart = false
    else
        tbAddItemCheckResult.bCanAddAll = false
        tbAddItemCheckResult.bCanAddAPart = true
    end
    tbAddItemCheckResult.tbStackItemDatas = tbStackItemDatas
    tbAddItemCheckResult.nNeedAddSlotCount = nNeedAddSlotCount
    tbAddItemCheckResult.nCanAddCount = nCanAddCount
end

-- 对增加物品进行预先判断，给出增加时的详细参数
-- @param nItemTemplateId 物品的类型id
-- @param nCount 物品的数量
-- @return tbAddItemCheckResult
--         tbAddItemCheckResult = {}
--         tbAddItemCheckResult.bCanAddAll = false        -- 是否可以全部增加，true表示可以增加，false表示不能增加
--         tbAddItemCheckResult.bCanAddAPart = false      -- 如果不能全部增加，是否可以增加一部分，true表示可以增加，false表示不能增加
--         tbAddItemCheckResult.tbStackItemDatas = {}     -- 需要被叠加的物品数据
--         local tbStackItemData = {}
--         tbStackItemData.StackItem = {}            -- 需要被叠加的物品
--         tbStackItemData.nStackCount = 0           -- 需要被叠加在原有物品上的物品叠加数量
--         table.insert(tbAddItemCheckResult.tbStackItemDatas, tbStackItemData)
--         tbAddItemCheckResult.nNeedAddSlotCount = 0     -- 需要被增加的物品实例数量
--         tbAddItemCheckResult.nCanAddCount = 0          -- 可以被增加的物品叠加总数量
function BattleInventoryRoom:CheckAddItem(bIsClient, nItemTemplateId, nCount)
    local tbAddItemCheckResult = {}

    local nInventoryCapacity = self:GetInventoryCapacity(bIsClient)
    local nAllItemsWeight = self:GetAllItemsWeight(bIsClient)

    if nAllItemsWeight >= nInventoryCapacity then
        tbAddItemCheckResult.bCanAddAll = false
        tbAddItemCheckResult.bCanAddAPart = false
        return tbAddItemCheckResult
    end

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nWeight = tbTemplate.nWeight

    local nCanAddCount = nCount
    if nAllItemsWeight + nWeight * nCanAddCount > nInventoryCapacity then
        nCanAddCount = math.max((nInventoryCapacity - nAllItemsWeight) // nWeight, 0)
        nCanAddCount = math.floor(nCanAddCount)
    end
    if nCanAddCount == 0 then
        tbAddItemCheckResult.bCanAddAll = false
        tbAddItemCheckResult.bCanAddAPart = false
        return tbAddItemCheckResult
    end

    local nMaxInventorySlots = self:GetMaxInventorySlots(bIsClient)
    local nInventorySlotsCount = self:GetInventorySlotsCount()

    if nInventorySlotsCount >= nMaxInventorySlots then
        CheckAddItemWhenNoEmptySlot(self, bIsClient, tbAddItemCheckResult, tbTemplate, nCount, nCanAddCount,
                                    nMaxInventorySlots, nInventorySlotsCount, nInventoryCapacity, nAllItemsWeight)
    else
        CheckAddItemWhenHasEmptySlot(self, bIsClient, tbAddItemCheckResult, tbTemplate, nCount, nCanAddCount, nInventoryCapacity, nAllItemsWeight)
    end
    return tbAddItemCheckResult
end

return BattleInventoryRoom