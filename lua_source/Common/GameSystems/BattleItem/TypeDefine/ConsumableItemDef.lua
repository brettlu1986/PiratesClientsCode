local ConsumableItemDef = {}

ConsumableItemDef.ValidTargetType = {
    SHIP                = 0,    -- 人
    HUMAN               = 1,    -- 船
    SHIP_AND_HUMAN      = 2,    -- 人船
}

ConsumableItemDef.RecoveringType = {
    HP = 0,
    EP = 1,
}

ConsumableItemDef.RecoveringValueType = {
    RECOVER_FIXED_VALUE         = 0, -- 回复固定值
    RECOVER_PERCENT_VALUE       = 1, -- 回复百分比
    RECOVER_TO_FIXED_VALUE      = 2, -- 回复至固定值
    RECOVER_TO_PERCENT_VALUE    = 3, -- 回复至百分比
}

ConsumableItemDef.ConsumableSubType = {
    MEDICINE                = 1,    -- 药品
    FOOD_AND_DRINK          = 2,    -- 食物饮料
}

return ConsumableItemDef