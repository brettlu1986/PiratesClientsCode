-----------------------------------------------------
--File Name    : HumanArmorDef.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 2:49:31 PM
--Description  : HumanArmorDef
-----------------------------------------------------
local HumanArmorDef = {}
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local PropertyWrapperType = require("PropertyWrapperType")

HumanArmorDef.MAX_LEVEL = 3

if GlobalVariableSystem.bUseNewBattleItem then
    HumanArmorDef.ArmorCategory = {
        All     = 1,      --全套，适应新版的改动
    }
else
    HumanArmorDef.ArmorCategory = {
        Head    = 1,      --头
        Body    = 2,      --身
    }
end

HumanArmorDef.ArmorType =
{
    Knight  = 1,
    Light   = 2,
    Robe    = 3,
    Stealth = 4,
}

-- 盔甲影响人属性的枚举
-- key: string，用于填写在配置表中，或其他索引
-- value：string，对应PropName中的定义
HumanArmorDef.ArmorAffectHumanWeaponPropertyDef =
{
    AttackCD                           = "nAttackCD",
    AttackRate                         = "nAttackRate",
    AttackRegion                       = "nAttackRegion",
    BulletCapacity                     = "nBulletCapacity",
    BulletCostPerAttack                = "nBulletCostPerAttack",
    BulletCountPerAttack               = "nBulletCountPerAttack",
    BulletInitialSpeed                 = "nBulletInitialSpeed",
    BulletSpeedMagnification           = "nBulletSpeedMagnification",
    DamagePerAttack                    = "nDamagePerAttack",
    DamageFullCharge                   = "nDamageFullCharge",
    DispersionRatio                    = "nDispersionRatio",
    FireballExplosiveInnerRadius       = "nFireballExplosiveInnerRadius",
    FireballExplosiveOutsideRadius     = "nFireballExplosiveOutsideRadius",
    RecoilHorizontal                   = "nRecoilHorizontalRatio",
    RecoilVertical                     = "nRecoilVerticalRatio",
    SectorDegree                       = "nSectorDegree",
    AttackCoefficient                  = "nAttackCoefficient",
    ReloadCoefficient                  = "nReloadCoefficient",
    HumanWeaponAttackSoundSettingIndex = "nHumanWeaponAttackSoundSettingIndex",
}

HumanArmorDef.ArmorAffectHumanActionPropertyDef =
{
    ClimbCoefficient                = "nClimbCoefficient",
    MountCoefficient                = "nMountCoefficient",
    ResistFallDownCoefficient       = "nResistFallDownCoefficient",
    ResistFallOffHorseCoefficient   = "nResistFallOffHorseCoefficient",
}


-- 盔甲影响人属性方式的枚举
HumanArmorDef.ArmorAffectActionDef =
{
    Add      = PropertyWrapperType.TYPE_ADD,    --加法值
    Multiply = PropertyWrapperType.TYPE_MULTIPLY,    --乘法值
    Override = PropertyWrapperType.TYPE_OVERRIDE     --覆盖值
}


return HumanArmorDef