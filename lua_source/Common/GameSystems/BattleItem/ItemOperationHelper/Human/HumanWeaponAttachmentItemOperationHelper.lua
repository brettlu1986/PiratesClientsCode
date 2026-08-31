-----------------------------------------------------
--File Name    : HumanWeaponAttachmentItemOperationHelper.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 11:35:03 AM
--Description  : HumanWeaponAttachmentItemOperationHelper
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local HumanWeaponAttachmentItemOperationHelper = luaclass("HumanWeaponAttachmentItemOperationHelper", ItemCategoryOperationHelperBase)
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanWeaponAttachmentDef = require("HumanWeaponAttachmentDef")
local HumanWeaponAttachmentSlotDef = require("HumanWeaponAttachmentSlotDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
-- local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleHumanWeaponSystemNew

local INVALID_SLOT_INDEX = -1

local tbAttachmentSlots = {
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Muzzle,
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.HandGuard,
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Sight,
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Stock,
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Magazine
}

HumanWeaponAttachmentItemOperationHelper.nMaxSlot = #tbAttachmentSlots


local function GetWeaponIdForAttachmentToEquip(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbEquips = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbTemplate.nAttachmentCategory)
    local nAttachmentId = nItemTemplateId
    local tbCandidateEquipSlots = {}
    for k, v in pairs(tbEquips) do
        local tbEquipTemplate = v:GetTemplate()
        local tbMatchedAttachmentIds = tbEquipTemplate.tbAttachmentSlots[nSlotIndex]
        for _, nId in ipairs(tbMatchedAttachmentIds) do
            if nId == nAttachmentId then
                table.insert(tbCandidateEquipSlots, k)
                break
            end
        end
    end
    if #tbCandidateEquipSlots <= 0 then  -- 没有匹配的
        return INVALID_SLOT_INDEX
    end
    table.sort(tbCandidateEquipSlots)
    local tbCandidatesForEmpty = {}
    local nCurrentWeaponId = nil

    if(BattleHumanWeaponSystemNew == nil) then
        BattleHumanWeaponSystemNew = dynamic_require("BattleHumanWeaponSystemNew")
    end

    for _, nSlot in ipairs(tbCandidateEquipSlots) do
        local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON,nCharacterInstanceId, nSlot, bIsClient)
        local nId = tbWeapon:GetInstanceId()
        local tbAttach = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nId, nSlotIndex, bIsClient)
        local bCurrentWeapon = BattleHumanWeaponSystemNew:IsCurrentWeapon(tbWeapon)

        if bCurrentWeapon then
            if tbAttach == nil then
                return nId
            end
            nCurrentWeaponId = nId
        else
            if tbAttach == nil then
                table.insert(tbCandidatesForEmpty, nId)
            end
        end
    end
    if #tbCandidatesForEmpty > 0 then
        return tbCandidatesForEmpty[1]
    elseif nCurrentWeaponId~= nil then
        return nCurrentWeaponId
    else
        local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON,nCharacterInstanceId, tbCandidateEquipSlots[1], bIsClient)
        local nId = tbWeapon:GetInstanceId()
        return nId
    end
end

local function GetSlotIndexForItemToEquip(nCharacterInstanceId, nHumanWeaponId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbTemplate.nAttachmentCategory)
    local tbAttachment = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, nHumanWeaponId, nSlotIndex, bIsClient)
    if bNeedEmptySlot and tbAttachment ~= nil then
        return INVALID_SLOT_INDEX
    else
        return nSlotIndex
    end
end

local function IsHumanWeaponAttachmentMatched(nCharacterInstanceId, Item, bIsClient)
    local tbAttachmentTemplate = Item:GetTemplate()
    local nAttachmentTemplateId = Item:GetTemplateId()
    local nSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbAttachmentTemplate.nAttachmentCategory)
    local tbEquips = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, bIsClient)
    for k, v in pairs(tbEquips) do
        -- check slot empty
        local tbAttachment = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, v:GetInstanceId(), nSlotIndex, bIsClient)
        if tbAttachment == nil then
            local tbWeaponTemplate = v:GetTemplate()
            local tbCandidates = tbWeaponTemplate.tbAttachmentSlots[nSlotIndex]
            -- check slot matched
            for _, v2 in ipairs(tbCandidates) do
                if v2 == nAttachmentTemplateId then
                    return true
                end
            end
        end
    end
    return false
end

function HumanWeaponAttachmentItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nHumanWeaponId, nSlotIndex, Item, bIsClient)
    if nSlotIndex <= 0 or nSlotIndex > self.nMaxSlot then
        return false
    end
    local tbAttachmentTemplate = Item:GetTemplate()
    if tbAttachmentTemplate.nAttachmentCategory ~= tbAttachmentSlots[nSlotIndex] then
        return false
    end

    local tbWeaponItem = BattleItemSystemHelper:GetItem(nHumanWeaponId, bIsClient)

    local tbWeaponTemplate = tbWeaponItem:GetTemplate()
    local nAttachmenTemplateId = Item:GetTemplateId()
    for _, v in ipairs(tbWeaponTemplate.tbAttachmentSlots[nSlotIndex]) do
        if v == nAttachmenTemplateId then
            return true
        end
    end
    return false
end

-- 是否可以自动拾取, 客户端方法
function HumanWeaponAttachmentItemOperationHelper:CanAutoPickUpOnClient(Item)
    local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    local nCharacterInstanceId = GamePlayerSelfHelper:GetServerInstanceId()
    local bMatched = IsHumanWeaponAttachmentMatched(nCharacterInstanceId, Item, true)
    return bMatched, bMatched
end

-- 是否可以手动拾取, 客户端方法
function HumanWeaponAttachmentItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

function HumanWeaponAttachmentItemOperationHelper:CanAutoEquipWhenOwnerChanged()
    return true
end

-- 获得装配的位置(客户端方法)
function HumanWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local nHumanWeaponId = GetWeaponIdForAttachmentToEquip(nCharacterInstanceId, nItemTemplateId, true)
    local nSlotIdx = GetSlotIndexForItemToEquip(nCharacterInstanceId, nHumanWeaponId, nItemTemplateId, bNeedEmptySlot, true)
    return nHumanWeaponId, nSlotIdx
end

-- 获得装配的位置id(客户端方法)
function HumanWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetSlotIndexForItemToEquip(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function HumanWeaponAttachmentItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return IsHumanWeaponAttachmentMatched(nCharacterInstanceId, Item, false)
end

-- 获得装配的位置（服务端方法）
function HumanWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nHumanWeaponId = GetWeaponIdForAttachmentToEquip(nCharacterInstanceId, nItemTemplateId, false)
    local nSlotIdx = GetSlotIndexForItemToEquip(nCharacterInstanceId, nHumanWeaponId, nItemTemplateId, bNeedEmptySlot, false)
    return nHumanWeaponId, nSlotIdx
end

-- 获得装配的位置id（服务端方法）
function HumanWeaponAttachmentItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nHumanWeaponId, nItemTemplateId, bNeedEmptySlot)
    return GetSlotIndexForItemToEquip(nCharacterInstanceId, nHumanWeaponId, nItemTemplateId, bNeedEmptySlot, false)
end

return HumanWeaponAttachmentItemOperationHelper