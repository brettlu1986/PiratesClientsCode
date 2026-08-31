local GameCameraModeDef = {}

GameCameraModeDef.ModeChangeTarget  = 1 
GameCameraModeDef.ModeHandleMove    = 1 << 1
GameCameraModeDef.ModeOffsetMove    = 1 << 2
GameCameraModeDef.ModeShake         = 1 << 3
GameCameraModeDef.ModeFov           = 1 << 4
GameCameraModeDef.ModeArmLen        = 1 << 5
GameCameraModeDef.ModeSyncArmRot    = 1 << 6  --观战同步摇臂的旋转
GameCameraModeDef.ModeArmRot        = 1 << 7  
GameCameraModeDef.ModeCameraTrack   = 1 << 8  --camera track to location

local Def = GameCameraModeDef

GameCameraModeDef.ModeParamKey = 
{
    [Def.ModeChangeTarget] = "ModeChangeTargetParam",
    [Def.ModeHandleMove]   = "ModeHandleMoveParam",
    [Def.ModeOffsetMove]   = "ModeOffsetMoveParam",
    [Def.ModeShake]        = "ModeShakeParam",
    [Def.ModeFov]          = "ModeFovParam",
    [Def.ModeArmLen]       = "ModeArmLenParam",
    [Def.ModeSyncArmRot]   = "ModeSyncArmRot",
    [Def.ModeArmRot]       = "ModeArmRot",
    [Def.ModeCameraTrack]  = "ModeCameraTrack",
}


return GameCameraModeDef