-----------------------------------------------------
--File Name    : ShipWeaponFiringFailedDef.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-18
--Description  : 舰船武器开火失败
-----------------------------------------------------
return {
    IN_FIRING_CD        = 1,    -- 开火CD中
    BULLET_EMPTY        = 2,    -- 已装填子弹不足
    MANUAL_LOADING      = 3,    -- 手动装弹中
    PLAYER_IN_DYING     = 4,    -- 玩家处于重伤状态
    IN_FIRING           = 5,    -- 开火中
    NOT_IN_FIRING       = 6,    -- 没有在开火中
    INVALID_OPERATION   = 7,    -- 操作无效
}