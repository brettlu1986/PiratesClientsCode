-----------------------------------------------------
--File Name    : UPLobbyShopItem.lua
--Author       : zhiyuan
--Create Time  : 2019-07-19
--Description  : 商店的商品UP
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShopItem = luaclass("UPLobbyShopItem", ListItemBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local UITextDef = require("UITextDef")
local ShopSystem = require("ShopSystem")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local ItemDataTable = require("ItemDataTable")
local CurrencySystem = require("CurrencySystem")
local ItemCategoryDef = require("ItemCategoryDef")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

UPLobbyShopItem.tbGoodsData = nil
UPLobbyShopItem.pbLobbyShopDisplayItem = nil
UPLobbyShopItem.bBuyLimit = nil

local ITEM_NAME_FORMAT = UISetUtils.GetL10NTextByKey("ITEM_NAME_FORMAT")
local COLOR_BUY = KMUMGLibrary.GetSlateColorFromHex("93C9E1FF")
local COLOR_FREE = KMUMGLibrary.GetSlateColorFromHex("3F575DFF")

local function OnBuyButtonClicked(self)
    local tbGoodsData = self.tbGoodsData
    local tbGoodsTemplate = tbGoodsData.tbGoodsTemplate
    ShopSystem:OnBuyButtonClick(tbGoodsTemplate)
end

local function GetItemName(nItemTemplateId)
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local l10nName = tbItemTemplate.l10nName

    if tbItemTemplate.nCategory == ItemCategoryDef.SHIP_SKIN then
        local COLOR_TEXT = UITextDef.ITEM_GRADE_COLOR_TEXT[tbItemTemplate.nGrade]
        local tbShipTemplate = ItemDataTable:GetTemplate(tbItemTemplate.nShipItemId)
        l10nName = L10N:Format(ITEM_NAME_FORMAT, COLOR_TEXT, tbItemTemplate.l10nPrefixName, tbShipTemplate.l10nName)
    end
    return l10nName
end

local function RefreshItemBaseInfo(self, nItemTemplateId)

    local tbGoodsData = self.tbGoodsData
    local tbGoodsTemplate = tbGoodsData.tbGoodsTemplate
    self.pbLobbyShopDisplayItem:SetDisplayItemData(nItemTemplateId, tbGoodsTemplate.nId)

    local pWidgetRef = self.pWidgetRef
    local l10nName = GetItemName(nItemTemplateId)
    pWidgetRef.ktxtItemName:SetText(l10nName)

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    LobbyItemUiHelper.SetGradeHalfColorImage(UIResourceDef.ITEM_COLOR_GRADE_HALFBG, pWidgetRef, tbItemTemplate.nGrade)
end

local function IsFreeItem(self)
    local tbGoodsData = self.tbGoodsData
    local tbGoodsTemplate = tbGoodsData.tbGoodsTemplate
    return tbGoodsTemplate.nCurrencyCount1 and tbGoodsTemplate.nCurrencyCount1 == 0
end

local function RefreshOnePrice(self, nCurrencyId, nCount, pWidgetCurrency, pWidgetCount)
    local szCurrencySmallIcon1 = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(pWidgetCurrency, szCurrencySmallIcon1:load())
    pWidgetCount:SetText(nCount)
end

local function RefreshPrice(self, tbGoodsTemplate)
    local pWidgetRef = self.pWidgetRef
    local nCurrencyId1 = tbGoodsTemplate.nCurrencyId1

    local nOriginPrice = ShopSystem:GetCompensationPrice(tbGoodsTemplate, false)
    if not nOriginPrice then
        nOriginPrice = tbGoodsTemplate.nCurrencyCount1
    end

    pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.ktxtFree:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if nOriginPrice == 0 then
        pWidgetRef.hboxPrice:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ktxtFree:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_FREE"))
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnBuy, UIResourceDef.NEW_SHOP_FREE_BTN_IMAGE:load())
        pWidgetRef.ktxtFree:SetColorAndOpacity(COLOR_FREE)
    else
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnBuy, UIResourceDef.NEW_SHOP_BTN_IMAGE:load())
        pWidgetRef.ktxtFree:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_PURCHASE"))
        pWidgetRef.ktxtFree:SetColorAndOpacity(COLOR_BUY)
        RefreshOnePrice(self, nCurrencyId1, nOriginPrice, pWidgetRef.imgCurrency1, pWidgetRef.txtCurrency1)
        if tbGoodsTemplate.bHasSecondCurrencyPrice then
            pWidgetRef.imgCurrency2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtCurrency2:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
            pWidgetRef.txtOr:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

            RefreshOnePrice(self, tbGoodsTemplate.nCurrencyId2, tbGoodsTemplate.nCurrencyCount2, pWidgetRef.imgCurrency2, pWidgetRef.txtCurrency2)
        else
            pWidgetRef.imgCurrency2:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtCurrency2:SetVisibility(ESlateVisibility.Collapsed)
            pWidgetRef.txtOr:SetVisibility(ESlateVisibility.Collapsed)
        end
    end

end

local function RefreshBuyLimit(self, tbGoodsTemplate)
    local pWidgetRef = self.pWidgetRef
    if tbGoodsTemplate.bHasBuyLimit then
        pWidgetRef.ktxtCountLimit:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local nBuyTimes = math.min(tbGoodsTemplate.nBuyLimit, ShopSystem:GetBuyTimes(tbGoodsTemplate.nId))
        local nRemainBuyTimes = tbGoodsTemplate.nBuyLimit - nBuyTimes
        local l10nBuyLimitDesc = L10N:Format(UISetUtils.GetL10NTextByKey("GOODS_BUY_LIMIT"), nBuyTimes, tbGoodsTemplate.nBuyLimit)
        if nRemainBuyTimes <= 0 then
            self.bBuyLimit = true
        else
            self.bBuyLimit = false
        end
        pWidgetRef.ktxtCountLimit:SetText(l10nBuyLimitDesc)
    else
        pWidgetRef.ktxtCountLimit:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshBuyTimeLimit(self, tbGoodsTemplate)
    local pWidgetRef = self.pWidgetRef
    local nRemainDay = ShopSystem:GetRemainBuyDay(tbGoodsTemplate)
    if nRemainDay then
        pWidgetRef.bdrLimitTime:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local l10TimeLimit = L10N:Format(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_LIMIT_DAY"), nRemainDay)
        pWidgetRef.ktxtTimeLimit:SetText(l10TimeLimit)
    else
        pWidgetRef.bdrLimitTime:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshButton(self, tbGoodsTemplate)
    local pWidgetRef = self.pWidgetRef
    if ShopSystem:HasOwned(tbGoodsTemplate.nItemTemplateId) then
        pWidgetRef.ktxtOwned:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxPrice:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.ktxtOwned:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnBuy:SetVisibility(ESlateVisibility.Visible)
        local bFree = IsFreeItem(self)
        local pVisibleState = bFree and ESlateVisibility.Collapsed or ESlateVisibility.SelfHitTestInvisible
        pWidgetRef.hboxPrice:SetVisibility(pVisibleState)
    end
end

local function RefreshDiscount(self, tbGoodsTemplate)
    local pWidgetRef = self.pWidgetRef

    if ShopSystem:HasOwned(tbGoodsTemplate.nItemTemplateId) then
        pWidgetRef.bdrLimitTime:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxOriginPrice:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.bdrCurDiscount:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ktxtFree:SetVisibility(ESlateVisibility.Collapsed)
        return
    end

    if IsFreeItem(self) then
        pWidgetRef.bdrLimitTime:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxOriginPrice:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.bdrCurDiscount:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.ktxtFree:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        return
    end

    local nRemainDiscountDay = ShopSystem:GetRemainDiscountDay(tbGoodsTemplate)
    if nRemainDiscountDay then
        pWidgetRef.bdrLimitTime:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local l10TimeLimit = L10N:Format(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_DISCOUNT_DAY"), nRemainDiscountDay)
        pWidgetRef.ktxtTimeLimit:SetText(l10TimeLimit)

        pWidgetRef.hboxOriginPrice:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local nDiscountPrice = ShopSystem:GetCompensationPrice(tbGoodsTemplate, true)
        if not nDiscountPrice then
            nDiscountPrice = ShopSystem:GetDiscountPrice(tbGoodsTemplate.nId)
        end
        RefreshOnePrice(self, tbGoodsTemplate.nDiscountCurrencyId, nDiscountPrice, pWidgetRef.imgCurrency1, pWidgetRef.txtCurrency1)

        --计算原价，可能是补了差价的原价
        local nOriginPrice = ShopSystem:GetCompensationPrice(tbGoodsTemplate, false)
        if not nOriginPrice then
            nOriginPrice = tbGoodsTemplate.nCurrencyCount1
        end

        local l10OriginPrice = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_SHOP_ORIGIN_PRICE"), nOriginPrice)
        pWidgetRef.txtOriginCurrency:SetText(l10OriginPrice)

        pWidgetRef.bdrCurDiscount:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local pre, num = math.modf(tbGoodsTemplate.nDiscountRate * 10)
        local nDiscount = num == 0 and pre or tbGoodsTemplate.nDiscountRate * 10
        local l10Discount = L10N:Format(UISetUtils.GetL10NTextByKey("SHOP_DISCOUNT"), nDiscount)
        pWidgetRef.txtCurDiscount:SetText(l10Discount)
    else
        pWidgetRef.bdrLimitTime:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxOriginPrice:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.bdrCurDiscount:SetVisibility(ESlateVisibility.Collapsed)

    end
end

local function Refresh(self)
    local tbGoodsData = self.tbGoodsData
    local tbGoodsTemplate = tbGoodsData.tbGoodsTemplate
    local nItemTemplateId = tbGoodsTemplate.nItemTemplateId
    RefreshItemBaseInfo(self, nItemTemplateId)
    RefreshPrice(self, tbGoodsTemplate)
    RefreshBuyLimit(self, tbGoodsTemplate)
    RefreshBuyTimeLimit(self, tbGoodsTemplate)
    RefreshButton(self, tbGoodsTemplate)
    RefreshDiscount(self, tbGoodsTemplate)
end

function UPLobbyShopItem:OnRefresh(tbGoodsData)
    self.tbGoodsData = tbGoodsData
    Refresh(self)
end

function UPLobbyShopItem:OnLoad()
    self.pbLobbyShopDisplayItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItemNew, UIDef.UP_LOBBY_SHOP_DISPLAY_ITEMNEW)
    self.pbLobbyShopDisplayItem:SetOnlyTip(false)
end

function UPLobbyShopItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnBuy.OnClicked, self, OnBuyButtonClicked)
end

return UPLobbyShopItem
