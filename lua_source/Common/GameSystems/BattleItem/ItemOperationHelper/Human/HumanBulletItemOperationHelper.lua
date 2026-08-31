-----------------------------------------------------
--File Name    : HumanBulletItemOperationHelper.lua
--Author       : zhiyuan
--Create Time  : 2018-09-11
--Description  : 人的弹药操作helper
-----------------------------------------------------
local luaclass = require("luaclass")
local BulletItemOperationHelperBase = require("BulletItemOperationHelperBase")
local HumanBulletItemOperationHelper = luaclass("HumanBulletItemOperationHelper", BulletItemOperationHelperBase)

local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

-- 获得Owner物品的大类型
-- need override
function HumanBulletItemOperationHelper:GetOwnerCategory()
    return BattleItemCategoryDef.HUMAN_WEAPON
end

-- 获取可装填的弹药类型
-- need override
function HumanBulletItemOperationHelper:GetBulletItemTemplateId(WeaponItem)
    return WeaponItem:GetBulletItemTemplateId()
end

-- 获取可装填的弹药数量上限
-- need override
function HumanBulletItemOperationHelper:GetBulletMax(WeaponItem)
    return WeaponItem:GetBulletMax()
end

-- 是否玩家可见
function HumanBulletItemOperationHelper:CanKnownByPlayer(_)
    return not BattleItemSystemHelper:IsHumanBulletInfinite()
end

return HumanBulletItemOperationHelper