--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local HumanMovementIni = {}
HumanMovementIni.szFileName = "common/human/human_movement.ini"

function HumanMovementIni:OnParse(Parser)
    local tbMovementParams = {}
    tbMovementParams.nMaxWalkSpeed = Parser:Get("movement_params", "max_walk_speed", -1, Parser.TypeNumber)
    tbMovementParams.nSafeTelePortMinDistance = Parser:Get("movement_params", "safe_teleprot_min_distance", -1, Parser.TypeNumber)
    tbMovementParams.nSafeTelePortMaxDistance = Parser:Get("movement_params", "safe_teleprot_max_distance", -1, Parser.TypeNumber)
    self.tbMovementParams = tbMovementParams

    local tbFallParams = {}
    tbFallParams.nAirDragCoefficient = Parser:Get("fall_params", "air_drag_coefficient", -1, Parser.TypeNumber)
    tbFallParams.nLateralAcceleration = Parser:Get("fall_params", "lateral_acceleration", -1, Parser.TypeNumber)
    tbFallParams.nDefaultOriginSpeed = Parser:Get("fall_params", "default_origin_speed", -1, Parser.TypeNumber)
    tbFallParams.nLandStunTime = Parser:Get("fall_params", "land_stun_time", -1, Parser.TypeNumber)
    tbFallParams.nLandStunSpeedPreservation = Parser:Get("fall_params", "land_stun_speed_preservation", -1, Parser.TypeNumber)
    tbFallParams.nJumpLateralSpeedRatio = Parser:Get("fall_params", "jump_lateral_speed_ratio", -1, Parser.TypeNumber)
    tbFallParams.nJumpZVelocity = Parser:Get("fall_params", "jump_z_velocity", -1, Parser.TypeNumber)
    tbFallParams.nCustomGravityScale = Parser:Get("fall_params", "custom_gravity_scale", -1, Parser.TypeNumber)
    self.tbDefaultFallParams = tbFallParams
end

return HumanMovementIni
