-----------------------------------------------------
--File Name    : ItemDefine.lua
--Description  : Item相关术语的定义
-----------------------------------------------------

local ItemDef = 
{
    GEN_SPECIAL         = 0,        -- 特殊物品(类似金币银币等)
    GEN_MATERIAL        = 1,        -- 材料
    GEN_CARGO           = 2,        -- 货物
    GEN_CONSUMABLE      = 3,        -- 消耗品
    GEN_ACCESSORY       = 4,        -- 配件
    GEN_DRESS           = 5,        -- 时装
    GEN_QUEST           = 6,        -- 任务物品
    GEN_DIRECTLY_USABLE = 7,        -- 可直接使用的物品
    GEN_EQUIPMENT       = 8,        -- 装备
    GEN_MODPART         = 9,        -- 改造零件
}
return ItemDef
