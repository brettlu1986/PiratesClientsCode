local luaclass = require ("luaclass")
local UpSettingLayoutBase = require("UpSettingLayoutBase")
local UPSettingLayoutHuman = luaclass("UPSettingLayoutHuman", UpSettingLayoutBase)

local SettingLayoutFromDef = require("SettingLayoutFromDef")

function UPSettingLayoutHuman:LoadTargetWidgets(tbTargetWidgetMap)
    self.nFrom = SettingLayoutFromDef.HUMAN
    self.pRoot = self.pWidgetRef.cvsHuman
    return UPSettingLayoutHuman.super.LoadTargetWidgets(self, tbTargetWidgetMap)
end

return UPSettingLayoutHuman
