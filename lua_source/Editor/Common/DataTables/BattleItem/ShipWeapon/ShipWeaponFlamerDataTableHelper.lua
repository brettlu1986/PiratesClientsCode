local ShipWeaponFlamerDataTableHelper = {}

local ShipWeaponDataTableHelper = require("ShipWeaponDataTableHelper")

function ShipWeaponFlamerDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    ShipWeaponDataTableHelper.ParseExtraAttriLine(Parser, NewTemplate)
    NewTemplate.nDamageInterval = Parser:Get("damage_interval", 0.0, Parser.TypeFloat, true)
end

return ShipWeaponFlamerDataTableHelper
