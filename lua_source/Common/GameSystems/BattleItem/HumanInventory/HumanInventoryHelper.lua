-----------------------------------------------------
--File Name    : HumanInventoryHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-10-16
--Description  : 人物背包的工具方法
-----------------------------------------------------
local HumanInventoryHelper = {}

local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local FFAItemIni = require("FFAItemIni")

-- 获得已装备的背包物品
function HumanInventoryHelper:GetHumanBackpackItem(nCharacterInstanceId, bIsClient)
    local tbHumanBackpackItems = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_BACKPACK, nCharacterInstanceId, bIsClient)
    if #tbHumanBackpackItems > 0 then
        return tbHumanBackpackItems[1]
    end
    return nil
end

-- 获得不装备背包时的基础容量
function HumanInventoryHelper:GetHumanBackpackCapacityBase()
    return FFAItemIni.tbInventory.nDefaultInventoryCapacity
end

-- 获得不装备背包时的基础格子数
function HumanInventoryHelper:GetHumanBackpackMaxInventorySlotsBase()
    return FFAItemIni.tbInventory.nDefaultMaxInventorySlots
end

return HumanInventoryHelper