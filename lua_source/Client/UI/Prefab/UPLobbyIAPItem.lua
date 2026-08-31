-----------------------------------------------------
--File Name    : UPLobbyIAPItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-07-22
--Description  : 商店充值页面Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyIAPItem = luaclass("UPLobbyIAPItem", ListItemBase)

local L10N = require("L10N")
local UIUtils = require("UIUtils")
local IAPSystem = require("IAPSystem")
local UISetUtils = require("UISetUtils")

local function OnClickedBtnPurchase(self)
    if IAPSystem:IsIAPEnabled() then
        IAPSystem:RequestPurchase(self.tbData.nId)
    else
        UIUtils.ShowToastWithKey("FFA_FUNCTION_NOT_OPEN")
    end
end

function UPLobbyIAPItem:OnRefresh(tbData)
    local tbTemplate = tbData
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtItemName:SetText(tbTemplate.l10nDisplayName)
    pWidgetRef.txtItemPrice:SetText(tbTemplate.l10nDisplayPrice)
    local pIconRes = tbTemplate.szIconRes:load()
    if pIconRes then
        UISetUtils.SetImageBrushRes(pWidgetRef.imgItemIcon, pIconRes, true)
    end
    if tbTemplate.nDisplayGiftCount > 0 then
        pWidgetRef.ovlTips:SetVisibility(ESlateVisibility.HitTestInvisible)

        local l10nTipsFormat = UISetUtils.GetL10NTextByKey("IAP_GIFT_TIPS_FORMAT_TEXT")
        local l10nTips = L10N:Format(l10nTipsFormat, tbTemplate.nDisplayGiftCount)
        pWidgetRef.rtxtTips:SetText(l10nTips)
    else
        pWidgetRef.ovlTips:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPLobbyIAPItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPurchase.OnClicked, self, OnClickedBtnPurchase)
end

return UPLobbyIAPItem