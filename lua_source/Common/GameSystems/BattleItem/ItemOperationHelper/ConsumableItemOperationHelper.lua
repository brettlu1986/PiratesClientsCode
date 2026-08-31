local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local ConsumableItemOperationHelper = luaclass("ConsumableItemOperationHelper", ItemCategoryOperationHelperBase)

local BattleItemAutoPickUpHelper = require("BattleItemAutoPickUpHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

local function GetAutoPickUpCount(nCharacterInstanceId, Item, bIsClient)
    local nItemTemplateId = Item:GetTemplateId()
    local nAutoPickupMax = BattleItemAutoPickUpHelper.GetAutoPickUpSettingValue(bIsClient, nItemTemplateId)
    local nItemCount = BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId, bIsClient)
    return math.max(0, nAutoPickupMax - nItemCount)
end


-- 是否可以自动拾取
function ConsumableItemOperationHelper:CanAutoPickUpOnClient(Item)
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
function ConsumableItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function ConsumableItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    local nAutoPickupCount = GetAutoPickUpCount(nCharacterInstanceId, Item, false)
    if nAutoPickupCount > 0 then
        local nAvailableCount = BattleItemSystemHelper:GetAvailableAddCount(nCharacterInstanceId, Item:GetTemplateId(), nAutoPickupCount, false)
        if nAvailableCount > 0 then
            return true
        else
            return false
        end
    else
        return false
    end
end

return ConsumableItemOperationHelper