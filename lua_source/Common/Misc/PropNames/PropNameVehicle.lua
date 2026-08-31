local PropNameVehicle = {}

function PropNameVehicle.Init(Define, T, R)
    -- Define("bIsHumanDead",                        T.Bool,       R.InitialOnly) -- 必须放最前面
    Define("nVehicleHp",                          T.Float,      R.All)
    Define("nVehicleEp",                          T.Float,      R.All)
    Define("nVehicleMaxHpBase",                   T.Float)
    Define("nVehicleMaxHp",                       T.Float,      R.All)
    Define("nVehicleMaxEp",                       T.Float,      R.All)
    Define("nVehicleHpShield",                    T.Float)
    Define("bIsVehicleDying",                     T.Bool,       R.All)
    Define("bIsVehicleRescuing",                  T.Bool,       R.All)
    Define("bVehicleDead",                        T.Bool,       R.All)
    Define("nVehicleMinHpRatio",                  T.Float)
    Define("nVehicleDamageRatioFromNpc",          T.Float)
    Define("nVehicleDamageRatioToNpc",            T.Float)
    Define("nVehicleDamageRatio",                 T.Float)

    Define("nVehicleOwnerId",                     T.Int,        R.All)
    Define("VehicleSpeedBuffRadio",               T.Float,      R.All)
    Define("nStopType",                           T.Int,        R.OwnerOnly)     -- 1为不带动画，2为带动画
end

return PropNameVehicle