local SkillCastFailedDef = {
    UNKNOWN                         = -1,   -- 未定义
    UNKNOWN_SKILL                   =  0,   -- 没有找到该技能
    SKILL_IN_CD                     =  1,   -- 技能正在CD
    CONSUMABLE_NOT_ENOUGH           =  2,   -- 消耗品不足
    CAST_COUNT_NOT_ENOUGH           =  3,   -- 单场副本释放次数不足
    HP_NOT_ENOUGH                   =  4,   -- 血量未达指定条件
    CHARGE_NOT_ENOUGH               =  5,   -- 充能不足
    PROB_NOT_ENOUGH                 =  6,   -- 概率不足
    SKILL_CASTING                   =  7,   -- 有技能正在释放
    CAN_NOT_FOUND_TRAGET_SHIP       =  8,   -- 找不到技能释放目标
    CAN_NOT_FOUND_TRAGET_IN_NEARBY  =  9,   -- 范围内没有释放目标
    BUFF_CONDITION_NOT_ENOUGH       = 10,   -- Buff条件不足
    DONT_HAVE_BROKEN_PART           = 11,   -- 当前没有可修理项
    SKILL_IS_DISABLED               = 12,   -- 当前技能被禁用
}
return SkillCastFailedDef
