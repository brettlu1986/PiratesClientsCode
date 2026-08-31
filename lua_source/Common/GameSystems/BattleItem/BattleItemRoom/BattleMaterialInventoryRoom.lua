-----------------------------------------------------
--File Name    : BattleMaterialInventoryRoom.lua
--Author       : zhiyuan
--Create Time  : 2018-08-30
--Description  : 材料room
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleInventoryRoom = require("BattleInventoryRoom")
local BattleMaterialInventoryRoom = luaclass("BattleMaterialInventoryRoom", BattleInventoryRoom)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local FFAItemIni = require("FFAItemIni")
local ShipGradeDataTable = require("ShipGradeDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")
local MathUtil = require("MathUtil")

local function GetItemMaxStack(self)
    return FFAItemIni.tbMaterial.nMaxMaterialStackCount
end

-- override
function BattleMaterialInventoryRoom:GetInventoryCapacity(bIsClient)
    local tbPlayer = self:GetOwnerCharacter()
    local nCharacterInstanceId = tbPlayer:GetServerInstanceId()
    local nCurBuiltGrade = BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, bIsClient)
    local nCapacityBase = ShipGradeDataTable:GetMaxMaterialCapacity(nCurBuiltGrade)
    local nRatio = BattleHumanDecorationSystem.GetShipExtraMaterialCapacityRatio(tbPlayer)
    if nRatio ~= nil and nRatio > 0 then
        return nCapacityBase + MathUtil.Round(nCapacityBase * nRatio)
    end
    return nCapacityBase
end

-- override
function BattleMaterialInventoryRoom:GetMaxInventorySlots(bIsClient)
    return FFAItemIni.tbMaterial.nMaxMaterialType
end

-- override
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
function BattleMaterialInventoryRoom:CheckAddItem(bIsClient, nItemTemplateId, nCount)
    local tbAddItemCheckResult = {}
    local tbStackItemDatas = {}

    local nMaxMaterialCount = GetItemMaxStack(self)

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nItemWeight = tbTemplate.nWeight
    local nInventoryCapacity = self:GetInventoryCapacity(bIsClient)
    local nWeight = self:GetAllItemsWeight(bIsClient)

    local nCanAddMax = (nInventoryCapacity - nWeight) // nItemWeight

    local FoundItem = nil
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for _, v in pairs(self.tbItemList) do
        local Item = BattleItemSystem:GetItem(v)
        if Item:GetTemplateId() == nItemTemplateId then
            FoundItem = Item
            break
        end
    end

    local nCanAddCount = nCount
    local nStackCount = 0
    local nNeedAddSlotCount = 0
    if FoundItem == nil then
        nNeedAddSlotCount = 1
        if nCanAddCount > nMaxMaterialCount then
            nCanAddCount = nMaxMaterialCount
        end
        if nCanAddCount > nCanAddMax then
            nCanAddCount = nCanAddMax
        end
    else
        if nCanAddCount + FoundItem:GetStackCount() > nMaxMaterialCount then
            nCanAddCount = math.max(nMaxMaterialCount - FoundItem:GetStackCount(), 0)
        end
        if nCanAddCount > nCanAddMax then
            nCanAddCount = nCanAddMax
        end
        nStackCount = nCanAddCount
        local tbStackItemData = {}
        tbStackItemData.StackItem = FoundItem
        tbStackItemData.nStackCount = nStackCount
        table.insert(tbStackItemDatas, tbStackItemData)
    end

    self:FillCheckResult(tbAddItemCheckResult, nCanAddCount, nCount, tbStackItemDatas, nNeedAddSlotCount)

    return tbAddItemCheckResult
end

function BattleMaterialInventoryRoom:CanAddToInventoryRoom(nItemTemplateId, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nItemWeight = tbTemplate.nWeight

    local nInventoryCapacity = self:GetInventoryCapacity(bIsClient)
    local nWeight = self:GetAllItemsWeight(bIsClient)
    if nWeight + nItemWeight > nInventoryCapacity then
        return false
    end

    local FoundItem = nil
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for _, v in pairs(self.tbItemList) do
        local Item = BattleItemSystem:GetItem(v)
        if Item:GetTemplateId() == nItemTemplateId then
            FoundItem = Item
            break
        end
    end

    if FoundItem then
        if FoundItem:GetStackCount() < GetItemMaxStack(self) then
            return true
        else
            return false
        end
    else
        return true
    end
end

return BattleMaterialInventoryRoom