local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPTabButtonLobby = luaclass("UPTabButtonLobby", PrefabBase)

local LuaDelegateClass = require("LuaDelegate")
local UISetUtils = require("UISetUtils")

UPTabButtonLobby.nIdx = 0
UPTabButtonLobby.OnClickedDelegated  = nil

local function OnClickedBtnTab(self)
    self.OnClickedDelegated:Fire(self.nIdx)
end

function UPTabButtonLobby:Init(nIdx)
    self.nIdx = nIdx
    self.OnClickedDelegated = LuaDelegateClass()
    local szKey = self.pWidgetRef.TextKey
    if szKey and szKey ~= "" then
        self.pWidgetRef.txtTitle.Key = szKey
        self.pWidgetRef.Text = UISetUtils.GetL10NTextByKey(szKey)
    end
end

function UPTabButtonLobby:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnTab.OnClicked, self, OnClickedBtnTab)
end

function UPTabButtonLobby:OnSelected()
    self.pWidgetRef:SetIsSelected(true)
end

function UPTabButtonLobby:OnUnselected()
    self.pWidgetRef:SetIsSelected(false)
end

function UPTabButtonLobby:SetResourceText(l10nText)
    self.pWidgetRef.Text = l10nText
    self.pWidgetRef.txtTitle:SetText(l10nText)
end

function UPTabButtonLobby:SetIsEnabled(bEnabled)
    self.bEnable = bEnabled
end

function UPTabButtonLobby:SetTipIconVisible(bVisible)
    self.pWidgetRef.ovlTipIcon:SetVisibility(bVisible and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

function UPTabButtonLobby:SetTipCount(nCount)
    if nCount > 0 then
        self:SetTipIconVisible(true)
        self.pWidgetRef.txtTipCount:SetText(nCount)
        self.pWidgetRef.txtTipCount:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self:SetTipIconVisible(false)
        self.pWidgetRef.txtTipCount:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPTabButtonLobby:SetVisibility(eVisibility)
    self.pWidgetRef:SetVisibility(eVisibility)
end

return UPTabButtonLobby
