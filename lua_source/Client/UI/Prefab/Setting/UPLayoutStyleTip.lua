-----------------------------------------------------
--File Name    : UPLayoutStyleTip.lua
--Author       : ranjie
--Create Time  : 2019-06-12
--Description  : 布局设置风格选择框
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPLayoutStyleTip = luaclass("UPLayoutStyleTip", PrefabBase)

local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")

local TXT_LAYOUT_USE = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_STYLE_USE")
local TXT_LAYOUT_DOWNLOAD = UISetUtils.GetL10NTextByKey("SETTING_LAYOUT_STYLE_DOWNLOAD")


UPLayoutStyleTip.SettingLayout = nil
UPLayoutStyleTip.nFrom = nil

local function RefreshUsedLayout(self, nStyle)
    for i = 1, self.SettingLayout:GetMaxStyleCount() do
        local pWidget = self.pWidgetRef["chkLayout"..i]
        if pWidget then
            if i == nStyle then
                self.pWidgetRef["txtButton"..i]:SetText(TXT_LAYOUT_USE)
                pWidget:SetIsChecked(true)
                pWidget:SetVisibility(ESlateVisibility.HitTestInvisible)
            else
                self.pWidgetRef["txtButton"..i]:SetText(TXT_LAYOUT_DOWNLOAD)
                pWidget:SetIsChecked(false)
                pWidget:SetVisibility(ESlateVisibility.Visible)
            end
        end
    end
    self.pWidgetRef.txtCurrentLayout:SetText(UITextDef.LAYOUT_NAME[nStyle])
end

local function OnLayoutUseChanged(self, nStyle, bChecked)
    if not self.nFrom then
        logerror("OnLayoutUseChanged,self.nFrom is nil, not init with from")
        return
    end
    if not bChecked then
        return
    end
    self.SettingLayout:SetLayoutStyle(self.nFrom, nStyle)
    RefreshUsedLayout(self, nStyle)
end

function UPLayoutStyleTip:OnLoad()
    self.SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
end

function UPLayoutStyleTip:Init(nFrom)
    self.nFrom = nFrom
    local nStyle = self.SettingLayout:GetLayoutStyle(self.nFrom)
    RefreshUsedLayout(self, nStyle)
end

function UPLayoutStyleTip:OnBindEvent(EventHelper)
    for i = 1, self.SettingLayout:GetMaxStyleCount() do
        local pWidget = self.pWidgetRef["chkLayout"..i]
        if pWidget then
            EventHelper:RegisterCppDelegateFunc(pWidget.OnCheckStateChanged, function(bChecked) 
                OnLayoutUseChanged(self, i, bChecked) 
            end)
        end
    end
end

return UPLayoutStyleTip
