local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataShipMovementState = luaclass("SyncDataShipMovementState", SyncDataBase)

SyncDataShipMovementState.tbShipMovement = nil


local function ClearShipMovementState(ship_movement_state)
    ship_movement_state.linear_speed = 0;
    ship_movement_state.angular_speed = 0;
    ship_movement_state.acceleration = 0;
end

local function FillShipMovementState(self, ship_movement_state)
    local tbOwner = self.tbOwner
    if not tbOwner:IsShip() then
        ClearShipMovementState(ship_movement_state)
        return
    end

    local ShipMovementComponent = tbOwner.pUEActor.ShipMovementComponent
    ship_movement_state.linear_speed = ShipMovementComponent:GetCurrentLinearSpeed()
    ship_movement_state.angular_speed = ShipMovementComponent:GetCurrentAngularSpeed()
    ship_movement_state.acceleration = ShipMovementComponent:GetCurrentLinearAcceleration();
end

function SyncDataShipMovementState:OnSync(tbPack)
    FillShipMovementState(self, self.tbShipMovement)
    tbPack.ship_movement_state = self.tbShipMovement
end


function SyncDataShipMovementState:OnStart()
    self.tbShipMovement = {}
end


function SyncDataShipMovementState:OnStop()

end

return SyncDataShipMovementState