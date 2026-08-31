--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]
local StringUtil = require("StringUtil")

local DungeonIni = {}
DungeonIni.szFileName = "common/dungeon/dungeon.ini"

function DungeonIni:OnParse(Parser)
    local tbDungeon = {}
    tbDungeon.nGameStartTimeout                 = Parser:Get("dungeon"      , "game_start_timeout"                      , -1    , Parser.TypeNumber)
    self.tbDungeon = tbDungeon

    local tbCheaterCheck = {}
    tbCheaterCheck.nMinCheckInterval            = Parser:Get("cheater_check", "min_check_interval"                      , 8     , Parser.TypeNumber)
    tbCheaterCheck.nMaxCheckInterval            = Parser:Get("cheater_check", "max_check_interval"                      , 15    , Parser.TypeNumber)
    tbCheaterCheck.nTolerantCheckInterval       = Parser:Get("cheater_check", "tolerant_check_interval"                 , 1     , Parser.TypeNumber)
    tbCheaterCheck.nCheckCountLimit             = Parser:Get("cheater_check", "check_count_limit"                       , 3     , Parser.TypeNumber)
    self.tbCheaterCheck = tbCheaterCheck

    local tbUIConfig = {}
    tbUIConfig.nSendCommandInterval             = Parser:Get("ui_config"    , "send_command_interval"                   , -1    , Parser.TypeNumber)
    tbUIConfig.nDisplayCommandInterval          = Parser:Get("ui_config"    , "display_command_interval"                , -1    , Parser.TypeNumber)
    tbUIConfig.nDropInfoDelay                   = Parser:Get("ui_config"    , "drop_info_delay"                         , -1    , Parser.TypeNumber)
    tbUIConfig.tbDamageToLevelType              = Parser:Get("ui_config"    , "damage_to_level_type"                    , {}    , Parser.TypeNumber)
    tbUIConfig.nStopGearPercent                 = Parser:Get("ui_config"    , "stop_gear_percent"                       , 1     , Parser.TypeNumber)
    tbUIConfig.nStopSteerPercent                = Parser:Get("ui_config"    , "stop_steer_percent"                      , 1     , Parser.TypeNumber)
    tbUIConfig.nFullSpeedPercent                = Parser:Get("ui_config"    , "full_speed_percent"                      , 1     , Parser.TypeNumber)
    tbUIConfig.nFullSteerPercent                = Parser:Get("ui_config"    , "full_steer_percent"                      , 1     , Parser.TypeNumber)
    tbUIConfig.nMountainCheckDistance           = Parser:Get("ui_config"    , "mountain_check_distance"                 , 20000 , Parser.TypeNumber)
    tbUIConfig.nMountainCheckInterval           = Parser:Get("ui_config"    , "mountain_check_1nterval"                 , 1     , Parser.TypeNumber)
 -- tbUIConfig.tbHpLevelPercents                = Parser:Get("ui_config"    , "hp_level_percent"                        , {}    , Parser.TypeNumber)
 -- tbUIConfig.tbHpLevelBgOpacities             = Parser:Get("ui_config"    , "hp_level_bg_opacity"                     , {}    , Parser.TypeNumber)
 -- tbUIConfig.tbHpLevelColors                  = Parser:Get("ui_config"    , "hp_level_color"                          , {}    , Parser.TypeString)
 -- tbUIConfig.nDyingHpBgOpacity                = Parser:Get("ui_config"    , "dying_hp_bg_opacity"                     , 1     , Parser.TypeNumber)
 -- tbUIConfig.szDyingHpColor                   = Parser:Get("ui_config"    , "dying_hp_color"                          , nil   , Parser.TypeString)
    self.tbUIConfig = tbUIConfig

    local tbAbility = {}
    tbAbility.nGlobalCDTime                     = Parser:Get("ability"      , "global_cd_time"                          , 1.5   , Parser.TypeNumber)
    self.tbAbility = tbAbility

    local tbFFA = {}
    tbFFA.nHumanDamageRatioFromShip             = Parser:Get("ffa"          , "human_damage_ratio_from_ship"            , 0.1   , Parser.TypeNumber)
    tbFFA.nShipDamageRatioFromHuman             = Parser:Get("ffa"          , "ship_damage_ratio_from_human"            , 10    , Parser.TypeNumber)
    tbFFA.nShipMaxVisibleDistance               = Parser:Get("ffa"          , "ship_max_visible_distance"               , 1200  , Parser.TypeNumber) * 100
    tbFFA.nShipExitFightingStateTime            = Parser:Get("ffa"          , "ship_exit_fighting_state_time"           , 10    , Parser.TypeNumber)
    tbFFA.nDiamondRefreshTimeOnMap              = Parser:Get("ffa"          , "diamond_refresh_time_on_map"             , 300   , Parser.TypeNumber)
    tbFFA.nBGMId                                = Parser:Get("ffa"          , "bgm_id"                                  , 0     , Parser.TypeNumber)
    self.tbFFA = tbFFA

    local tbDying = {}
    tbDying.bIgnorePoisonDamageWhenBeRescued    = Parser:Get("dying"        , "ignore_poison_damage_when_be_rescued"    , false , Parser.TypeBool)
    tbDying.bEnableDualRescueTimeReduction      = Parser:Get("dying"        , "enable_dual_rescue_time_reduction"       , false , Parser.TypeBool)
    tbDying.nRescuingRangeForShip               = Parser:Get("dying"        , "rescuing_range_for_ship"                 , 5000  , Parser.TypeNumber)
    tbDying.nRescuingRangeForHuman              = Parser:Get("dying"        , "rescuing_range_for_human"                , 100   , Parser.TypeNumber)
    tbDying.nRescuingRangeRatioForShip          = Parser:Get("dying"        , "rescuing_range_ratio_for_ship"           , 1.2   , Parser.TypeNumber)
    tbDying.nRescuingRangeRatioForHuman         = Parser:Get("dying"        , "rescuing_range_ratio_for_human"          , 1.2   , Parser.TypeNumber)
    tbDying.nDyingPublishmentIntervalForShip    = Parser:Get("dying"        , "dying_publishment_interval_for_ship"     , 5     , Parser.TypeNumber)
    tbDying.nDyingPublishmentIntervalForHuman   = Parser:Get("dying"        , "dying_publishment_interval_for_human"    , 5     , Parser.TypeNumber)
    tbDying.nDyingPublishmentRatioForShip       = Parser:Get("dying"        , "dying_publishment_ratio_for_ship"        , 0.5   , Parser.TypeNumber)
    tbDying.nDyingPublishmentRatioForHuman      = Parser:Get("dying"        , "dying_publishment_ratio_for_human"       , 0.5   , Parser.TypeNumber)
    tbDying.nDyingReduceIntervalForShip         = Parser:Get("dying"        , "dying_reduce_interval_for_ship"          , 1.0   , Parser.TypeNumber)
    tbDying.nDyingReduceIntervalForHuman        = Parser:Get("dying"        , "dying_reduce_interval_for_human"         , 1.0   , Parser.TypeNumber)
    self.tbDying = tbDying

    local tbDead = {}
    tbDead.nShipDeadParticleResId               = Parser:Get("dead"         , "ship_dead_particle_res_id"               , -1    , Parser.TypeNumber)
    tbDead.nHumanDeadParticleResId              = Parser:Get("dead"         , "human_dead_particle_res_id"              , -1    , Parser.TypeNumber)
    tbDead.szShipDeadSoundRes                   = Parser:Get("dead"         , "ship_dead_sound_res"                     , nil   , Parser.TypeString)
    tbDead.nHideShipActorDelayTime              = Parser:Get("dead"         , "hide_ship_actor_delay_time"              , 0     , Parser.TypeNumber)
    tbDead.nHideHumanActorDelayTime             = Parser:Get("dead"         , "hide_human_actor_delay_time"             , 0     , Parser.TypeNumber)
    tbDead.nHideVehicleActorDelayTime           = Parser:Get("dead"         , "hide_vehicle_actor_delay_time"           , 0     , Parser.TypeNumber)
    tbDead.nCreateShipBoxDelayTime              = Parser:Get("dead"         , "create_ship_box_delay_time"              , 0     , Parser.TypeNumber)
    tbDead.nCreateHumanBoxDelayTime             = Parser:Get("dead"         , "create_human_box_delay_time"             , 0     , Parser.TypeNumber)
    tbDead.nCreateNpcBoxDelayTime               = Parser:Get("dead"         , "create_npc_box_delay_time"               , 0     , Parser.TypeNumber)
    self.tbDead = tbDead

    self.nTrainingCampDungeonId                 = Parser:Get("trainingcamp" , "dungeon_id"                              , 0     , Parser.TypeNumber)

    local tbShipWeapon = {}
    tbShipWeapon.bShipWeaponLoadingAfterBuilt           = Parser:Get("ship_weapon", "ship_weapon_loading_after_built"           , false , Parser.TypeBool)
    tbShipWeapon.bShipThrownItemTeammateDamageEnabled   = Parser:Get("ship_weapon", "ship_thrown_item_teammate_damge_enabled"   , false , Parser.TypeBool)
    tbShipWeapon.bTorpedoTriggerDebugEnabled            = Parser:Get("ship_weapon", "torpedo_trigger_debug_enabled"             , false , Parser.TypeBool)
    tbShipWeapon.bTorpedoTriggerByTorpedo               = Parser:Get("ship_weapon", "torpedo_trigger_by_torpedo"                , false , Parser.TypeBool)
    tbShipWeapon.bTorpedoTriggerByGrenade               = Parser:Get("ship_weapon", "torpedo_trigger_by_grenade"                , false , Parser.TypeBool)
    tbShipWeapon.bTorpedoTriggerByCarronade             = Parser:Get("ship_weapon", "torpedo_trigger_by_carronade"              , false , Parser.TypeBool)
    tbShipWeapon.bTorpedoTriggerByShipShot              = Parser:Get("ship_weapon", "torpedo_trigger_by_ship_shot"              , false , Parser.TypeBool)
    tbShipWeapon.bTorpedoTriggerByHumanShot             = Parser:Get("ship_weapon", "torpedo_trigger_by_human_shot"             , false , Parser.TypeBool)
    self.tbShipWeapon = tbShipWeapon

    local tbFFANoob = {}
    local szDungeonIds = Parser:Get("ffa_noob", "dungeon_id", "", Parser.TypeString)
    local tbDungeonIdStrs = StringUtil.Split(szDungeonIds, ",")
    local tbDungeonId = {}
    for i, v in ipairs(tbDungeonIdStrs) do
        table.insert(tbDungeonId, tonumber(v))
    end
    tbFFANoob.tbDungeonId = tbDungeonId
    tbFFANoob.nAreaId = Parser:Get("ffa_noob", "area_id", -1, Parser.TypeNumber)
    self.tbFFANoob = tbFFANoob
end

return DungeonIni
