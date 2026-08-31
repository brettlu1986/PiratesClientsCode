-----------------------------------------------------
--File Name    : RelationDefine.lua
--Description  : Relation相关术语的定义
-----------------------------------------------------

local CampDef = {}

-- 阵营的类型
CampDef.Type = {
    CAMP_NONE = 0,
    CAMP_1 = 1,
    CAMP_2 = 2,
    CAMP_HOSTILE = 3,
    CAMP_NEUTRAL = 4,
    CAMP_ALLHOSTILE = 5,
    CAMP_6 = 6,
    CAMP_ENGLAND = 7,
    CAMP_SPAIN = 8,
    CAMP_PIRATE = 9,
}

-- 关系定义
CampDef.Relation = {
    RELATION_NEUTRAL = 0,    -- 中立关系
    RELATION_FRIEND = 1,    -- 好友关系
    RELATION_ENEMY  = 2,    -- 敌对关系
}


return CampDef
