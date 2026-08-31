local ShipWeaponAttachmentMuzzleItemDataTableHelper = {}

function ShipWeaponAttachmentMuzzleItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nFireSoundReduction = Parser:Get("fire_sound_reduction", 0, Parser.TypeFloat)
    NewTemplate.nPerfectFiringRangeBegin = Parser:Get("perfect_firing_range_begin_delta", 0, Parser.TypeFloat) * 100
    NewTemplate.nPerfectFiringRangeEnd = Parser:Get("perfect_firing_range_end_delta", 0, Parser.TypeFloat) * 100
    NewTemplate.nShipBulletDeviationRatio = Parser:Get("ship_bullet_deviation_ratio", 0, Parser.TypeFloat)
    NewTemplate.nShipBulletAimDeviationRatio = Parser:Get("ship_bullet_aim_deviation_ratio", 0, Parser.TypeFloat)
    NewTemplate.nPowderKegFiringAngleRatio = Parser:Get("powder_keg_firing_angle_ratio", 0, Parser.TypeFloat)
end

return ShipWeaponAttachmentMuzzleItemDataTableHelper