local luaclass = require ("luaclass")
local UpSettingLayoutBase = require("UpSettingLayoutBase")
local UPSettingLayoutVehicle = luaclass("UPSettingLayoutVehicle", UpSettingLayoutBase)

local SettingLayoutFromDef = require("SettingLayoutFromDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")

function UPSettingLayoutVehicle:LoadTargetWidgets(tbTargetWidgetMap)
    self.nFrom = SettingLayoutFromDef.VEHICLE
    self.pRoot = self.pWidgetRef.cvsHorse
    local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
    self.nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
    return UPSettingLayoutVehicle.super.LoadTargetWidgets(self, tbTargetWidgetMap)
end


return UPSettingLayoutVehicle
