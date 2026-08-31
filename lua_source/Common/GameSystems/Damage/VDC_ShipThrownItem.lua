-----------------------------------------------------
--File Name    : VDC_ShipThrownItem.lua
--Author       : fang jing
--Create Time  : 2020-03-24
--Description  : 计算可破坏物受到的伤害（来自舰船投掷物）
-----------------------------------------------------
local DamageTypeEx = require("DamageTypeEx")
local BattleItemDataTable = require("BattleItemDataTable")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local PropUtil = require("PropUtil")

local function PlayHitEffect(pDamageCauser)
    local nHitEffectType = Enum_HitEffectType.HitShipBody
    pDamageCauser:PlayHitSoundAndFx(nHitEffectType)
end

local function GetCauser(pDamageCauser)
    local nInstigatorInstanceId = pDamageCauser:GetInstigatorInstanceId()
    return GameObjectSystem:FindByInstanceId(nInstigatorInstanceId)
end

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    -- 播放命中特效
    PlayHitEffect(pDamageCauser)

    -- 找不到Causer
    local tbCauser = GetCauser(pDamageCauser)
    if not tbCauser then
        logerror("[VDC_ShipThrownItem] Cannot find Causer")
        return
    end

    -- 获取投掷物相关信息
    local nThrownItemTemplateId = pDamageCauser.WeaponId
    local tbThrownItemtemplate = BattleItemDataTable:GetTemplate(nThrownItemTemplateId)
    if not tbThrownItemtemplate then
        logerror("[VDC_ShipThrownItem] Cannot find ThrownItemtemplate, nThrownItemTemplateId =", nThrownItemTemplateId)
        return
    end

    -- 默认伤害为直接传进来的值
    local nFinalDamage = nActualDamage

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponTemplateId = nThrownItemTemplateId

    local nThrownItemSubCategory = tbThrownItemtemplate.nSubCategory
    local nDamageType = DamageTypeEx.SHIP_THROWN_ITEM_BEGIN + nThrownItemSubCategory
    PropUtil.ApplyDamage(tbTaker, tbCauser, nDamageType, nFinalDamage, tbDamageExtraData)
end