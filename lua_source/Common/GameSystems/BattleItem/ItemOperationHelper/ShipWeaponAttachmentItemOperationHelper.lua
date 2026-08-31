-----------------------------------------------------
--File Name    : ShipWeaponAttachmentItemOperationHelper.lua
--Author       : chenjing6
--Create Time  : 2018-08-03
--Description  : 武器配件插槽物件
-----------------------------------------------------

local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local ShipWeaponAttachmentItemOperationHelper = luaclass("ShipWeaponAttachmentItemOperationHelper", ItemCategoryOperationHelperBase)

local WeaponAttachmentTypeDef   = require("ShipWeaponAttachmentTypeDef")
local GameObjectSystem  = dynamic_require("GameObjectSystem")
local ShipWeaponAttachmentHelper = require("ShipWeaponAttachmentHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

ShipWeaponAttachmentItemOperationHelper.nMaxSlot = WeaponAttachmentTypeDef.Max

function ShipWeaponAttachmentItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nWeaponId, nSlotIndex, tbAttachmentItem, bIsClient)
    assert(tbAttachmentItem, "CheckItemSlotCompatibility(): Invalid Weapon Attachment Item.")
    local tbPlayerObject = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    if tbPlayerObject then
        local tbAttachmentTemplate = tbAttachmentItem.tbTemplate
        assert(tbAttachmentTemplate, "Invalid Weapon Attachment Template.")
        if tbAttachmentTemplate.nSubCategory == nSlotIndex then
            local tbWeaponItem = BattleItemSystemHelper:GetItem(nWeaponId, bIsClient)
            if tbWeaponItem then
                if ShipWeaponAttachmentHelper.IsWeaponAttachmentCompatible(tbWeaponItem, tbAttachmentItem:GetTemplateId()) then
                    return true
                end
            end
        end
    end

    return false
end

function ShipWeaponAttachmentItemOperationHelper:CanAutoEquipWhenOwnerChanged()
    return true
end

-- 是否可以自动拾取
function ShipWeaponAttachmentItemOperationHelper:CanAutoPickUpOnClient(tbItemObject)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local bHasEmptySlot = ShipWeaponAttachmentHelper.FindWeaponToReceiveAttachment(nCharacterInstanceId, tbItemObject:GetTemplateId(), false, true) > 0
    return bHasEmptySlot, bHasEmptySlot
end

-- 是否可以手动拾取
function ShipWeaponAttachmentItemOperationHelper:CanManuallyPickUpOnClient(tbItemObject)
    return true
end

local function GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nWeaponAttachmentItemTemplateId, bNeedEmptySlot, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponAttachmentItemTemplateId)
    local nAttachmentSlotIndex = tbTemplate.nSubCategory
    local nWeaponInstanceId = ShipWeaponAttachmentHelper.FindWeaponToReceiveAttachment(nCharacterInstanceId, nWeaponAttachmentItemTemplateId, not bNeedEmptySlot, bIsClient)
    return nWeaponInstanceId, nAttachmentSlotIndex
end

local function GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nWeaponId, nWeaponAttachmentItemTemplateId, bNeedEmptySlot, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nWeaponAttachmentItemTemplateId)
    local nAttachmentSlotIndex = tbTemplate.nSubCategory
    local tbWeaponItem = BattleItemSystemHelper:GetItem(nWeaponId, bIsClient)
    if ShipWeaponAttachmentHelper.IsWeaponAttachmentCompatible(tbWeaponItem, nWeaponAttachmentItemTemplateId) then
        if bNeedEmptySlot then
            local tbEquippedAttachmentItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), nAttachmentSlotIndex, bIsClient)
            if tbEquippedAttachmentItem then
                nAttachmentSlotIndex = -1
            end
        end
    else
        nAttachmentSlotIndex = -1
    end
    return nAttachmentSlotIndex
end

-- 获得装配的位置(客户端方法)
function ShipWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 获得装配的位置id(客户端方法)
function ShipWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function ShipWeaponAttachmentItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return ShipWeaponAttachmentHelper.FindWeaponToReceiveAttachment(nCharacterInstanceId, Item:GetTemplateId(), false, false) > 0
end

-- 获得装配的位置（服务端方法）
function ShipWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nWeaponAttachmentItemTemplateId, bNeedEmptySlot)
    return GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nWeaponAttachmentItemTemplateId, bNeedEmptySlot, false)
end

-- 获得装配的位置id（服务端方法）
function ShipWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nWeaponId, nWeaponAttachmentItemTemplateId, bNeedEmptySlot)
    return GetAvailableEquipmentSlotForItemWithOwner(nCharacterInstanceId, nWeaponId, nWeaponAttachmentItemTemplateId, bNeedEmptySlot, false)
end

return ShipWeaponAttachmentItemOperationHelper