local ShipWeaponAttachmentHelper = { }
local WeaponAttachmentTypeDef   = require("ShipWeaponAttachmentTypeDef")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local ShipWeaponCategoryDataTable = require("ShipWeaponCategoryDataTable")

local tbSlotIndexNames = {
    [WeaponAttachmentTypeDef.MUZZLE]    = "tbMuzzles",
    [WeaponAttachmentTypeDef.SIGHT]     = "tbSights",
    [WeaponAttachmentTypeDef.HOLDER]    = "tbHolders",
    [WeaponAttachmentTypeDef.AMMUNITION]    = "tbAmmunitions",
    [WeaponAttachmentTypeDef.PEDESTAL]  = "tbPedestals",
}

-- 安装配件的时候，会先安装在船舷武器上
local ShipWeaponSlotWeight = {
    [ShipWeaponSlotDef.UNKNOWN] = 0,
    [ShipWeaponSlotDef.HEAD]    = 2,
    [ShipWeaponSlotDef.SIDE]    = 3,
    [ShipWeaponSlotDef.DECK]    = 1,
}

function ShipWeaponAttachmentHelper.IsWeaponAttachmentOpen(tbWeaponItem, nSlotIndex)
    if tbWeaponItem and tbWeaponItem.tbTemplate and tbSlotIndexNames[nSlotIndex] then
        local tbValidAttachmentIds = tbWeaponItem.tbTemplate[tbSlotIndexNames[nSlotIndex]]
        if tbValidAttachmentIds and #tbValidAttachmentIds > 0 then
            return true
        end
    end
    return false
end

function ShipWeaponAttachmentHelper.IsWeaponAttachmentCompatible(tbWeaponItem, nAttachmentItemTemplateId)
    local tbAttachmentItemTemplate = BattleItemDataTable:GetTemplate(nAttachmentItemTemplateId)
    if tbWeaponItem and tbAttachmentItemTemplate then
        local nSlotIndex = tbAttachmentItemTemplate.nSubCategory
        if tbWeaponItem.tbTemplate and tbSlotIndexNames[nSlotIndex] then
            local tbValidAttachmentIds = tbWeaponItem.tbTemplate[tbSlotIndexNames[nSlotIndex]]
            if tbValidAttachmentIds then
                for _,v in ipairs(tbValidAttachmentIds) do
                    if v == nAttachmentItemTemplateId then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function ShipWeaponAttachmentHelper.GetWeaponCompatibleAttachments(tbWeaponItem, nSlotIndex)
    if tbWeaponItem and tbWeaponItem.tbTemplate and tbSlotIndexNames[nSlotIndex] then
        local tbValidAttachmentIds = tbWeaponItem.tbTemplate[tbSlotIndexNames[nSlotIndex]]
        if tbValidAttachmentIds and #tbValidAttachmentIds > 0 then
            return tbValidAttachmentIds
        end
    end
    return nil
end

local function SortWeaponFunc(tbWeaponItemA, tbWeaponItemB)
    local nWeaponItemSubCategoryA = tbWeaponItemA:GetSubCategory()
    local nWeaponSlotA = ShipWeaponCategoryDataTable:GetWeaponSlot(nWeaponItemSubCategoryA)

    local nWeaponItemSubCategoryB = tbWeaponItemB:GetSubCategory()
    local nWeaponSlotB = ShipWeaponCategoryDataTable:GetWeaponSlot(nWeaponItemSubCategoryB)

    return ShipWeaponSlotWeight[nWeaponSlotA] > ShipWeaponSlotWeight[nWeaponSlotB]
end

local function SortWeaponItems(tbAllWeaponItems)
    local tbSortedWeaponItems = {}
    for _, v in pairs(tbAllWeaponItems) do
        table.insert(tbSortedWeaponItems, v)
    end
    table.sort(tbSortedWeaponItems, SortWeaponFunc)
    return tbSortedWeaponItems
end

function ShipWeaponAttachmentHelper.FindWeaponToReceiveAttachment(nCharacterInstanceId, nAttachmentItemTemplateId, bManual, bIsClient)
    -- Find all weapons compatible with the weapon attachment.
    local tbAttachmentTemplate = BattleItemDataTable:GetTemplate(nAttachmentItemTemplateId)
    local nAttachmentSlotIndex = tbAttachmentTemplate.nSubCategory
    local tbAllWeaponItems = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON, nCharacterInstanceId, bIsClient)

    local tbWeaponItems = {}
    local tbSortedWeaponItems = SortWeaponItems(tbAllWeaponItems)
    for _,tbWeaponItem in ipairs(tbSortedWeaponItems) do
        if tbWeaponItem and ShipWeaponAttachmentHelper.IsWeaponAttachmentCompatible(tbWeaponItem, nAttachmentItemTemplateId) then
            table.insert(tbWeaponItems, tbWeaponItem)
            -- If any one of the found weapons has any empty slots then return the weapon.
            local tbEquippedAttachmentItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT,
                                             tbWeaponItem:GetInstanceId(), nAttachmentSlotIndex, bIsClient)
            if not tbEquippedAttachmentItem then
                return tbWeaponItem:GetInstanceId()
            end
        end
    end

    -- 按照策划需求，先不判断物品等级，后面如果需求变动了再修改
    -- Try replacing an existing inferior weapon attachment with the new one.
    -- for _,v in pairs(tbWeaponItems) do
    --     if v then
    --         local tbWeaponItem = v
    --         local tbEquippedAttachmentItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId, BattleItemCategoryDef.SHIP_WEAPON_ATTACHMENT, tbWeaponItem:GetInstanceId(), nAttachmentSlotIndex, bIsClient)
    --         if tbAttachmentItem.tbTemplate.nGrade > tbEquippedAttachmentItem.tbTemplate.nGrade then  -- TODO: Temp code. Need Real compare solution.
    --             return tbWeaponItem:GetInstanceId()
    --         end
    --     end
    -- end

    -- When failed to find a proper slot to fit and currently doing equiping manually, return a compatible weapon by force.
    if bManual and #tbWeaponItems > 0 then
        return tbWeaponItems[1]:GetInstanceId()
    end
    return -1
end

return ShipWeaponAttachmentHelper