-----------------------------------------------------
--File Name    : BattleItemCategoryDef.lua
--Author       : zhiyuan
--Create Time  : 2018-08-11
--Description  : Item的大类型枚举的定义
-----------------------------------------------------

local BattleItemCategoryDef =
{
    MATERIAL                = 11,   -- 材料
    SHIP_WEAPON             = 12,   -- 船的武器
    SHIP_PART               = 13,   -- 船的零件
    SHIP_WEAPON_ATTACHMENT  = 14,   -- 船的武器配件
 -- SHIP_CONSUMABLE         = 15,   -- 船的补给品
    SHIP_DRESS              = 16,   -- 船的外装
    SHIP_BULLET             = 17,   -- 船的武器炮弹
    HUMAN_WEAPON            = 18,   -- 人的武器
    HUMAN_ARMOR             = 19,   -- 人的护甲
    HUMAN_WEAPON_ATTACHMENT = 20,   -- 人的武器配件
    HUMAN_CONSUMABLE        = 21,   -- 人的消耗品
    HUMAN_DRESS             = 22,   -- 人的外装
    HUMAN_BULLET            = 23,   -- 人的武器子弹
    HUMAN_BACKPACK          = 24,   -- 人的背包
    SCENE_ITEM_PACKAGE      = 25,   -- 场景中的箱子
    SHIP                    = 26,   -- 船
    HUMAN_THROWN_ITEM       = 27,   -- 人投掷物
    BUILD_KEY_ITEM          = 28,   -- 建造图纸
    CONVERTIBLE_ITEM        = 29,   -- 拾取时转换为其他类型物品的物品
    SPECIAL_ITEM            = 30,   -- 特殊道具，玩法和活动中出现
    SHIP_THROWN_ITEM        = 31,   -- 船投掷物
}

return BattleItemCategoryDef