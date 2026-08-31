-----------------------------------------------------
--File Name    : BattleAdditionalSuccessResultDef.lua
--Author       : LiHui
--Create Time  : 
--Description  : 额外胜利结果枚举
-----------------------------------------------------

local BattleAdditionalSuccessResultDef =
{
    EXIT_BATTLE                               = 0,        -- 逃出生天
    FIGHTING                                  = 1,        -- 继续战斗
    REMAIN_COUNT_NOT_ENOUGH                   = 2,        -- 额外胜利名额不够
    WANT_EXIT_BUT_COUNT_NOT_ENOUGH            = 3,        -- 想逃出但是名额没有了
}

return BattleAdditionalSuccessResultDef