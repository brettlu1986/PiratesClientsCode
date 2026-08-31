local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local ShipWeaponItemOperationHelper = luaclass("ShipWeaponItemOperationHelper", ItemCategoryOperationHelperBase)

local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local ShipWeaponAttachmentHelper = require("ShipWeaponAttachmentHelper")

ShipWeaponItemOperationHelper.nMaxSlot = ShipWeaponSlotDef.MAX

local function GetAvailableSlotIndex(nCharacterInstanceId, nWeaponItemTemplateId, bForce, bIsClient)
    local tbWeaponItemTemplate = BattleItemDataTable:GetTemplate(nWeaponItemTemplateId)
    local nSubCategory = tbWeaponItemTemplate.nSubCategory
    local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)

    local EquippedWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, nWeaponSlot, bIsClient)
    if (not EquippedWeapon) or EquippedWeapon:GetTemplate().bDefaultWeapon or bForce then
        return nWeaponSlot
    end

    return ShipWeaponSlotDef.UNKNOWN
end

local function VerifyCustomBuildingConditions(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local bSucceeded = GetAvailableSlotIndex(nCharacterInstanceId, nItemTemplateId, true, bIsClient) > 0
    if bSucceeded then
        return true, nil
    else
        local tbFailures = {}
        local tbFailure = {}
        tbFailure.nType = ItemBuildingVerificationFailureDef.NOT_COMPATIBLE
        tbFailure.Params = nil
        table.insert(tbFailures, tbFailure)
        return false, tbFailures
    end
end

local function CheckAttachmentOnServer(nCharacterInstanceId, WeaponItem)
    local tbAttachmentItems = BattleItemSystemHelper:GetUnequippedItemsByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, false)
    table.sort(tbAttachmentItems, function(tbAttachmentA, tbAttachmentB)
        return tbAttachmentA:GetTemplateId() > tbAttachmentB:GetTemplateId()
    end)
    for _, v in ipairs(tbAttachmentItems) do
        local nAttachmentSlotIndex = v:GetSubCategory()
        local tbEquippedAttachmentItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT,
                                             WeaponItem:GetInstanceId(), nAttachmentSlotIndex, false)
        if not tbEquippedAttachmentItem and ShipWeaponAttachmentHelper.IsWeaponAttachmentCompatible(WeaponItem, v:GetTemplateId()) then
            local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
            BattleItemSystemServer:EquipItem(nCharacterInstanceId, WeaponItem:GetInstanceId(), v:GetInstanceId(), nAttachmentSlotIndex, true)
        end
    end
end

-- 检查SlotIndex是否合法
-- @param nSlotIndex 槽位ID
function ShipWeaponItemOperationHelper:IsSlotIndexValid(nSlotIndex)
    return ShipWeaponSlotDef.IsValid(nSlotIndex)
end

function ShipWeaponItemOperationHelper:CanAutoPickUpOnClient(WeaponItem)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local bHasAvailableSlot = GetAvailableSlotIndex(nCharacterInstanceId, WeaponItem:GetTemplateId(), false, true) > 0
    return bHasAvailableSlot, bHasAvailableSlot
end

function ShipWeaponItemOperationHelper:CanManuallyPickUpOnClient(WeaponItem)
    return true
end

-- 获得装配的位置(客户端方法)
function ShipWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nWeaponItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return nCharacterInstanceId, GetAvailableSlotIndex(nCharacterInstanceId, nWeaponItemTemplateId, not bNeedEmptySlot, true)
end

-- 获得装配的位置id(客户端方法)
function ShipWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nWeaponItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetAvailableSlotIndex(nCharacterInstanceId, nWeaponItemTemplateId, not bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function ShipWeaponItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return GetAvailableSlotIndex(nCharacterInstanceId, Item:GetTemplateId(), false, false) > 0
end

-- 获得装配的位置（服务端方法）
function ShipWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nWeaponItemTemplateId, bNeedEmptySlot)
    return nCharacterInstanceId, GetAvailableSlotIndex(nCharacterInstanceId, nWeaponItemTemplateId, not bNeedEmptySlot, false)
end

-- 获得装配的位置id（服务端方法）
function ShipWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nWeaponItemTemplateId, bNeedEmptySlot)
    return GetAvailableSlotIndex(nCharacterInstanceId, nWeaponItemTemplateId, not bNeedEmptySlot, false)
end

function ShipWeaponItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, WeaponItem, bIsClient)
    local nSubCategory = WeaponItem:GetSubCategory()
    local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)
    return nWeaponSlot == nSlotIndex
end

function ShipWeaponItemOperationHelper:VerifyCustomBuildingConditionsOnClient(nItemTemplateId, _)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return VerifyCustomBuildingConditions(nCharacterInstanceId, nItemTemplateId, true)
end

function ShipWeaponItemOperationHelper:VerifyCustomBuildingConditionsOnServer(nCharacterInstanceId, nItemTemplateId, _)
    return VerifyCustomBuildingConditions(nCharacterInstanceId, nItemTemplateId, false)
end

function ShipWeaponItemOperationHelper:AfterBuiltOnServer(nCharacterInstanceId, Item)
    CheckAttachmentOnServer(nCharacterInstanceId, Item)
end

function ShipWeaponItemOperationHelper:AfterPickedUpOnServer(nCharacterInstanceId, Item)
    CheckAttachmentOnServer(nCharacterInstanceId, Item)
end

-- 是否玩家可见
function ShipWeaponItemOperationHelper:CanKnownByPlayer(nItemTemplateId)
    local tbWeaponItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    return not tbWeaponItemTemplate.bDefaultWeapon
end

return ShipWeaponItemOperationHelper
