local PropNameHuman = {}

local function IncludeCommonRepIds()
    local PropNameCommon = require("PropNameCommon")
    local tbIds = PropNameCommon.GetRepIds()
    local tbSelfRepIds = PropNameHuman.GetRepIds()
    for _, v in ipairs(tbIds) do
        table.insert(tbSelfRepIds, v)
    end
end

function PropNameHuman.Init(Define, T, R)
    IncludeCommonRepIds()

    -- human property
    Define("bIsHumanAlreadyDead",               T.Bool,       R.InitialOnly) -- 必须放bIsHumanDead前面，因为需要确保bIsHumanAlreadyDead比bIsHumanDead先同步下来
    Define("bIsHumanDead",                      T.Bool,       R.All)         -- 必须放最前面
    Define("nHumanHp",                          T.Float,      R.All)
    Define("nHumanEp",                          T.Float,      R.All)
    Define("nHumanMaxHpBase",                   T.Float)
    Define("nHumanMaxHp",                       T.Float,      R.All)
    Define("nHumanMaxEp",                       T.Float,      R.All)
    Define("nSwimmingStamina",                  T.Float,      R.OwnerOnly)
    Define("nHumanHpShield",                    T.Float)
    Define("bIsHumanDying",                     T.Bool,       R.All)
    Define("bIsHumanRescuing",                  T.Bool,       R.All)
    Define("nHumanMinHpRatio",                  T.Float)

    Define("nHumanMaxDyingHp",                  T.Float)
    Define("nHumanRescuedHp",                   T.Float)
    Define("nHumanDyingHpReduceSpeed",          T.Float)
    Define("nHumanRescuedTime",                 T.Float)
    Define("nCommonRecoverLimit",               T.Int)
    Define("nEpReduceSpeed",                    T.Int)
    Define("nHeadInjuryRatio",                  T.Float)
    Define("nBodyInjuryRatio",                  T.Float)
    Define("nAllFoursInjuryRatio",              T.Float)

    -- human movement
    Define("HumanMovementState",                T.Int,        R.All)
    Define("HumanRunState",                     T.Bool,       R.All)
    Define("HumanSpeedBuffRadio",               T.Float,      R.All)
    Define("rHumanRootMotionJump",              T.Proto,      R.SkipOwner)
    Define("rHumanRootMotionJumpNew",           T.Proto,      R.SkipOwner)
    Define("rHumanVehicleState",                T.Proto,      R.All)
    Define("rHumanJumpBuffConfig",              T.Proto,      R.All)
    Define("rHumanVehicleStateNew",             T.Proto,      R.All)

    -- human avatar
    -- Define("HumanAvatarResData",                T.Proto,      R.All)

    -- human weapon avatar
    -- Define("HumanPrimaryHandGunAvatarData",     T.Proto,      R.All)
    -- Define("HumanSecondHandGunAvatarData",      T.Proto,      R.All)
    -- Define("HumanPrimaryLongGunAvatarData",     T.Proto,      R.All)
    -- Define("HumanSecondLongGunAvatarData",      T.Proto,      R.All)

    -- ai is bot
    Define("nHumanBotType",                     T.Int,        R.All)

    -- new human weapon
    Define("nHumanCurrentWeaponInstanceId",     T.Int,        R.SkipOwner)
    Define("bHumanWeaponInAiming",              T.Bool,       R.SkipOwner)
    Define("bAttacking",                        T.Bool,       R.SkipOwner)
    Define("nHumanReloading",                   T.Int,        R.SkipOwner)

    Define("nHumanWeaponPrimaryInstanceId",     T.Int,        R.SkipOwner)
    Define("nHumanWeaponPrimaryTemplateId",     T.Int,        R.SkipOwner)
    Define("nHumanWeaponPrimaryFashionId",      T.Int,        R.SkipOwner)
    Define("nHumanWeaponSecondaryInstanceId",   T.Int,        R.SkipOwner)
    Define("nHumanWeaponSecondaryTemplateId",   T.Int,        R.SkipOwner)
    Define("nHumanWeaponSecondaryFashionId",    T.Int,        R.SkipOwner)
    Define("nHumanWeaponMeleeInstanceId",       T.Int,        R.SkipOwner)
    Define("nHumanWeaponMeleeTemplateId",       T.Int,        R.SkipOwner)
    Define("nHumanWeaponThrowInstanceId",       T.Int,        R.SkipOwner)
    Define("nHumanWeaponThrowTemplateId",       T.Int,        R.SkipOwner)
    Define("nHumanBowPreAttack",                T.Int,        R.SkipOwner)

    Define("rHumanGunAttackRoute",              T.Proto,      R.SkipOwner)
    Define("rHumanPorjectGunAttackRoute",       T.Proto,      R.SkipOwner)
    Define("rHumanGunAttackOnceResult",         T.Proto,      R.All)
    Define("rHumanDualWieldAttack",             T.Proto,      R.SkipOwner)
    Define("rHumanGunAttackMultiResult",        T.Proto,      R.All)
    Define("rHumanMeleeAttackRoute",            T.Proto,      R.SkipOwner)
    Define("rHumanMeleeAttackHits",             T.Proto,      R.All)
    Define("nHumanThrownState",                 T.Int,        R.SkipOwner)
    Define("nHumanExtraPackageCapacityValue",   T.Int)
    Define("nHumanListenRange",                 T.Float,      R.OwnerOnly)
    Define("nHumanPickupRange",                 T.Float,      R.OwnerOnly)
    Define("nHumanMoraleConsumedSpeed",         T.Float)
    Define("nHumanAttackSubState",              T.Int,        R.SkipOwner)

    Define("nHumanAttack",                      T.Float)
    Define("nHumanAttackInterval",              T.Float)
    Define("nHumanReloadTime",                  T.Float)

    Define("rHumanAvatarData",                  T.Proto,      R.All)


    Define("nHumanItemUsingTime",               T.Float)
    Define("nHumanDamageRatioFromNpc",          T.Float)
    Define("nHumanDamageRatioToNpc",            T.Float)
    Define("nHumanDamageRatio",                 T.Float)

    Define("rHumanPickupItem",                    T.Proto,    R.SkipOwner)
    Define("nHumanFootStepSoundSettingIndex",     T.Int,      R.All)
    Define("nHumanWeaponAttackSoundSettingIndex", T.Int,      R.All)

    Define("bHumanConceal",                     T.Bool,       R.All)
    Define("nArmorLevel",                       T.Float,      R.All)

    Define("nCurrentArmorTemplateId",           T.Int,        R.All)

    --武器相关
    Define("nAttackCD",                         T.Float,      R.OwnerOnly)               --输入cd
    Define("nAttackRate",                       T.Float,      R.OwnerOnly)               --射速
    Define("nAttackRegion",                     T.Float,      R.All)                     --射程/近战武器攻击范围
    Define("nBulletCapacity",                   T.Int,        R.OwnerOnly)               --子弹容量
    Define("nBulletCostPerAttack",              T.Int,        R.OwnerOnly)               --一次性扣弹数
    Define("nBulletCountPerAttack",             T.Int,        R.OwnerOnly)               --一次性打出的子弹个数
    Define("nBulletInitialSpeed",               T.Float,      R.All)                     --子弹初速度
    Define("nBulletSpeedMagnification",         T.Float,      R.OwnerOnly)               --蓄力满子弹速度倍率
    Define("nBulletDispersionMagnification",    T.Float,      R.OwnerOnly)               --蓄力满散布倍率
    Define("nDamagePerAttack",                  T.Float)                                  --单发伤害
    Define("nDamageFullCharge",                 T.Float)                                  --蓄力满伤
    Define("nDispersionRatio",                  T.Float,      R.OwnerOnly)               --武器扩散修改
    Define("nFireballExplosiveInnerRadius",     T.Float,      R.OwnerOnly)               --火球爆炸范围（内径）
    Define("nFireballExplosiveOutsideRadius",   T.Float,      R.OwnerOnly)               --火球爆炸范围（外径）
    Define("nRecoilHorizontalRatio",            T.Float,      R.OwnerOnly)               --后坐力水平值
    Define("nRecoilVerticalRatio",              T.Float,      R.OwnerOnly)               --后坐力垂直值
    Define("nSectorDegree",                     T.Float,      R.OwnerOnly)               --扇形角度
    Define("nAttackCoefficient",                T.Float,      R.All)                     --攻击动作系数
    Define("nReloadCoefficient",                T.Float,      R.All)                     --换弹动作系数

    --行为相关
    Define("nClimbCoefficient",                 T.Float,      R.All)                     --攀爬系数
    Define("nMountCoefficient",                 T.Float,      R.All)                     --上下马系数
    Define("nResistFallDownCoefficient",        T.Float,      R.OwnerOnly)               --坠落减伤
    Define("nResistFallOffHorseCoefficient",    T.Float,      R.OwnerOnly)               --下马减伤
end

return PropNameHuman