-----------------------------------------------------
--File Name    : SDC_ShipBullet.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-29
--Description  : 计算船受到的伤害（来自舰船火炮）
-----------------------------------------------------
local PropName = require("PropName")
-- local BaseUtil = require("BaseUtil")
local SDCHelper = require("SDCHelper")
local DamageTypeEx = require("DamageTypeEx")
local ShipPartHelper = require("ShipPartHelper")
local ShipRegionTypeDef = require("ShipRegionTypeDef")
local ShipWeaponAttackType = require("ShipWeaponAttackType")
local ShipArmorDataTableEx = require("ShipArmorDataTableEx")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local RelationshipSystem = require("RelationshipSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local DamageHurtDef = require("DamageHurtDef")

local MAX_DISTANCE_DAMAGE_RATIO = 1
local EXTEND_BLUEPRINT_FUNCTIONS = ExtendBlueprintFunctions
local FN_GET_COMPONENT_FROM_HIT_RESULT = EXTEND_BLUEPRINT_FUNCTIONS.GetComponentFromHitResult


local ARMOR_DAMAGE_RATIO_PROP_ID_MAP =  {
    [ShipRegionTypeDef.HEAD]    = PropName.nShipHeadDamageRatio,     -- 船帆
    [ShipRegionTypeDef.SIDE]    = PropName.nShipBodyDamageRatio,     -- 船头
    [ShipRegionTypeDef.STERN]   = PropName.nShipSternDamageRatio,    -- 船身
    [ShipRegionTypeDef.SAIL]    = PropName.nShipSailDamageRatio,     -- 船尾
    [ShipRegionTypeDef.DECK]    = PropName.nShipDeckDamageRatio      -- 甲板
}

local function PlayHitEffect(pDamageCauser, nRegionType, bIsCoreRegion)
    local nHitEffectType = Enum_HitEffectType.HitShipBody
    if bIsCoreRegion then
        nHitEffectType = Enum_HitEffectType.HitShipBodyCore
    elseif nRegionType == ShipRegionTypeDef.SAIL then
        nHitEffectType = Enum_HitEffectType.HitShipSail
    end
    pDamageCauser:PlayHitSoundAndFx(nHitEffectType)
end

local function CalculatePointY(nX1, nY1, nX2, nY2, nDistance)
    local nK = (nY2 - nY1) / (nX2 - nX1)
    return nK * (nDistance - nX1) + nY1
end

local function GetCauser(pDamageCauser)
    local nInstigatorInstanceId = pDamageCauser:GetInstigatorInstanceId()
    return GameObjectSystem:FindByInstanceId(nInstigatorInstanceId)
end

return function(tbTaker, nActualDamage, pDamageCauser, pHitResult)
    -- 获取Armor相关信息
    local pHitComponent = FN_GET_COMPONENT_FROM_HIT_RESULT(pHitResult)
    local nArmorId = tonumber(KismetSystemLibrary.GetObjectName(pHitComponent))
    local nShipTemplateId = tbTaker:GetShipTemplateId()
    local tbArmorTemplate = ShipArmorDataTableEx:GetTemplate(nShipTemplateId, nArmorId)
    if not tbArmorTemplate then
        PlayHitEffect(pDamageCauser)
        logerror("[SDC_ShipBullet] Cannot find ArmorTemplate, nShipTemplateId, nArmorId =" .. tostring(nShipTemplateId), tostring(nArmorId), KismetSystemLibrary.GetObjectName(pHitComponent))
        return
    end

    -- 播放命中特效
    local nRegionType = tbArmorTemplate.nRegionType
    PlayHitEffect(pDamageCauser, nRegionType, tbArmorTemplate.bIsCoreRegion)

    -- 免疫找不到Causer或队友的伤害
    local tbCauser = GetCauser(pDamageCauser)
    if (not tbCauser) or RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
        SDCHelper.LOG("Causer无效或命中队友")
        return
    end

    local tbTakerPropCmpt = tbTaker.ShipBattlePropertyComponent
    local tbCauserPropCmpt = tbCauser.ShipBattlePropertyComponent

    -- 获取Weapon相关信息
    local nWeaponId = pDamageCauser.WeaponId
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponId, false)
    if not WeaponItem then
        logerror("[SDC_ShipBullet] Cannot find WeaponItem, nWeaponId =", nWeaponId)
        return
    end

    local tbWeaponTemplate = WeaponItem:GetTemplate()
    local nWeaponSubCategory = WeaponItem:GetSubCategory()

    local nDamageHurtTag = DamageHurtDef.HURT_NONE
    -- 处理漏水
    local bResultLeaking = SDCHelper.CheckLeaking(tbCauser, tbTaker, tbWeaponTemplate, tbArmorTemplate)
    nDamageHurtTag = bResultLeaking and nDamageHurtTag | DamageHurtDef.HURT_LEAKING or nDamageHurtTag

    -- 处理点火
    local bResultBurning = SDCHelper.CheckBurning(tbCauser, tbTaker, tbWeaponTemplate, tbArmorTemplate)
    nDamageHurtTag = bResultBurning and nDamageHurtTag | DamageHurtDef.HURT_FIRE or nDamageHurtTag

    -- 默认伤害为直接传进来的值
    local nFinalDamage = nActualDamage
    SDCHelper.LOG("初始伤害：%f", nFinalDamage)

    -- 处理最大伤害加成
    nFinalDamage = BattleShipWeaponSystem:GetWeaponAttack(tbCauser, nWeaponSubCategory, nActualDamage)
    SDCHelper.LOG("初始伤害加成后伤害：%f", nFinalDamage)

    -- -- 处理对减速敌人伤害
    -- local tbAttackReductionDamageRatioInfo = tbCauserPropCmpt:GetProp(PropName.tbAttackReductionDamageRatioInfo)
    -- if tbAttackReductionDamageRatioInfo then
    --     if BaseUtil:ContainsByValue(tbAttackReductionDamageRatioInfo.tbWeaponTypes, nWeaponSubCategory)
    --     or BaseUtil:ContainsByValue(tbAttackReductionDamageRatioInfo.tbWeaponIds, nWeaponId) then
    --         if tbTaker.pUEActor.ShipMovementComponent:GetShipMoveGearBuffValue(true, EShipMoveGearBuffType.MAX_LINEAR_SPEED) < 0 then
    --             local nAttackReductionDamageRatio = tbAttackReductionDamageRatioInfo.nValue + 1
    --             nFinalDamage = nFinalDamage * nAttackReductionDamageRatio
    --             SDCHelper.LOG("攻击减速目标加成后伤害：%f，伤害加成值：%f", nFinalDamage, nAttackReductionDamageRatio)
    --         end
    --     end
    -- end

    -- 计算武器飞行距离对伤害影响
    local nFlyingDistance = pDamageCauser:GetFlyingDistance()
    local nDistanceDamageRatio = tbWeaponTemplate.nMinDistanceDamageRatio
    local nFiringRange = tbWeaponTemplate.nFiringRange * tbCauserPropCmpt:GetProp(PropName.nFiringRangeRatio)
    local nPerfectFiringRangeBegin = math.max(0, tbCauserPropCmpt:CalcPropOverlapValue(PropName.nPerfectFiringRangeBegin, tbWeaponTemplate.nPerfectFiringRangeBegin))
    local nPerfectFiringRangeEnd = math.min(nFiringRange, tbCauserPropCmpt:CalcPropOverlapValue(PropName.nPerfectFiringRangeEnd, tbWeaponTemplate.nPerfectFiringRangeEnd))
    SDCHelper.LOG("默认射程：%f米，加成后值：%f米", tbWeaponTemplate.nFiringRange / 100, nFiringRange / 100)
    SDCHelper.LOG("默认最佳射程开始距离：%f米，加成后值：%f米", tbWeaponTemplate.nPerfectFiringRangeBegin / 100, nPerfectFiringRangeBegin / 100)
    SDCHelper.LOG("默认最佳射程结束距离：%f米，加成后值：%f米", tbWeaponTemplate.nPerfectFiringRangeEnd / 100, nPerfectFiringRangeEnd / 100)
    if nFlyingDistance < nPerfectFiringRangeBegin then
        nDistanceDamageRatio = CalculatePointY(0, tbWeaponTemplate.nMinDistanceDamageRatio, nPerfectFiringRangeBegin, MAX_DISTANCE_DAMAGE_RATIO, nFlyingDistance)
    elseif nFlyingDistance < nPerfectFiringRangeEnd then
        nDistanceDamageRatio = MAX_DISTANCE_DAMAGE_RATIO
    elseif nFlyingDistance < nFiringRange then
        nDistanceDamageRatio = CalculatePointY(nPerfectFiringRangeEnd, MAX_DISTANCE_DAMAGE_RATIO, nFiringRange, tbWeaponTemplate.nMaxDistanceDamageRatio, nFlyingDistance)
    else
        nDistanceDamageRatio = tbWeaponTemplate.nMaxDistanceDamageRatio
    end
    nFinalDamage = nFinalDamage * nDistanceDamageRatio
    SDCHelper.LOG("距离衰减后伤害：%f，飞行距离：%f米，距离衰减后伤害系数：%f", nFinalDamage, (nFlyingDistance / 100), nDistanceDamageRatio)

    -- 计算物理伤害
    if tbWeaponTemplate.nAttackType == ShipWeaponAttackType.PHYSICAL_ATTACK then
        -- 计算武器对各区域伤害系数
        local nWeaponDamageRatio = tbWeaponTemplate.tbDamageRatioFromWeapons[nRegionType]           -- 敌船武器针对区域伤害系数
        nFinalDamage = nFinalDamage * nWeaponDamageRatio
        SDCHelper.LOG("计算武器对各区域系数后伤害：%f，武器对区域系数：%f", nFinalDamage, nWeaponDamageRatio)

        -- 扣除零件耐久，并计算零件抵挡后伤害
        local nPartDamageRatio = nil
        nFinalDamage, nPartDamageRatio = ShipPartHelper.DecreaseDurability(tbTaker, nArmorId, nFinalDamage)
        SDCHelper.LOG("计算零件抵挡后伤害：%f，伤害系数：%f", nFinalDamage, nPartDamageRatio)

        -- 计算区块自有伤害减免
        local nDefaultArmorDamageRatio = tbArmorTemplate.nDamageRatio
        nFinalDamage = nFinalDamage * nDefaultArmorDamageRatio
        SDCHelper.LOG("计算区块自有伤害减免后伤害：%f，伤害系数：%f", nFinalDamage, nDefaultArmorDamageRatio)

        -- 计算护甲额外伤害减免
        local nExtraArmorDamageRatio = tbTakerPropCmpt:GetProp(ARMOR_DAMAGE_RATIO_PROP_ID_MAP[nRegionType])
        nFinalDamage = nFinalDamage * nExtraArmorDamageRatio
        SDCHelper.LOG("计算区块额外(buff叠加、外围属性叠加)伤害减免后伤害：%f，伤害系数：%f", nFinalDamage, nExtraArmorDamageRatio)

        -- 计算核心区伤害减免
        if tbArmorTemplate.bIsCoreRegion then
            nDamageHurtTag = DamageHurtDef.HURT_CORE
            local nShipCaptainRoomDamageRatio = tbTakerPropCmpt:GetProp(PropName.nShipCaptainRoomDamageRatio)
            nFinalDamage = nFinalDamage * nShipCaptainRoomDamageRatio
            SDCHelper.LOG("计算核心区区块额外(buff叠加、外围属性叠加)伤害减免后伤害：%f，伤害系数：%f", nFinalDamage, nShipCaptainRoomDamageRatio)
        end

        SDCHelper.LOG("最终造成伤害：%f", nFinalDamage)
    end

    -- 处理命中Buff
    for _,v in ipairs(tbWeaponTemplate.tbTakerBuffList) do
        tbTaker.BuffComponentServer:AddBuffWithInstigator(tbCauser, v)
    end

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponId = nWeaponId
    tbDamageExtraData.nWeaponTemplateId = WeaponItem:GetTemplateId()
    tbDamageExtraData.nRegionType = nRegionType
    tbDamageExtraData.bIsCoreRegion = tbArmorTemplate.bIsCoreRegion
    tbDamageExtraData.nShipArmorId = nArmorId
    -- logdebug("hurt tage damage :", nDamageHurtTag)
    tbDamageExtraData.nHurtTag = nDamageHurtTag

    local nDamageType = DamageTypeEx.SHIP_WEAPON_BEGIN + nWeaponSubCategory - 1
    tbTakerPropCmpt:ApplyDamage(tbCauser, nDamageType, nFinalDamage, tbDamageExtraData)
    pDamageCauser.TotalDamage = pDamageCauser.TotalDamage + nFinalDamage
    SDCHelper.LOG("ApplyDamage:%f", nFinalDamage)
end