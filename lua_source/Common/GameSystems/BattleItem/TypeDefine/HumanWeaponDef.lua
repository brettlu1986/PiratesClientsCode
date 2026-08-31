-----------------------------------------------------
--File Name    : HumanWeaponDef.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 2:49:31 PM
--Description  : HumanWeaponDef
-----------------------------------------------------
local HumanWeaponDef = {}

HumanWeaponDef.MAX_LEVEL = 3

HumanWeaponDef.WeaponDamageType = {
    Bullet    = 1,
    Melee     = 2,
    Magic     = 3,
    DOT       = 4,   --持续伤害，如燃烧弹
    Expolsive = 5,   --爆炸伤害，如手雷
}


HumanWeaponDef.WeaponCategory = {
    Melee     = 1,      --近战
    Pistol    = 2,      --手枪
    Flintlock = 3,      --燧发枪
    Matchlock = 4,      --火绳枪
    Crossbow  = 5,      --弩
    Bow       = 6,      --弓
    TwoHand   = 7,      --双手武器
    ThrowWeapon = 8,    --双持飞刀
    Wand = 9,           --魔杖
}

HumanWeaponDef.WeaponSlotCategory ={}
HumanWeaponDef.WeaponSlotCategory["Melee"] = 1--近战
HumanWeaponDef.WeaponSlotCategory["Ranged"] = 2--远程
HumanWeaponDef.WeaponSlotCategory["All"] = HumanWeaponDef.WeaponSlotCategory.Melee | HumanWeaponDef.WeaponSlotCategory.Ranged--皆可，适应新版的改动



-- 这个分类和上面的WeaponSlotCategory有些重复，但暂时保持
-- 当前这个分类为武器大类
HumanWeaponDef.WeaponPrimaryCategory = {
    Melee     = 1,      --近战
    Ranged    = 2,      --远程
}

HumanWeaponDef.HumanPose = {
    Stand = 1,
    Squat = 2,
    Prone = 3,
    Jump = 4,
}

HumanWeaponDef.HumanMotion = {
    Stay = 1,
    Walk = 2,
    Run = 3,
}

HumanWeaponDef.HumanFireAction = {
    Normal = 1,    --腰射
    Sight  = 2,    --瞄准
}

HumanWeaponDef.FireType = {
    Single  = 1,     --单发
    Triple  = 2,     --三连
    Auto    = 3,     --自动
}

-- 后坐力等级
HumanWeaponDef.RecoilLevel = {
    Very_Strong        = 1,    -- 极强
    Strong             = 2,    -- 强
    Normal             = 3,    -- 中等
    Weak               = 4,    -- 弱
    Very_Weak          = 5,    -- 极弱
}

HumanWeaponDef.MeleeAttackSpeedLevel = {
    Very_Fast          = 1,    -- 极快
    Fast               = 2,    -- 快
    Normal             = 3,    -- 中等
    Slow               = 4,    -- 慢
    Very_Slow          = 5,    -- 极慢
}

HumanWeaponDef.RecoilProperty =
{

    RecoilUpperAngle                    = "nRecoilUpperAngle",                  --后座力垂直角度上限
    RecoildLowerAngle                   = "nRecoildLowerAngle",                 --后坐力垂直角度下限
    RecoildHUpperAngle                  = "nRecoildHUpperAngle",                --后座力水平角度上限
    RecoilHorizontalMaxPercent          = "nHorizontalMaxPercent",              --枪口水平随机跳动最大比例
    RecoilHorizontalMinPercent          = "nHorizontalMinPercent",              --枪口水平随机跳动最小比例
    RecoilDuration                      = "nRecoilDuration",                    --后坐力持续时间
    RecoilRecoverMaxPercent             = "nRecoilRecoverMaxPercent",           --后座恢复最大百分比
    RecoilRecoverMinPercent             = "nRecoilRecoverMinPercent",           --后座恢复最小百分比
    UseRecoverInVertical                = "bUseRecoverInVertical",
    RecoilMaxYaw                        = "nRecoilMaxYaw",                      --开火后座造成的摄像机在Z轴上进行旋转的角度随机范围上限
    RecoilMinYaw                        = "nRecoilMinYaw",                      --开火后座造成的摄像机在Z轴上进行旋转的角度随

    RecoilUpperAngleAim                 = "nRecoilUpperAngleAim",
    RecoildLowerAngleAim                = "nRecoildLowerAngleAim",
    RecoildHUpperAngleAim               = "nRecoildHUpperAngleAim",
    RecoilHorizontalMaxPercentAim       = "nRecoilHorizontalMaxPercentAim",
    RecoilHorizontalMinPercentAim       = "nRecoilHorizontalMinPercentAim",

    RecoilDurationAim                   = "nRecoilDurationAim",
    RecoilRecoverMaxPercentAim          = "nRecoilRecoverMaxPercentAim",
    RecoilRecoverMinPercentAim          = "nRecoilRecoverMinPercentAim",
    UseRecoverInVerticalAim             = "bUseRecoverInVerticalAim",
    RecoilMaxYawAim                     = "nRecoilMaxYawAim",
    RecoilMinYawAim                     = "nRecoilMinYawAim",
}

HumanWeaponDef.Property = {
    CD                                  = "nCD",                                --输入cd
    OpenSightSpeed                      = "nOpenSightSpeed",                    --开镜速度
    DamagePerBullet                     = "nDamagePerBullet",                   --单发伤害
    DamageMagnification                 = "nDamageMagnification",               --单发蓄力倍率
    ShipDamageRatio                     = "nShipDamageRatio",                   --单发蓄力倍率
    RateOfFire                          = "nRateOfFire",                        --射速
    SpeedAffectDamage                   = "bSpeedAffectDamage",                 --飞行速度是否影响伤害
    InitialSpeed                        = "nInitialSpeed",                      --子弹初速度
    InitialSpeedMagnification           = "nInitialSpeedMagnification",         --子弹初速度蓄力倍率
    FireType                            = "nFireType",                          --开枪制式，单发；三连；自动
    ReloadTime                          = "nReloadTime",                        --装填时间
    BulletType                          = "nBulletType",                        --子弹类型
    BulletMax                           = "nBulletMax",                         --子弹数量
    EffectiveRange                      = "nEffectiveRange",                    --射程，cm

    --散布相关
    DispersionDeviation                 = "nDispersionDeviation",               --散布标准差
    DispersionRecover                   = "nDispersionRecover",                 --散布的恢复时间

    --散布惩罚
    Dispersion                          = "nDispersion",                        --武器散布基础值, 瞄准后开火时子弹射击后理论上飞行50m后分布的圆形半径对应的角度：单位MOA
    DispersionMagnification             = "nDispersionMagnification",           --武器散布基础值蓄力倍率
    --散布惩罚：姿态惩罚
    DispersionPublishStand              = "nDispersionPublishStand",            --站姿散布惩罚
    DispersionPublishSquat              = "nDispersionPublishSquat",            --蹲姿散布惩罚
    DispersionPublishProne              = "nDispersionPublishProne",            --卧姿散布惩罚
    --散布惩罚：移动惩罚
    DispersionPublishWalk               = "nDispersionPublishWalk",             --走姿散布惩罚
    DispersionPublishJump               = "nDispersionPublishJump",             --跳姿散布惩罚
    --散布惩罚：瞄准状态惩罚
    DispersionPublishNormalAim          = "nDispersionPublishNormalAim",        --腰射瞄准散布惩罚（非开火后恢复时间内，使用此值）
    DispersionPublishSightAim           = "nDispersionPublishSightAim",         --开镜瞄准散布惩罚（非开火后恢复时间内，使用此值）
    DispersionPublishNormalFire         = "nDispersionPublishNormalFire",       --腰射开火散布惩罚（开火后恢复时间内，使用此值）
    DispersionPublishSightFire          = "nDispersionPublishSightFire",        --开镜开火散布惩罚（开火后恢复时间内，使用此值）

    --近战武器属性
    MeleeAttackSpeed                    = "nMeleeAttackSpeed",                  --近战挥动速度

    --准星相关
    ScopeResId                          = "nScopeResId",                        --开镜准镜资源id

    --开镜相关
    OpenAimCameraRate                   = "nOpenAimCameraRate",                 --武器开镜倍率
    OpenAimCameraHMoveScale             = "nOpenAimCameraHMoveScale",           --武器开镜划屏水平方向系数
    OpenAimCameraVMoveScale             = "nOpenAimCameraVMoveScale",           --武器开镜划屏垂直方向系数

    DeviationX                          = "nDeviationX",                        --不开镜长轴散布系数
    DeviationY                          = "nDeviationY",                        --不开镜短轴散布系数
    AimDeviationX                       = "nAimDeviationX",                     --开镜长轴散布系数
    AimDeviationY                       = "nAimDeviationY",                     --开镜短轴散布系数
    DecreaseBulletCount                 = "nDecreaseBulletCount",               --一次性扣弹个数
    MaxSpotCount                        = "nMaxSpotCount",                      --一次性打出的子弹个数
    MaxSectorAngle                      = "nMaxSectorAngle",                    --最大散布角度
    WeaponLength                        = "nWeaponLength",                      --武器长度
    OffsetToAim                         = "nOffsetToAim",                       --开镜相机在武器上的偏移

    FireAbsorptionSpeed                 = "nFireAbsorptionSpeed",                --开火吸附速度
    FireAbsorptionInterp                = "nFireAbsorptionInterp",

    FireballExplosiveInnerRadius        = "nFireballExplosiveInnerRadius",       --火球爆炸范围（内径）
    FireballExplosiveOutsideRadius      = "nFireballExplosiveOutsideRadius",     --火球爆炸范围（外径）

    ProjectileFireAngle                 = "nProjectileFireAngle",                --默认抛物线仰角(度)
}


HumanWeaponDef.TotalProperty = {}

local function MergeTotalProperty()
    local tb = HumanWeaponDef.TotalProperty
    for k, v in pairs(HumanWeaponDef.Property) do
        tb[k] = v
    end
    for k, v in pairs(HumanWeaponDef.RecoilProperty) do
        tb[k] = v
    end
end

MergeTotalProperty()


local WeaponPropertyToHumanPropertyMap = {}

local WeaponProperty = HumanWeaponDef.Property

WeaponPropertyToHumanPropertyMap[WeaponProperty.CD]                             = "nAttackCD"
WeaponPropertyToHumanPropertyMap[WeaponProperty.RateOfFire]                     = "nAttackRate"
WeaponPropertyToHumanPropertyMap[WeaponProperty.EffectiveRange]                 = "nAttackRegion"
WeaponPropertyToHumanPropertyMap[WeaponProperty.BulletMax]                      = "nBulletCapacity"
WeaponPropertyToHumanPropertyMap[WeaponProperty.DecreaseBulletCount]            = "nBulletCostPerAttack"
WeaponPropertyToHumanPropertyMap[WeaponProperty.MaxSpotCount]                   = "nBulletCountPerAttack"
WeaponPropertyToHumanPropertyMap[WeaponProperty.InitialSpeed]                   = "nBulletInitialSpeed"
WeaponPropertyToHumanPropertyMap[WeaponProperty.InitialSpeedMagnification]      = "nBulletSpeedMagnification"
WeaponPropertyToHumanPropertyMap[WeaponProperty.DamagePerBullet]                = "nDamagePerAttack"
WeaponPropertyToHumanPropertyMap[WeaponProperty.DamageMagnification]            = "nDamageFullCharge"
WeaponPropertyToHumanPropertyMap[WeaponProperty.FireballExplosiveInnerRadius]   = "nFireballExplosiveInnerRadius"
WeaponPropertyToHumanPropertyMap[WeaponProperty.FireballExplosiveOutsideRadius] = "nFireballExplosiveOutsideRadius"
WeaponPropertyToHumanPropertyMap[WeaponProperty.MaxSectorAngle]                 = "nSectorDegree"

HumanWeaponDef.WeaponPropertyToHumanPropertyMap = WeaponPropertyToHumanPropertyMap

return HumanWeaponDef