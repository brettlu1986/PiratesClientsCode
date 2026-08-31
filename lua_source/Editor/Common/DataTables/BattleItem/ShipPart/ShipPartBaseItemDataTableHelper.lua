local ShipPartBaseItemDataTableHelper = {}

function ShipPartBaseItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nAppearanceResId            = Parser:Get("appearance_res_id"            , -1    , Parser.TypeInt)
    NewTemplate.nDurability                 = Parser:Get("durability"                   , -1    , Parser.TypeInt)
    NewTemplate.bCanDestroy                 = Parser:Get("candestroy"                   , true  , Parser.TypeBool)
    NewTemplate.nValidShips                 = Parser:Get("valid_ships"                  , nil   , Parser.TypeArrayInt)

    -- 护甲、船长室有
    NewTemplate.nShipPartArmor              = Parser:Get("armor"                        , 1     , Parser.TypeFloat  , false)
    
    -- 以下是零件可以叠加的属性，默认值请都用nil，方便判断是否没填
    NewTemplate.nFireDamageResistance       = Parser:Get("fire_damage_resistance"       , nil   , Parser.TypeInt    , false)
    NewTemplate.nLeakDamageResistance       = Parser:Get("leak_damage_resistance"       , nil   , Parser.TypeInt    , false)
    NewTemplate.nSpeedAdditionPercent       = Parser:Get("speed_addition_percent"       , nil   , Parser.TypeFloat  , false)
    NewTemplate.nAngleSpeedAdditionPercent  = Parser:Get("angle_speed_addition_percent" , nil   , Parser.TypeFloat  , false)
    NewTemplate.nSpeedAddition              = Parser:Get("speed_addition"               , nil   , Parser.TypeFloat  , false)
    NewTemplate.nAngleSpeedAddition         = Parser:Get("angle_speed_addition"         , nil   , Parser.TypeFloat  , false)
    NewTemplate.nSlowSpeedResistance        = Parser:Get("slow_speed_resistance"        , nil   , Parser.TypeFloat  , false)
    NewTemplate.nStunResistance             = Parser:Get("stun_resistance"              , nil   , Parser.TypeFloat  , false)
    NewTemplate.nMaxHpPercent               = Parser:Get("max_hp_percent"               , nil   , Parser.TypeFloat  , false)
end

return ShipPartBaseItemDataTableHelper