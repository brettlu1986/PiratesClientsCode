local ShipDataDisplayIni = {}
ShipDataDisplayIni.szFileName = "client/ui/ship_data_display.ini"

function ShipDataDisplayIni:OnParse(Parser)
    local tbCommon = {}
    local tbVitality = {}
    local tbMovement = {}
    local tbHeadFirePower = {}
    local tbSideFirePower = {}
    local tbDeckFirePower = {}
    local tbVisibility = {}
    local tbFinalScore = {}

    self.tbCommon = tbCommon
    self.tbVitality = tbVitality
    self.tbMovement = tbMovement
    self.tbHeadFirePower = tbHeadFirePower
    self.tbSideFirePower = tbSideFirePower
    self.tbDeckFirePower = tbDeckFirePower
    self.tbVisibility = tbVisibility
    self.tbFinalScore = tbFinalScore

    tbCommon.nBaseCarronadeFiringRoundCount             = Parser:Get("common"           , "base_carronade_firing_round_count"   , 0 , Parser.TypeNumber)

    tbVitality.nFirstPartParam                          = Parser:Get("vitality"         , "first_part_param"                    , 0 , Parser.TypeNumber)
    tbVitality.nSecondPartParam                         = Parser:Get("vitality"         , "second_part_param"                   , 0 , Parser.TypeNumber)
    tbVitality.nThirdPartParam                          = Parser:Get("vitality"         , "third_part_param"                    , 0 , Parser.TypeNumber)
    tbVitality.nSecondPartHeadDamageWeight              = Parser:Get("vitality"         , "second_part_head_damage_weight"      , 0 , Parser.TypeNumber)
    tbVitality.nSecondPartSideDamageWeight              = Parser:Get("vitality"         , "second_part_side_damage_weight"      , 0 , Parser.TypeNumber)
    tbVitality.nSecondPartSternDamageWeight             = Parser:Get("vitality"         , "second_part_stern_damage_weight"     , 0 , Parser.TypeNumber)
    tbVitality.nSecondPartCoreDamageWeight              = Parser:Get("vitality"         , "second_part_core_damage_weight"      , 0 , Parser.TypeNumber)
    tbVitality.nThirdPartSternDamageWeight              = Parser:Get("vitality"         , "third_part_stern_damage_weight"      , 0 , Parser.TypeNumber)
    tbVitality.nThirdPartCoreDamageWeight               = Parser:Get("vitality"         , "third_part_core_damage_weight"       , 0 , Parser.TypeNumber)

    tbMovement.nMaxAngleSpeedWeight                     = Parser:Get("movement"         , "max_angle_speed_weight"              , 0 , Parser.TypeNumber)
    tbMovement.nAngularAccelerationWeight               = Parser:Get("movement"         , "angular_acceleration_weight"         , 0 , Parser.TypeNumber)
    tbMovement.nMaxLinerSpeedWeight                     = Parser:Get("movement"         , "max_liner_speed_weight"              , 0 , Parser.TypeNumber)
    tbMovement.nLinearAccelerationWeight                = Parser:Get("movement"         , "linear_acceleration_weight"          , 0 , Parser.TypeNumber)

    tbHeadFirePower.nHeadGunCountWeight                 = Parser:Get("head_fire_power"  , "head_gun_count_weight"               , 0 , Parser.TypeNumber)

    tbSideFirePower.nSideGunCountWeight                 = Parser:Get("side_fire_power"  , "side_gun_count_weight"               , 0 , Parser.TypeNumber)

    tbDeckFirePower.nSternCannonCountWeight             = Parser:Get("stern_fire_power" , "stern_cannon_count_weight"           , 0 , Parser.TypeNumber)

    tbFinalScore.nParam                                 = Parser:Get("final_score"      , "param"                                , 0 , Parser.TypeNumber)
end

return ShipDataDisplayIni
