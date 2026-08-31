--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local CameraIni = {}
CameraIni.szFileName = "client/camera/camera.ini"

function CameraIni:OnParse(Parser)
    local tbWinCameraConfig = { }
    tbWinCameraConfig.nHumanArmLen = Parser:Get("win_camera", "human_arm_length"        , 0, Parser.TypeNumber)
    tbWinCameraConfig.nHumanArmYaw = Parser:Get("win_camera", "human_arm_yaw"           , 0, Parser.TypeNumber)
    tbWinCameraConfig.nHumanArmPitch = Parser:Get("win_camera", "human_arm_pitch"       , 0, Parser.TypeNumber)

    tbWinCameraConfig.nShipArmLen = Parser:Get("win_camera", "ship_arm_length"          , 0, Parser.TypeNumber)
    tbWinCameraConfig.nShipArmYaw = Parser:Get("win_camera", "ship_arm_yaw"             , 0, Parser.TypeNumber)
    tbWinCameraConfig.nShipArmPitch = Parser:Get("win_camera", "ship_arm_pitch"         , 0, Parser.TypeNumber)

    self.tbWinCameraConfig = tbWinCameraConfig

    local tbCarronadeActiveCamera = {}
    tbCarronadeActiveCamera.nOffsetForward = Parser:Get("carronade_active_camera", "offset_forward"  , 0, Parser.TypeNumber)
    tbCarronadeActiveCamera.nOffsetUp = Parser:Get("carronade_active_camera", "offset_up"            , 0, Parser.TypeNumber)
    tbCarronadeActiveCamera.nMoveTime = Parser:Get("carronade_active_camera", "move_time"            , 0, Parser.TypeNumber)
    
    self.tbCarronadeActiveCamera = tbCarronadeActiveCamera

    self.nOnHorseTime = Parser:Get("vehicle_camera", "on_horse_time"  , 0, Parser.TypeNumber)
    self.nDownHorseTime = Parser:Get("vehicle_camera", "down_horse_time"  , 0, Parser.TypeNumber)
    self.nFollowInterp = Parser:Get("vehicle_camera", "follow_interp"  , 0, Parser.TypeNumber)
    self.nActiveMinYaw = Parser:Get("vehicle_camera", "active_min_yaw"  , 0, Parser.TypeNumber)
    self.nFollowStartSpeed = Parser:Get("vehicle_camera", "follow_start_speed"  , 0, Parser.TypeNumber)
    self.nFollowTriggerTime = Parser:Get("vehicle_camera", "follow_trigger_time"  , 0, Parser.TypeNumber)
    
    self.nMinSphereSize = Parser:Get("aim_assist", "aim_sphere_min_radius"  , 0, Parser.TypeNumber)
    self.nMaxSphereSize = Parser:Get("aim_assist", "aim_sphere_max_radius"  , 0, Parser.TypeNumber)
    
    self.nTrackMaxPercent = Parser:Get("aim_assist", "track_assist_max_percent"  , 0, Parser.TypeNumber)
    self.nTrackMinDistance = Parser:Get("aim_assist", "track_assist_min_distance"  , 0, Parser.TypeNumber)

    self.bOpenRubAssist = Parser:Get("aim_assist", "open_rub_assist", true, Parser.TypeBool)
    self.bOpenTrackAssist = Parser:Get("aim_assist", "open_track_assist", true, Parser.TypeBool)
    self.bOpenFireAssist = Parser:Get("aim_assist", "open_fire_assist", true, Parser.TypeBool)

    self.nSpeelDuration = Parser:Get("camera_lag", "speel_lag_duration"  , 0, Parser.TypeNumber)
    self.nSpeelLagSpeed = Parser:Get("camera_lag", "speel_lag_speed"  , 0, Parser.TypeNumber)
    self.nMeleeLagSpeed = Parser:Get("camera_lag", "melee_lag_speed"  , 0, Parser.TypeNumber)

    self.nHumanOceanFov = Parser:Get("camera_init_fov", "human_fov"  , 0, Parser.TypeNumber)
    self.nShipOceanFov = Parser:Get("camera_init_fov", "ship_fov"  , 0, Parser.TypeNumber)

    self.bGlideReset = Parser:Get("parachute_glide", "glide_camera_reset"  , true, Parser.TypeBool)
    self.nGlidePitch = Parser:Get("parachute_glide", "glide_camera_pitch"  , 0, Parser.TypeNumber)
    self.nGlideTriggerTime = Parser:Get("parachute_glide", "glide_camera_trigger_time"  , 0, Parser.TypeNumber)
    self.bGlideSpecalReset = Parser:Get("parachute_glide", "glide_special_reset"  , false, Parser.TypeBool)
    self.nGlideFollowInterp = Parser:Get("parachute_glide", "glide_follow_interp"  , 0, Parser.TypeNumber)

    
    self.szAimSocket = Parser:Get("aim_track", "player_aim_socket"  , 0, Parser.TypeString)
    self.nTrackSpeed = Parser:Get("aim_track", "aim_track_speed"  , 0, Parser.TypeNumber)
    self.nDelayBeginTime = Parser:Get("aim_track", "delay_begin_time"  , 0, Parser.TypeNumber)
    self.nDelayTraceOnceTime = Parser:Get("aim_track", "delay_trace_once_time"  , 0, Parser.TypeNumber)

    self.nShipAimArmLen = Parser:Get("aim", "ship_aim_arm_len"  , 0, Parser.TypeNumber)

    self.nWandFocusTimes = Parser:Get("wand_focus", "wand_fucus_time"  , 0, Parser.TypeNumber)
    self.nWandFovRate = Parser:Get("wand_focus", "wand_fov_rate"  , 0, Parser.TypeNumber)
end

return CameraIni
