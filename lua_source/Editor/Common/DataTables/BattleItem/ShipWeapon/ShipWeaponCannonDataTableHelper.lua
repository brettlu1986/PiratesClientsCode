local ShipWeaponCannonDataTableHelper = {}

local ShipWeaponDataTableHelper = require("ShipWeaponDataTableHelper")

function ShipWeaponCannonDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipWeaponDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nGravityZ = Parser:Get("gravity_z", 0.0, Parser.TypeFloat) * 100
    NewTemplate.nBulletLaunchInterval = Parser:Get("bullet_launching_interval", 0.0, Parser.TypeFloat, false)
end

return ShipWeaponCannonDataTableHelper
