-----------------------------------------------------
--File Name    : ULLobbyShipPartDetail.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-23
--Description  : 舰船备战零件分页详情逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipPartDetail = luaclass("ULLobbyShipPartDetail", UILogicBase)

local UISetUtils = require("UISetUtils")
local ShopSystem = require("ShopSystem")
local UIResourceDef = require("UIResourceDef")
local ShopDataTable = require("ShopDataTable")
local CurrencySystem = require("CurrencySystem")
local ItemSourceDataTable = require("ItemSourceDataTable")
local BattleItemDataTable = require("BattleItemDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local TAB_INDEX_EMPTY   = 0
local TAB_INDEX_DETAIL  = 1

local BUTTON_TYPE_NULL = 0
local BUTTON_TYPE_EQUIP = 1
local BUTTON_TYPE_PURCHASE = 2

ULLobbyShipPartDetail.tbTemplate = nil
ULLobbyShipPartDetail.tbDetailMaterialsItem = nil
ULLobbyShipPartDetail.nButtonType = BUTTON_TYPE_NULL

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function ShowPurchaseDialog(self)
    local tbTemplate = self.tbTemplate
    local nItemTemplateId = tbTemplate.nId
    local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
    if tbGoodsTemplate then
        ShopSystem:OnBuyButtonClick(tbGoodsTemplate)
    end
end

-- 点击启用武器按钮
local function OnClickedBtnActivate(self)
    local nButtonType = self.nButtonType
    if nButtonType == BUTTON_TYPE_NULL then
        logerror("OnClickedBtnActivate button type is BUTTON_TYPE_NULL!")
        return
    end
    if not self.tbTemplate then
        logerror("OnClickedBtnActivate tbTemplate is nil!")
        return
    end
    if nButtonType == BUTTON_TYPE_EQUIP then
        GetPreparationComponent():RequestActivatePart(self.tbTemplate.nId)
    elseif nButtonType == BUTTON_TYPE_PURCHASE then
        ShowPurchaseDialog(self)
    end
end

function ULLobbyShipPartDetail:OnLoad()
    self.tbDetailMaterialsItem = {}
    for i = 1, 3 do
        self.tbDetailMaterialsItem[i] = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbDetailMaterials_"..i])
    end
end

function ULLobbyShipPartDetail:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnActivate.OnClicked, self, OnClickedBtnActivate)
end

function ULLobbyShipPartDetail:SetPartTemplate(tbTemplate)
    self.tbTemplate = tbTemplate
    if tbTemplate then
        self.pWidgetRef.txtDetailName:SetText(tbTemplate.l10nName)
        for i, nTemplateId in ipairs(tbTemplate.tbBattleItemIdList) do
            self.tbDetailMaterialsItem[i]:SetBuildId(nTemplateId)
            local tbBattleTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
            self.pWidgetRef["txtDetailDesc_"..i]:SetText(tbBattleTemplate.l10nDesc)
        end
        self:RefreshBtnActivateState()
        self.pWidgetRef.wsRightContent:SetActiveWidgetIndex(TAB_INDEX_DETAIL)
    else
        self.pWidgetRef.wsRightContent:SetActiveWidgetIndex(TAB_INDEX_EMPTY)
    end
end

local function ShowUnlockState(self, nActivePartId, nPartId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnActivate:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtLocked:SetVisibility(ESlateVisibility.Collapsed)
    if nActivePartId == nPartId then
        pWidgetRef.txtActivate:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ACTIVATED"))
        pWidgetRef.btnActivate:SetIsEnabled(false)
        self.nButtonType = BUTTON_TYPE_NULL
    else
        pWidgetRef.txtActivate:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ACTIVATE"))
        pWidgetRef.btnActivate:SetIsEnabled(true)
        self.nButtonType = BUTTON_TYPE_EQUIP
    end
end

local function ShowPrice(self, tbGoodsTemplate, nIndex)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef["imgCurrency"..nIndex]:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef["txtPrice"..nIndex]:SetVisibility(ESlateVisibility.HitTestInvisible)
    local nCurrencyId = tbGoodsTemplate["nCurrencyId"..nIndex]
    local nCurrencyPrice = tbGoodsTemplate["nCurrencyCount"..nIndex]
    local nCurrencyCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
    local bEnough = nCurrencyCount >= nCurrencyPrice
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    pWidgetRef["txtPrice"..nIndex]:SetText(nCurrencyPrice)
    pWidgetRef["txtPrice"..nIndex]:SetColorAndOpacity(bEnough and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
    UISetUtils.SetImageBrushRes(pWidgetRef["imgCurrency"..nIndex], szCurrencySmallIcon:load())
end

local function ShowBuyState(self, nItemTemplateId)
    local pWidgetRef = self.pWidgetRef
    self.nButtonType = BUTTON_TYPE_PURCHASE
    pWidgetRef.btnActivate:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.btnActivate:SetIsEnabled(true)
    pWidgetRef.txtActivate:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_PURCHASE"))
    pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.txtLocked:SetVisibility(ESlateVisibility.Collapsed)

    local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
    if not tbGoodsTemplate then
        pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.btnActivate:SetVisibility(ESlateVisibility.Collapsed)
        logerror("Cannot find item price!", nItemTemplateId)
        return
    end

    ShowPrice(self, tbGoodsTemplate, 1)

    if tbGoodsTemplate.bHasSecondCurrencyPrice then
        pWidgetRef.txtOr:SetVisibility(ESlateVisibility.HitTestInvisible)

        ShowPrice(self, tbGoodsTemplate, 2)
    else
        pWidgetRef.txtOr:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgCurrency2:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtPrice2:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function ShowCannotBuyState(self, nSourceType)
    local pWidgetRef = self.pWidgetRef
    self.nButtonType = BUTTON_TYPE_NULL
    pWidgetRef.btnActivate:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
    local l10nSourceDesc = ItemSourceDataTable:GetSourceDesc(nSourceType)
    pWidgetRef.txtLocked:SetVisibility(ESlateVisibility.HitTestInvisible)
    if l10nSourceDesc ~= nil then
        self.pWidgetRef.txtLocked:SetText(l10nSourceDesc)
    else
        self.pWidgetRef.txtLocked:SetText("")
    end
end

function ULLobbyShipPartDetail:RefreshBtnActivateState()
    if not self.tbTemplate then
        logerror("ULLobbyShipPartDetail RefreshBtnActivateState, cannot find template.")
        return
    end
    local nPartId = self.tbTemplate.nId
    local bUnlocked = GetPreparationComponent():IsItemUnlocked(nPartId)
    local nActivePartId = GetPreparationComponent():GetActivePartId(self.tbTemplate.nSubCategory)
    if bUnlocked then
        ShowUnlockState(self, nActivePartId, nPartId)
    else
        local nSourceType = self.tbTemplate.nSourceType
        if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
            ShowBuyState(self, nPartId)
        else
            ShowCannotBuyState(self, nSourceType)
        end
    end
end

return ULLobbyShipPartDetail