-----------------------------------------------------
--File Name    : UILobbyShopGiftBoxPurchase.lua
--Author       : lzheng
--Create Time  : 2019-10-08
--Description  : 商城礼包购买提示框
-----------------------------------------------------
local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILobbyShopGiftBoxPurchase = luaclass("UILobbyShopGiftBoxPurchase", WndBase)

local ItemSystem = require("ItemSystem")
local ShopSystem = require("ShopSystem")
local MathUtil = require("MathUtil")
local UISetUtils = require("UISetUtils")
local CurrencySystem = require("CurrencySystem")
local UIResourceDef = require("UIResourceDef")
local ShopDataTable = require("ShopDataTable")
local LobbyItemIni = require("LobbyItemIni")
local UIUtils = require("UIUtils")
local CurrencyIni = require("CurrencyIni")
local ClientEventDef = require("ClientEventDef")
local SelfListHelperNew = require("SelfListHelperNew")
local CostCurrencyHelper = require("CostCurrencyHelper")

UILobbyShopGiftBoxPurchase.nMaxChooseCount = nil
UILobbyShopGiftBoxPurchase.nCurrentCount = nil
UILobbyShopGiftBoxPurchase.nStepSize = nil

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId
local EXCHANGED_ID = CurrencyIni.tbExchange.nExchangedId
local DEFAULT_ITEM_COUNT = 1

local function IsMeetCantBuyCondition(self)
    local tbGoodsTemplate = self.tbGoodsTemplate
    if tbGoodsTemplate.bHasBuyLimit then
        local nBuyTimes = math.min(tbGoodsTemplate.nBuyLimit, ShopSystem:GetBuyTimes(tbGoodsTemplate.nId))
        local nRemainBuyTimes = tbGoodsTemplate.nBuyLimit - nBuyTimes
        return nRemainBuyTimes <= 0
    end
    return false
end

local function ShowTotalCost(self)
    local tbGoodsTemplate = self.tbGoodsTemplate
    local nCurrencyId = tbGoodsTemplate.nCurrencyId1

    local nCurrencyPrice = ShopSystem:GetCompensationPrice(tbGoodsTemplate, true)
    if not nCurrencyPrice then
        nCurrencyPrice = ShopSystem:GetValidDiscountPrice(nCurrencyId, tbGoodsTemplate)
    end
    if not nCurrencyPrice then
        nCurrencyPrice = tbGoodsTemplate.nCurrencyCount1
    end

    local nTotalCost = nCurrencyPrice * self.nCurrentCount

    local pWidgetRef = self.pWidgetRef
    if nTotalCost == 0 then
        if IsMeetCantBuyCondition(self) then
            pWidgetRef.txtFree2:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.hboxTotalMoney:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef.hboxTotalMoney:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtFree2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    else
        pWidgetRef.txtFree2:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxTotalMoney:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local nCurrencyCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
        local bEnough = nCurrencyCount >= nTotalCost
        local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
        pWidgetRef.txtTotalMoney:SetText(nTotalCost)
        pWidgetRef.txtTotalMoney:SetColorAndOpacity(bEnough and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgTotalCurrency, szCurrencySmallIcon:load())
    end
end

local function SetChooseCount(self, nCount)
    local nCurrentMaxCount = self.nMaxChooseCount
    local nCurrentCount = MathUtil.Clamp(nCount, 1, nCurrentMaxCount)
    local nPercent = nCurrentMaxCount == 0 and 0 or nCurrentCount / nCurrentMaxCount
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbCount:SetPercent(nPercent)
    pWidgetRef.sldrCount:SetValue(nPercent)

    local szChooseCount = nCurrentCount .."/".. self.nMaxChooseCount
    self.pWidgetRef.txtChooseCount:SetText(szChooseCount)

    self.nCurrentCount = nCurrentCount

    ShowTotalCost(self)
end

local function OnClickedBtnAdd(self)
    if IsMeetCantBuyCondition(self) then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_CANNOT_BUY_COUNT_LIMIT"))
        return
    end

    if self.nCurrentCount < self.nMaxChooseCount then
        SetChooseCount(self, self.nCurrentCount + 1)
    end
end

local function OnClickedBtnMinus(self)
    if IsMeetCantBuyCondition(self) then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_CANNOT_BUY_COUNT_LIMIT"))
        return
    end
    SetChooseCount(self, self.nCurrentCount - 1)
end

local function OnSldrCountValueChanged(self, nValue)
    if IsMeetCantBuyCondition(self) then
        self.pWidgetRef.sldrCount:SetValue(0)
        return
    end

    local nCount = MathUtil.Round(nValue / self.nStepSize)
    SetChooseCount(self, nCount)
end

local function SetChooseMaxAndStepSize(self)
    self.nMaxChooseCount = LobbyItemIni.tbItemUse.nUseMax
    local tbItemTemplate = self.tbItemTemplate
    local nItemTemplateId = tbItemTemplate.nId
    if tbItemTemplate.bHasHoldLimit then
        local nHoldLimit = tbItemTemplate.nHoldLimit
        local nItemCount = ItemSystem:GetItemCount(nItemTemplateId)
        local nRemainItemLimit = math.max(0, nHoldLimit - nItemCount)
        if nRemainItemLimit < self.nMaxChooseCount then
            self.nMaxChooseCount = nRemainItemLimit
        end
    end
    local tbGoodsTemplate = self.tbGoodsTemplate
    if tbGoodsTemplate.bHasBuyLimit then
        local nBuyTimes = ShopSystem:GetBuyTimes(tbGoodsTemplate.nId)
        local nRemainBuyTimes = math.max(0, tbGoodsTemplate.nBuyLimit - nBuyTimes)
        if nRemainBuyTimes < self.nMaxChooseCount then
            self.nMaxChooseCount = nRemainBuyTimes
        end
    end

    self.nStepSize = 1 / self.nMaxChooseCount
    self.pWidgetRef.sldrCount:SetStepSize(self.nStepSize)
end

local function RequestGoShopping(nGoodsId, nCount, nCurrencyId, bAutoExchange)
    ShopSystem:RequestGoShopping(nGoodsId, nCount, nCurrencyId, bAutoExchange)
end

local function OnClickBuyButton(self, nCurrencyId, nCurrencyPrice)

    local tbGoodsTemplate = self.tbGoodsTemplate
    local nCurrentPrice = ShopSystem:GetCompensationPrice(tbGoodsTemplate, true)
    if not nCurrentPrice then
        nCurrentPrice = ShopSystem:GetValidDiscountPrice(nCurrencyId, tbGoodsTemplate)
    end
    if not nCurrentPrice then
        nCurrentPrice = nCurrencyPrice
    end

    local nBuyCount = self.nCurrentCount and self.nCurrentCount or DEFAULT_ITEM_COUNT
    local nTotalCost = nBuyCount * nCurrentPrice

    local firstRequest = function ()
        RequestGoShopping(tbGoodsTemplate.nId, nBuyCount, nCurrencyId, false)
    end

    local secondRequest = nil
    if nCurrencyId == UNEXCHANGED_ID then
        secondRequest = function ()
            RequestGoShopping(tbGoodsTemplate.nId, nBuyCount, EXCHANGED_ID, true)
        end
    end
    CostCurrencyHelper:SetData(nCurrencyId, nTotalCost, firstRequest, secondRequest, UISetUtils.GetL10NTextByKey("SHOP_CURRENCY_NOT_ENOUGH"))
    CostCurrencyHelper:FirstRequest()
end

local function OnClickBuy(self)
    if IsMeetCantBuyCondition(self) then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_CANNOT_BUY_COUNT_LIMIT"))
        return
    end

    local tbGoodsTemplate = self.tbGoodsTemplate
    OnClickBuyButton(self, tbGoodsTemplate.nCurrencyId1, tbGoodsTemplate.nCurrencyCount1)
end

local function OnGoShoppingSuccess(self, nGoodsId)
    if nGoodsId == self.tbGoodsTemplate.nId then
        self:CloseSelf()
    end
end

function UILobbyShopGiftBoxPurchase:OnLoad()

    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetDialogClosedCallback(self.CloseSelf, self)
    self.pbDialogFrame:SetCloseButtonVisible(true)

    self.ListHelper = SelfListHelperNew()
    self.ListHelper:Init(self, self.pWidgetRef.listItems)

    local nItemTemplateId = self.tbOpenArgs.nItemTemplateId
    local tbAwardItems = ShopSystem:GetGiftBoxItems(nItemTemplateId)
    self.ListHelper:SetData(tbAwardItems)
    self.ListHelper:ScrollToTopLeft(false)
    -- logdebug("init goods template", nItemTemplateId, nGoodsId)
end

function UILobbyShopGiftBoxPurchase:OnUnload()
    self.ListHelper:Uninit()
    self.ListHelper = nil
end

function UILobbyShopGiftBoxPurchase:OnShow()
    local nItemTemplateId = self.tbOpenArgs.nItemTemplateId
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    self.pWidgetRef.txtIntro:SetText(tbItemTemplate.l10nIntro)

    local nGoodsId = self.tbOpenArgs.nGoodsId
    self.tbGoodsTemplate = ShopDataTable:GetTemplate(nGoodsId)
    self.tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)

    self.pbDialogFrame:ShowDialog()
    SetChooseMaxAndStepSize(self)
    SetChooseCount(self, DEFAULT_ITEM_COUNT)
end

function UILobbyShopGiftBoxPurchase:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedBtnAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrCount.OnValueChanged, self, OnSldrCountValueChanged)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnConfirm.OnClicked, self, OnClickBuy)

    EventHelper:RegisterEvent(ClientEventDef.EV_GO_SHOPPING_SUCCESS, self, OnGoShoppingSuccess)
end

return UILobbyShopGiftBoxPurchase
