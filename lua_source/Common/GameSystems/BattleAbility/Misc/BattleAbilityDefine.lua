local BattleAbilityDefine = {}


BattleAbilityDefine.ABILITY_EVENT_PREFIX        = "AbilityEvent_"
BattleAbilityDefine.ABILITY_CONDITION_PREFIX    = "AbilityCondition_"
BattleAbilityDefine.ABILITY_CONSUMABLE_PREFIX   = "AbilityConsumable_"
BattleAbilityDefine.ABILITY_ACTION_PREFIX       = "AbilityAction_"

BattleAbilityDefine.DYING_REMOVE_BUFF_GROUP_ID = 1

BattleAbilityDefine.TargetType = {
    ENEMY               = 1, -- 全体敌人单位
    TEAMMATE_AND_SELF   = 2, -- 全体友方单位（包含自己）
    TEAMMATE            = 3, -- 全体友方单位（不包含自己）
    SELF                = 4, -- 自己
    ALL                 = 5, -- 所有单位
    SPECIAL             = 6  -- 特别单位单位
}

BattleAbilityDefine.RangeType = {
    All     = 1, -- 全场景范围
    SECTOR  = 2, -- 扇形范围
    CIRCLE  = 3, -- 圆形范围
    RECT    = 4  -- 矩形范围
}

BattleAbilityDefine.CenterTarget = {
    SELF            = 1, -- 自己的位置
    AIM_LOCATION    = 2, -- 瞄准的位置
    WORLD_LOCATION  = 3  -- 场景中指定位置
}

BattleAbilityDefine.TriggerType = {
    ACTIVE          = 1, -- 主动触发
    PASSIVE         = 2  -- 被动触发
}

BattleAbilityDefine.OverlapType = {
    ADD         = 1, -- 加法叠加
    MULTIPLY    = 2, -- 乘法叠加
    FIXED       = 3  -- 固定值叠加
}

BattleAbilityDefine.ValueType = {
    FIXED   = 1, -- 固定值
    PERCENT = 2  -- 百分比
}

BattleAbilityDefine.BUFF_GROUP_TYPE = {
    DEFAULT             = -1,   -- 默认
    ALLOW_REDUCE_TIME   = 1,    -- 允许由属性控制减少Buff时间
    FROM_LOBBY          = 2     -- 由外围系统带入
}

BattleAbilityDefine.REMOVE_BUFF_TYPE = {
    REMOVE_BY_BUFF_ID = 1,  -- 按Buff的id移除
    REMOVE_BY_GROUP_ID = 2, -- 按Buff组id移除
    REMOVE_BY_TYPE_ID = 3,  -- 按Buff类型id移除
    REMOVE_BY_BUFF_LIST = 4 -- 按显式指定的Buff id list移除
}

BattleAbilityDefine.BUFF_TYPE = {
    ENHANCE_BUFF = 1,   -- 增益Buff
    DEBUFF = 2,         -- 减益Buff
    NEUTRAL = 3         -- 中性Buff
}


BattleAbilityDefine.BUFF_ADDABLE_TARGET_TYPE = {
    SHIP = 0,           -- 人
    HUMAN = 1,          -- 船
    SHIP_AND_HUMAN = 2  -- 人船
}


BattleAbilityDefine.BUFF_REMOVE_TYPE_ON_SWITCH = {
    ALWAYS = 0,             -- 切就移除
    SHIP_TO_HUMAN = 1,      -- 船切人移除
    HUMAN_TO_SHIP = 2,      -- 人切船移除
    ALWAYS_NOT = 3          -- 不移除
}

BattleAbilityDefine.EFFECTIVE_TARGET_TYPE = {
    SHIP = 0,           -- 人
    HUMAN = 1,          -- 船
    SHIP_AND_HUMAN = 2  -- 人船
}

BattleAbilityDefine.BUFF_INDIVIDUAL_TYPE = {
    NONE = 0,
    BY_INSTIGATOR = 1,
    ALL = 2
}

BattleAbilityDefine.CHARACTER_TYPE = {
    ALL     = 0,    -- 人和船
    HUMAN   = 1,    -- 人
    SHIP    = 2     -- 船
}

return BattleAbilityDefine
