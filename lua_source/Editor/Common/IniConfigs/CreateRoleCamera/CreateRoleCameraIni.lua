--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
--]]

local CreateRoleCameraIni = {}
CreateRoleCameraIni.szFileName = "client/createrole/create_role_camera.ini"

function CreateRoleCameraIni:OnParse(Parser)
    local tbCreateRoleConfig = { }
    tbCreateRoleConfig.nMaxYawOffset = Parser:Get("create_role_camera", "max_yaw"        , -1, Parser.TypeNumber)
    tbCreateRoleConfig.nMinYawOffset = Parser:Get("create_role_camera", "min_yaw"        , -1, Parser.TypeNumber)
    tbCreateRoleConfig.nMaxPitchOffset = Parser:Get("create_role_camera", "max_pitch"    , -1, Parser.TypeNumber)
    tbCreateRoleConfig.nMinPitchOffset = Parser:Get("create_role_camera", "min_pitch"    , -1, Parser.TypeNumber)
    tbCreateRoleConfig.nMinArmLength = Parser:Get("create_role_camera", "min_arm_length"   , -1, Parser.TypeNumber)
    tbCreateRoleConfig.fZoomTime = Parser:Get("create_role_camera", "zoom_duration"        , 0.5, Parser.TypeNumber)
    tbCreateRoleConfig.nMaxLightShadowDistance = Parser:Get("create_role_camera", "max_light_shadow_distance"   , -1, Parser.TypeNumber)
    tbCreateRoleConfig.nMinLightShadowDistance = Parser:Get("create_role_camera", "min_light_shadow_distance"   , -1, Parser.TypeNumber)

    self.tbCreateRole = tbCreateRoleConfig

    local tbSelectRoleConfig = { }
    tbSelectRoleConfig.nMaxYawOffset = Parser:Get("select_role_camera", "max_yaw"        , -1, Parser.TypeNumber)
    tbSelectRoleConfig.nMinYawOffset = Parser:Get("select_role_camera", "min_yaw"        , -1, Parser.TypeNumber)
    tbSelectRoleConfig.nMaxPitchOffset = Parser:Get("select_role_camera", "max_pitch"    , -1, Parser.TypeNumber)
    tbSelectRoleConfig.nMinPitchOffset = Parser:Get("select_role_camera", "min_pitch"    , -1, Parser.TypeNumber)
    tbSelectRoleConfig.nMinArmLength = Parser:Get("select_role_camera", "min_arm_length"   , -1, Parser.TypeNumber)
    tbSelectRoleConfig.fZoomTime = Parser:Get("select_role_camera", "zoom_duration"        , 0.5, Parser.TypeNumber)
    tbSelectRoleConfig.nMaxLightShadowDistance = Parser:Get("select_role_camera", "max_light_shadow_distance"   , -1, Parser.TypeNumber)
    tbSelectRoleConfig.nMinLightShadowDistance = Parser:Get("select_role_camera", "min_light_shadow_distance"   , -1, Parser.TypeNumber)

    self.tbSelectRole = tbSelectRoleConfig

end

return CreateRoleCameraIni
