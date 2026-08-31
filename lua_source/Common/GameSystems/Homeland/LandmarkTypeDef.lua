-----------------------------------------------------
--File Name    : LandmarkTypeDef.lua
--Author       : zhiyuan
--Create Time  : 2019-05-15
--Description  : 标志性建筑类型枚举
-----------------------------------------------------
local LandmarkTypeDef =
{
    COMMAND            = 1,           -- 指挥部
    SHIPYARD           = 2,           -- 船坞
    ARSENAL            = 3,           -- 军火库
    WEAPON_WORKSHOP    = 4,           -- 武器工坊
    EQUIPMENT_WORKSHOP = 5,           -- 装备工坊
    WAREHOUSE          = 6,           -- 仓库
    TREASURE_SHOP      = 7,           -- 藏宝处
}
LandmarkTypeDef.MAX = 7

return LandmarkTypeDef
