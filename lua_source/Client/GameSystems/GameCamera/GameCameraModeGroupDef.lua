local GameCameraModeGroupDef = {}

GameCameraModeGroupDef.HumanNormal                  = 1        -- 正常切人的状态
GameCameraModeGroupDef.ShipNormal                   = 2        -- 正常切船的状态

GameCameraModeGroupDef.HumanFreeView                = 6        -- 小眼睛
GameCameraModeGroupDef.HumanAiming                  = 7        -- 人瞄准
GameCameraModeGroupDef.ShipAiming                   = 8        -- 船瞄准

GameCameraModeGroupDef.ViewDeadBoxHuman             = 9       --顶视角观看 死亡成盒的盒子 人
GameCameraModeGroupDef.ViewDeadBoxShip              = 10       --顶视角观看 死亡成盒的盒子 人
GameCameraModeGroupDef.ViewShipKiller               = 11       --正面观察船击杀者
GameCameraModeGroupDef.ViewHumanKiller              = 12       --正面观察人击杀者

GameCameraModeGroupDef.BotHuman                     = 13       --用于GM切换HumanBot视角用
GameCameraModeGroupDef.BotShip                      = 14       --用于GM切换ShipBot视角用

GameCameraModeGroupDef.ViewTeammateShip             = 15       --观战队友是船
GameCameraModeGroupDef.ViewTeammateHuman            = 16       --观战队友是人

GameCameraModeGroupDef.NewParachuteShipping         = 17       -- 新跳伞上运输船，远距离看向甲板
GameCameraModeGroupDef.NewParachuteLaunchFocus      = 18       -- 人发射聚焦，看发射特效要用，这个时候已经发射了
GameCameraModeGroupDef.NewParachuteLaunchPlayer     = 19       -- 发射过程，到达最高点之前
GameCameraModeGroupDef.NewParachuteTopPoint         = 20       -- 到达高点
GameCameraModeGroupDef.NewParachuteOpenParachute    = 21       -- 开伞

GameCameraModeGroupDef.HumanSwimming                = 22       -- 人游泳
GameCameraModeGroupDef.VehicleView                  = 23       -- 载具
GameCameraModeGroupDef.BuildingView                 = 24       -- 家园建筑物

GameCameraModeGroupDef.HumanState = 
{
    Normal = 1,
    WatchBattle = 2,
    Swim = 3,
    WatchSwim = 4,
}

--用于新的逻辑整理
GameCameraModeGroupDef.LogicDef = 
{
    CL_CARRONADE            = 1,
    CL_GAME_PLAYER          = 2,
    CL_AIMING               = 3,
    CL_MOVEMENT             = 4,
    CL_WATCHBATTLE          = 5,
    CL_COMMON_SETTING       = 6,
}

GameCameraModeGroupDef.SettingValueType = 
{
    Mini    = 1, --用于标识 最低值 但不作为设置界面的设置选项
    Min     = 2,
    Mid     = 3, 
    Max     = 4, 
    Custom  = 5,
}

GameCameraModeGroupDef.SettingTargetType =
{
    Parachute       = 1,
    HumanNotAim     = 2,
    HumanAim        = 3,
    ShipNotAim      = 4,
    ShimAim2        = 5, 
    ShipAim4        = 6,
    ShipAim8        = 7,
}

GameCameraModeGroupDef.WatchBattleDef = 
{
    ChangeAim = 1,
    ChangeMovement = 2,
    ChangeVehicle = 3,
    ChangeSwimState = 4,
}

return GameCameraModeGroupDef