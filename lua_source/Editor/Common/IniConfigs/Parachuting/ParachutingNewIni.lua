--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local ParachutingIni = {}
ParachutingIni.szFileName = "common/ffa/parachuting/parachutingnew.ini"

function ParachutingIni:OnParse(Parser)
    local tbReadyArea = {}
    tbReadyArea.nCoreAreaRadius = Parser:Get("ready_area", "core_area_radius", 0, Parser.TypeNumber)
    tbReadyArea.nAutoSelectionMaxRadius = Parser:Get("ready_area", "auto_selection_max_radius", 0, Parser.TypeNumber)
    tbReadyArea.nAutoSelectionMinRadius = Parser:Get("ready_area", "auto_selection_min_radius", 0, Parser.TypeNumber)
    tbReadyArea.nMapCellWidth = Parser:Get("ready_area", "map_cell_width", 0, Parser.TypeNumber)
    tbReadyArea.nMapCellHeight = Parser:Get("ready_area", "map_cell_height", 0, Parser.TypeNumber)
    if tbReadyArea.nMapCellWidth < 10000 or tbReadyArea.nMapCellHeight < 10000 then
        error(string.format("ParachutingIni map cell too small %d %d", tbReadyArea.nMapCellWidth, tbReadyArea.nMapCellHeight))
    end
    tbReadyArea.nBPDefaultCellCount = Parser:Get("ready_area", "bot_player_default_cell_count", 0, Parser.TypeNumber)
    if tbReadyArea.nBPDefaultCellCount <= 0 then
        tbReadyArea.nBPDefaultCellCount = 1
    end
    tbReadyArea.nMapCellHeight = Parser:Get("ready_area", "map_cell_height", 0, Parser.TypeNumber)
    tbReadyArea.bOtherSelectionPoint = Parser:Get("ready_area", "other_selection_point", false, Parser.TypeBool)
    tbReadyArea.bBotVirtualSelectionPoint = Parser:Get("ready_area", "bot_virtual_selection_point", false, Parser.TypeBool)
    self.tbReadyArea = tbReadyArea

    local tbTransport = {}
    tbTransport.nTransportTime = Parser:Get("transport", "transport_time", 0, Parser.TypeNumber)
    tbTransport.nTriggerTime = Parser:Get("transport", "trigger_time", 0, Parser.TypeNumber)
    if tbTransport.nTransportTime == 0 then
        error("ParachutingIni transport time is 0")
    end
    self.tbTransport = tbTransport

    local tbLaunch = {}
    tbLaunch.nBotTime = Parser:Get("launch", "bot_time", 1, Parser.TypeNumber)
    tbLaunch.nLaunchHeight = Parser:Get("launch", "launch_height", -1, Parser.TypeNumber)
    tbLaunch.nOperateHeight = Parser:Get("launch", "operate_height", -1, Parser.TypeNumber)
    tbLaunch.nOpenParachuteMaxHeight = Parser:Get("launch", "open_parachute_max_height", -1, Parser.TypeNumber)
    tbLaunch.nOpenParachuteMinHeight = Parser:Get("launch", "open_parachute_min_height", -1, Parser.TypeNumber)
    tbLaunch.nLaunchTime = Parser:Get("launch", "launch_time", -1, Parser.TypeNumber)
    tbLaunch.nPreTopHeight = Parser:Get("launch", "pre_top_height", -1, Parser.TypeNumber)
    tbLaunch.nPreOpenParachuteHeight = Parser:Get("launch", "pre_open_parachute_height", -1, Parser.TypeNumber)
    tbLaunch.nMaxLandHeight = Parser:Get("launch", "max_land_height", -1, Parser.TypeNumber)
    self.tbLaunch = tbLaunch

    local tbNewTarget = {}
    local nSameTimeLaunch = Parser:Get("newtarget", "is_sametime_launch", -1, Parser.TypeNumber)
    tbNewTarget.IsSameTimeLaunch = nSameTimeLaunch > 0 
    tbNewTarget.nTargetDistance = Parser:Get("newtarget", "target_distance", -1, Parser.TypeNumber)
    self.tbNewTarget = tbNewTarget
    
    local tbParachuteNoOpen = {}
    tbParachuteNoOpen.nNormalFallSpeed = Parser:Get("parachute_noopen", "normal_fall_speed", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nMaxFallSpeed = Parser:Get("parachute_noopen", "max_fall_speed", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nMinFallSpeed = Parser:Get("parachute_noopen", "min_fall_speed", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nAcceleration = Parser:Get("parachute_noopen", "acceleration", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nTranslationSpeed = Parser:Get("parachute_noopen", "translation_speed", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nTranslationAcceleration = Parser:Get("parachute_noopen", "translation_acceleration", -1, Parser.TypeNumber)
    tbNewTarget.nDefaultTranslationSpeed = Parser:Get("parachute_noopen", "translation_speed", -1, Parser.TypeNumber)

    -- tbParachuteNoOpen.nRockerM = Parser:Get("parachute_noopen", "rocker_m", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nFallDecaySpeed = Parser:Get("parachute_noopen", "fall_decay_speed", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nTranslationDecaySpeed = Parser:Get("parachute_noopen", "translation_decay_speed", -1, Parser.TypeNumber)    
    tbParachuteNoOpen.nDegree = Parser:Get("parachute_noopen", "degree", -1, Parser.TypeNumber)
    tbParachuteNoOpen.nNoOperateFallSpeed = Parser:Get("parachute_noopen", "no_operate_fall_speed", -1, Parser.TypeNumber)    
    tbParachuteNoOpen.nNoOperateTranslationSpeed = Parser:Get("parachute_noopen", "no_operate_translation_speed", -1, Parser.TypeNumber)
    self.tbParachuteNoOpen = tbParachuteNoOpen

    local tbParachuteOpen = {}
    tbParachuteOpen.bHad = tbLaunch.nOpenParachuteMinHeight > 0
    tbParachuteOpen.nTranslationMaxAngleSpeed = Parser:Get("parachute_open", "translation_max_angle_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nTranslationMinAngleSpeed = Parser:Get("parachute_open", "translation_min_angle_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nTranslationNormalSpeed = Parser:Get("parachute_open", "translation_normal_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nTranslationMaxSpeed = Parser:Get("parachute_open", "translation_max_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nTranslationMinSpeed = Parser:Get("parachute_open", "translation_min_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nNormalFallSpeed = Parser:Get("parachute_open", "normal_fall_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nFrontFallSpeed = Parser:Get("parachute_open", "front_fall_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nBackFallSpeed = Parser:Get("parachute_open", "back_fall_speed", -1, Parser.TypeNumber)
    tbParachuteOpen.nFrontFallDecay = Parser:Get("parachute_open", "front_fall_decay", -1, Parser.TypeNumber)
    tbParachuteOpen.nBackFallDecay = Parser:Get("parachute_open", "back_fall_decay", -1, Parser.TypeNumber)
    tbParachuteOpen.nAcceleration = Parser:Get("parachute_open", "acceleration", -1, Parser.TypeNumber)    
    tbParachuteOpen.nTranslationAcceleration = Parser:Get("parachute_open", "translation_acceleration", -1, Parser.TypeNumber)
    tbParachuteOpen.nForwardAngle = Parser:Get("parachute_open", "forward_angle", -1, Parser.TypeNumber)
    tbParachuteOpen.nNoOperateFallSpeed = Parser:Get("parachute_open", "no_operate_fall_speed", -1, Parser.TypeNumber)    
    tbParachuteOpen.nNoOperateTranslationSpeed = Parser:Get("parachute_open", "no_operate_translation_speed", -1, Parser.TypeNumber)
    
    tbParachuteOpen.nRemoveParachuteHeight = Parser:Get("parachute_open", "remove_parachute_height", -1, Parser.TypeNumber)
    tbParachuteOpen.nPlayDropAniHeight = Parser:Get("parachute_open", "play_drop_ani_height", -1, Parser.TypeNumber)
    tbParachuteOpen.nRotationRate = Parser:Get("parachute_open", "rotation_rate", -1, Parser.TypeNumber)
    tbParachuteOpen.nDropRollAniTranslationSpeed = Parser:Get("parachute_open", "drop_roll_ani_translation_speed", -1, Parser.TypeNumber)
    self.tbParachuteOpen = tbParachuteOpen   

    local tbRelevantDistance = {}
    tbRelevantDistance.nInAirDistance = Parser:Get("relevant_distance", "inair_distance", -1, Parser.TypeNumber)
    self.tbRelevantDistance = tbRelevantDistance

    local tbRedarMap = {}
    tbRedarMap.nTranslationSpeed = Parser:Get("redar_map", "translation_speed", -1, Parser.TypeNumber)
    self.tbRedarMap = tbRedarMap
end

return ParachutingIni
