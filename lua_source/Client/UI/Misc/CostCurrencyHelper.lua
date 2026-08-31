local CostCurrencyHelper = {}

local L10N = require("L10N")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local IAPSystem = require("IAPSystem")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local CurrencyIni = require("CurrencyIni")
local CurrencySystem = require("CurrencySystem")

CostCurrencyHelper.nCurrencyId = nil
CostCurrencyHelper.nPrice = nil
CostCurrencyHelper.nBuyCount = nil
CostCurrencyHelper.costCallback = nil
CostCurrencyHelper.secondCostCallback = nil

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId
local EXCHANGED_ID = CurrencyIni.tbExchange.nExchangedId
local EXCHANGE_RATIO = CurrencyIni.tbExchange.nExchangeRatio

local function ShowCurrencyNotEnoughToast(self, nCurrencyId)
    UIUtils.ShowToast(L10N:Format(self.l10nFailedMsgFormat, CurrencySystem:GetCurrencyName(nCurrencyId)))
end

local function RequestSecondCurrencyGoShopping(self)
    if self.secondCostCallback then
        self.secondCostCallback()
        UIUtils.ShowWaitingPacket()
    end
end

local function OpenIapWnd()
    UIManager:OpenWnd(UIDef.UI_LOBBY_IAP)
end

local function ShowIfGoToIAPDialog()
    local l10nTitle = UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_GO_TO_IAP_TITLE")
    local Dialog = UIUtils.CreateDialog(l10nTitle)
    local l10nDescFormat = UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_GO_TO_IAP_DESC")
    local l10nDesc = L10N:Format(l10nDescFormat, CurrencySystem:GetCurrencyName(EXCHANGED_ID))
    Dialog:SetMessage(l10nDesc)
    Dialog:SetPositiveButtonCallback(OpenIapWnd)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetNegativeButtonVisible(true)
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
end

local function ChangeToSecondCurrency(self)
    local l10nTitle = UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_CHANGE_CURRENCY_TITLE")
    local Dialog = UIUtils.CreateDialog(l10nTitle)
    local l10nDescFormat = UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_CHANGE_CURRENCY_DESC")
    local nCostAfterExchange = self.nCost // EXCHANGE_RATIO
    local l10nDesc = L10N:Format(l10nDescFormat, CurrencySystem:GetCurrencyName(UNEXCHANGED_ID), nCostAfterExchange, CurrencySystem:GetCurrencyName(EXCHANGED_ID))

    local function ConfirmChange()
        RequestSecondCurrencyGoShopping(self)
    end

    Dialog:SetMessage(l10nDesc)
    Dialog:SetPositiveButtonCallback(ConfirmChange)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetNegativeButtonVisible(true)
    Dialog:SetCloseButtonVisible(false)
    Dialog:ShowDialog()
end

function CostCurrencyHelper:SetData(nCurrencyId, nCost, costCallback, secondCostCallback, l10nFailedMsgFormat)
    self.nCurrencyId = nCurrencyId
    self.nCost = nCost
    self.costCallback = costCallback
    self.secondCostCallback = secondCostCallback
    self.l10nFailedMsgFormat = l10nFailedMsgFormat
end

function CostCurrencyHelper:FirstRequest()
    if self.costCallback then
        self.costCallback()
        UIUtils.ShowWaitingPacket()
    end
end

function CostCurrencyHelper:SecondCostFailed()
    if IAPSystem:IsIAPEnabled() then
        ShowIfGoToIAPDialog()
    else
        ShowCurrencyNotEnoughToast(self, EXCHANGED_ID)
    end
end

function CostCurrencyHelper:FirstCostFailed()
    if self.nCurrencyId == UNEXCHANGED_ID then
        ChangeToSecondCurrency(self)
    else
        ShowCurrencyNotEnoughToast(self, self.nCurrencyId)
    end
end

function CostCurrencyHelper:FinishRequest()
    UIUtils.HideWaitingPacket()
end

return CostCurrencyHelper