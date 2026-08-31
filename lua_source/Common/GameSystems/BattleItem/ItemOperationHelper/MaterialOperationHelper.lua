local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local MaterialOperationHelper = luaclass("MaterialOperationHelper", ItemCategoryOperationHelperBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ShipGradeDataTable = require("ShipGradeDataTable")
local BattleItemAutoPickUpHelper  = require("BattleItemAutoPickUpHelper")


local function GetAutoPickUpCount(nCharacterInstanceId, Item, bIsClient)
    local nItemTemplateId = Item:GetTemplateId()
    local nAutoPickupMaxPercentage = BattleItemAutoPickUpHelper.GetAutoPickUpSettingValue(bIsClient, nItemTemplateId)
    local nCurBuiltGrade = BattleItemSystemHelper:GetShipBuiltGrade(nCharacterInstanceId, bIsClient)
    local nCapacityBase = ShipGradeDataTable:GetMaxMaterialCapacity(nCurBuiltGrade)
    local nAutoPickUpMax = math.floor(nCapacityBase * nAutoPickupMaxPercentage)
    local nItemCount = BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local nAutoPickupCount = math.max(0, nAutoPickUpMax - nItemCount)
    return nAutoPickupCount
end

-- 是否可以自动拾取
function MaterialOperationHelper:CanAutoPickUpOnClient(Item)
    local nCharacterInstanceId = self:GetPlayerServerInstanceIdOnClient()
    local nAutoPickupCount = GetAutoPickUpCount(nCharacterInstanceId, Item, true)
    if nAutoPickupCount > 0 then
        local nAvailableCount = BattleItemSystemHelper:GetAvailableAddCount(nCharacterInstanceId, Item:GetTemplateId(), nAutoPickupCount, true)
        if nAvailableCount > 0 then
            return true, true, nAvailableCount
        else
            return true, false
        end
    else
        return false, false
    end
end

-- 是否可以手动拾取
function MaterialOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function MaterialOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    local nAutoPickupCount = GetAutoPickUpCount(nCharacterInstanceId, Item, false)
    if nAutoPickupCount > 0 then
        local nAvailableCount = BattleItemSystemHelper:GetAvailableAddCount(nCharacterInstanceId, Item:GetTemplateId(), nAutoPickupCount, false)
        if nAvailableCount > 0 then
            return true
        else
            return false
        end
    else
        return  false
    end
end

return MaterialOperationHelper