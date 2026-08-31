local ShipMovementDef = {}

ShipMovementDef.ShipPostureDef = {
    FullSail    = 0,    -- 满帆姿势
    HalfSail    = 1,    -- 半帆姿势
    Reef        = 2,    -- 收帆姿势
    Sinking     = 3     -- 沉没姿势
}

ShipMovementDef.ShipGearDef = {
    FullSpeed   = 0,    -- 行驶档位
    LowSpeed    = 1,    -- 低速档位
    Stopped     = 2,    -- 停船档位
    Reverse     = 3,    -- 倒船档位
}

return ShipMovementDef
