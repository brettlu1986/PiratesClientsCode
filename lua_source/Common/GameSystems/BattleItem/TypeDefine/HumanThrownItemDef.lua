-----------------------------------------------------
--File Name    : HumanThrownItemDef.lua
--Author       : WuJizhou
--Create Time  : 9/17/2018, 2:49:31 PM
--Description  : HumanThrownItemDef
-----------------------------------------------------
local HumanThrownItemDef = {}

HumanThrownItemDef.ItemCategory = {
    Hit              = 1,      --一次性命中类，飞刀
    Explosive        = 2,      --一次性爆炸类，手雷
    RangedBuff       = 3,      --范围buff类，燃烧弹
    VisibleEffect    = 4       --单纯视觉效果类，烟雾
}



HumanThrownItemDef.ExplodeType = {
    Inexplosive     = 1,      --不爆炸
    Timer           = 2,      --定时
    Collision       = 3,      --首次碰撞
    MoveFinished    = 4       --运动停止
}

return HumanThrownItemDef