-----------------------------------------------------
--File Name    : SDC_ShipThrownItem.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-29
--Description  : 计算船受到的伤害（来自舰船投掷物）
-----------------------------------------------------
local PropName = require("PropName")
local SDCHelper = require("SDCHelper")
local DamageTypeEx = require("DamageTypeEx")
local ShipPartHelper = require("ShipPartHelper")
local ShipRegionTypeDef = require("ShipRegionTypeDef")
local RelationshipSystem = require("RelationshipSystem")
local BattleItemDataTable = require("BattleItemDataTable")
local ShipWeaponAttackType = require("ShipWeaponAttackType")
local ShipArmorDataTableEx = require("ShipArmorDataTableEx")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local DamageHurtDef = require("DamageHurtDef")
local DungeonIni = require("DungeonIni")

local EXTEND_BLUEPRINT_FUNCTIONS = ExtendBlueprintFunctions
local FN_GET_COMPONENT_FROM_HIT_RESULT = EXTEND_BLUEPRINT_FUNCTIONS.GetComponentFromHitResult
local TEAMMATE_DAMAGE_ENABLED = DungeonIni.tbShipWeapon.bShipThrownItemTeammateDamageEnabled

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
        logerror("[SDC_ShipThrownItem] Cannot find ArmorTemplate, nShipTemplateId, nArmorId =" .. tostring(nShipTemplateId), tostring(nArmorId), KismetSystemLibrary.GetObjectName(pHitComponent))
        return
    end

    -- 播放命中特效
    local nRegionType = tbArmorTemplate.nRegionType
    PlayHitEffect(pDamageCauser, nRegionType, tbArmorTemplate.bIsCoreRegion)

    -- 免疫找不到Causer或队友的伤害
    local tbCauser = GetCauser(pDamageCauser)
    if (not tbCauser)
    or ((not TEAMMATE_DAMAGE_ENABLED) and RelationshipSystem:IsFriendRelation(tbTaker, tbCauser)) then
        SDCHelper.LOG("Causer无效或命中队友")
        return
    end

    local tbTakerPropCmpt = tbTaker.ShipBattlePropertyComponent

    -- 获取投掷物相关信息
    local nThrownItemTemplateId = pDamageCauser.WeaponId
    local tbThrownItemtemplate = BattleItemDataTable:GetTemplate(nThrownItemTemplateId)
    if not tbThrownItemtemplate then
        logerror("[SDC_ShipThrownItem] Cannot find ThrownItemtemplate, nThrownItemTemplateId =", nThrownItemTemplateId)
        return
    end

    local nDamageHurtTag = DamageHurtDef.HURT_NONE
    -- 处理漏水
    local bResultLeaking = SDCHelper.CheckLeaking(tbCauser, tbTaker, tbThrownItemtemplate, tbArmorTemplate)
    nDamageHurtTag = bResultLeaking and nDamageHurtTag | DamageHurtDef.HURT_LEAKING or nDamageHurtTag
    -- 处理点火
    local bResultFire = SDCHelper.CheckBurning(tbCauser, tbTaker, tbThrownItemtemplate, tbArmorTemplate)
    nDamageHurtTag = bResultFire and nDamageHurtTag | DamageHurtDef.HURT_FIRE or nDamageHurtTag


    -- 默认伤害为直接传进来的值
    local nFinalDamage = nActualDamage
    SDCHelper.LOG("初始伤害：%f", nFinalDamage)

    -- 计算物理伤害
    if tbThrownItemtemplate.nAttackType == ShipWeaponAttackType.PHYSICAL_ATTACK then
        -- 计算武器对各区域伤害系数
        local nWeaponDamageRatio = tbThrownItemtemplate.tbDamageRatioFromWeapons[nRegionType]           -- 敌船武器针对区域伤害系数
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

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponTemplateId = nThrownItemTemplateId
    tbDamageExtraData.nRegionType = nRegionType
    tbDamageExtraData.bIsCoreRegion = tbArmorTemplate.bIsCoreRegion
    tbDamageExtraData.nShipArmorId = nArmorId
    tbDamageExtraData.nHurtTag = nDamageHurtTag

    local nThrownItemSubCategory = tbThrownItemtemplate.nSubCategory
    local nDamageType = DamageTypeEx.SHIP_THROWN_ITEM_BEGIN + nThrownItemSubCategory
    tbTakerPropCmpt:ApplyDamage(tbCauser, nDamageType, nFinalDamage, tbDamageExtraData)
    SDCHelper.LOG("ApplyDamage:%f", nFinalDamage)
end