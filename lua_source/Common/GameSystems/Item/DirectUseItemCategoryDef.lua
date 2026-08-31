-----------------------------------------------------
--File Name    : DirectUseItemCategoryDef.lua
--Author       : lzheng
--Create Time  : 2019-02-27
--Description  : 直接使用道具
-----------------------------------------------------
local DirectUseItemCategoryDef =
{
    RENAME_CARD         = 1,        -- 改名卡
    ROSES               = 2,        -- 玫瑰花/玫瑰花束
    SPEAKER             = 3,        -- 大喇叭/小喇叭
    DIAMOND_CARD        = 4,        -- 钻石周卡/钻石月卡
    SAILOR_CARD         = 5,        -- 水手币周卡/水手币月卡
    GOLD_COIN_CARD      = 6,        -- 胜利金币卡/双倍金币卡
    EXP_CARD            = 7,        -- 胜利经验卡/双倍经验卡
}

DirectUseItemCategoryDef.Usage =
{
    RENAME_CARD         = "RENAME_CARD", 
    FRIENDSHIP_CARD     = "FRIENDSHIP_CARD", 
    SHOUT_CARD          = "SHOUT_CARD",
    VIP_CARD            = "VIP_CARD",
    BUFF_CARD           = "BUFF_CARD",
    CHEST               = "CHEST",
}


return DirectUseItemCategoryDef
