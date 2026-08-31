local PropName = require("PropName")
local PropUtil = require("PropUtil")
local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanBodyDef = require("HumanBodyDef")
local DamageTypeHelper = require("DamageTypeHelper")
local RelationshipSystem = dynamic_require("RelationshipSystem")
local DamageTypeEx = require("DamageTypeEx")
local GlobalVariableSystem =  dynamic_require("GlobalVariableSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local DungeonIni = require("DungeonIni")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local tbPartPropertyNames =
{
    [HumanBodyDef.HUMAN_ALLFOURS]     = PropName.nAllFoursInjuryRatio,         --后臂 左
    [HumanBodyDef.HUMAN_HEAD]         = PropName.nHeadInjuryRatio,        --后臂 右
    [HumanBodyDef.HUMAN_BODY]         = PropName.nBodyInjuryRatio,         --前臂 左
}


local function GetHumanPartDamageRatio(tbTaker, nBodyType)
    local szPropertyName = tbPartPropertyNames[nBodyType]
    if szPropertyName == "" or (szPropertyName == nil) then  return 1 end

    local nPartRatio = PropUtil.GetProp(tbTaker,szPropertyName)
    return  nPartRatio and nPartRatio or 1
end

-- local function GetCauser(pDamageCauser)
--     local pInstigator = pDamageCauser:GetInstigator()
--     if isvalidhandle(pInstigator) then
--         return GameObjectSystem:FindByUEActor(pInstigator)
--     end
--     return nil
-- end

return function(tbTaker, nActualDamage, tbCauserOwner, tbCauserProperty, nBodyType)
    --local tbCauserOwner = GetCauser(pDamageCauser)
    --TODO: 获取武器id 获取武器基础伤害
    local nBaseDamage = nActualDamage
    local nRealDamage = 0

    if not tbCauserProperty then
        logerror("OnHumanBulletHit error can't find current weaponInfo")
        return
    end
    local tbWeaponProperty = tbCauserProperty

    if not tbWeaponProperty then
        log("OnHumanBulletHit error can't find current weapon")
        return
    end

    local nDamageType = DamageTypeHelper.GetHumanWeaponDamageType(tbWeaponProperty.nWeaponCategory)
    if not tbWeaponProperty.nTemplateId then
        nDamageType = DamageTypeEx.HUMAN_EMPTY_HAND
    end

    if RelationshipSystem:IsFriendRelation(tbTaker, tbCauserOwner) then
        -- PropUtil.ApplyDamage(tbTaker, tbCauserOwner, nDamageType, nRealDamage, nil)
        return
    end

    local tbWeaponCategoryProperty = tbWeaponProperty.tbWeaponCategoryProperty

    local nWeaponFactor = 1
    -- logdebug("damage tbTaker.nServerInstanceId", tbTaker.nServerInstanceId, "nBodyType" , nBodyType)
    if nBodyType == nil then
        nBodyType = 0
    end

    local bTakerIsCharacter = GameObjectSystem:IsCharacter(tbTaker) 
    local bTakerIsHuman = bTakerIsCharacter and tbTaker:IsHuman()

    if nBodyType == HumanBodyDef.HUMAN_BODY then
        nWeaponFactor = tbWeaponCategoryProperty.nBodyDamageFactor
    elseif nBodyType ==  HumanBodyDef.HUMAN_HEAD then
        nWeaponFactor = tbWeaponCategoryProperty.nHeadDamageFactor
    elseif nBodyType ==  HumanBodyDef.HUMAN_ALLFOURS then
        nWeaponFactor = tbWeaponCategoryProperty.nAllFoursDamageFactor
    elseif bTakerIsHuman then
        log("OnHumanBulletHit error PorpertyType " , nBodyType)
        return
    end

    local nDecayFactor = 1
    if tbWeaponProperty.bSpeedAffectDamage then
        nDecayFactor = 1
    end

    local nPartRatio   = 1
    if bTakerIsHuman then
        GetHumanPartDamageRatio(tbTaker, nBodyType)
    end
    -- tbWeaponInfo.tbProperty.tbWeaponCategoryProperty.nHeadDamageFactor -- 武器类型区块伤害
    local nArmorDamage    = nBaseDamage * nPartRatio * nWeaponFactor *  nDecayFactor
    local nArmorFactor = 1

    if bTakerIsHuman and GlobalVariableSystem:GetDungeonDamageEnabled() then
        if GlobalVariableSystem.bUseNewBattleItem then
            local nCalcDamageType = DamageTypeHelper.GetHumanWeaponCalcDamageType(tbWeaponProperty.nWeaponCategory)
            nArmorFactor = HumanWeaponHelper.GetArmorFactor(tbTaker.nServerInstanceId, nCalcDamageType, nBodyType)
        else
            nArmorFactor = HumanWeaponHelper.GetArmorFactor(tbTaker.nServerInstanceId, nBodyType)
        end

        HumanWeaponHelper.DecreaseArmorDurability(tbTaker.nServerInstanceId, nBodyType, nArmorDamage)
        -- logdebug("nArmorFactor", nArmorFactor, "nArmorDamage", nArmorDamage, "nBodyType", nBodyType)
    end
    -- logdebug("tbTaker.nServerInstanceId", tbTaker.nServerInstanceId)
    -- logdebug(string.format( "Damage HitNamt: %s BaseDamage: %f nPartRatio: %f nWeaponFactor: %f nArmorFactor: %f", szHitName, nBaseDamage, nPartRatio, nWeaponFactor, nArmorFactor))
    -- nRealDamage = 1
    nRealDamage = nArmorDamage * nArmorFactor

    -- log("OnHumanBulletHit nArmorDamage" , nArmorDamage, "nRealDamage", nRealDamage, "nPartRatio", nPartRatio)
    log(string.format( "OnHumanBulletHit nArmorDamage = %.1f nRealDamage = %.1f nPartRatio = %.1f nWeaponFactor = %.1f nArmorFactor = %.1f nBodyType = %d nDamageType = %d",
    nArmorDamage, nRealDamage,nPartRatio, nWeaponFactor, nArmorFactor, nBodyType, nDamageType))

    --武器类别命中部位伤害比例 = WepaonProperty.tbWeaponCategoryProperty.nHeadDamageFactor, nBodyDamageFactor, nAllFoursDamageFactor
    --护甲减伤比例 = tbTaker
    --logdebug("trigger damage")

    --获取击中区块护甲 减伤比例

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponId = 0
    tbDamageExtraData.nWeaponTemplateId = tbWeaponProperty.nTemplateId
    tbDamageExtraData.nRegionType = nBodyType
    tbDamageExtraData.bIsCoreRegion = nBodyType == HumanBodyDef.HUMAN_HEAD

    log("OnHumanBulletHit WeaponTemplateId", tbWeaponProperty.nTemplateId)

    if bTakerIsCharacter and not bTakerIsHuman then
        if tbWeaponProperty and tbWeaponProperty.nShipDamageRatio ~= nil then 
            log("OnHumanBulletHit ShipDamageRatioFromWeapon", tbWeaponProperty.nShipDamageRatio)
            nRealDamage = nRealDamage * tbWeaponProperty.nShipDamageRatio
        else
            log("OnHumanBulletHit ShipDamageRatioFromHuman", DungeonIni.tbFFA.nShipDamageRatioFromHuman)
            nRealDamage = nRealDamage * DungeonIni.tbFFA.nShipDamageRatioFromHuman
        end
    end
    EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_DAMAGE, tbTaker, tbCauserOwner, nDamageType)

    tbCauserOwner.HumanWeaponComponent:OnHumanWeaponDamage(nRealDamage)
    PropUtil.ApplyDamage(tbTaker, tbCauserOwner, nDamageType, nRealDamage, tbDamageExtraData)
end