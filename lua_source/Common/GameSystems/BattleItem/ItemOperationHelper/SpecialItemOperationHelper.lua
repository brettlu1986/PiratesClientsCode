-----------------------------------------------------
--File Name    : SpecialItemOperationHelper.lua
--Author       : zhiyuan
--Create Time  : 2019-04-23
--Description  : 特殊道具的操作helper
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local SpecialItemOperationHelper = luaclass("SpecialItemOperationHelper", ItemCategoryOperationHelperBase)

local BattleItemSystemHelper = require("BattleItemSystemHelper")

-- 是否可以自动拾取, 客户端方法
-- @param Item 被检查的物品
-- @return bIsBetter, bAutoPickUp
-- bIsBetter true表示需要给出的提示让玩家拾取，false表示不需要
-- bAutoPickUp true表示可以自动拾取，false表示不能自动拾取
function SpecialItemOperationHelper:CanAutoPickUpOnClient(Item)
    local BattleItemSystemClient  = BattleItemSystemHelper:GetBattleItemSystemClient()
    if BattleItemSystemClient:CanAddToInventoryRoom(Item:GetTemplateId()) then
        return true, true
    else
        return true, false
    end
end

-- 是否可以手动拾取, 客户端方法
-- @param Item 被检查的物品
-- @return true表示可以手动拾取，false表示不能手动拾取
function SpecialItemOperationHelper:CanManuallyPickUpOnClient(Item)
    return true
end

-- 是否可以自动拾取, 服务端方法，给机器人AI使用
-- @param nCharacterInstanceId LuaCharacter的ServerInstanceId
-- @param Item 被检查的物品
-- @return bAutoPickUp
-- bAutoPickUp true表示可以自动拾取，false表示不能自动拾取
function SpecialItemOperationHelper:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    if BattleItemSystemHelper:CanAddToInventoryRoom(nCharacterInstanceId, Item:GetTemplateId(), false) then
        return true
    else
        return false
    end
end

return SpecialItemOperationHelper