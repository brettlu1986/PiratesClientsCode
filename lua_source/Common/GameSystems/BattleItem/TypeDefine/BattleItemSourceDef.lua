-----------------------------------------------------
--File Name    : BattleItemSourceDef.lua
--Author       : zhiyuan
--Create Time  : 2019-12-02
--Description  : 道具来源
-----------------------------------------------------

local BattleItemSourceDef = {
    INIT                 = 1,        -- 初始道具
    BUILD                = 2,        -- 建造
    PICK_UP              = 3,        -- 拾取
    GM                   = 4,        -- GM指令
    CHANG_POS            = 5,        -- 只是换位置，不是新增道具
    UNLIMITED_BULLETS    = 6,        -- 无限弹药
    WEAPON_INIT_BULLETS  = 7,        -- 武器初始弹药
    DEFAULT_WEAPON       = 8,        -- 恢复默认船武器
    CHANGE_TO_HUMAN      = 9,        -- 船变人
    OTHER                = 10,       -- 其他途径
}

return BattleItemSourceDef