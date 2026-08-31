-----------------------------------------------------
--File Name    : HumanThrownItemDataTableHelper.lua
--Author       : WuJizhou
--Create Time  : 9/17/2018, 3:45:49 PM
--Description  : HumanThrownItemDataTableHelper
-----------------------------------------------------
local HumanThrownItemDataTableHelper = {}



function HumanThrownItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nThrownItemCategory             = Parser:Get("thrown_item_category"         , -1     , Parser.TypeInt)
    NewTemplate.nDamage                         = Parser:Get("damage"                       , 0.0    , Parser.TypeFloat)
    NewTemplate.nInnerRadius                    = Parser:Get("inner_radius"                 , 0.0    , Parser.TypeFloat)
    NewTemplate.nOuterRadius                    = Parser:Get("outer_radius"                 , 0.0    , Parser.TypeFloat)
    NewTemplate.nDamageFallOff                  = Parser:Get("damage_falloff"               , 0      , Parser.TypeInt)
    NewTemplate.nBuffId                         = Parser:Get("buff_id"                      , 0      , Parser.TypeInt)
    NewTemplate.nPreActionTime                  = Parser:Get("pre_action_time"              , 0.0    , Parser.TypeFloat)  --拉保险时长
    NewTemplate.nPreExplodeTime                 = Parser:Get("pre_explode_time"             , 0.0    , Parser.TypeFloat)  --引信时长
    NewTemplate.nThrowOutTime                   = Parser:Get("throw_out_time"               , 0.0    , Parser.TypeFloat)  --投掷脱手时长
    NewTemplate.nGroundLastTime                 = Parser:Get("ground_last_time"             , 0.0    , Parser.TypeFloat)  --地面效果持续时长
    NewTemplate.nCD                             = Parser:Get("cd"                           , 0.0    , Parser.TypeFloat)  --投掷冷却时长
    NewTemplate.nTraceId                        = Parser:Get("trace_id"                     , 0      , Parser.TypeInt)
    NewTemplate.nThrowDistance                  = Parser:Get("throw_distance"               , 0.0    , Parser.TypeFloat)
    NewTemplate.nInitialSpeed                   = Parser:Get("initial_speed"                , 0.0    , Parser.TypeFloat)
    NewTemplate.nBounceAttenuationValue         = Parser:Get("bounce_attenuation_value"     , 0.0    , Parser.TypeFloat)
    NewTemplate.nBounceAttenuationPercent       = Parser:Get("bounce_attenuation_percent"   , 0.0    , Parser.TypeFloat)
    NewTemplate.nInitialLowSpeed                = Parser:Get("initial_low_speed"            , 0.0    , Parser.TypeFloat)
    NewTemplate.nVerticleHighSpeed              = Parser:Get("verticle_high_speed"          , 0.0    , Parser.TypeFloat)
    NewTemplate.nVerticleLowSpeed               = Parser:Get("verticle_low_speed"           , 0.0    , Parser.TypeFloat)
    NewTemplate.nGravityRate                    = Parser:Get("gravity_rate"                 , 0.0    , Parser.TypeFloat)
    NewTemplate.nPressRes                       = Parser:Get("press_res"                    , ""     , Parser.TypeString)
    NewTemplate.nNormalRes                      = Parser:Get("normal_res"                   , ""     , Parser.TypeString)
    NewTemplate.nTrunkPartId                    = Parser:Get("trunk_part_id"                , -1     , Parser.TypeInt)
    NewTemplate.szSightRes                      = Parser:Get("sight_res"                    , ""     , Parser.TypeString)

    NewTemplate.tbExplodeTypes = {}
    local tbExplodeTypes = NewTemplate.tbExplodeTypes
    for idx = 1, 2 do
        local tbTemp = Parser:Get("explode_type_"..idx, {}, Parser.TypeArrayInt)
        table.insert(tbExplodeTypes, tbTemp)
    end

end

return HumanThrownItemDataTableHelper