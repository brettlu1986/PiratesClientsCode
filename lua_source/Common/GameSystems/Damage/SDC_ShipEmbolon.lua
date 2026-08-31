-----------------------------------------------------
--File Name    : SDC_ShipEmbolon.lua
--Author       : Song Fuhao
--Create Time  : 2018-08-29
--Description  : 计算船受到的伤害（来自舰船撞角）
-----------------------------------------------------
local MathUtil = require("MathUtil")
-- local BaseUtil = require("BaseUtil")
local SDCHelper = require("SDCHelper")
local DamageTypeEx = require("DamageTypeEx")
local ShipDataTable = require("ShipDataTable")
local ShipPartHelper = require("ShipPartHelper")
local ShipWeaponAttackType = require("ShipWeaponAttackType")
local ShipArmorDataTableEx = require("ShipArmorDataTableEx")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local RelationshipSystem = require("RelationshipSystem")
local ShipRegionTypeDef = require("ShipRegionTypeDef")
local DamageHurtDef = require("DamageHurtDef")
local PropName = require("PropName")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local CM_TO_M = 100

local ARMOR_DAMAGE_RATIO_PROP_ID_MAP =  {
    [ShipRegionTypeDef.HEAD]    = PropName.nShipHeadDamageRatio,     -- 船帆
    [ShipRegionTypeDef.SIDE]    = PropName.nShipBodyDamageRatio,     -- 船头
    [ShipRegionTypeDef.STERN]   = PropName.nShipSternDamageRatio,    -- 船身
    [ShipRegionTypeDef.SAIL]    = PropName.nShipSailDamageRatio,     -- 船尾
    [ShipRegionTypeDef.DECK]    = PropName.nShipDeckDamageRatio      -- 甲板
}

local function GetCauser(pDamageCauser)
    if isvalidhandle(pDamageCauser) then
        return GameObjectSystem:FindByUEActor(pDamageCauser)
    end
    return nil
end

local function GetArmorIdByCollisionArea(nShipTemplateId, pCollisionArea)
    local tbShipTemplate = ShipDataTable:GetTemplate(nShipTemplateId)
    if pCollisionArea == EShipImpactArea.Front then
        return tbShipTemplate.nHeadCollisionArmorId
    elseif pCollisionArea == EShipImpactArea.Middle then
        return tbShipTemplate.nSideCollisionArmorId
    elseif pCollisionArea == EShipImpactArea.Back then
        return tbShipTemplate.nSternCollisionArmorId
    end
    return -1
end

return function (tbTaker, nActualDamage, pDamageCauser, pHitResult)
    local tbCauser = GetCauser(pDamageCauser)
    if RelationshipSystem:IsFriendRelation(tbTaker, tbCauser) then
        return
    end
    local tbTakerPropCmpt = tbTaker.ShipBattlePropertyComponent

    local pEmbolonComponent = tbCauser.pUEActor.EmbolonComponent
    local pCollisionArea = pEmbolonComponent:GetOtherCollisionArea()

    -- 获取Armor相关信息
    local nShipTemplateId = tbTaker:GetShipTemplateId()
    local nArmorId = GetArmorIdByCollisionArea(nShipTemplateId, pCollisionArea)

    local tbArmorTemplate = ShipArmorDataTableEx:GetTemplate(nShipTemplateId, nArmorId)
    if not tbArmorTemplate then
        logerror("nShipTemplateId,nArmorId",nShipTemplateId, nArmorId)
        return
    end

    local nRegionType = tbArmorTemplate.nRegionType

    -- 获取Weapon相关信息
    local nWeaponId = pEmbolonComponent:GetWeaponId()
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponId, false)
    local tbWeaponTemplate = WeaponItem:GetTemplate()
    local nWeaponSubCategory = WeaponItem:GetSubCategory()

    -- 处理速度
    local nCurrentSpeed = tbCauser and (tbCauser.pUEActor.ShipMovementComponent:GetCurrentLinearSpeed() / CM_TO_M) or 0
    local nAttckStandardSpeed = tbWeaponTemplate.nAttckStandardSpeed
    if nCurrentSpeed < nAttckStandardSpeed then
        return
    end

    local nDamageHurtTag = DamageHurtDef.HURT_NONE
    -- 处理漏水
    local bLeakingResult = SDCHelper.CheckLeaking(tbCauser, tbTaker, tbWeaponTemplate, tbArmorTemplate)
    nDamageHurtTag = bLeakingResult and nDamageHurtTag | DamageHurtDef.HURT_LEAKING or nDamageHurtTag

    -- 默认伤害为直接传进来的值
    local nFinalDamage = nActualDamage
    SDCHelper.LOG("初始伤害：%f", nFinalDamage)

    -- 处理最大伤害加成
    nActualDamage = BattleShipWeaponSystem:GetWeaponAttack(tbCauser, nWeaponSubCategory, nActualDamage)
    SDCHelper.LOG("Buff数值加成后伤害：%f", nFinalDamage)

    -- -- 处理对减速敌人伤害
    -- local tbAttackReductionDamageRatioInfo = tbCauser and tbCauser.ShipBattlePropertyComponent:GetProp(PropName.tbAttackReductionDamageRatioInfo)
    -- if tbAttackReductionDamageRatioInfo then
    --     if BaseUtil:ContainsByValue(tbAttackReductionDamageRatioInfo.tbWeaponTypes, WeaponItem:GetSubCategory())
    --     or BaseUtil:ContainsByValue(tbAttackReductionDamageRatioInfo.tbWeaponIds, nWeaponId) then
    --         if tbTaker.pUEActor.ShipMovementComponent:GetShipMoveGearBuffValue(true, EShipMoveGearBuffType.MAX_LINEAR_SPEED) < 0 then
    --             local nAttackReductionDamageRatio = tbAttackReductionDamageRatioInfo.nValue + 1
    --             nFinalDamage = nFinalDamage * nAttackReductionDamageRatio
    --             SDCHelper.LOG("攻击减速目标加成后伤害：%f， 伤害加成值：%f", nFinalDamage, nAttackReductionDamageRatio)
    --         end
    --     end
    -- end

    -- 计算速度对伤害影响
    local nSpeedDamageRatio = 1 + (nCurrentSpeed - nAttckStandardSpeed) * tbWeaponTemplate.nDamageRatioDelta
    nSpeedDamageRatio = MathUtil.Clamp(nSpeedDamageRatio, 0, tbWeaponTemplate.nMaxDamageRatioAddition)
    nFinalDamage = nFinalDamage * nSpeedDamageRatio
    SDCHelper.LOG("计算速度影响后伤害：%f，伤害加成值：%f，速度：%f米", nFinalDamage, nSpeedDamageRatio, nCurrentSpeed)

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

    -- 应用伤害
    local tbDamageExtraData = {}
    tbDamageExtraData.nWeaponId = nWeaponId
    tbDamageExtraData.nWeaponTemplateId = WeaponItem:GetTemplateId()
    tbDamageExtraData.nRegionType = nRegionType
    tbDamageExtraData.bIsCoreRegion = tbArmorTemplate.bIsCoreRegion
    tbDamageExtraData.nShipArmorId = nArmorId
    tbDamageExtraData.nHurtTag = nDamageHurtTag

    tbTakerPropCmpt:ApplyDamage(tbCauser, DamageTypeEx.SHIP_EMBOLON, nFinalDamage, tbDamageExtraData)
    SDCHelper.LOG("ApplyDamage:%f", nFinalDamage)
end