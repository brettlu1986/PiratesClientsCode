-----------------------------------------------------
--File Name    : HumanWeaponItemOperationHelper.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 11:35:03 AM
--Description  : HumanWeaponItemOperationHelper
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local HumanWeaponItemOperationHelper = luaclass("HumanWeaponItemOperationHelper", ItemCategoryOperationHelperBase)

local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")
local HumanWeaponAttachmentSlotDef = require("HumanWeaponAttachmentSlotDef")

local INVALID_SLOT_INDEX = -1

HumanWeaponItemOperationHelper.nMaxSlot = HumanWeaponSlotDef:SlotCount()


local function GetOwnerIdForItemToEquip(nCharacterInstanceId, _nItemTemplateId)
    return nCharacterInstanceId
end

local function HasMatchedSlot(tbMatchedSlots)
    if #tbMatchedSlots == 0 then
        return false
    end
    return true
end

local function GetEmptySlot(nCharacterInstanceId, tbMatchedSlots, bIsClient)
    for _, nSlotIndex in pairs(tbMatchedSlots) do
        local tbWeaponItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlotIndex, bIsClient)
        if tbWeaponItem == nil then
            return nSlotIndex
        end
    end
    return nil
end

local function GetSameAndLowGradeWeaponSlot(nCharacterInstanceId, tbTemplate, bIsClient)
    local nSameAndLowGradeWeaponSlot = nil
    local nItemTemplateId = tbTemplate.nId
    local nMaxCount = HumanWeaponSlotDef:SlotCount()
    local nMinGrade = tbTemplate.nGrade
    for nIdx = 1, nMaxCount do
        local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nIdx, bIsClient)
        if tbWeapon ~= nil then
            if BattleItemBuildDataTable:IsSameBaseItemTemplateIds(tbWeapon:GetTemplateId(), nItemTemplateId) then
                if nMinGrade > tbWeapon:GetGrade() then
                    nSameAndLowGradeWeaponSlot = nIdx
                    nMinGrade = tbWeapon:GetGrade()
                end
            end
        end
    end
    return nSameAndLowGradeWeaponSlot
end

-- local function GetCurrentLowGradeWeaponSlot(nCharacterInstanceId, tbMatchedSlots, bIsClient)
--     local tbWeapons = {}
--     for _, nSlotIndex in pairs(tbMatchedSlots) do
--         local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlotIndex, bIsClient)
--         table.insert(tbWeapons, tbWeapon)
--     end
--     local bSameGrade = true
--     local tbMinGradeWeapon = nil
--     if #tbWeapons > 0 then
--         for _, v in ipairs(tbWeapons) do
--             if not tbMinGradeWeapon then
--                 tbMinGradeWeapon = v
--             else
--                 if v:GetGrade() < tbMinGradeWeapon:GetGrade() then
--                     tbMinGradeWeapon = v
--                     bSameGrade = false
--                 elseif v:GetGrade() > tbMinGradeWeapon:GetGrade() then
--                     bSameGrade = false
--                 end
--             end
--         end
--     end
--     local nLowGradeWeaponSlot = nil
--     if not bSameGrade then
--         local _, _, nSlot = tbMinGradeWeapon:SplitAndGetStorageLocation()
--         nLowGradeWeaponSlot = nSlot
--     end
--     return nLowGradeWeaponSlot
-- end

local function IsCurrentSlotMatch(tbMatchedSlotIndexes, nCurrentSlotIndex)
    for _, v in pairs(tbMatchedSlotIndexes) do
        if v == nCurrentSlotIndex then
            return true
        end
    end
    return false
end

local function GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local tbMatchedSlots = HumanWeaponHelper.GetMatchedSlotIndexes(nItemTemplateId)
    if not HasMatchedSlot(tbMatchedSlots) then
        return INVALID_SLOT_INDEX
    end
    -- 有空槽位
    local nEmptySlot = GetEmptySlot(nCharacterInstanceId, tbMatchedSlots, bIsClient)
    if nEmptySlot then
        return nEmptySlot
    end
    local tbCharacter = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    --if tbCharacter:IsShip() then
    -- 判断是否有相同的但是等级较低的武器槽位
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nSameAndLowGradeWeaponSlot = GetSameAndLowGradeWeaponSlot(nCharacterInstanceId, tbTemplate, bIsClient)

    if nSameAndLowGradeWeaponSlot then
        return nSameAndLowGradeWeaponSlot
    end
    --end
    if bNeedEmptySlot then
        return INVALID_SLOT_INDEX
    end

    -- -- 与被拾取武器的类型都不同，选等级低的
    -- local nLowGradeWeaponSlot = GetCurrentLowGradeWeaponSlot(nCharacterInstanceId, tbMatchedSlots, bIsClient)
    -- if nLowGradeWeaponSlot then
    --     return nLowGradeWeaponSlot
    -- end

    local nFirstMatchedSlotIdx = tbMatchedSlots[1]


    -- if tbCharacter:IsShip() then
    --     return nFirstMatchedSlotIdx
    -- end

    local nCurWeaponId = nil
    if tbCharacter:IsShip() then
        nCurWeaponId = HumanWeaponHelper.GetSavedCurrentWeaponFromOwner(tbCharacter)
    else
        nCurWeaponId = tbCharacter.HumanWeaponComponent:GetCurrentWeaponInstanceId()
    end

    if nCurWeaponId == 0 or nCurWeaponId == nil then
        return nFirstMatchedSlotIdx
    end

    local tbCurWeapon = BattleItemSystemHelper:GetItem(nCurWeaponId, bIsClient)
    if not tbCurWeapon then
        return nFirstMatchedSlotIdx
    end
    if tbCurWeapon:GetCategory() ~= BattleItemCategoryDef.HUMAN_WEAPON then -- 当前手持装备不是武器,可能是手雷
        return nFirstMatchedSlotIdx
    end
    local nCurWeaponSlotIdx = tbCurWeapon.tbStorageLocation.nSlotIndex
    local bMatched = IsCurrentSlotMatch(tbMatchedSlots, nCurWeaponSlotIdx)
    if bMatched then
        return nCurWeaponSlotIdx
    else
        return nFirstMatchedSlotIdx
    end
end

local function CheckAttachmentOnServer(nCharacterInstanceId, WeaponItem)
    local tbAttachmentItems = BattleItemSystemHelper:GetUnequippedItemsByCategory(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT, false)
    table.sort(tbAttachmentItems, function(tbAttachmentA, tbAttachmentB)
        return tbAttachmentA:GetTemplateId() > tbAttachmentB:GetTemplateId()
    end)
    for _, v in ipairs(tbAttachmentItems) do
        local tbAttachmentTemplate = v:GetTemplate()
        local nAttachmentSlotIndex = HumanWeaponAttachmentSlotDef:GetSlotIndex(tbAttachmentTemplate.nAttachmentCategory)
        local tbEquippedAttachmentItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON_ATTACHMENT,
                                             WeaponItem:GetInstanceId(), nAttachmentSlotIndex, false)
        if not tbEquippedAttachmentItem then
            local tbWeaponTemplate = WeaponItem:GetTemplate()
            local tbCandidates = tbWeaponTemplate.tbAttachmentSlots[nAttachmentSlotIndex]
            -- check slot matched
            for _, v1 in ipairs(tbCandidates) do
                if v1 == v:GetTemplateId() then
                    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
                    BattleItemSystemServer:EquipItem(nCharacterInstanceId, WeaponItem:GetInstanceId(), v:GetInstanceId(), nAttachmentSlotIndex, true)
                end
            end
        end
    end
end


function HumanWeaponItemOperationHelper:CheckItemSlotCompatibility(nCharacterInstanceId, nOwnerItemInstanceId, nSlotIndex, Item, bIsClient)
    if nSlotIndex <= 0 or nSlotIndex > self.nMaxSlot then
        return false
    end

    local tbTemplate = Item:GetTemplate()
    local tbMatchedSlotTypes = tbTemplate.tbMatchedSlotTypes
    for _, nSlotType in ipairs(tbMatchedSlotTypes) do
        if nSlotType & HumanWeaponSlotDef.Slots[nSlotIndex] ~= 0 then
            return true
        end
    end
    return false
end

local function CanAutoPickUp(nCharacterInstanceId, Item, bIsClient)
    local tbTemplate = Item:GetTemplate()
    local tbMatchedSlotTypes = tbTemplate.tbMatchedSlotTypes
    local nMaxCount = HumanWeaponSlotDef:SlotCount()
    -- 先判断是否有空槽位
    for nIdx = 1, nMaxCount do
        local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nIdx, bIsClient)
        if tbWeapon == nil then
            for _, nSlotType in ipairs(tbMatchedSlotTypes) do
                if nSlotType & HumanWeaponSlotDef.Slots[nIdx] ~= 0 then
                    return true, true
                end
            end
        end
    end
    -- 判断是否有相同的但是等级较低的武器
    local nItemTemplateId = tbTemplate.nId
    -- local tbCharacter = GameObjectSystem:FindByInstanceId(nCharacterInstanceId)
    for nIdx = 1, nMaxCount do
        local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nIdx, bIsClient)
        if tbWeapon ~= nil then
            if BattleItemBuildDataTable:IsSameBaseItemTemplateIds(tbWeapon:GetTemplateId(), nItemTemplateId)
                and tbWeapon:GetGrade() < tbTemplate.nGrade then
                    return true, true
                    -- if tbCharacter:IsShip() then
                    --     return true, true
                    -- else
                    --     return true, false
                    -- end
            end
        end
    end
    return false, false
end

-- 是否可以自动拾取, 客户端方法
function HumanWeaponItemOperationHelper:CanAutoPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return CanAutoPickUp(nCharacterInstanceId, Item, true)
end

-- 是否可以手动拾取, 客户端方法
function HumanWeaponItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 获得装配的位置(客户端方法)
function HumanWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local nOwnerInstanceId = GetOwnerIdForItemToEquip(nCharacterInstanceId, nItemTemplateId)
    local nSlotIdx = GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, true)
    return nOwnerInstanceId, nSlotIdx
end

-- 获得装配的位置id(客户端方法)
function HumanWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function HumanWeaponItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    local _, bAuto = CanAutoPickUp(nCharacterInstanceId, Item, false)
    return bAuto
end

-- 获得装配的位置（服务端方法）
function HumanWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nOwnerInstanceId = GetOwnerIdForItemToEquip(nCharacterInstanceId, nItemTemplateId)
    local nSlotIdx = GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, false)

    return nOwnerInstanceId, nSlotIdx
end

-- 获得装配的位置id（服务端方法）
function HumanWeaponItemOperationHelper:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
    return GetSlotIndexForItemToEquip(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot, false)
end

local function FillFailures(nFailureType)
    local tbFailure = {}
    tbFailure.nType = nFailureType
    tbFailure.Params = nil
    local tbFailures = {}
    table.insert(tbFailures, tbFailure)
    return tbFailures
end

local function VerifyCustomBuildingConditions(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlotIndex, bIsClient)
    if not EquippedItem then
        local tbFailures = FillFailures(ItemBuildingVerificationFailureDef.NO_LOW_LEVEL_HUMAN_WEAPON)
        return false, tbFailures
    end

    local tbBuildItemTemplate = BattleItemBuildDataTable:GetBuildTemplate(nItemTemplateId)
    if tbBuildItemTemplate.nPrerequisiteId ~= EquippedItem:GetTemplateId() then
        local tbFailures = FillFailures(ItemBuildingVerificationFailureDef.NO_LOW_LEVEL_HUMAN_WEAPON)
        return false, tbFailures
    end
    return true, nil
end

function HumanWeaponItemOperationHelper:VerifyCustomBuildingConditionsOnClient(nItemTemplateId, nSlotIndex)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    return VerifyCustomBuildingConditions(nCharacterInstanceId, nItemTemplateId, nSlotIndex, true)
end

function HumanWeaponItemOperationHelper:VerifyCustomBuildingConditionsOnServer(nCharacterInstanceId, nItemTemplateId, nSlotIndex)
    return VerifyCustomBuildingConditions(nCharacterInstanceId, nItemTemplateId, nSlotIndex, false)
end

function HumanWeaponItemOperationHelper:AfterBuiltOnServer(nCharacterInstanceId, Item)
    CheckAttachmentOnServer(nCharacterInstanceId, Item)
end

function HumanWeaponItemOperationHelper:AfterPickedUpOnServer(nCharacterInstanceId, Item)
    CheckAttachmentOnServer(nCharacterInstanceId, Item)
end

return HumanWeaponItemOperationHelper