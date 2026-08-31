--飞刀飞斧伤害
local HumanWeaponHelper = require("HumanWeaponHelper")
-- local TakeDamage = require("HDC_HumanBulletNew")
local GameObjectSystem = dynamic_require("GameObjectSystem")
-- local DamageTypeHelper = require("DamageTypeHelper")
local RelationshipSystem = require("RelationshipSystem")
local PropUtil = require("PropUtil")
local HumanBodyDef = require("HumanBodyDef")
local PropName = require("PropName")
local DamageTypeEx = require("DamageTypeEx")
local HumanWeaponDef = require("HumanWeaponDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


local WeaponDamageType = HumanWeaponDef.WeaponDamageType
local tbPartPropertyNames =
{
    [HumanBodyDef.HUMAN_ALLFOURS]     = PropName.nAllFoursInjuryRatio,         --后臂 左
    [HumanBodyDef.HUMAN_HEAD]         = PropName.nHeadInjuryRatio,        --后臂 右
    [HumanBodyDef.HUMAN_BODY]         = PropName.nBodyInjuryRatio,         --前臂 左
}


local function GetCauser(pDamageCauser)
    local pInstigator = pDamageCauser:GetInstigator()
    if isvalidhandle(pInstigator) then
        return GameObjectSystem:FindByUEActor(pInstigator)
    end
    return nil
end

local function GetHumanPartDamageRatio(tbTaker, nBodyType)
    local szPropertyName = tbPartPropertyNames[nBodyType]
    if szPropertyName == "" or (szPropertyName == nil) then  return 1 end

    local nPartRatio = PropUtil.GetProp(tbTaker,szPropertyName)
    return  nPartRatio and nPartRatio or 1
end

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    local nBodyType = HumanWeaponHelper.GetHitBodyType(pHitResult)
    local tbCauserOwner = GetCauser(pDamageCauser)

    local nTemplateId = pDamageCauser.TemplateId
    local nBaseDamage = nActualDamage
    local nRealDamage = 0

    local nDamageType = DamageTypeEx.HUMAN_FLYINGKNIFE
    if RelationshipSystem:IsFriendRelation(tbTaker, tbCauserOwner) then
        -- PropUtil.ApplyDamage(tbTaker, tbCauserOwner, nDamageType, nRealDamage, nil)
        return
    end

    local nPartRatio   = GetHumanPartDamageRatio(tbTaker, nBodyType)
    -- tbWeaponInfo.tbProperty.tbWeaponCategoryProperty.nHeadDamageFactor -- 武器类型区块伤害
    local nArmorDamage    = nBaseDamage * nPartRatio
    --  nWeaponFactor *  nDecayFactor
    local nArmorFactor
    if GlobalVariableSystem.bUseNewBattleItem then
        nArmorFactor = HumanWeaponHelper.GetArmorFactor(tbTaker.nServerInstanceId, WeaponDamageType.Bullet, nBodyType)
    else
        nArmorFactor = HumanWeaponHelper.GetArmorFactor(tbTaker.nServerInstanceId, nBodyType)
    end
    -- logdebug("tbTaker.nServerInstanceId", tbTaker.nServerInstanceId)
    HumanWeaponHelper.DecreaseArmorDurability(tbTaker.nServerInstanceId, nBodyType, nArmorDamage)
    -- logdebug(string.format( "Damage HitNamt: %s BaseDamage: %f nPartRatio: %f nWeaponFactor: %f nArmorFactor: %f", szHitName, nBaseDamage, nPartRatio, nWeaponFactor, nArmorFactor))
    -- nRealDamage = 1
    nRealDamage = nArmorDamage * nArmorFactor

    -- log("OnHumanBulletHit nArmorDamage" , nArmorDamage, "nRealDamage", nRealDamage, "nPartRatio", nPartRatio)
    log(string.format( "OnHumanBulletHit nArmorDamage = %.1f nRealDamage = %.1f nPartRatio = %.1f nArmorFactor = %.1f nBodyType = %d",
    nArmorDamage, nRealDamage,nPartRatio, nArmorFactor, nBodyType ))

    --武器类别命中部位伤害比例 = WepaonProperty.tbWeaponCategoryProperty.nHeadDamageFactor, nBodyDamageFactor, nAllFoursDamageFactor
    --护甲减伤比例 = tbTaker
    --logdebug("trigger damage")

    --获取击中区块护甲 减伤比例
    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponId = 0
    tbDamageExtraData.nWeaponTemplateId = nTemplateId
    tbDamageExtraData.nRegionType = nBodyType
    tbDamageExtraData.bIsCoreRegion = nBodyType == HumanBodyDef.HUMAN_HEAD

    PropUtil.ApplyDamage(tbTaker, tbCauserOwner, nDamageType, nRealDamage, tbDamageExtraData)
end