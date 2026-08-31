local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local BuildKeyItemOperationHelper = luaclass("BuildKeyItemOperationHelper", ItemCategoryOperationHelperBase)
local BattleItemBuildDataTable = require("BattleItemBuildDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")
local FFAItemIni = require("FFAItemIni")

local function IsIgnoreShipWeapon(nTemplateId)
    local tbAutoPickUp = FFAItemIni.tbAutoPickUp

    if tbAutoPickUp == nil then
        return false
    end

    local tbIgnoreShipWeapons = tbAutoPickUp.tbIgnoreShipWeapons
    if tbIgnoreShipWeapons == nil or #tbIgnoreShipWeapons == 0 then
        return false
    end

    for _, v in pairs(tbIgnoreShipWeapons) do
        if v == nTemplateId then
            return true
        end
    end
    return false
end

local function GetEmptyWeaponSlot(nCharacterInstanceId, tbShipWeaponItemTemplate, bIsClient)
    local nSubCategory = tbShipWeaponItemTemplate.nSubCategory
    local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)
    local tbEmptySupportedSlots = {}
    local EquippedWeapon = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, nWeaponSlot, bIsClient)
    if EquippedWeapon == nil or EquippedWeapon:GetTemplate().bDefaultWeapon or IsIgnoreShipWeapon(EquippedWeapon:GetTemplateId()) then
        table.insert(tbEmptySupportedSlots, nWeaponSlot)
    end
    return tbEmptySupportedSlots
end

local function CheckOneKeyItemCanBuildWeaponInOneSlot(nCharacterInstanceId, KeyItem, tbEmptySupportedSlots)
    local nKeyItemTemplateId = KeyItem:GetTemplateId()
    local nBuildItemTemplateId = BattleItemBuildDataTable:GetKeyItemBuildItemTemplateId(nKeyItemTemplateId)
    local tbBuildItemTemplate = BattleItemDataTable:GetTemplate(nBuildItemTemplateId)
    local nCategory = tbBuildItemTemplate.nCategory
    if nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        -- 检查对应的武器能不能装上
        local nSubCategory = tbBuildItemTemplate.nSubCategory
        local nWeaponSlot = ShipWeaponCategoryDataTable:GetWeaponSlot(nSubCategory)
        for _, v in pairs(tbEmptySupportedSlots) do
            if v == nWeaponSlot then
                return true
            end
        end
    end
    return false
end

local function HasSamePosWeaponKeyItem(nCharacterInstanceId, tbEmptySupportedSlots, bIsClient)
    local tbKeyItems = BattleItemSystemHelper:GetUnequippedItemsByCategory(nCharacterInstanceId, BattleItemCategoryDef.BUILD_KEY_ITEM, bIsClient)
    for _, KeyItem in pairs(tbKeyItems) do
        local bCanBuild = CheckOneKeyItemCanBuildWeaponInOneSlot(nCharacterInstanceId, KeyItem, tbEmptySupportedSlots)
        if bCanBuild then
            return true
        end
    end
    return false
end

local function IfNeedShipWeaponKeyItem(nCharacterInstanceId, KeyItem, tbShipWeaponItemTemplate, bIsClient)
    -- 先查找有没有空的可以安装的位置
    local tbEmptySupportedSlots = GetEmptyWeaponSlot(nCharacterInstanceId, tbShipWeaponItemTemplate, bIsClient)
    if #tbEmptySupportedSlots == 0 then
        return false
    end

    -- 检查这几个位置有没有已经在背包里的图纸
    return not HasSamePosWeaponKeyItem(nCharacterInstanceId, tbEmptySupportedSlots, bIsClient)
end

local function IfNeedShipPartKeyItem(nCharacterInstanceId, KeyItem, tbShipPartItemTemplate, bIsClient)
    return true
end

local function IfNeed(nCharacterInstanceId, Item, bIsClient)
    local nKeyItemTemplateId = Item:GetTemplateId()
    local nBuildItemTemplateId = BattleItemBuildDataTable:GetKeyItemBuildItemTemplateId(nKeyItemTemplateId)
    local tbBuildItemTemplate = BattleItemDataTable:GetTemplate(nBuildItemTemplateId)
    if tbBuildItemTemplate == nil then
        error("Cannot find key item build item!".. nKeyItemTemplateId)
    end
    local nCategory = tbBuildItemTemplate.nCategory
    local bCanAutoPickUp = false
    if nCategory == BattleItemCategoryDef.SHIP_WEAPON then
        bCanAutoPickUp = IfNeedShipWeaponKeyItem(nCharacterInstanceId, Item, tbBuildItemTemplate, bIsClient)
    elseif nCategory == BattleItemCategoryDef.SHIP_PART then
        bCanAutoPickUp = IfNeedShipPartKeyItem(nCharacterInstanceId, Item, tbBuildItemTemplate, bIsClient)
    end
    return bCanAutoPickUp
end

-- 是否可以自动拾取(客户端方法)
function BuildKeyItemOperationHelper:CanAutoPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local bIsBetter = IfNeed(nCharacterInstanceId, Item, true)
    local bCanAutoPickUp = false
    if bIsBetter then
        bCanAutoPickUp = BattleItemSystemHelper:CanAddToInventoryRoom(nCharacterInstanceId, Item:GetTemplateId(), true)
    end

    return bIsBetter, bCanAutoPickUp
end

-- 是否可以手动拾取(客户端方法)
function BuildKeyItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function BuildKeyItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return IfNeed(nCharacterInstanceId, Item, false)
        and BattleItemSystemHelper:CanAddToInventoryRoom(nCharacterInstanceId, Item:GetTemplateId(), false)
end

return BuildKeyItemOperationHelper