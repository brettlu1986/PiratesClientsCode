-----------------------------------------------------
--File Name    : HumanThrownItemOperationHelper.lua
--Author       : WuJizhou
--Create Time  : 9/17/2018, 3:33:21 PM
--Description  : HumanThrownItemOperationHelper
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local HumanThrownItemOperationHelper = luaclass("HumanThrownItemOperationHelper", ItemCategoryOperationHelperBase)

local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemAutoPickUpHelper = require("BattleItemAutoPickUpHelper")

local function GetAutoPickUpCount(nCharacterInstanceId, Item, bIsClient)
    local nItemTemplateId = Item:GetTemplateId()
    local nAutoPickupMax = BattleItemAutoPickUpHelper.GetAutoPickUpSettingValue(bIsClient, nItemTemplateId)
    local nItemCount = BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId, bIsClient)
    local nAutoPickupCount = math.max(0, nAutoPickupMax - nItemCount)
    return nAutoPickupCount
end


-- 是否可以自动拾取, 客户端方法
function HumanThrownItemOperationHelper:CanAutoPickUpOnClient(Item)
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

-- 是否可以手动拾取, 客户端方法
function HumanThrownItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function HumanThrownItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    return false
end

return HumanThrownItemOperationHelper