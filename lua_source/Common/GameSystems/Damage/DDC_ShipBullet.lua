-----------------------------------------------------
--File Name    : DDC_ShipBullet.lua
--Author       : fangjing
--Create Time  :
--Description  : 计算船对可破坏物的伤害
-----------------------------------------------------
local DamageTypeEx = require("DamageTypeEx")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local MAX_DISTANCE_DAMAGE_RATIO = 1

local function CalculatePointY(nX1, nY1, nX2, nY2, nDistance)
    local nK = (nY2 - nY1) / (nX2 - nX1)
    return nK * (nDistance - nX1) + nY1
end

local function GetCauser(pDamageCauser)
    local nInstigatorInstanceId = pDamageCauser:GetInstigatorInstanceId()
    return GameObjectSystem:FindByInstanceId(nInstigatorInstanceId)
end

return function (tbTaker, nActualDamage, pDamageCauser, pHitResult)
    local tbCauser = GetCauser(pDamageCauser)
    if not tbCauser then
        return
    end

    -- 获取Weapon相关信息
    local nWeaponId = pDamageCauser.WeaponId
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponId, false)
    if not WeaponItem then
        logerror("[DDC_ShipBullet] Cannot find WeaponItem ", nWeaponId)
        return
    end
    local tbWeaponTemplate = WeaponItem:GetTemplate()
    if not tbWeaponTemplate then
        logerror("[DDC_ShipBullet] Cannot find tbWeaponTemplate ", nWeaponId)
        return
    end
    local nWeaponSubCategory = WeaponItem:GetSubCategory()

    -- 船基础伤害叠加
    nActualDamage = BattleShipWeaponSystem:GetWeaponAttack(tbCauser, nWeaponSubCategory, nActualDamage)

    -- 计算武器飞行距离对伤害影响
    local nFlyingDistance = pDamageCauser:GetFlyingDistance()
    local nDistanceDamageRatio = tbWeaponTemplate.nMinDistanceDamageRatio
    if nFlyingDistance < tbWeaponTemplate.nPerfectFiringRangeBegin then
        nDistanceDamageRatio = CalculatePointY(0, tbWeaponTemplate.nMinDistanceDamageRatio,
                                               tbWeaponTemplate.nPerfectFiringRangeBegin, MAX_DISTANCE_DAMAGE_RATIO, nFlyingDistance)
    elseif nFlyingDistance < tbWeaponTemplate.nPerfectFiringRangeEnd then
        nDistanceDamageRatio = MAX_DISTANCE_DAMAGE_RATIO
    elseif nFlyingDistance < tbWeaponTemplate.nFiringRange then
        nDistanceDamageRatio = CalculatePointY(tbWeaponTemplate.nPerfectFiringRangeEnd, MAX_DISTANCE_DAMAGE_RATIO,
                                               tbWeaponTemplate.nFiringRange, tbWeaponTemplate.nMaxDistanceDamageRatio, nFlyingDistance)
    else
        nDistanceDamageRatio = tbWeaponTemplate.nMaxDistanceDamageRatio
    end
    nActualDamage = nActualDamage * nDistanceDamageRatio

    ---------------------------------- 伤害逻辑分界线，以上计算与船无关，以下计算与船相关 ----------------------------------------

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponId = nWeaponId
    tbDamageExtraData.nWeaponTemplateId = WeaponItem:GetTemplateId()
    local nDamageType = DamageTypeEx.SHIP_WEAPON_BEGIN + nWeaponSubCategory - 1
    tbTaker.DestructibleObjectPropertyComponent:ApplyDamage(tbCauser, nDamageType, nActualDamage, tbDamageExtraData)
end