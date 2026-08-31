-----------------------------------------------------
--File Name    : ShipBulletItemOperationHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-11
--Description  : 船的弹药操作helper
-----------------------------------------------------
local luaclass = require("luaclass")
local BulletItemOperationHelperBase = require("BulletItemOperationHelperBase")
local ShipBulletItemOperationHelper = luaclass("ShipBulletItemOperationHelper", BulletItemOperationHelperBase)

local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

-- 获得Owner物品的大类型
function ShipBulletItemOperationHelper:GetOwnerCategory()
    return BattleItemCategoryDef.SHIP_WEAPON
end

-- 获取可装填的弹药类型
function ShipBulletItemOperationHelper:GetBulletItemTemplateId(WeaponItem)
    return WeaponItem:GetBulletItemTemplateId()
end

-- 获取可装填的弹药数量上限
function ShipBulletItemOperationHelper:GetBulletMax(WeaponItem)
    return WeaponItem:GetBulletMaxLoadingCount()
end

-- 是否玩家可见
function ShipBulletItemOperationHelper:CanKnownByPlayer(_)
    return not BattleItemSystemHelper:IsShipBulletInfinite()
end

return ShipBulletItemOperationHelper