local IntervalTimeDef = 
{
    DEFAULT_DIALOG_SUBID  = 1,
    DEFAULT_INTERVAL_TIME = 5,
    HIT_RESULT_CORE       = 4, -- 核心
    MAIN_INTERVAL_TIME    = 5, -- 总间隔5秒

    LAST_BORN_ENEMY_INDEX         = 1,     --敌人出生
    LAST_DISCOVER_ENEMY_INDEX     = 2,     --发现敌人
    LAST_KILL_ENEMY_INDEX         = 3,     --击杀敌人
    LAST_BURN_ENEMY_INDEX         = 4,     --点燃敌人
    LAST_HIT_ENEMY_INDEX          = 5,     --命中敌人
    LAST_DEAD_SELF_INDEX          = 6,     --玩家死亡
    LAST_HIT_TORPEDO_SELF_INDEX   = 7,     --被鱼雷命中
    LAST_HIT_CORE_INDEX           = 8,     --被命中核心
    LAST_BURN_SELF_INDEX          = 9,     --被点燃
    LAST_WATER_LEAK_SELF_INDEX    = 10,   --漏水
    LAST_HIT_SELF_INDEX           = 11,    --被命中
    LAST_MAIN_TIME                = 12    --总间隔，控制所有喊话的间隔时间
}


return IntervalTimeDef