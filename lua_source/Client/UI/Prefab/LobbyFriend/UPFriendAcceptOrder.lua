
local luaclass              = require("luaclass")
local UPFriendQuickTipBase  = require("UPFriendQuickTipBase")
local UPFriendAcceptOrder   = luaclass("UPFriendAcceptOrder", UPFriendQuickTipBase)
local UIUtils = require("UIUtils")
local L10N = require("L10N")
local UISetUtils = require("UISetUtils")

local function OnBtnAccept(self)
    self:Deactivate()
end

local function OnBtnWatch(self)
    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 0.2)
end

function UPFriendAcceptOrder:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnAccept.OnClicked, self, OnBtnAccept)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnWatch.OnClicked, self, OnBtnWatch)
end

function UPFriendAcceptOrder:Activate(tbData)
    UPFriendAcceptOrder.super.Activate(self, tbData)
    local l10nStr = UISetUtils.GetL10NTextByKey("UI_ACCEPT_ORDER")
    l10nStr = L10N:Format(l10nStr, tbData.name)
    self.pWidgetRef.txtAccept:SetText(l10nStr)
end

function UPFriendAcceptOrder:Deactivate()
    UPFriendAcceptOrder.super.Deactivate(self)
end

return UPFriendAcceptOrder