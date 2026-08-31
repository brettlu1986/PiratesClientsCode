local ShipWeaponAttachmentPedestalItemDataTableHelper = {}

function ShipWeaponAttachmentPedestalItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nFiringRotationRangeRatio = Parser:Get("rotation_range_inc", 0, Parser.TypeFloat)
    NewTemplate.nWeaponDamageIntervalRatio = Parser:Get("weapon_damage_interval_ratio", 0, Parser.TypeFloat)
end

return ShipWeaponAttachmentPedestalItemDataTableHelper