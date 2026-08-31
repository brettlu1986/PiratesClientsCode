local DamageCauserType = {
    POISON_CIRCLE = -4, -- 毒圈
    DYING_REDUCE = -3, -- 重伤下衰减
    DROWN = -2, -- 溺水
    FALLING = -1, -- 跌落
    UNKNOWN = 0,
    PLAYER = 1, -- 玩家
    BOT = 2, -- 机器人
    NPC = 3, -- NPC
}

return DamageCauserType