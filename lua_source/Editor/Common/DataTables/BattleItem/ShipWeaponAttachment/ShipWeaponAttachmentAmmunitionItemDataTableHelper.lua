local ShipWeaponAttachmentAmmunitionItemDataTableHelper = {}

function ShipWeaponAttachmentAmmunitionItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nReloadSpeedRatio = Parser:Get("reload_speed", 1, Parser.TypeFloat) - 1.0
    NewTemplate.nBulletTriggerRangeRatio = Parser:Get("bullet_trigger_range_ratio", 1, Parser.TypeFloat)
end

return ShipWeaponAttachmentAmmunitionItemDataTableHelper