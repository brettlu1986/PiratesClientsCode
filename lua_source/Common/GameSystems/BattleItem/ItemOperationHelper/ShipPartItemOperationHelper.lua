local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local ShipPartItemOperationHelper = luaclass("ShipPartItemOperationHelper", ItemCategoryOperationHelperBase)

local ShipPartTypeDef   = require("ShipPartTypeDef")
local GameObjectSystem  = dynamic_require("GameObjectSystem")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

ShipPartItemOperationHelper.nMaxSlot = ShipPartTypeDef.Max


local function IsShipPartSlotActive(nCharacterInstanceId, nSlotIndex)
    return true
end



--------------------------------------------------------------------------------------------------------------

function ShipPartItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, tbShipPart, bIsClient)
    assert(tbShipPart, "ShipPartItemOperationHelper:CheckItemSlotCompatibility: Invalid ship part item")
    local tbPlayerObject = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if tbPlayerObject then
        local tbTemplateShipPart = tbShipPart.tbTemplate
        assert(tbTemplateShipPart, "ShipPartItemOperationHelper:CheckItemSlotCompatibility: Invalid ship part config")
        if tbTemplateShipPart.nSubCategory == nSlotIndex then
            if IsShipPartSlotActive(nCharacterInstanceId, nSlotIndex) then
                return true
            end
        end
    end
    return false
end

local function IsShipPartBetter(nCharacterInstanceId, Item, bIsClient)
    local nSlotIndex = Item:GetSubCategory()
    local tbEquipedShipPartItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, nSlotIndex, bIsClient)
    if not tbEquipedShipPartItem then
        return true
    end

    if Item:GetGrade() >= tbEquipedShipPartItem:GetGrade()
        and Item:GetDurability() > tbEquipedShipPartItem:GetDurability() then
        return true
    end

    return false
end

-- 是否可以自动拾取
function ShipPartItemOperationHelper:CanAutoPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local bIsBetter = IsShipPartBetter(nCharacterInstanceId, Item, true)
    return bIsBetter, bIsBetter
end

-- 是否可以手动拾取
function ShipPartItemOperationHelper:CanManuallyPickUpOnClient(tbItemObject)
    return true
end

local function GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nSlotIndex = tbTemplate.nSubCategory
    if bNeedEmptySlot then
        local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, nOwnerInstanceId, nSlotIndex, bIsClient)
        if EquippedItem ~= nil then
            nSlotIndex = -1
        end
    end
    return nSlotIndex
end

local function GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local nOwnerInstanceId = nCharacterInstanceId
    local nSlotIndex = GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    if nSlotIndex <= 0 then
        nOwnerInstanceId = -1
    end
    return nOwnerInstanceId, nSlotIndex
end

-- 获得装配的位置(客户端方法)
function ShipPartItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 获得装配的位置id(客户端方法)
function ShipPartItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function ShipPartItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return IsShipPartBetter(nCharacterInstanceId, Item, false)
end

-- 获得装配的位置（服务端方法）
function ShipPartItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    return GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, false)
end

-- 获得装配的位置id（服务端方法）
function ShipPartItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot, false)
end

return ShipPartItemOperationHelper