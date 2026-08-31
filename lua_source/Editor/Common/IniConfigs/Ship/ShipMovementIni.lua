--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ShipMovementIni = {}
ShipMovementIni.szFileName = "common/ship/ship_movement.ini"

function ShipMovementIni:OnParse(Parser)
    local tbSyncParams = {}
    tbSyncParams.nClientMinSyncInterval = Parser:Get("synchronization_params", "client_min_sync_interval", 0, Parser.TypeNumber)
    tbSyncParams.nClientMaxSyncInterval = Parser:Get("synchronization_params", "client_max_sync_interval", 0, Parser.TypeNumber)
    tbSyncParams.nServerMaxSyncInterval = Parser:Get("synchronization_params", "server_max_sync_interval", 0, Parser.TypeNumber)
    tbSyncParams.nMaxSimTimeDiff = Parser:Get("synchronization_params", "max_sim_time_diff", 0, Parser.TypeNumber)
    tbSyncParams.nClientMaxLerpTime = Parser:Get("synchronization_params", "client_max_lerp_time", 0, Parser.TypeNumber)
    self.tbSyncParams = tbSyncParams

    local tbCollisionParams = {}
    tbCollisionParams.nSweepPullBackDistance = Parser:Get("collision_params", "sweep_pull_back_distance", 0, Parser.TypeNumber)
    tbCollisionParams.nMinAdjustDistanceForPenetration = Parser:Get("collision_params", "min_adjust_distance_for_penetration", 0, Parser.TypeNumber)
    tbCollisionParams.nMaxAdjustStepsForPenetration = Parser:Get("collision_params", "max_adjust_steps_for_penetration", 0, Parser.TypeNumber)
    tbCollisionParams.nMinSlideSpeedFactor = Parser:Get("collision_params", "min_slide_speed_factor", 0, Parser.TypeNumber)
    tbCollisionParams.nMaxImpactResolveTime = Parser:Get("collision_params", "max_impact_resolve_time", 0, Parser.TypeNumber)
    tbCollisionParams.nImpactMiddleAreaAngle = Parser:Get("collision_params", "impact_middle_area_angle", 0, Parser.TypeNumber)
    self.tbCollisionParams = tbCollisionParams

    local tbMisc = {}
    tbMisc.nReturnToBasicGearLinearDecelerationMultiplier = Parser:Get("misc", "return_to_basic_gear_linear_deceleration_multiplier", 1, Parser.TypeNumber)
    tbMisc.nReturnToBasicGearAngularDecelerationMultiplier = Parser:Get("misc", "return_to_basic_gear_angular_deceleration_multiplier", 1, Parser.TypeNumber)
    self.tbMisc = tbMisc

    local tbMovementParams = {}
    tbMovementParams.nSafeTeleportDistance = Parser:Get("movement_params", "safe_teleprot_distance", 0, Parser.TypeNumber)
    self.tbMovementParams = tbMovementParams
end

return ShipMovementIni
