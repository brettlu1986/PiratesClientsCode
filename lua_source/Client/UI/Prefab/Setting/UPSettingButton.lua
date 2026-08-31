local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSettingButton = luaclass("UPSettingButton", PrefabBase)
local UIResourceDef = require("UIResourceDef")

local UNDETERMINED = -1  
local UNCHECKED = 0
local CHECKED = 1 
local SLATE_COLOR_DARK_GRAY5 = UIResourceDef.COLOR.GREY1.SLATE_COLOR
local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE.SLATE_COLOR

UPSettingButton.szType = nil

function UPSettingButton:Init(szType, szTitle)
    self.szType = szType
    self.pWidgetRef.txtContent:SetText(szTitle)
end

function UPSettingButton:SetSelect(nSelect)
    local pWidgetRef = self.pWidgetRef
    if nSelect == UNDETERMINED then
        pWidgetRef.txtContent:SetColorAndOpacity(SLATE_COLOR_DARK_GRAY5)
        pWidgetRef.imgChecked:SetVisibility(ESlateVisibility.Collapsed)
    elseif nSelect == UNCHECKED then
        pWidgetRef.txtContent:SetColorAndOpacity(SLATE_COLOR_WHITE)
        pWidgetRef.imgChecked:SetVisibility(ESlateVisibility.Collapsed)
    elseif nSelect == CHECKED then
        pWidgetRef.txtContent:SetColorAndOpacity(SLATE_COLOR_WHITE)
        pWidgetRef.imgChecked:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

return UPSettingButton