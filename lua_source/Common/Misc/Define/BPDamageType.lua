-- 与蓝图中Enum_DamageTypeEx一一对应，只用于决定Calculator脚本
local BPDamageType = {
    Unknown         = 0,
    ShipBullet      = 1,
    ShipEmbolon     = 2,
    ShipIncendiary  = 3,
    ShipFlamer      = 4,
    ShipThrownItem  = 5,
    HumanBullet     = 6,
    HumanGrenade    = 7,
    HumanThrowWeapon= 8,
}
return BPDamageType