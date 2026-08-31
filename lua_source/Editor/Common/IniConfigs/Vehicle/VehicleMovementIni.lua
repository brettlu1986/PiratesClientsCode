--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local VehicleMovementIni = {}
VehicleMovementIni.szFileName = "common/ffa/vehicle/vehicle_movement.ini"
VehicleMovementIni.tbDefaultFallParams = nil
VehicleMovementIni.tbCrisisMonitorConfig = nil

function VehicleMovementIni:OnParse(Parser)
    local tbFallParams = {}
    tbFallParams.nAirDragCoefficient = Parser:Get("fall_params", "air_drag_coefficient", -1, Parser.TypeNumber)
    tbFallParams.nLateralAcceleration = Parser:Get("fall_params", "lateral_acceleration", -1, Parser.TypeNumber)
    tbFallParams.nLandStunTime = Parser:Get("fall_params", "land_stun_time", -1, Parser.TypeNumber)
    tbFallParams.nLandStunSpeedPreservation = Parser:Get("fall_params", "land_stun_speed_preservation", -1, Parser.TypeNumber)
    tbFallParams.nJumpLateralSpeedRatio = Parser:Get("fall_params", "jump_lateral_speed_ratio", -1, Parser.TypeNumber)
    tbFallParams.nJumpZVelocity = Parser:Get("fall_params", "jump_z_velocity", -1, Parser.TypeNumber)
    tbFallParams.nCustomGravityScale = Parser:Get("fall_params", "custom_gravity_scale", -1, Parser.TypeNumber)
    tbFallParams.nJumpableBlockDistance = Parser:Get("fall_params", "jumpable_block_distance", -1, Parser.TypeNumber)
    tbFallParams.nJumpableBlockHeight = Parser:Get("fall_params", "jumpable_block_height", -1, Parser.TypeNumber)
    tbFallParams.nJumpableMinSpeed = Parser:Get("fall_params", "jumpable_min_speed", -1, Parser.TypeNumber)
    self.tbDefaultFallParams = tbFallParams

    local tbCrisisMonitorConfig = {}
    tbCrisisMonitorConfig.nSpeed = Parser:Get("crisis_monitor_config", "crisis_trigger_speed", -1, Parser.TypeNumber)
    tbCrisisMonitorConfig.nDistance = Parser:Get("crisis_monitor_config", "crisis_trigger_distance", -1, Parser.TypeNumber)
    tbCrisisMonitorConfig.nHeight = Parser:Get("crisis_monitor_config", "crisis_trigger_height", -1, Parser.TypeNumber)
    tbCrisisMonitorConfig.nCDTime = Parser:Get("crisis_monitor_config", "crisis_monitor_cd_time", 0, Parser.TypeNumber)
    self.tbCrisisMonitorConfig = tbCrisisMonitorConfig

end

return VehicleMovementIni
