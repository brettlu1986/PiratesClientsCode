local luaclass = require ("luaclass")
local UpSettingLayoutBase = require("UpSettingLayoutBase")
local UPSettingLayoutShip = luaclass("UPSettingLayoutShip", UpSettingLayoutBase)

local SettingLayoutFromDef = require("SettingLayoutFromDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")

function UPSettingLayoutShip:LoadTargetWidgets(tbTargetWidgetMap)
    self.nFrom = SettingLayoutFromDef.SHIP
    self.pRoot = self.pWidgetRef.cvsShip
    local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
    self.nOperationMode = tbSettingOperationMode:GetShipOperationMode()
    return UPSettingLayoutShip.super.LoadTargetWidgets(self, tbTargetWidgetMap)
end


return UPSettingLayoutShip
