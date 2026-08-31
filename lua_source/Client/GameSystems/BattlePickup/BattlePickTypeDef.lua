-----------------------------------------------------
--File Name    : BattlePickTypeDef.lua
--Author       : ranjie
--Create Time  : 2018-12-14
--Description  : 拾取物类型
-----------------------------------------------------

local BattlePickTypeDef =
{
    ITEM                 = 1,        -- 单独的某个物品
    BOX                  = 2,        -- 箱子（可能是场景中的死亡箱、空投箱）
    TREASURE_CHEST       = 3,        -- 可自动打开的宝箱
}


return BattlePickTypeDef