local ShipWeaponDataTableHelper = {}

local ShipRegionTypeDef = require("ShipRegionTypeDef")
local ShipWeaponAttackType = require("ShipWeaponAttackType")
local ShipWeaponFiringType = require("ShipWeaponFiringType")
local ShipWeaponDeviationLevelDef = require("ShipWeaponDeviationLevelDef")

function ShipWeaponDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    -- Base Info
    NewTemplate.szModelRes                  = Parser:Get("model_res"                    , nil                                   , Parser.TypeString     , false)
    NewTemplate.szSimplifiedModelRes        = Parser:Get("simplified_model_res"         , nil                                   , Parser.TypeString     , false)
    NewTemplate.tbCharacteristics           = Parser:Get("characteristic_id"            , {}                                    , Parser.TypeArrayInt   , false)
    NewTemplate.bDefaultWeapon              = Parser:Get("default_weapon"               , false                                 , Parser.TypeBool       , false)
    NewTemplate.nLeanFactorRatio            = Parser:Get("lean_factor_ratio"            , 0                                     , Parser.TypeFloat      , false)

    -- Weapon Attachment
    NewTemplate.tbMuzzles                   = Parser:Get("muzzles"                      , {}                                    , Parser.TypeArrayInt   , false)
    NewTemplate.tbSights                    = Parser:Get("sights"                       , {}                                    , Parser.TypeArrayInt   , false)
    NewTemplate.tbHolders                   = Parser:Get("holders"                      , {}                                    , Parser.TypeArrayInt   , false)
    NewTemplate.tbAmmunitions               = Parser:Get("ammunitions"                  , {}                                    , Parser.TypeArrayInt   , false)
    NewTemplate.tbPedestals                 = Parser:Get("pedestals"                    , {}                                    , Parser.TypeArrayInt   , false)

    -- Damage
    NewTemplate.nBaseDamage                 = Parser:Get("base_damage"                  , 0.0                                   , Parser.TypeFloat)
    NewTemplate.nAttackType                 = Parser:Get("attack_type"                  , ShipWeaponAttackType.PHYSICAL_ATTACK  , Parser.TypeInt)
    NewTemplate.nDamageRadius               = Parser:Get("damage_radius"                , 0.0                                   , Parser.TypeFloat)                 * 100
    NewTemplate.nDamageInnerRadius          = Parser:Get("damage_inner_radius"          , 0.0                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.nMinRadiusDamage            = Parser:Get("min_radius_damage"            , 0.0                                   , Parser.TypeFloat      , false)

    NewTemplate.tbDamageRatioFromWeapons    = {
        [ShipRegionTypeDef.SAIL]            = Parser:Get("damage_ratio_to_sail"         , 1.0                                   , Parser.TypeFloat),
        [ShipRegionTypeDef.HEAD]            = Parser:Get("damage_ratio_to_head"         , 1.0                                   , Parser.TypeFloat),
        [ShipRegionTypeDef.SIDE]            = Parser:Get("damage_ratio_to_side"         , 1.0                                   , Parser.TypeFloat),
        [ShipRegionTypeDef.STERN]           = Parser:Get("damage_ratio_to_stern"        , 1.0                                   , Parser.TypeFloat),
        [ShipRegionTypeDef.DECK]            = Parser:Get("damage_ratio_to_deck"         , 1.0                                   , Parser.TypeFloat)
    }

    -- Fire Rule
    NewTemplate.nFiringInterval             = Parser:Get("firing_interval"              , 0.0                                   , Parser.TypeFloat)
    NewTemplate.nFiringRoundCount           = Parser:Get("firing_round_count"           , 1                                     , Parser.TypeInt        , false)
    NewTemplate.nFiringType                 = Parser:Get("firing_type"                  , ShipWeaponFiringType.FIRING_WITH_ONE  , Parser.TypeInt        , false)
    NewTemplate.bAllowRepeatFiring          = Parser:Get("allow_repeat_firing"          , false                                 , Parser.TypeBool       , false)
    NewTemplate.bConcentratedFiring         = Parser:Get("concentrated_firing"          , true                                  , Parser.TypeBool       , false)
    NewTemplate.nMinFiringRange             = Parser:Get("min_firing_range"             , 0.0                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.nFiringRange                = Parser:Get("firing_range"                 , 0.0                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.nPerfectFiringRangeBegin    = Parser:Get("perfect_firing_range_begin"   , 0.0                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.nPerfectFiringRangeEnd      = Parser:Get("perfect_firing_range_end"     , 0.0                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.nMinDistanceDamageRatio     = Parser:Get("min_distance_damage_ratio"    , 1.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nMaxDistanceDamageRatio     = Parser:Get("max_distance_damage_ratio"    , 1.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nRotationRange              = Parser:Get("rotation_range"               , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.tbValidWeaponSlotLevel      = Parser:Get("valid_weapon_slot_level"      , {1}                                   , Parser.TypeArrayInt   , false)

    -- Bullet
    NewTemplate.nDeviationX                 = Parser:Get("deviation_x"                  , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nDeviationY                 = Parser:Get("deviation_y"                  , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nAimDeviationX              = Parser:Get("aim_deviation_x"              , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nAimDeviationY              = Parser:Get("aim_deviation_y"              , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nDisplayDeviationLevel      = Parser:Get("display_deviation_level"      , ShipWeaponDeviationLevelDef.MEDIUM    , Parser.TypeInt        , false)

    NewTemplate.bInfiniteBullet             = Parser:Get("infinite_bullet"              , false                                 , Parser.TypeBool       , false)
    NewTemplate.nBurningProb                = Parser:Get("burning_prob"                 , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nLeakingProb                = Parser:Get("leaking_prob"                 , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.nLoadingTime                = Parser:Get("loading_time"                 , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.bAutoLoading                = Parser:Get("auto_loading"                 , false                                 , Parser.TypeBool       , false)
    NewTemplate.szBulletRes                 = Parser:Get("bullet_res"                   , nil                                   , Parser.TypeString     , false)
    NewTemplate.nBulletItemTemplateId       = Parser:Get("bullet_item_template_id"      , -1                                    , Parser.TypeInt        , false)
    NewTemplate.nBulletSpeed                = Parser:Get("bullet_speed"                 , 0.0                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.nBulletLifeSpan             = Parser:Get("bullet_life_span"             , 0.0                                   , Parser.TypeFloat      , false)
    NewTemplate.bAutoBoom                   = Parser:Get("auto_boom"                    , false                                 , Parser.TypeBool       , false)
    NewTemplate.nTriggerRange               = Parser:Get("trigger_range"                , 0.1                                   , Parser.TypeFloat      , false)    * 100
    NewTemplate.tbTakerBuffList             = Parser:Get("taker_buff_list"              , {}                                    , Parser.TypeArrayInt   , false)
end

return ShipWeaponDataTableHelper
