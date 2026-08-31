local ShipWeaponAttachmentHolderItemDataTableHelper = {}

function ShipWeaponAttachmentHolderItemDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nShipBulletDeviationRatio = Parser:Get("ship_bullet_deviation_ratio", 0, Parser.TypeFloat)
    NewTemplate.nShipBulletAimDeviationRatio = Parser:Get("ship_bullet_aim_deviation_ratio", 0, Parser.TypeFloat)
    NewTemplate.nFiringIntervalRatio = Parser:Get("firing_interval_ratio", 0, Parser.TypeFloat)
    NewTemplate.nBulletSpeedRatio = Parser:Get("bullet_speed_ratio", 0, Parser.TypeFloat)
end

return ShipWeaponAttachmentHolderItemDataTableHelper