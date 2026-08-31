local luaclass = require("luaclass")
local GameVehicle = require("GameVehicle")
local GameVehicle_C = luaclass("GameVehicle_C", GameVehicle)

function GameVehicle_C:OnCreate()
    return GameVehicle_C.super.OnCreate(self)
end

function GameVehicle_C:OnDead()
    GameVehicle_C.super.OnDead(self)
end

return GameVehicle_C