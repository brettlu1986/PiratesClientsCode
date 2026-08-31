-----------------------------------------------------
--File Name    : UIStateDef.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : 状态类型定义
-----------------------------------------------------

local UIStateDef = {}

UIStateDef.StateName =
{
    UI_LOGIN_STATE = "UILoginState",
    UI_BATTLE_STATE = "UIBattleState",
    UI_CINEMATIC_STATE = "UICinematicState",
    UI_INTERACTION_STATE = "UIInteractionState",
    UI_MATINEE_STATE = "UIMatineeState",
    UI_TEMP_HIDE_STATE = "UITempHideState",
    UI_FFA_RESULT_STATE = "UIFFAResultState",
    UI_WATCH_BATTLE_STATE = "UIWatchBattleState",
    UI_HOMELAND_STATE = "UIHomelandState",
    UI_HOMELAND_BUILD_STATE = "UIHomelandBuildState",
    UI_EMPTY_STATE = "UIEmptyState",
    UI_BOT_WATCH_STATE = "UIBotWatchState",
    UI_LOBBY3D_STATE = "UILobby3DState",
}

UIStateDef.StateType =
{
    NORMAL = 1,
    CINEMATIC = 2,
}

return UIStateDef
