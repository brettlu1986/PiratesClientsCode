
local InteractionDef = {}

InteractionDef.InteractionMode = {
    HEAD_PORTRAIT_DIALOG = 1,   -- 有头像气泡
    HEAD_TOP_DIALOG = 2,        -- 无头像气泡
    UI_NO_PORTRAIT = 3,         -- 无半身像
    UI_PORTRAIT = 4,            -- 有半身像    
    SPECIAL_CAMERA = 5,         -- 特殊镜头    
    MATINEE = 6,                -- 动画
    EXPLORE = 7,                -- 采集
    UI_BATTLE_PORTRAIT = 8,     -- 战斗中对话
    CHANGE_DISPLAY = 14         -- 船変人，人変船
}

--无需读条的交互类型
InteractionDef.tbQuickInterationTypeList = {0, 1, 3, 4, 5}

return InteractionDef