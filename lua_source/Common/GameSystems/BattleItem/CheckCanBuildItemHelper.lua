
local CheckCanBuildItemHelper = {}

local ShipItemHelper = require("ShipItemHelper")
local ShipPartTypeDef = require("ShipPartTypeDef")
local HumanWeaponSlotDef = require("HumanWeaponSlotDef")
local HumanArmorSlotDef = require("HumanArmorSlotDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local ShipGradeDataTable = require("ShipGradeDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local ItemBuildingVerificationFailureDef = require("ItemBuildingVerificationFailureDef")

local function fnSortByTemplateId(tbItemTemplate1, tbItemTemplate2)
    return tbItemTemplate1.nId < tbItemTemplate2.nId
end

local function fnSortByGrade(tbItemTemplate1, tbItemTemplate2)
    return tbItemTemplate1.nGrade < tbItemTemplate2.nGrade
end

function CheckCanBuildItemHelper.GetNextCanBuildShipGrade(nCharacterInstanceId, bIsClient)
    local nCurLevel = BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, bIsClient)
    local nMaxGrade = ShipGradeDataTable:GetMaxGrade()
    local nNextBuildLevel = nCurLevel + 1
    if nNextBuildLevel > nMaxGrade then
        nNextBuildLevel = nMaxGrade
    end

    return nNextBuildLevel
end

function CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = {}
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, nSlotIndex, bIsClient)
    if EquippedItem and (not EquippedItem:GetTemplate().bDefaultWeapon) then
        return tbCanBuildTemplateIds
    end
    local tbAvailableShipWeaponTemplates = CheckCanBuildItemHelper.GetAvailableShipWeaponTemplates(nCharacterInstanceId, nSlotIndex, bIsClient)
    for _, v in pairs(tbAvailableShipWeaponTemplates) do
        local nItemTemplateId = v.nId
        local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
        if bSucceeded then
            table.insert(tbCanBuildTemplateIds, nItemTemplateId)
        end
    end
    return tbCanBuildTemplateIds
end

function CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = {}
    local tbAvailableShipPartTemplates = CheckCanBuildItemHelper.GetAvailableShipPartTemplates(nCharacterInstanceId, nSlotIndex, bIsClient)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, nSlotIndex, bIsClient)
    for _, v in pairs(tbAvailableShipPartTemplates) do
        local nItemTemplateId = v.nId
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if not EquippedItem or tbItemTemplate.nGrade > EquippedItem:GetGrade() then
            local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
            if bSucceeded then
                table.insert(tbCanBuildTemplateIds, nItemTemplateId)
            end
        end
    end
    return tbCanBuildTemplateIds
end

function CheckCanBuildItemHelper.GetCanBuildHumanItemTemplateIdsOnSlot(nCharacterInstanceId, nCategory, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = {}
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, nCategory, nCharacterInstanceId, nSlotIndex, bIsClient)
    if EquippedItem then
        local tbSameBaseBuildTemplates = BattleItemBuildDataTable:GetSameBaseBuildItemTemplates(EquippedItem:GetTemplateId())
        for _, v in pairs(tbSameBaseBuildTemplates) do
            local nItemTemplateId = v.nId
            local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
            if tbTemplate.nGrade == EquippedItem:GetGrade() + 1 then
                local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
                if bSucceeded then
                    table.insert(tbCanBuildTemplateIds, nItemTemplateId)
                end
            end
        end
    end
    return tbCanBuildTemplateIds
end

function CheckCanBuildItemHelper.GetCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return CheckCanBuildItemHelper.GetCanBuildHumanItemTemplateIdsOnSlot(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nSlotIndex, bIsClient)
end

function CheckCanBuildItemHelper.GetCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return CheckCanBuildItemHelper.GetCanBuildHumanItemTemplateIdsOnSlot(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nSlotIndex, bIsClient)
end

function CheckCanBuildItemHelper.GetAvailableShipTemplates(nCharacterInstanceId, bIsClient)
    local tbAvailableShipBuildTemplates = {}
    local nCurrentShipItemTemplateId = ShipItemHelper.GetCurrentShipItemTemplateId(nCharacterInstanceId, bIsClient)
    if not nCurrentShipItemTemplateId then
        return tbAvailableShipBuildTemplates
    end
    local nNextBuildLevel = CheckCanBuildItemHelper.GetNextCanBuildShipGrade(nCharacterInstanceId, bIsClient)

    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP, bIsClient)
    if tbBuildDatas == nil then
        return tbAvailableShipBuildTemplates
    end
    for _, v in pairs(tbBuildDatas) do
        local tbShipItemTemplate = v.tbBattleItemTemplate
        if nNextBuildLevel == tbShipItemTemplate.nBuildingLevel and nCurrentShipItemTemplateId ~= tbShipItemTemplate.nId then
            table.insert(tbAvailableShipBuildTemplates, tbShipItemTemplate)
        end
    end
    table.sort(tbAvailableShipBuildTemplates, fnSortByTemplateId)
    return tbAvailableShipBuildTemplates
end

function CheckCanBuildItemHelper.GetAvailableShipWeaponTemplates(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, bIsClient)
    local tbAvailableShipWeaponTemplates = {}
    if tbBuildDatas == nil then
        return tbAvailableShipWeaponTemplates
    end
    for _, v in pairs(tbBuildDatas) do
        local tbItemTemplate = v.tbBattleItemTemplate
        local nWeaponSubCategory = tbItemTemplate.nSubCategory
        local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nWeaponSubCategory)
        if nWeaponSlot == nSlotIndex then
            table.insert(tbAvailableShipWeaponTemplates, tbItemTemplate)
        end
    end
    table.sort(tbAvailableShipWeaponTemplates, fnSortByTemplateId)
    return tbAvailableShipWeaponTemplates
end

function CheckCanBuildItemHelper.GetAvailableShipPartTemplates(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbAvailableShipPartTemplates = {}
    local tbBuildDatas = BattleItemSystemHelper.GetAvailableBuildTemplatesByCategory(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, bIsClient)
    if tbBuildDatas == nil then
        return tbAvailableShipPartTemplates
    end

    for _, v in pairs(tbBuildDatas) do
        local tbItemTemplate = v.tbBattleItemTemplate
        if tbItemTemplate.nSubCategory == nSlotIndex then
            table.insert(tbAvailableShipPartTemplates, tbItemTemplate)
        end
    end
    table.sort(tbAvailableShipPartTemplates, fnSortByGrade)
    return tbAvailableShipPartTemplates
end

function CheckCanBuildItemHelper.CanBuildShip(nCharacterInstanceId, bIsClient)
    local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, bIsClient)
    return #tbCanBuildTemplateIds > 0
end

function CheckCanBuildItemHelper.NeedBuildShipByTemplate(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local EquippedItem = ShipItemHelper.GetCurrentShipItem(nCharacterInstanceId, bIsClient)
    if not EquippedItem then
        return false
    end
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate.nGrade > EquippedItem:GetGrade() then
        local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nil, bIsClient)
        return bSucceeded
    end
    return false
end

function CheckCanBuildItemHelper.NeedBuildShipWeaponByTemplate(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nWeaponSubCategory = tbItemTemplate.nSubCategory
    local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nWeaponSubCategory)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, nWeaponSlot, bIsClient)
    if EquippedItem == nil then
        local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nWeaponSlot, bIsClient)
        return bSucceeded
    end
    return false
end

function CheckCanBuildItemHelper.NeedBuildShipPartByTemplate(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_PART, nCharacterInstanceId, tbItemTemplate.nSubCategory, bIsClient)
    if EquippedItem == nil or tbItemTemplate.nGrade > EquippedItem:GetGrade() then
        local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nil, bIsClient)
        return bSucceeded
    end
    return false
end

function CheckCanBuildItemHelper.NeedBuildHumanWeaponByTemplate(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_WEAPON, nCharacterInstanceId, nSlotIndex, bIsClient)
    if EquippedItem == nil or tbItemTemplate.nGrade > EquippedItem:GetGrade() then
        local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
        return bSucceeded
    end
    return false
end

function CheckCanBuildItemHelper.NeedBuildHumanArmorByTemplate(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId, tbItemTemplate.nArmorCategory, bIsClient)
    if EquippedItem == nil or tbItemTemplate.nGrade > EquippedItem:GetGrade() then
        local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nil, bIsClient)
        return bSucceeded
    end
    return false
end

function CheckCanBuildItemHelper.CanBuildShipByTemplate(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nil, bIsClient)
    return bSucceeded
end

function CheckCanBuildItemHelper.IsShipBuildLock(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local bVerificationResult, tbFailures = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nil, bIsClient)
    if not bVerificationResult then
        for _, tbFailure in ipairs(tbFailures) do
            local nFailureType = tbFailure.nType
            if nFailureType == ItemBuildingVerificationFailureDef.INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL then
                return true
            end
        end
    end
    return false
end

function CheckCanBuildItemHelper.CanBuildShipWeaponOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return #tbCanBuildTemplateIds > 0
end

function CheckCanBuildItemHelper.CanBuildShipPartOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return #tbCanBuildTemplateIds > 0
end

function CheckCanBuildItemHelper.CanBuildHumanWeaponOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildHumanWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return #tbCanBuildTemplateIds > 0
end

function CheckCanBuildItemHelper.CanBuildHumanArmorOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    local tbCanBuildTemplateIds = CheckCanBuildItemHelper.GetCanBuildHumanArmorItemTemplateIdsOnSlot(nCharacterInstanceId, nSlotIndex, bIsClient)
    return #tbCanBuildTemplateIds > 0
end

function CheckCanBuildItemHelper.CanBuildShipWeapon(nCharacterInstanceId, bIsClient)
    for i = ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        if CheckCanBuildItemHelper.CanBuildShipWeaponOnSlot(nCharacterInstanceId, i, bIsClient) then
            return true
        end
    end
    return false
end

function CheckCanBuildItemHelper.CanBuildShipPart(nCharacterInstanceId, bIsClient)
    for i = 1, ShipPartTypeDef.Max do
        if CheckCanBuildItemHelper.CanBuildShipPartOnSlot(nCharacterInstanceId, i, bIsClient) then
            return true
        end
    end
    return false
end

function CheckCanBuildItemHelper.CanBuildHumanWeapon(nCharacterInstanceId, bIsClient)
    for i = 1, HumanWeaponSlotDef:SlotCount() do
        if CheckCanBuildItemHelper.CanBuildHumanWeaponOnSlot(nCharacterInstanceId, i, bIsClient) then
            return true
        end
    end
    return false
end

function CheckCanBuildItemHelper.CanBuildHumanArmor(nCharacterInstanceId, bIsClient)
    for i = 1, HumanArmorSlotDef:SlotCount() do
        if CheckCanBuildItemHelper.CanBuildHumanArmorOnSlot(nCharacterInstanceId, i, bIsClient) then
            return true
        end
    end
    return false
end

function CheckCanBuildItemHelper.CanBuild(nCharacterInstanceId, bIsClient)
    if CheckCanBuildItemHelper.CanBuildShip(nCharacterInstanceId, bIsClient) then
        return true
    end

    if CheckCanBuildItemHelper.CanBuildShipPart(nCharacterInstanceId, bIsClient) then
        return true
    end

    if CheckCanBuildItemHelper.CanBuildShipWeapon(nCharacterInstanceId, bIsClient) then
        return true
    end

    if CheckCanBuildItemHelper.CanBuildHumanWeapon(nCharacterInstanceId, bIsClient) then
        return true
    end

    if CheckCanBuildItemHelper.CanBuildHumanArmor(nCharacterInstanceId, bIsClient) then
        return true
    end

    return false
end

function CheckCanBuildItemHelper.GetCanBuildShipItemTemplateIds(nCharacterInstanceId, bIsClient)
    local tbCanBuildTemplateIds = {}
    local tbAvailableShipTemplates = CheckCanBuildItemHelper.GetAvailableShipTemplates(nCharacterInstanceId, bIsClient)
    local EquippedItem = ShipItemHelper.GetCurrentShipItem(nCharacterInstanceId, bIsClient)
    if not EquippedItem then
        return tbCanBuildTemplateIds
    end

    for _, v in pairs(tbAvailableShipTemplates) do
        local nItemTemplateId = v.nId
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbItemTemplate.nGrade > EquippedItem:GetGrade() then
            local bSucceeded, _ = BattleItemSystemHelper:VerifyItemBuilding(nCharacterInstanceId, nItemTemplateId, nil, bIsClient)
            if bSucceeded then
                table.insert(tbCanBuildTemplateIds, nItemTemplateId)
            end
        end
    end
    return tbCanBuildTemplateIds
end

function CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIds(nCharacterInstanceId, bIsClient)
    local tbCanBuildTemplateIds = {}
    for i = ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipWeaponItemTemplateIdsOnSlot(nCharacterInstanceId, i, bIsClient)
        for _, v in pairs(tbTemplateIds) do
            table.insert(tbCanBuildTemplateIds, v)
        end
    end
    return tbCanBuildTemplateIds
end

function CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIds(nCharacterInstanceId, bIsClient)
    local tbCanBuildTemplateIds = {}
    for i = 1, ShipPartTypeDef.Max do
        local tbTemplateIds = CheckCanBuildItemHelper.GetCanBuildShipPartItemTemplateIdsOnSlot(nCharacterInstanceId, i, bIsClient)
        for _, v in pairs(tbTemplateIds) do
            table.insert(tbCanBuildTemplateIds, v)
        end
    end
    return tbCanBuildTemplateIds
end

function CheckCanBuildItemHelper.GetSameSlotEquippedItem(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nItemCategory = tbItemTemplate.nCategory
    local nSubCategory = tbItemTemplate.nSubCategory
    if nItemCategory == BattleItemCategoryDef.SHIP_WEAPON then
        local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)
        return BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, nItemCategory, nCharacterInstanceId, nWeaponSlot, bIsClient)
    elseif nItemCategory == BattleItemCategoryDef.SHIP_PART then
        return BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, nItemCategory, nCharacterInstanceId, nSubCategory, bIsClient)
    elseif nItemCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        return BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, nItemCategory, nCharacterInstanceId, nSlotIndex, bIsClient)
    elseif nItemCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        return BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, nItemCategory, nCharacterInstanceId, tbItemTemplate.nArmorCategory, bIsClient)
    end
    return nil
end


function CheckCanBuildItemHelper.GetSameSlotEquippedItemTemplateId(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
    local EquippedItem = CheckCanBuildItemHelper.GetSameSlotEquippedItem(nCharacterInstanceId, nItemTemplateId, nSlotIndex, bIsClient)
    if EquippedItem then
        return EquippedItem:GetTemplateId()
    else
        return nil
    end
end

function CheckCanBuildItemHelper.GetNextBuildHumanItemTemplateId(nTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
    local tbSameBaseBuildTemplates = BattleItemBuildDataTable:GetSameBaseBuildItemTemplates(nTemplateId)
    for _, v in pairs(tbSameBaseBuildTemplates) do
        local nItemTemplateId = v.nId
        local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbItemTemplate.nGrade == tbTemplate.nGrade + 1 then
            return nItemTemplateId
        end
    end
    return nil
end

return CheckCanBuildItemHelper
