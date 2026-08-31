local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISetting = luaclass("UISetting", WndBase)
local SettingSystemNew = require("SettingSystemNew")
local UIUtils = require("UIUtils")
-------------------------------------------------------------------------------------------------------
local TAB_WIDGET_NAME = {
    "pbSettingBasic",
    "pbSettingFrame",
    "pbSettingUse",
    "pbSettingPickUp",
    "pbSettingCamera",
    "pbSettingChat",
    "pbSettingSound",
}
UISetting.pbWindowFrame = nil

function UISetting:OnLoad()
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:BindWidgetSwitcher(self.pWidgetRef.wsContent, TAB_WIDGET_NAME)
end

function UISetting:OnCreate()
    SettingSystemNew:SetUseDefaultSaveId(true)
end

function UISetting:OnShow()
    self.pbWindowFrame:SetSelectedTab(1)
    self:PlayAnimation("animStart", 0, 1, EUMGSequencePlayMode.Forward, 1)
    UIUtils.BottomMenuUnselectAll()
end

function UISetting:OnHide()
    SettingSystemNew:Save()
    SettingSystemNew:SetUseDefaultSaveId(false)
end

function UISetting:OnDestroy()
    self.pbWindowFrame = nil
end

return UISetting