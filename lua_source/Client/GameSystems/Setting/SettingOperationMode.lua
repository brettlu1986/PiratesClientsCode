local luaclass = require("luaclass")
local SettingBase = require("SettingBase")
local SettingOperationMode = luaclass("SettingOperationMode", SettingBase)

local SettingKeyDef = require("SettingKeyDef")

local VehicleKey = SettingKeyDef.RemoteKeys.CONTROL_MODE_VEHICLE
local ShipKey = SettingKeyDef.RemoteKeys.CONTROL_MODE_SHIP

local ModeDef = {
    WithButton = 1,
    WithJoystick = 2
}

SettingOperationMode.ModeDef = ModeDef
SettingOperationMode.LocalSavedMode = {
    VehicleMode = ModeDef.WithButton,
    ShipMode = ModeDef.WithButton
}

function SettingOperationMode:GetShipOperationMode()
    local nMode = self:Get(ShipKey)
    if not nMode or nMode < 0 then
        nMode = self.LocalSavedMode.ShipMode
        self:Set(ShipKey, nMode)
    end
    self.LocalSavedMode.ShipMode = nMode
    return nMode
end

function SettingOperationMode:GetVehicleOperationMode()
    local nMode = self:Get(VehicleKey)
    if not nMode or nMode < 0 then
        nMode = self.LocalSavedMode.VehicleMode
        self:Set(VehicleKey, nMode)
    end
    self.LocalSavedMode.VehicleMode = nMode
    return nMode
end

function SettingOperationMode:SetShipOperationMode(nMode)
    self.LocalSavedMode.ShipMode = nMode
    self:Set(ShipKey, nMode)
    self.Owner:SaveRemoveData()
end

function SettingOperationMode:SetVehicleOperationMode(nMode)
    self.LocalSavedMode.VehicleMode = nMode
    self:Set(VehicleKey, nMode)
    self.Owner:SaveRemoveData()
end

return SettingOperationMode