--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanMiscPropertyDefaultIni = {}
HumanMiscPropertyDefaultIni.szFileName = "common/ffa/human/misc_property_default.ini"

function HumanMiscPropertyDefaultIni:OnParse(Parser)
    local tbDefault = {}
    tbDefault.nAttackCD                        = Parser:Get("weapon", "attack_cd",                         0, Parser.TypeNumber)  --输入cd
    tbDefault.nAttackRate                      = Parser:Get("weapon", "attack_rate",                       0, Parser.TypeNumber)  --射速
    tbDefault.nAttackRegion                    = Parser:Get("weapon", "attack_region",                     0, Parser.TypeNumber)  --射程/近战武器攻击范围
    tbDefault.nBulletCapacity                  = Parser:Get("weapon", "bullet_capacity",                   0, Parser.TypeNumber)  --子弹容量
    tbDefault.nBulletCostPerAttack             = Parser:Get("weapon", "bullet_cost_per_attack",            0, Parser.TypeNumber)  --一次性扣弹数
    tbDefault.nBulletCountPerAttack            = Parser:Get("weapon", "bullet_count_per_attack",           0, Parser.TypeNumber)  --一次性打出的子弹个数
    tbDefault.nBulletInitialSpeed              = Parser:Get("weapon", "bullet_initial_speed",              0, Parser.TypeNumber)  --子弹初速度
    tbDefault.nBulletSpeedMagnification        = Parser:Get("weapon", "bullet_speed_magnification",        0, Parser.TypeNumber)  --蓄力满子弹速度倍率
    tbDefault.nBulletDispersionMagnification   = Parser:Get("weapon", "bullet_dispersion_magnification",   0, Parser.TypeNumber)  --蓄力满散布倍率
    tbDefault.nDamagePerAttack                 = Parser:Get("weapon", "damage_per_attack",                 0, Parser.TypeNumber)  --单发伤害
    tbDefault.nDamageFullCharge                = Parser:Get("weapon", "damage_full_charge",                0, Parser.TypeNumber)  --蓄力满伤
    tbDefault.nDispersionRatio                 = Parser:Get("weapon", "dispersion_ratio",                  0, Parser.TypeNumber)  --武器扩散修改
    tbDefault.nFireballExplosiveInnerRadius    = Parser:Get("weapon", "fireball_explosive_inner_radius",   0, Parser.TypeNumber)  --火球爆炸范围（内径）
    tbDefault.nFireballExplosiveOutsideRadius  = Parser:Get("weapon", "fireball_explosive_outside_radius", 0, Parser.TypeNumber)  --火球爆炸范围（外径）
    tbDefault.nRecoilHorizontalRatio           = Parser:Get("weapon", "recoil_horizontal_ratio",           0, Parser.TypeNumber)  --后坐力水平值
    tbDefault.nRecoilVerticalRatio             = Parser:Get("weapon", "recoil_vertical_ratio",             0, Parser.TypeNumber)  --后坐力垂直值
    tbDefault.nSectorDegree                    = Parser:Get("weapon", "sector_degree",                     0, Parser.TypeNumber)  --扇形角度
    tbDefault.nAttackCoefficient               = Parser:Get("weapon", "attack_coefficient",                0, Parser.TypeNumber)  --攻击动作系数
    tbDefault.nReloadCoefficient               = Parser:Get("weapon", "reload_coefficient",                0, Parser.TypeNumber)  --换弹动作系数

    tbDefault.nClimbCoefficient                = Parser:Get("action", "climb_coefficient",                 0, Parser.TypeNumber)  --攀爬系数
    tbDefault.nMountCoefficient                = Parser:Get("action", "mount_coefficient",                 0, Parser.TypeNumber)  --上下马系数
    tbDefault.nResistFallDownCoefficient       = Parser:Get("action", "resist_falldown_coefficient",       0, Parser.TypeNumber)  --坠落减伤系数
    tbDefault.nResistFallOffHorseCoefficient   = Parser:Get("action", "resist_falloff_horse_coefficient",  0, Parser.TypeNumber)  --坠马减伤系数

    self.tbDefault = tbDefault
end

return HumanMiscPropertyDefaultIni
