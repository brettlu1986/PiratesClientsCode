local ShipWeaponPowderKegDataTableHelper = {}

local ShipWeaponDataTableHelper = require("ShipWeaponDataTableHelper")

function ShipWeaponPowderKegDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipWeaponDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nFiringAngle = Parser:Get("firing_angle", 0.0, Parser.TypeFloat, false)
end

return ShipWeaponPowderKegDataTableHelper