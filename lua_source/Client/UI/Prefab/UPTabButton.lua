local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPTabButton = luaclass("UPTabButton", PrefabBase)

local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local LuaDelegateClass = require("LuaDelegate")

UPTabButton.nIdx = 0
UPTabButton.OnClickedDelegated  = nil
UPTabButton.pTxtTitle = nil
UPTabButton.pImgIcon = nil
UPTabButton.bEnable = true

local CHECKED_TINT_COLOR = SlateColor{SpecifiedColor = LinearColor{ R = 1.0, G = 1.0, B = 1.0, A = 1.0 }}
local UNCHECKED_TINT_COLOR = SlateColor{SpecifiedColor = LinearColor{ R = 0.45, G = 0.53, B = 0.58, A = 1.0 }}
local DISABLED_TINT_COLOR = SlateColor{SpecifiedColor = LinearColor{ R = 1.0, G = 1.0, B = 1.0, A = 0.5 }}

local function OnClickedButton(self)
    self.OnClickedDelegated:Fire(self.nIdx)
end

function UPTabButton:OnLoad()
    self.OnClickedDelegated = LuaDelegateClass()
    self.pTxtTitle = self.pWidgetRef.nsTitle:GetChildAt(0)
    self.pImgIcon = self.pWidgetRef.nsIcon:GetChildAt(0)
    if not self.pImgIcon then
        self.pWidgetRef.nsIcon:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPTabButton:Init(nIdx)
    self.nIdx = nIdx
end

function UPTabButton:SetResourceText(l10nText)
    if l10nText then
        self.pTxtTitle:SetText(l10nText)
    end
end

function UPTabButton:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnTop.OnClicked, self, OnClickedButton)
end

function UPTabButton:OnSelected()
    self.pWidgetRef.chkButton:SetCheckedState(ECheckBoxState.Checked)
    if self.bEnable then
        self.pTxtTitle:SetColorAndOpacity(CHECKED_TINT_COLOR)
        if self.pImgIcon then
            self.pImgIcon:SetColorAndOpacity(CHECKED_TINT_COLOR.SpecifiedColor)
        end
    end
end

function UPTabButton:OnUnselected()
    self.pWidgetRef.chkButton:SetCheckedState(ECheckBoxState.Unchecked)
    if self.bEnable then
        self.pTxtTitle:SetColorAndOpacity(UNCHECKED_TINT_COLOR)
        if self.pImgIcon then
            self.pImgIcon:SetColorAndOpacity(UNCHECKED_TINT_COLOR.SpecifiedColor)
        end
    end
end

function UPTabButton:SetIsEnabled(bEnabled)
    self.bEnable = bEnabled

    self.pWidgetRef.chkButton:SetIsEnabled(bEnabled)
    self.pWidgetRef.btnTop:SetIsEnabled(bEnabled)
    if bEnabled == false then
        self.pTxtTitle:SetColorAndOpacity(DISABLED_TINT_COLOR)
        if self.pImgIcon then
            self.pImgIcon:SetColorAndOpacity(DISABLED_TINT_COLOR.SpecifiedColor)
        end
        UISetUtils.SetCheckBoxUncheckedBrushRes(self.pWidgetRef.chkButton, UIResourceDef.TAB_BUTTON_DISABLE:load())
    end
end

function UPTabButton:SetRedDot(bShow)
    self.pWidgetRef.chkButton:HideTipIcon(not bShow)
end

function UPTabButton:SetVisibility(eVisibility)
    self.pWidgetRef:SetVisibility(eVisibility)
end

return UPTabButton
