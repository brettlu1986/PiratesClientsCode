local SAIThreatStrategyDef = require("SAIThreatStrategyDef")
local SAIWeaponStrategyDef = require("SAIWeaponStrategyDef")
local NpcAIIni = require("NpcAIIni")

local SAILogicConfigNpcBattle = {
    AIResourceId = 11,               --对应的AIType表id

    --视野配置选项(可选)
    Sight = {
        Human = {
            InSightRange = 6000,    --视野距离
            LoseSightRange = 7000,  --视野丢失距离
            FOV = 120,              --视野角度
        },
        Ship = {
            InSightRange = 60000,
            LoseSightRange = 70000,
            FOV = 360,
        },
    },

    Threat = {
        DefaultStratrgy = SAIThreatStrategyDef.Enmity,        --默认的敌人选择策略
        Interval = 2,               --决策间隔
    },

    Weapon = {
        AllowEmptyHandAttack = true,    --允许拳头攻击
        PreFireTime = 0.5,              --开火前瞄准时间
        Strategy = SAIWeaponStrategyDef.DistanceBased,  --切换武器策略
        HumanSwitchWeaponCD = NpcAIIni.nHumanSwitchWeaponCD,
        ShipSwitchWeaponCD = NpcAIIni.nShipSwitchWeaponCD,
    },

    --警戒配置
    Alert = {
        AlertChangeSpeed = 10,          --警戒值变化速度
        BaseAlertLevel = 10,            --警戒值起点值
    },

    --仇恨值配置
    Enmity = {
        ExpirationTime = 15,            --仇恨持续时间
        EnmityScale = NpcAIIni.nDamageEnmityScale,                --伤害值转仇恨值倍率
    }

}

return SAILogicConfigNpcBattle