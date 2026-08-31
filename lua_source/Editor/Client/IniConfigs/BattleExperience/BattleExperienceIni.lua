--[[
    IniConfig类中必须有的成员变量与函数
    szFileName : 文件名，不包含路径
    Container: table
    OnParse： 解析函数，参数Parser
--]]

local BattleExperienceIni = {}
BattleExperienceIni.szFileName = "client/battle_experience/battle_experience.ini"

function BattleExperienceIni:OnParse(Parser)
    local tbSound = {}
    local tbSoundIds = {}
    local tbShake = {}
    local tbShakeIds = {}
    local tbPostProcess = {}
    local tbPostProcessIds = {}

    self.tbSound = tbSound
    self.tbSoundIds = tbSoundIds
    self.tbShake = tbShake
    self.tbShakeIds = tbShakeIds
    self.tbPostProcess = tbPostProcess
    self.tbPostProcessIds = tbPostProcessIds

    tbSound.bEnabled                            = Parser:Get("sound"            , "enabled"                         , false , Parser.TypeBool)
    tbSound.nPlayingDelayTime                   = Parser:Get("sound"            , "playing_delay_time"              , 0.1   , Parser.TypeNumber)
    tbSound.nRepeatHitCoreDuration              = Parser:Get("sound"            , "repeat_hit_core_duration"        , 5     , Parser.TypeNumber)
    tbSound.nRepeatHitCoreCount                 = Parser:Get("sound"            , "repeat_hit_core_count"           , 5     , Parser.TypeNumber)
    tbSoundIds.nHitCore                         = Parser:Get("sound_id"         , "hit_core"                        , -1    , Parser.TypeNumber)
    tbSoundIds.nRepeatHitCore                   = Parser:Get("sound_id"         , "repeat_hit_core"                 , -1    , Parser.TypeNumber)
    tbSoundIds.nEnemyDead                       = Parser:Get("sound_id"         , "enemy_dead"                      , -1    , Parser.TypeNumber)
    tbSoundIds.nEnemyInjury                     = Parser:Get("sound_id"         , "enemy_injury"                    , -1    , Parser.TypeNumber)
    tbSoundIds.nHumanChangeToShip               = Parser:Get("sound_id"         , "human_change_to_ship"            , -1    , Parser.TypeNumber)
    tbSoundIds.nEnterLowLevelHPShipSound        = Parser:Get("sound_id"         , "enter_low_level_hp_ship"         , -1    , Parser.TypeNumber)
    tbSoundIds.nEnterLowLevelHPMaleSound        = Parser:Get("sound_id"         , "enter_low_level_hp_human_male"   , -1    , Parser.TypeNumber)
    tbSoundIds.nEnterLowLevelHPFemaleSound      = Parser:Get("sound_id"         , "enter_low_level_hp_human_female" , -1    , Parser.TypeNumber)
    tbSoundIds.nLowLevelHPMaleSound             = Parser:Get("sound_id"         , "low_level_hp_human_male"         , -1    , Parser.TypeNumber)
    tbSoundIds.nLowLevelHPFemaleSound           = Parser:Get("sound_id"         , "low_level_hp_human_female"       , -1    , Parser.TypeNumber)
    tbShake.bEnabled                            = Parser:Get("shake"            , "enabled"                         , false , Parser.TypeBool)
    tbShakeIds.nBeHitCore                       = Parser:Get("shake_id"         , "be_hit_core"                     , -1    , Parser.TypeNumber)
    tbShakeIds.nFiringWithSaker                 = Parser:Get("shake_id"         , "firing_with_saker"               , -1    , Parser.TypeNumber)
    tbShakeIds.nFiringWithSnipeGun              = Parser:Get("shake_id"         , "firing_with_snipe_gun"           , -1    , Parser.TypeNumber)
    tbPostProcess.bEnabled                      = Parser:Get("post_process"     , "enabled"                         , false , Parser.TypeBool)
    tbPostProcess.nLowLevelHpPercent            = Parser:Get("post_process"     , "low_level_hp_Percent"            , 0.1   , Parser.TypeNumber)
    tbPostProcessIds.nBeHitCore                 = Parser:Get("post_process_id"  , "be_hit_core"                     , -1    , Parser.TypeNumber)
    tbPostProcessIds.nFiringWithSnipeGun        = Parser:Get("post_process_id"  , "firing_with_snipe_gun"           , -1    , Parser.TypeNumber)
    tbPostProcessIds.nFiringSprayWithSnipeGun   = Parser:Get("post_process_id"  , "firing_spray_with_snipe_gun"     , -1    , Parser.TypeNumber)
    tbPostProcessIds.nLowLevelHp                = Parser:Get("post_process_id"  , "low_level_hp"                    , -1    , Parser.TypeNumber)
end

return BattleExperienceIni
