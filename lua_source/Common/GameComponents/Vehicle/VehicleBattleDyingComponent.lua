local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local VehicleBattleDyingComponent = luaclass("VehicleBattleDyingComponent", GameComponentBase)

function VehicleBattleDyingComponent:TryToEnterDying(nHp)
    return false
end

return VehicleBattleDyingComponent