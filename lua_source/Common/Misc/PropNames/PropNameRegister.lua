local PropNameRegister = {}

function PropNameRegister.RegisterNames(Register)
    Register("PropNameCommon")
    Register("PropNameHuman")
    Register("PropNameShip")
    Register("PropNameVehicle")
    Register("PropNameDestructible")
    Register("PropNameGameState")
end

return PropNameRegister