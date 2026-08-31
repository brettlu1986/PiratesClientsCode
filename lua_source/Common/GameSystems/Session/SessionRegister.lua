local SessionRegister = {}

local SessionType = require("SessionType")

function SessionRegister:Register(SessionSystem)
    local T = SessionType
    SessionSystem:Register(T.ChangeToShip, "ChangeToShipSession")
    SessionSystem:Register(T.ChangeToHuman, "ChangeToHumanSession")
end

return SessionRegister