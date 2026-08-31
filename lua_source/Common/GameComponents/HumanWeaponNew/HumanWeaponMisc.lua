local HumanWeaponMisc = {}

HumanWeaponMisc.SlotDef = {
    PRIMARY     = 1,
    SECONDARY   = 2,
    MELEE       = 3,
    THROW       = 4,
}

HumanWeaponMisc.Type = {
    INSTANT         = 1,
    PROJECTILE      = 1<<1,
    THROW           = 1<<2,
    MELEE           = 1<<3,
    DUAL_WIELD      = 1<<4,
}

local HumanWeaponType = HumanWeaponMisc.Type
HumanWeaponType.GUN = HumanWeaponType.INSTANT | HumanWeaponType.PROJECTILE

HumanWeaponMisc.ThrownState = {
    NONE        = 0,
    IDLE        = 1,
    READY       = 2,
    THROWED     = 3,
}

HumanWeaponMisc.AttackSubState = {
    IDLE            = 0,        -- not attacking
    PRE_ATTACK      = 1,
    MID_ATTACK      = 2,
    POST_ATTACK     = 3,
}

HumanWeaponMisc.AttackExitType = {
    CURRENT_STATE_FINISHED  = 1,    -- 当前状态结束后退出Attacking
    ALL_STATE_FINISHED      = 2,    -- 所有状态结束后退出
}

return HumanWeaponMisc