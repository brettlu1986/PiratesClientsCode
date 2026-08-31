-----------------------------------------------------
--File Name    : UILobbyShopItemPurchase.lua
--Description  : 商城物品购买弹窗
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyShopItemPurchase = luaclass("UILobbyShopItemPurchase", WndBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local MathUtil = require("MathUtil")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ShopSystem = require("ShopSystem")
local AwardSystem = require("AwardSystem")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local ItemCategoryDef = require("ItemCategoryDef")
local AwardSessionType = require("AwardSessionType")
local ItemResDataTable = require("ItemResDataTable")
local ItemDataTable = require("ItemDataTable")
local LobbyItemIni = require("LobbyItemIni")
local CurrencyIni = require("CurrencyIni")
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local CostCurrencyHelper = require("CostCurrencyHelper")
local UITextDef = require("UITextDef")

UILobbyShopItemPurchase.pbLobbyDisplayItem = nil
UILobbyShopItemPurchase.pbFashionItem = nil
UILobbyShopItemPurchase.nMaxChooseCount = nil
UILobbyShopItemPurchase.nCurrentCount = nil
UILobbyShopItemPurchase.nStepSize = nil
UILobbyShopItemPurchase.szSourceWndName = nil
UILobbyShopItemPurchase.nTypeMode = nil

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId
local EXCHANGED_ID = CurrencyIni.tbExchange.nExchangedId
local DEFAULT_ITEM_COUNT = 1

local WND_MODE_DEF = {
    ["Common"] = 1,
    ["Human"] = 2,
    ["Ship"] = 3,
}

local INDEX_TO_MODE_KEY = {
    [1] = "Common",
    [2] = "Human",
    [3] = "Ship",
}

local L10N_LOBBY_SHIP_PURCHASE_BUTTON_FORMAT = UISetUtils.GetL10NTextByKey("LOBBY_SHIP_PURCHASE_BUTTON_FORMAT")

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
        pWidgetRef.hBoxPrice:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.hBoxPrice:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local nCurrencyCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
        local bEnough = nCurrencyCount >= nTotalCost
        local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
        pWidgetRef.txtPriceCommon1:SetText(nTotalCost)
        pWidgetRef.txtPriceCommon1:SetColorAndOpacity(bEnough and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrencyCommon1, szCurrencySmallIcon:load())
    end
end

local function SetChooseCount(self, nCount)
    local nCurrentMaxCount = self.nMaxChooseCount
    local nCurrentCount = MathUtil.Clamp(nCount, 1, nCurrentMaxCount)
    local nPercent = nCurrentCount / nCurrentMaxCount
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pgbCount:SetPercent(nPercent)
    pWidgetRef.sldrCount:SetValue(nPercent)

    local szChooseCount = nCurrentCount .."/".. self.nMaxChooseCount
    self.pWidgetRef.txtChooseCount:SetText(szChooseCount)

    self.nCurrentCount = nCurrentCount

    ShowTotalCost(self)
end

local function OnClickedBtnAdd(self)
    if self.nCurrentCount < self.nMaxChooseCount then
        SetChooseCount(self, self.nCurrentCount + 1)
    end
end

local function OnClickedBtnMinus(self)
    SetChooseCount(self, self.nCurrentCount - 1)
end

local function OnSldrCountValueChanged(self, nValue)
    local nCount = MathUtil.Round(nValue / self.nStepSize)
    SetChooseCount(self, nCount)
end

local function RequestGoShopping(nGoodsId, nCount, nCurrencyId, bAutoExchange, szSourceWndName)
    if szSourceWndName then
        AwardSystem:StartSession(AwardSessionType.BuyAwardSession, {nGoodsId = nGoodsId, nCount = nCount, szSourceWndName = szSourceWndName})
    end
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
        RequestGoShopping(tbGoodsTemplate.nId, nBuyCount, nCurrencyId, false, self.szSourceWndName)
    end

    local secondRequest = nil
    if nCurrencyId == UNEXCHANGED_ID then
        secondRequest = function ()
            RequestGoShopping(tbGoodsTemplate.nId, nBuyCount, EXCHANGED_ID, true, self.szSourceWndName)
        end
    end
    CostCurrencyHelper:SetData(nCurrencyId, nTotalCost, firstRequest, secondRequest, UISetUtils.GetL10NTextByKey("SHOP_CURRENCY_NOT_ENOUGH"))
    CostCurrencyHelper:FirstRequest()
end

local function OnClickedNegativeButton(self)
    local tbGoodsTemplate = self.tbGoodsTemplate
    if self.nTypeMode == "Human" then  
        self.pbDialogFrame:HideDialog()
    end
    OnClickBuyButton(self, tbGoodsTemplate.nCurrencyId2, tbGoodsTemplate.nCurrencyCount2)
end

local function OnClickedPositiveButton(self)
    local tbGoodsTemplate = self.tbGoodsTemplate
    if self.nTypeMode == "Human" then  
        self.pbDialogFrame:HideDialog()
    end
    OnClickBuyButton(self, tbGoodsTemplate.nCurrencyId1, tbGoodsTemplate.nCurrencyCount1)
end

local function UpdateFirstCurrencyInfo(self, szMode)
    local pWidgetRef = self.pWidgetRef
    local tbGoodsTemplate = self.tbGoodsTemplate
    local nCurrencyId1 = tbGoodsTemplate.nCurrencyId1
    local nCurrencyPrice1 = tbGoodsTemplate.nCurrencyCount1
    local pPrice = pWidgetRef["txtPrice" .. szMode .. 1]

    local nCurrencyPrice = ShopSystem:GetCompensationPrice(tbGoodsTemplate, true)
    if not nCurrencyPrice then
        nCurrencyPrice = ShopSystem:GetValidDiscountPrice(nCurrencyId1, tbGoodsTemplate)
    end
    if not nCurrencyPrice then
        nCurrencyPrice = nCurrencyPrice1
    end
    

    local l10nButtonFormat = L10N_LOBBY_SHIP_PURCHASE_BUTTON_FORMAT

    local nCurrencyCount1 = CurrencySystem:GetCurrencyCount(nCurrencyId1)
    local bEnough1 = nCurrencyCount1 >= nCurrencyPrice
    local szCurrencySmallIcon1 = CurrencySystem:GetCurrencySmallIcon(nCurrencyId1)
    local szCurrencyName = CurrencySystem:GetCurrencyName(nCurrencyId1)
    local l10nBtnText = L10N:Format(l10nButtonFormat, szCurrencyName)
    self.pbDialogFrame:SetPositiveText(l10nBtnText)
    if pPrice then
        if nCurrencyPrice == 0 then 
            pPrice:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_FREE"))
            pWidgetRef["imgCurrency" .. szMode .. 1]:SetVisibility(ESlateVisibility.Collapsed)
        else  
            pPrice:SetText(nCurrencyPrice)
        end
    end
    pPrice:SetColorAndOpacity(bEnough1 and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
    UISetUtils.SetImageBrushRes(pWidgetRef["imgCurrency" .. szMode .. 1], szCurrencySmallIcon1:load())
end

local function UpdateSecondCurrencyInfo(self, szMode)
    local pWidgetRef = self.pWidgetRef
    local tbGoodsTemplate = self.tbGoodsTemplate
    local pPrice = pWidgetRef["txtPrice" .. szMode .. 2]
    -- local pWealth = pWidgetRef["txtWealth" .. szMode .. 2]

    if tbGoodsTemplate.bHasSecondCurrencyPrice then
        local nCurrencyId2 = tbGoodsTemplate.nCurrencyId2
        local nCurrencyPrice2 = tbGoodsTemplate.nCurrencyCount2

        --补偿只存在宝箱，宝箱只计算第一个Currency, 不会计算第二个 Currency
        local nCurrencyPrice = ShopSystem:GetValidDiscountPrice(nCurrencyId2, tbGoodsTemplate)
        if not nCurrencyPrice then
            nCurrencyPrice = nCurrencyPrice2
        end

        local nCurrencyCount2 = CurrencySystem:GetCurrencyCount(nCurrencyId2)
        local bEnough2 = nCurrencyCount2 >= nCurrencyPrice

        local l10nButtonFormat = L10N_LOBBY_SHIP_PURCHASE_BUTTON_FORMAT
        local szCurrencySmallIcon2 = CurrencySystem:GetCurrencySmallIcon(nCurrencyId2)
        local l10nBtnText = L10N:Format(l10nButtonFormat, CurrencySystem:GetCurrencyName(nCurrencyId2))
        self.pbDialogFrame:SetNegativeText(l10nBtnText)
        if pPrice then
            pPrice:SetText(nCurrencyPrice)
            pPrice:SetColorAndOpacity(bEnough2 and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
            UISetUtils.SetImageBrushRes(pWidgetRef["imgCurrency" .. szMode .. 2], szCurrencySmallIcon2:load())
        end
    else
        pWidgetRef["hBoxSecondPrice" .. szMode]:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.pbDialogFrame:SetNegativeButtonVisible(tbGoodsTemplate.bHasSecondCurrencyPrice)
end

local function SetChooseMaxAndStepSize(self)
    self.nMaxChooseCount = LobbyItemIni.tbItemUse.nUseMax
    local tbItemTemplate = self.tbItemTemplate
    local nItemTemplateId = tbItemTemplate.nId
    local nItemCount = ItemSystem:GetItemCount(nItemTemplateId)
    local l10nStackCount = L10N:Format(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_PURCHASE_ITEM_STACK_COUNT"), nItemCount)
    self.pWidgetRef.txtStackCount:SetText(l10nStackCount)

    if tbItemTemplate.bHasHoldLimit then
        local nHoldLimit = tbItemTemplate.nHoldLimit
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

    SetChooseCount(self, 1)
end

local function UpdateHumanItem(self)
    local pbFashionItem = self.pbFashionItem
    local tbItemTemplate = self.tbItemTemplate
    local szIcon = tbItemTemplate.szDefaultFashionIcon  -- 武器
    if tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
        local tbData = {}
        tbData.tbItemTemplateIds = tbItemTemplate.tbSubItemTemplateIds
        tbData.l10nTitle = L10N:Format(UITextDef.LOBBY_SHOP_SUIT_TITLE, tbItemTemplate.l10nName)
        self.pbSuit:Display(tbData)
        self.pbSuit.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        pbFashionItem.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    elseif tbItemTemplate.nCategory == ItemCategoryDef.FASHION
    or tbItemTemplate.nCategory == ItemCategoryDef.DECORATION
    or tbItemTemplate.nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        local tbResTemplate = ItemResDataTable:GetTemplate(tbItemTemplate.nResId)
        szIcon = tbResTemplate.szIconPath
        local tbData = {
            tbTemplate = tbItemTemplate,
            nTemplateId = tbItemTemplate.nId,
            l10nFirstName = tbItemTemplate.l10nName,
            szIcon = szIcon,
            nGrade = tbItemTemplate.nGrade,
            bOwned = true,
        }
        pbFashionItem:Display(tbData)
        pbFashionItem.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
        self.pbSuit.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    end
end

local function UpdateShipItem(self)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = self.tbItemTemplate
    local szImgRes = nil
    local l10nName = tbTemplate.l10nName

    local tbItemRes = ItemDataTable:GetResTemplate(tbTemplate.nId)
    szImgRes = tbItemRes.szIconPath

    LobbyItemUiHelper.SetGradeHalfColorImage(UIResourceDef.ITEM_COLOR_GRADE_SMALL_HALFBG, pWidgetRef, tbTemplate.nGrade)

    pWidgetRef.txtSpecialItemName:SetText(l10nName)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgSpecialItemIcon, szImgRes:load())
end

local function UpdateStyleForCommonItem(self)
    local pWidgetRef = self.pWidgetRef
    local pbLobbyItem = pWidgetRef.pbLobbyItem
    local tbItemTemplate = self.tbItemTemplate

    self.pbLobbyDisplayItem = self.PrefabHelper:BindPrefab(pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
    self.pbLobbyDisplayItem:SetDisplayItemData(tbItemTemplate.nId, nil, false)

    local tbGoodsTemplate = self.tbGoodsTemplate
    if tbGoodsTemplate.bHasBuyLimit then
        pWidgetRef.txtChooseCountTitle:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_PURCHASE_LIMIT_COUNT"))
    else
        pWidgetRef.txtChooseCountTitle:SetText(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_PURCHASE_COUNT"))
    end

    pWidgetRef.txtName:SetText(tbItemTemplate.l10nName)

    SetChooseMaxAndStepSize(self)
end

local function SwitchWndMode(self, nMode)
    local pWidgetRef = self.pWidgetRef
    if nMode == WND_MODE_DEF.Common then
        
        --[[
            商品购买 Common
        ]]
        UpdateStyleForCommonItem(self)
        pWidgetRef.vBoxItemPurchase:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.hBoxPrice:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    elseif nMode == WND_MODE_DEF.Human then
        --[[
            时装/武器/饰品购买 Human
        ]]
        UpdateHumanItem(self)
        pWidgetRef.cvsHumanItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    elseif nMode == WND_MODE_DEF.Ship then
        --[[
            舰船/火炮购买 Ship
            TODO: 旧版舰船界面不用之后，将图标资源改回引用ship_res.tab
        ]]
        UpdateShipItem(self)
        pWidgetRef.cvsShipItem:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

function UILobbyShopItemPurchase:OnLoad()
    self.pbDialogFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbDialogFrame)
    self.pbDialogFrame:SetPositiveButtonCallback(OnClickedPositiveButton, self)
    self.pbDialogFrame:SetNegativeButtonCallback(OnClickedNegativeButton, self)
    self.pbDialogFrame:SetDialogClosedCallback(self.CloseSelf, self)
    self.pbDialogFrame:SetCloseButtonVisible(true)
    self.pbFashionItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbFashionItem)
    self.pbSuit = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbSuit)
end

function UILobbyShopItemPurchase:OnShow()
    local tbGoodsTemplate = self.tbOpenArgs.tbGoodsTemplate
    self.szSourceWndName = self.tbOpenArgs.szSourceWndName
    self.tbGoodsTemplate = tbGoodsTemplate
    local nItemTemplateId = tbGoodsTemplate.nItemTemplateId
    self.tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if self.tbItemTemplate then
        local nMode = WND_MODE_DEF.Common
        local nCategory = self.tbItemTemplate.nCategory

        if nCategory == ItemCategoryDef.SHIP
        or nCategory == ItemCategoryDef.SHIP_SKIN
        or nCategory == ItemCategoryDef.SHIP_WEAPON
        or nCategory == ItemCategoryDef.SHIP_PART then
            nMode = WND_MODE_DEF.Ship
        elseif nCategory == ItemCategoryDef.FASHION
            or nCategory == ItemCategoryDef.DECORATION
            or nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION
            or nCategory == ItemCategoryDef.SUIT then
            nMode = WND_MODE_DEF.Human
        end
        self.nTypeMode = nMode

        local tbCategoryInfo = ItemDataTable.tbCategoryInfoTable[self.tbItemTemplate.nCategory]
        local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("UI_LOBBY_SHOP_ITEM_PURCHASE_TITLE_FORMAT"), tbCategoryInfo.szCategoryName)
        self.pbDialogFrame:SetTitle(l10nTitle)

        SwitchWndMode(self, nMode)

        UpdateFirstCurrencyInfo(self, INDEX_TO_MODE_KEY[nMode])
        UpdateSecondCurrencyInfo(self, INDEX_TO_MODE_KEY[nMode])

        self.pbDialogFrame:ShowDialog()
    else
        logerror("tbItemTemplate is nil")
    end
end

function UILobbyShopItemPurchase:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAdd.OnClicked, self, OnClickedBtnAdd)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrCount.OnValueChanged, self, OnSldrCountValueChanged)
end


return UILobbyShopItemPurchase