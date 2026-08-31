local SAIThreatStrategyDef = require("SAIThreatStrategyDef")

local SAILogicConfigBot = {
    AIResourceId = 10,               --对应的AIType表id

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

    --听力配置选项(可选)
    Hearing = {
        RememberTime = 10,          --声音信息记忆时间
        Human = {
            ListenRange = 5000      --听力范围

        },
        Ship = {
            ListenRange = 50000
        },
    },

    --伤害信息选项(可选)
    Damage = {
        RememberTime = 15,          --伤害信息记忆时间
    },

    Threat = {
        DefaultStratrgy = SAIThreatStrategyDef.AnyEnemy,        --默认的敌人选择策略
        Interval = 2,               --决策间隔
        StartDisable = true,        --开始禁止
    },

    Weapon = {
        AllowEmptyHandAttack = true,    --允许拳头攻击
        PreFireTime = 0.5,              --开火前瞄准时间
    },

    bEscapingPoison = true,         --是否跑毒

    Build = {
        bCanBuildShipPart   = true,    --是否建造船护甲
        bCanBuildShipWeapon = true,    --是否建造船武器
        bCanBuildHumanWeapon= true,    --是否建造人武器
        bCanBuildHumanArmor = true,    --是否建造人护甲
    },

    Parachute = {
        nStartBattleDelayTime = 3,     --跳伞后多久启动战斗AI
    },

    DoorDetect = {
        nInterval = 2, --检测门的间隔 s
    }
}

return SAILogicConfigBot