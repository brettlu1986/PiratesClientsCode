-----------------------------------------------------
--File Name    : ItemBuildingVerificationFailureDef.lua
--Author       : zhiyuan
--Create Time  : 2018-09-19
--Description  : 校验物品建造的结果枚举
-----------------------------------------------------

-- 注意：这里的值要跟battleitem.proto里面ItemReturnCode里相同语义的值相同，方便代码的编写
-- todo @zhiyuan 考虑一下如何优化
local ItemBuildingVerificationFailureDef =
{
    MATERIALS_NOT_ENOUGH                      = 1,        -- 材料不足             对应的参数为不足的材料物品templateId的列表
    KEY_ITEMS_NOT_ENOUGH                      = 2,        -- 图纸不足             对应的参数为不足的材料物品templateId的列表
    PREREQUISITE_ITEMS_NOT_ENOUGH             = 3,        -- 前置物品不足         对应的参数为不足的前置物品templateId的列表
    ITEM_TYPE_CANNOT_BUILD                    = 4,        -- 物品类型不能建造      对应的参数为nil
    INACCEPTABLE_PLAYER_SHIP_BUILDING_LEVEL   = 5,        -- 不能建造这个等级的船  对应的参数为nil
    NOT_COMPATIBLE                            = 6,        -- 物品不兼容           对应的参数为nil
    SAME_SHIP                                 = 7,        -- 跟当前相同类型船      对应的参数为nil
    NO_LOW_LEVEL_HUMAN_WEAPON                 = 8,        -- 没有找到低等级的人武器 对应的参数为nil
}

return ItemBuildingVerificationFailureDef