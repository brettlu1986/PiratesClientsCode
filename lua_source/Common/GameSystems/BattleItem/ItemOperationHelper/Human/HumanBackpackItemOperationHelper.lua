-----------------------------------------------------
--File Name    : HumanBackpackItemOperationHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-13
--Description  : 人的背包物品操作
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local HumanBackpackItemOperationHelper = luaclass("HumanBackpackItemOperationHelper", ItemCategoryOperationHelperBase)

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemUnequipCheckFailureDef = require("BattleItemUnequipCheckFailureDef")
local BattleItemThrowAwayCheckFailureDef = require("BattleItemThrowAwayCheckFailureDef")
local HumanInventoryHelper = require("HumanInventoryHelper")

-- 最大槽位个数，槽位index需要从1开始且连续
HumanBackpackItemOperationHelper.nMaxSlot = 1

local HUMAN_BACK_PACK_SLOT = 1

-------------------------------------------local function-------------------------------------------------

local function CheckItemSlotCompatibility(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, bIsClient)
    if nSlotIndex ~= HUMAN_BACK_PACK_SLOT then
        return false
    end

    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_BACKPACK, nOwnerInstanceId, nSlotIndex, bIsClient)

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if EquippedItem == nil or tbTemplate.nGrade >= EquippedItem:GetGrade() then
        return true
    end

    local nItemRoomType = BattleItemRoomDef.HUMAN_INVENTORY
    local nAllItemsWeight = BattleItemSystemHelper:GetAllItemsWeight(nCharacterInstanceId, nItemRoomType, bIsClient)
    local nInventorySlotsCount = BattleItemSystemHelper:GetInventorySlotsCount(nCharacterInstanceId, nItemRoomType, bIsClient)

    local nCapacityBase = HumanInventoryHelper:GetHumanBackpackCapacityBase()
    local nMaxInventorySlotsBase = HumanInventoryHelper:GetHumanBackpackMaxInventorySlotsBase()

    if nCapacityBase + tbTemplate.nInventoryCapacity < nAllItemsWeight then
        return false
    end

    if nMaxInventorySlotsBase + tbTemplate.nMaxInventorySlots < nInventorySlotsCount then
        return false
    end

    return true
end

local function CheckItemBetter(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, nItemTemplateId, bIsClient)
    if nSlotIndex ~= HUMAN_BACK_PACK_SLOT then
        return false
    end

    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_BACKPACK, nOwnerInstanceId, nSlotIndex, bIsClient)

    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if EquippedItem == nil or tbTemplate.nGrade > EquippedItem:GetGrade() then
        return true
    end
    return false
end


------------------------------------------客户端服务端共用的方法-----------------------------------------------

function HumanBackpackItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item, bIsClient)
    return CheckItemSlotCompatibility(self, nCharacterInstanceId, nOwnerInstanceId, nSlotIndex, Item:GetTemplateId(), bIsClient)
end

-------------------------------------------客户端方法----------------------------------------------------------------

function HumanBackpackItemOperationHelper:CanAutoPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local bIsBetter = CheckItemBetter(self, nCharacterInstanceId, nCharacterInstanceId, HUMAN_BACK_PACK_SLOT, Item:GetTemplateId(), true)
    return bIsBetter, bIsBetter
end

function HumanBackpackItemOperationHelper:CanManuallyPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return CheckItemSlotCompatibility(self, nCharacterInstanceId, nCharacterInstanceId, HUMAN_BACK_PACK_SLOT, Item:GetTemplateId(), true)
end

function HumanBackpackItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local nSlotIndex = self:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    if nSlotIndex == -1 then
        return -1, -1
    end
    return nCharacterInstanceId, nSlotIndex
end

function HumanBackpackItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    if CheckItemSlotCompatibility(self, nCharacterInstanceId, nOwnerInstanceId, HUMAN_BACK_PACK_SLOT, nItemTemplateId, true) then
        return HUMAN_BACK_PACK_SLOT
    else
        return -1
    end
end

---------------------------------------------服务端方法-----------------------------------------------------------------

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function HumanBackpackItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return CheckItemBetter(self, nCharacterInstanceId, nCharacterInstanceId, HUMAN_BACK_PACK_SLOT, Item:GetTemplateId(), false)
end

function HumanBackpackItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nSlotIndex = self:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    if nSlotIndex == -1 then
        return -1, -1
    end
    return nCharacterInstanceId, nSlotIndex
end

function HumanBackpackItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    if CheckItemSlotCompatibility(self, nCharacterInstanceId, nOwnerInstanceId, HUMAN_BACK_PACK_SLOT, nItemTemplateId, false) then
        return HUMAN_BACK_PACK_SLOT
    else
        return -1
    end
end

local function CanUnEquipOnServer(self, nCharacterInstanceId, Item)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local nItemRoomType = BattleItemRoomDef.HUMAN_INVENTORY

    local nAllItemsWeight = BattleItemSystemServer:GetAllItemsWeight(nCharacterInstanceId, nItemRoomType)
    local nCapacityBase = HumanInventoryHelper:GetHumanBackpackCapacityBase()

    if nAllItemsWeight > nCapacityBase then
        return false
    end

    local nInventorySlotsCount = BattleItemSystemServer:GetInventorySlotsCount(nCharacterInstanceId, nItemRoomType)
    local nMaxInventorySlotsBase = HumanInventoryHelper:GetHumanBackpackMaxInventorySlotsBase()
    if nInventorySlotsCount > nMaxInventorySlotsBase then
        return false
    end

    return true
end

-- 是否可以卸下
function HumanBackpackItemOperationHelper:CanUnequipOnServer(nCharacterInstanceId, Item)
    local bCanUnequip = CanUnEquipOnServer(self, nCharacterInstanceId, Item)
    if not bCanUnequip then
        return bCanUnequip, BattleItemUnequipCheckFailureDef.INVENTORY_CAPACITY_NOT_ENOUGHT
    end
    return true
end


-- 是否可以扔掉
function HumanBackpackItemOperationHelper:CanThrowAwayOnServer(nCharacterInstanceId, Item)
    local bCanUnequip = CanUnEquipOnServer(self, nCharacterInstanceId, Item)
    if not bCanUnequip then
        return bCanUnequip, BattleItemThrowAwayCheckFailureDef.INVENTORY_CAPACITY_NOT_ENOUGHT
    end
    return true
end

return HumanBackpackItemOperationHelper