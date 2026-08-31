-----------------------------------------------------
--File Name    : SceneItemActorDef.lua
--Author       : zhiyuan
--Create Time  : 2018-08-22
--Description  : 定义场景中的物品actor的类型
-----------------------------------------------------

local SceneItemActorDef =
{
    ITEM                 = 1,        -- 单独的某个物品
    DIE_BOX              = 2,        -- 死亡后箱子
    AIR_DROP_BOX         = 3,        -- 空投箱子
    TREASURE_CHEST       = 4,        -- 宝箱
    SIGHT_FREE_ITEM      = 5,        -- 无视视距，哪里都能看到的道具，假设这个只能是单个物品，不能是箱子
}

return SceneItemActorDef