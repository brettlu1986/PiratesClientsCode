-----------------------------------------------------
--File Name    : HumanWeaponDataTableHelperBase.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 12:05:53 PM
--Description  : HumanWeaponDataTableHelperBase
-----------------------------------------------------
local HumanWeaponDef = require("HumanWeaponDef")
local DataTableExporter = require("DataTableExporter")
local L10N = require("L10N")
local HumanWeaponDataTableHelperBase = {}

local Property = HumanWeaponDef.Property

local tbColumnFieldToPropertyField = {}

local function Define(szColumn, szProperty, defaultValue, nType)
    local tb = {}
    tb["PropertyName"] = szProperty
    tb["DefaultValue"] = defaultValue
    tb["ValueType"]    = nType
    tbColumnFieldToPropertyField[szColumn] = tb
end

local function DefineColumnFieldToPropertyField()
    Define("open_sight_speed"                       , Property.OpenSightSpeed                   , 0.0  , DataTableExporter.TypeFloat)
    Define("bullet_type"                            , Property.BulletType                       , 0    , DataTableExporter.TypeInt)
    Define("bullet_max"                             , Property.BulletMax                        , 0    , DataTableExporter.TypeInt)
    Define("damage_per_bullet"                      , Property.DamagePerBullet                  , 0.0  , DataTableExporter.TypeFloat)
    Define("damege_magnification"                   , Property.DamageMagnification              , 0.0  , DataTableExporter.TypeFloat)
    Define("ship_damage_ratio"                      , Property.ShipDamageRatio                  , 1.0  , DataTableExporter.TypeFloat)
    Define("rate_of_fire"                           , Property.RateOfFire                       , 0.0  , DataTableExporter.TypeFloat)
    Define("cd"                                     , Property.CD                               , 0.0  , DataTableExporter.TypeFloat)
    Define("speed_affect_damage"                    , Property.SpeedAffectDamage                , false, DataTableExporter.TypeBool)
    Define("initial_speed"                          , Property.InitialSpeed                     , 0.0  , DataTableExporter.TypeFloat)
    Define("initial_speed_magnification"            , Property.InitialSpeedMagnification        , 0.0  , DataTableExporter.TypeFloat)
    Define("reload_time"                            , Property.ReloadTime                       , 0.0  , DataTableExporter.TypeFloat)

    Define("effective_range"                        , Property.EffectiveRange                   , 0    , DataTableExporter.TypeInt)
    Define("melee_attack_speed"                     , Property.MeleeAttackSpeed                 , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_recover"                     , Property.DispersionRecover                , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_deviation"                   , Property.DispersionDeviation              , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion"                             , Property.Dispersion                       , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_magnification"               , Property.DispersionMagnification          , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_stand"               , Property.DispersionPublishStand           , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_squat"               , Property.DispersionPublishSquat           , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_prone"               , Property.DispersionPublishProne           , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_walk"                , Property.DispersionPublishWalk            , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_jump"                , Property.DispersionPublishJump            , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_normal_fire"         , Property.DispersionPublishNormalFire      , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_sight_fire"          , Property.DispersionPublishSightFire       , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_normal_aim"          , Property.DispersionPublishNormalAim       , 0.0  , DataTableExporter.TypeFloat)
    Define("dispersion_publish_sight_aim"           , Property.DispersionPublishSightAim        , 0.0  , DataTableExporter.TypeFloat)
    Define("scope_res_id"                           , Property.ScopeResId                       , 0    , DataTableExporter.TypeInt)
    Define("open_aim_camera_rate"                   , Property.OpenAimCameraRate                , 0.0  , DataTableExporter.TypeFloat)
    Define("open_aim_camera_h_move_scale"           , Property.OpenAimCameraHMoveScale          , 0.0  , DataTableExporter.TypeFloat)
    Define("open_aim_camera_v_move_scale"           , Property.OpenAimCameraVMoveScale          , 0.0  , DataTableExporter.TypeFloat)
    Define("deviation_x"                            , Property.DeviationX                       , 0.0  , DataTableExporter.TypeFloat)
    Define("deviation_y"                            , Property.DeviationY                       , 0.0  , DataTableExporter.TypeFloat)
    Define("aim_deviation_x"                        , Property.AimDeviationX                    , 0.0  , DataTableExporter.TypeFloat)
    Define("aim_deviation_y"                        , Property.AimDeviationY                    , 0.0  , DataTableExporter.TypeFloat)
    Define("decrease_bullet_count"                  , Property.DecreaseBulletCount              , 0.0  , DataTableExporter.TypeInt)
    Define("max_spot_count"                         , Property.MaxSpotCount                     , 0.0  , DataTableExporter.TypeInt)
    Define("sector_angle"                           , Property.MaxSectorAngle                   , 0.0  , DataTableExporter.TypeFloat)
    Define("weapon_length"                          , Property.WeaponLength                     , 0.0  , DataTableExporter.TypeFloat)
    Define("offset_to_aim"                          , Property.OffsetToAim                      , 0.0  , DataTableExporter.TypeFloat)
    --开火吸附
    Define("fire_absorption_speed"                  , Property.FireAbsorptionSpeed              , 0.0  , DataTableExporter.TypeFloat)
    Define("fire_absorption_interp"                 , Property.FireAbsorptionInterp             , 0.0  , DataTableExporter.TypeFloat)
    --火球爆炸相关
    Define("fireball_explosive_inner_radius"        , Property.FireballExplosiveInnerRadius     , 0.0  , DataTableExporter.TypeFloat)
    Define("fireball_explosive_outside_radius"      , Property.FireballExplosiveOutsideRadius   , 0.0  , DataTableExporter.TypeFloat)
    Define("projectile_fire_angle"                  , Property.ProjectileFireAngle              , 0.0  , DataTableExporter.TypeFloat)

end

function HumanWeaponDataTableHelperBase.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nWeaponCategory             = Parser:Get("weapon_category"              , -1    , Parser.TypeInt)
    NewTemplate.tbMatchedSlotTypes          = Parser:Get("slot_type"                    , {}    , Parser.TypeArrayInt)
    NewTemplate.nPrimaryCategory            = Parser:Get("primary_category"             , -1    , Parser.TypeInt)
    NewTemplate.szSightRes                  = Parser:Get("sight_res"                    , ""    , Parser.TypeString)
    NewTemplate.nMaxDispersionForUISight    = Parser:Get("max_dispersion_for_ui_sight"  , 0.0   , Parser.TypeFloat) --准星扩散程度最大值
    NewTemplate.nMinDispersionForUISight    = Parser:Get("min_dispersion_for_ui_sight"  , 0.0   , Parser.TypeFloat) --准星扩散程度最小值
    NewTemplate.nMaxZoomForUISight          = Parser:Get("max_zoom_for_ui_sight"        , 0.0   , Parser.TypeFloat) --腰射准星UI扩散最大范围
    NewTemplate.nPressRes                   = Parser:Get("press_res"                    , ""    , Parser.TypeString)
    NewTemplate.nNormalRes                  = Parser:Get("normal_res"                   , ""    , Parser.TypeString)
    NewTemplate.nAdsorpRange                = Parser:Get("adsorp_range"                 , 0.0   , Parser.TypeFloat)
    NewTemplate.nAdsorpMinRange             = Parser:Get("adsorp_min_range"             , 0.0   , Parser.TypeFloat)
    NewTemplate.nAdsorpScale                = Parser:Get("adsorp_scale"                 , 0.0   , Parser.TypeFloat)
    NewTemplate.nRecoilLevel                = Parser:Get("recoil_level"                 , -1    , Parser.TypeInt)
    NewTemplate.nMeleeAttackSpeedLevel      = Parser:Get("melee_attack_speed_level"     , -1    , Parser.TypeInt)
    NewTemplate.bUseSniperUi                = Parser:Get("use_sniper_ui"                , false , Parser.TypeBool)
    NewTemplate.nArmorAffectGroup           = Parser:Get("armor_affect_group"           , -1    , Parser.TypeInt)
    NewTemplate.nDamageType                 = Parser:Get("damage_type"                  , -1    , Parser.TypeInt)
    NewTemplate.nWeaponInstanceType         = Parser:Get("weapon_instance_type"         , -1    , Parser.TypeInt)
    NewTemplate.nTrunkPartId                = Parser:Get("trunk_part_id"                , -1    , Parser.TypeInt)
    NewTemplate.l10nGeneralDesc             = Parser:Get("general_desc"                 , L10N.NullString,    Parser.TypeL10N)
    NewTemplate.l10nSpecialDesc             = Parser:Get("special_desc"                 , L10N.NullString,    Parser.TypeL10N)

    --摩擦辅助相关
    NewTemplate.nAssistDistance             = Parser:Get("assist_distance"              , 0.0   , Parser.TypeFloat)
    NewTemplate.nAssistHReduceRate          = Parser:Get("assist_h_reduce_rate"         , 0.0   , Parser.TypeFloat)
    NewTemplate.nAssistVReduceRate          = Parser:Get("assist_v_reduce_rate"         , 0.0   , Parser.TypeFloat)
    NewTemplate.nAssistReducePercent        = Parser:Get("assist_reduce_percent"        , 0.0   , Parser.TypeFloat)
    --追踪辅助相关
    NewTemplate.nTrackSpeedPercent         = Parser:Get("track_assist_percent"          , 0.0   , Parser.TypeFloat)
    NewTemplate.nTrackEffMinSpeed          = Parser:Get("track_assist_min_speed"        , 0.0   , Parser.TypeFloat)
    NewTemplate.nTrackInterpPercent        = Parser:Get("track_assist_interp_percent"   , 0.0   , Parser.TypeFloat)
    NewTemplate.nBulletSpeed               = Parser:Get("bullet_speed"                  , 0.0   , Parser.TypeFloat)
    NewTemplate.szHoldSocketMale           = Parser:Get("hold_socket_male"              , nil   , Parser.TypeString)
    NewTemplate.szHoldSocketFemale         = Parser:Get("hold_socket_female"            , nil   , Parser.TypeString)
    NewTemplate.szHoldSocketNpc            = Parser:Get("hold_socket_npc"               , nil   , Parser.TypeString)
    NewTemplate.szUnholdPrimarySocket      = Parser:Get("unhold_primary_socket"         , nil   , Parser.TypeString)
    NewTemplate.szUnholdSecondarySocket    = Parser:Get("unhold_secondary_socket"       , nil   , Parser.TypeString)

    for k, v in pairs(tbColumnFieldToPropertyField) do
        NewTemplate[v.PropertyName] = Parser:Get(k, v.DefaultValue, v.ValueType)
    end
    NewTemplate.tbFireTypes = Parser:Get("fire_type", {}, Parser.TypeArrayInt)

    local tbAttachmentSlots = {}
    table.insert(tbAttachmentSlots,  Parser:Get("muzzle_slot"          , {}   , Parser.TypeArrayInt))
    table.insert(tbAttachmentSlots,  Parser:Get("handguard_slot"       , {}   , Parser.TypeArrayInt))
    table.insert(tbAttachmentSlots,  Parser:Get("sight_slot"           , {}   , Parser.TypeArrayInt))
    table.insert(tbAttachmentSlots,  Parser:Get("stock_slot"           , {}   , Parser.TypeArrayInt))
    table.insert(tbAttachmentSlots,  Parser:Get("magazine_slot"        , {}   , Parser.TypeArrayInt))

    NewTemplate.tbAttachmentSlots = tbAttachmentSlots

    local szMuzzleSlotName         = Parser:Get("muzzle_slot_name"     , nil  , Parser.TypeString)
    local szHandGuarSlotdName      = Parser:Get("handguard_slot_name"  , nil  , Parser.TypeString)
    local szSightSlotName          = Parser:Get("sight_slot_name"      , nil  , Parser.TypeString)
    local szStockSlotName          = Parser:Get("stock_slot_name"      , nil  , Parser.TypeString)
    local szMagazineSlotName       = Parser:Get("magazine_slot_name"   , nil  , Parser.TypeString)

    local tbAttachmentSlotNames = {
        [1] = szMuzzleSlotName,
        [2] = szHandGuarSlotdName,
        [3] = szSightSlotName,
        [4] = szStockSlotName,
        [5] = szMagazineSlotName,
    }

    NewTemplate.tbAttachmentSlotNames = tbAttachmentSlotNames

end

function HumanWeaponDataTableHelperBase.GetPropertyField(szColumnFiled)
    local tb = tbColumnFieldToPropertyField[szColumnFiled]
    if tb then
        return tb.PropertyName
    else
        return nil
    end
end

DefineColumnFieldToPropertyField()

return HumanWeaponDataTableHelperBase