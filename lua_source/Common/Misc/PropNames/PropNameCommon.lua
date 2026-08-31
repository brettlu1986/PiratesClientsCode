local PropNameCommon = {}

PropNameCommon.bReplicate = false

-- 人船共用的属性
function PropNameCommon.Init(Define, T, R)
    Define("nShipTemplateId",                   T.Int,        R.All)
    Define("nShipResTemplateId",                T.Int,        R.All)
    Define("nHumanTemplateId",                  T.Int,        R.All)

    -- progressbar
    Define("ProgressBar",                       T.Proto,      R.All)

    -- human weapon avatar
    Define("HumanPrimaryHandGunAvatarData",     T.Proto,      R.All)
    Define("HumanSecondHandGunAvatarData",      T.Proto,      R.All)
    Define("HumanPrimaryLongGunAvatarData",     T.Proto,      R.All)
    Define("HumanSecondLongGunAvatarData",      T.Proto,      R.All)

    -- team
    Define("rBattleTeamBaseInfo",               T.Proto,      R.OwnerOnly)
    Define("rBattleTeamHealthInfo",             T.Proto,      R.OwnerOnly)
    Define("rBattleTeamStateInfo",              T.Proto,      R.OwnerOnly)
    Define("rBattleTeamPosInfo",                T.Proto,      R.OwnerOnly)
    Define("rBattleTeamSignInfo",               T.Proto,      R.OwnerOnly)
    Define("rTeamPlayersInfo",                  T.Proto,      R.OwnerOnly)

    Define("rBattleWatchTeamBaseInfo",          T.Proto,      R.OwnerOnly)
    Define("rBattleWatchTeamHealthInfo",        T.Proto,      R.OwnerOnly)
    Define("rBattleWatchTeamStateInfo",         T.Proto,      R.OwnerOnly)
    Define("rBattleWatchTeamPosInfo",           T.Proto,      R.OwnerOnly)
    Define("rBattleWatchTeamSignInfo",          T.Proto,      R.OwnerOnly)
    Define("rWatchTeamPlayersInfo",             T.Proto,      R.OwnerOnly)

    -- npc battle state
    Define("bInBattleState",                    T.Bool,       R.SkipOwner)

    Define("nBuildingTimeAddition",             T.Float)
    Define("nPartBuildingTimeAddition",         T.Float)
    Define("nWeaponBuildingTimeAddition",       T.Float)
    Define("nShipBuildingTimeAddition",         T.Float)
    Define("nPartBuildingMaterialRatio",        T.Float,      R.OwnerOnly)
    Define("nWeaponBuildingMaterialRatio",      T.Float,      R.OwnerOnly)
    Define("nShipBuildingMaterialRatio",        T.Float,      R.OwnerOnly)

    -- npc risk alert  value
    Define("nRiskAlertLevel",                   T.Float,      R.SkipOwner)
    Define("nRiskAlertTarget",                  T.Int,        R.SkipOwner)
    Define("nNpcAttackTarget",                  T.Int,        R.SkipOwner)

    -- character buff rep
    Define("rCharacterAllBuff",                 T.Proto,      R.All)
    Define("rRescuingInfo",                     T.Proto,      R.OwnerOnly)

    Define("bCanSeeAirDropOnMap",               T.Bool,       R.OwnerOnly)
    Define("bCanSeeDiamondOnMap",               T.Bool,       R.OwnerOnly)
    Define("nDiamondRefreshTimeOnMap",          T.Float,      R.OwnerOnly)
end

return PropNameCommon