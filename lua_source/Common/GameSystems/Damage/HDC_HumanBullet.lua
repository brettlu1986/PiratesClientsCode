local PropName = require("PropName")
local PropUtil = require("PropUtil")
local BattleHumanWeaponSystem = require("BattleHumanWeaponSystem")
local HumanBodyDef = require("HumanBodyDef")
local DamageTypeHelper = require("DamageTypeHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local RelationshipSystem = dynamic_require("RelationshipSystem")
local HumanWeaponDef = require("HumanWeaponDef")
local WeaponDamageType = HumanWeaponDef.WeaponDamageType
local FN_GET_COMPONENT_FROM_HIT_RESULT = ExtendBlueprintFunctions.GetComponentFromHitResult
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local tbPartPropertyNames =
{
    [HumanBodyDef.HUMAN_ALLFOURS]     = PropName.nAllFoursInjuryRatio,         --后臂 左
    [HumanBodyDef.HUMAN_HEAD]         = PropName.nHeadInjuryRatio,        --后臂 右
    [HumanBodyDef.HUMAN_BODY]         = PropName.nBodyInjuryRatio,         --前臂 左
}

local tbPartPropertyToEnum =
{
    ["Uparm_l"]     = HumanBodyDef.HUMAN_ALLFOURS,             --后臂 左
    ["Uparm_r"]     = HumanBodyDef.HUMAN_ALLFOURS,             --后臂 右
    ["Forearm_l"]   = HumanBodyDef.HUMAN_ALLFOURS,             --前臂 左
    ["Forearm_r"]   = HumanBodyDef.HUMAN_ALLFOURS,             --前臂 右
    ["Head"]        = HumanBodyDef.HUMAN_HEAD,                 --头
    ["Body"]        = HumanBodyDef.HUMAN_BODY,                 --上半身
    ["Thigh_r"]     = HumanBodyDef.HUMAN_ALLFOURS,             --大腿 右
    ["Thigh_l"]     = HumanBodyDef.HUMAN_ALLFOURS,             --大腿 左
    ["Calf_l"]      = HumanBodyDef.HUMAN_ALLFOURS,             --小腿 左
    ["Calf_r"]      = HumanBodyDef.HUMAN_ALLFOURS,             --小腿 右
}


local function GetHumanPartDamageRatio(tbTaker, nPorpertyType)
    local szPropertyName = tbPartPropertyNames[nPorpertyType]
    if szPropertyName == "" or (szPropertyName == nil) then  return 1 end

    local nPartRatio = PropUtil.GetProp(tbTaker,szPropertyName)
    return  nPartRatio and nPartRatio or 1
end

local function GetCauser(pDamageCauser)
    local pInstigator = pDamageCauser:GetInstigator()
    if isvalidhandle(pInstigator) then
        return GameObjectSystem:FindByUEActor(pInstigator)
    end
    return nil
end

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    local tbCauserOwner = GetCauser(pDamageCauser)
    --TODO: 获取武器id 获取武器基础伤害
    local nBaseDamage = nActualDamage
    local nRealDamage = 0

    local tbWeaponInfo = tbCauserOwner.HumanWeaponComponent:GetCurrentWeapon()
    if not tbWeaponInfo then
        logerror("OnHumanBulletHit error can't find current weaponInfo")
        return
    end
    local tbWeaponProperty = tbWeaponInfo.tbProperty

    if not tbWeaponProperty then
        log("OnHumanBulletHit error can't find current weapon")
        return
    end

    local nDamageType = DamageTypeHelper.GetHumanWeaponDamageType(tbWeaponProperty.nWeaponCategory)
    if RelationshipSystem:IsFriendRelation(tbTaker, tbCauserOwner) then
        PropUtil.ApplyDamage(tbTaker, tbCauserOwner, nDamageType, nRealDamage, nil)
        return
    end

    local tbWeaponCategoryProperty = tbWeaponProperty.tbWeaponCategoryProperty

    local pHitComponent = FN_GET_COMPONENT_FROM_HIT_RESULT(pHitResult)
    local szHitName = KismetSystemLibrary.GetObjectName(pHitComponent)
    local nPorpertyType = tbPartPropertyToEnum[szHitName]

    local nWeaponFactor = 1
    -- logdebug("damage tbTaker.nServerInstanceId", tbTaker.nServerInstanceId, "nPorpertyType" , nPorpertyType)

    if nPorpertyType == HumanBodyDef.HUMAN_BODY then
        nWeaponFactor = tbWeaponCategoryProperty.nBodyDamageFactor
    elseif nPorpertyType ==  HumanBodyDef.HUMAN_HEAD then
        nWeaponFactor = tbWeaponCategoryProperty.nHeadDamageFactor
    elseif nPorpertyType ==  HumanBodyDef.HUMAN_ALLFOURS then
        nWeaponFactor = tbWeaponCategoryProperty.nAllFoursDamageFactor
    else
        log("OnHumanBulletHit error PorpertyType " , nPorpertyType)
        return
    end

    local nDecayFactor = 1
    if tbWeaponProperty.bSpeedAffectDamage then
        nDecayFactor = 1
    end

    local nPartRatio   = GetHumanPartDamageRatio(tbTaker, nPorpertyType)
    -- tbWeaponInfo.tbProperty.tbWeaponCategoryProperty.nHeadDamageFactor -- 武器类型区块伤害
    local nArmorDamage    = nBaseDamage * nPartRatio * nWeaponFactor *  nDecayFactor
    local nArmorFactor
    if GlobalVariableSystem.bUseNewBattleItem then
        nArmorFactor = BattleHumanWeaponSystem:GetArmorFactor(tbTaker.nServerInstanceId, WeaponDamageType.Bullet ,nPorpertyType)
    else
        nArmorFactor = BattleHumanWeaponSystem:GetArmorFactor(tbTaker.nServerInstanceId, nPorpertyType)
    end

    -- logdebug("tbTaker.nServerInstanceId", tbTaker.nServerInstanceId)
    BattleHumanWeaponSystem:DecreaseArmorDurability(tbTaker.nServerInstanceId, nPorpertyType, nArmorDamage)
    -- logdebug(string.format( "Damage HitNamt: %s BaseDamage: %f nPartRatio: %f nWeaponFactor: %f nArmorFactor: %f", szHitName, nBaseDamage, nPartRatio, nWeaponFactor, nArmorFactor))
    -- nRealDamage = 1
    nRealDamage = nArmorDamage * nArmorFactor

    -- log("OnHumanBulletHit nArmorDamage" , nArmorDamage, "nRealDamage", nRealDamage, "nPartRatio", nPartRatio)
    log(string.format( "OnHumanBulletHit nArmorDamage = %.1f nRealDamage = %.1f nPartRatio = %.1f nWeaponFactor = %.1f nArmorFactor = %.1f szHitName = %s",
    nArmorDamage, nRealDamage,nPartRatio, nWeaponFactor, nArmorFactor, szHitName ))

    --武器类别命中部位伤害比例 = WepaonProperty.tbWeaponCategoryProperty.nHeadDamageFactor, nBodyDamageFactor, nAllFoursDamageFactor
    --护甲减伤比例 = tbTaker
    --logdebug("trigger damage")

    --获取击中区块护甲 减伤比例

    PropUtil.ApplyDamage(tbTaker, tbCauserOwner, nDamageType, nRealDamage, nil)

end