-----------------------------------------------------
--File Name    : HumanArmorItemOperationHelper.lua
--Author       : WuJizhou
--Create Time  : 9/11/2018, 3:12:21 PM
--Description  : HumanArmorItemOperationHelper
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local HumanArmorItemOperationHelper = luaclass("HumanArmorItemOperationHelper", ItemCategoryOperationHelperBase)
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")

local INVALID_SLOT_INDEX = -1
-- 最大槽位个数，槽位index需要从1开始且连续
HumanArmorItemOperationHelper.nMaxSlot = HumanArmorSlotDef:SlotCount()

local function GetOwnerIdForItemToEquip(nCharacterInstanceId, _nTemplateId)
    return nCharacterInstanceId
end

local function GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nArmorCategory = tbTemplate.nArmorCategory
    local nMatchedSlotIdxButNotEmpty = nil
    for nIdx, v in ipairs(HumanArmorSlotDef.ArmorSlots) do
        if v == nArmorCategory then
            local tbArmor = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId, nIdx, bIsClient)
            if tbArmor == nil then
                return nIdx
            else
                nMatchedSlotIdxButNotEmpty = (nMatchedSlotIdxButNotEmpty == nil and nIdx or nMatchedSlotIdxButNotEmpty)
            end
        end
    end
    if nMatchedSlotIdxButNotEmpty ~= nil and not bNeedEmptySlot then
        return nMatchedSlotIdxButNotEmpty
    else
        return INVALID_SLOT_INDEX
    end
end

local function GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local nOwnerInstanceId = GetOwnerIdForItemToEquip(nCharacterInstanceId, nItemTemplateId)
    local nSlotIndex = GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    return nOwnerInstanceId, nSlotIndex
end

-- 检查物品和槽位是否兼容
function HumanArmorItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, Item, bIsClient)
    local nCategory = HumanArmorSlotDef.ArmorSlots[nSlotIndex]
    local nTemplateArmorCategory = Item:GetTemplate().nArmorCategory
    return nTemplateArmorCategory == nCategory
end

local function IsBetterHumanArmor(Item, nCharacterInstanceId, bIsClient)
    local tbTemplate = Item:GetTemplate()
    local nTemplateArmorCategory = tbTemplate.nArmorCategory
    local nSlotIndex = nil
    for nIdx, v in ipairs(HumanArmorSlotDef.ArmorSlots) do
        if v == nTemplateArmorCategory then
            nSlotIndex = nIdx
            break
        end
    end
    if nSlotIndex ~= nil then
        local tbEquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId, nSlotIndex, bIsClient)
        if not tbEquippedItem then
            return true, false
        elseif BattleItemBuildDataTable:IsSameBaseItemTemplateIds(tbTemplate.nId, tbEquippedItem:GetTemplateId())
            and (tbTemplate.nGrade >= tbEquippedItem:GetTemplate().nGrade and Item:GetDurability() >= tbEquippedItem:GetDurability())
            and not (tbTemplate.nGrade == tbEquippedItem:GetTemplate().nGrade and Item:GetDurability() == tbEquippedItem:GetDurability()) then
            return true, true
        end
    end
    return false, false
end

-- 是否可以自动拾取, 客户端方法
function HumanArmorItemOperationHelper:CanAutoPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return IsBetterHumanArmor(Item, nCharacterInstanceId, true)
end

-- 是否可以手动拾取, 客户端方法
function HumanArmorItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 获得装配的位置(客户端方法)
function HumanArmorItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 获得装配的位置id(客户端方法)
function HumanArmorItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function HumanArmorItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    local bIsBetter, _ = IsBetterHumanArmor(Item, nCharacterInstanceId, false)
    return bIsBetter
end

-- 获得装配的位置（服务端方法）
function HumanArmorItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    return GetAvailableEquipmentSlotForItem(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, false)
end

-- 获得装配的位置id（服务端方法）
function HumanArmorItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, false)
end


return HumanArmorItemOperationHelper