-----------------------------------------------------
--File Name    : ULLobbyShipWeaponDetail.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-23
--Description  : 舰船备战武器分页详情逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipWeaponDetail = luaclass("ULLobbyShipWeaponDetail", UILogicBase)

local L10N = require("L10N")
local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local ShopSystem = require("ShopSystem")
local ShopDataTable = require("ShopDataTable")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local ItemSourceDataTable = require("ItemSourceDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BuildShipWeaponTipsContentHelper = require("BuildShipWeaponTipsContentHelper")

local TAB_INDEX_EMPTY = 0
local TAB_INDEX_DETAIL = 1
local WEAPON_PREFAB_OFFSET = Margin{Left=0, Top=5, Right=0, Bottom=5}
local BUTTON_TYPE_NULL = 0
local BUTTON_TYPE_EQUIP = 1
local BUTTON_TYPE_PURCHASE = 2

ULLobbyShipWeaponDetail.tbTemplate = nil
ULLobbyShipWeaponDetail.nButtonType = BUTTON_TYPE_NULL

local function GetPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function ClearGridPanels(self)
    if self.tbGridPanelChilden ~= nil and #self.tbGridPanelChilden > 0 then
        for _, v in ipairs(self.tbGridPanelChilden) do
            v:RemoveFromParent()
        end
    end
end

-- TODO Hao 这块有空改改吧，直接粘过来的，没有Cache，太费了
local function CreateTextBlock(self, nRow, nColumn, l10nText, nHorizontalAlignment, nTextJustify, pSlateColor)
    local WidgetHelper = self.WidgetHelper
    local pWidgetRef = self.pWidgetRef
    local pTextBlock = WidgetHelper:CreateWidget(TextBlock)
    local pGridSlot = pWidgetRef.gridPanelShipWeapon:AddChildToGrid(pTextBlock, 0, 0)
    pGridSlot:SetRow(nRow)
    pGridSlot:SetColumn(nColumn)
    pGridSlot:SetHorizontalAlignment(nHorizontalAlignment)
    pGridSlot:SetPadding(WEAPON_PREFAB_OFFSET)
    pTextBlock:SetText(l10nText)
    UISetUtils.SetTextblockFont(pTextBlock, UIResourceDef.FFA_FONT_RES_PINGFANG:load(), "Bold")
    UISetUtils.SetTextblockFontSize(pTextBlock, 22)
    pTextBlock:SetJustification(nTextJustify)
    pTextBlock:SetColorAndOpacity(pSlateColor)
    if self.tbGridPanelChilden == nil then
        self.tbGridPanelChilden = {}
    end
    table.insert(self.tbGridPanelChilden, pTextBlock)
end

local function FillGridPanels(self, tbProperties, tbActiveProperties)
    for i, v in ipairs(tbProperties) do
        local l10nTitle = v.szTitle
        local l10nDesc = v.szDesc
        CreateTextBlock(self, i-1, 0, l10nTitle, EHorizontalAlignment.HAlign_Left, ETextJustify.Left, UIResourceDef.COLOR.WHITE.SLATE_COLOR)

        if l10nDesc then
            local tbProperty = tbActiveProperties and tbActiveProperties[i]
            local l10nActiveDesc = tbProperty and tbProperty.szDesc
            local pSlateColor = ((not l10nActiveDesc) or (L10N:ToString(l10nDesc) == L10N:ToString(l10nActiveDesc))) and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.YELLOW.SLATE_COLOR
            CreateTextBlock(self, i-1, 1, l10nDesc, EHorizontalAlignment.HAlign_Right, ETextJustify.Right, pSlateColor)
        end
    end
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
        GetPreparationComponent():RequestActivateWeapon(self.tbTemplate.nId)
    elseif nButtonType == BUTTON_TYPE_PURCHASE then
        ShowPurchaseDialog(self)
    end
end

local function ShowUnlockState(self, nActiveWeaponId, nWeaponId)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.hboxPurchase:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.btnActivate:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.txtLocked:SetVisibility(ESlateVisibility.Collapsed)
    if nActiveWeaponId == nWeaponId then
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

function ULLobbyShipWeaponDetail:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnActivate.OnClicked, self, OnClickedBtnActivate)
end

function ULLobbyShipWeaponDetail:RefreshActivateState()
    if not self.tbTemplate then
        logerror("ULLobbyShipWeaponDetail RefreshActivateState, cannot find template.")
        return
    end
    local pWidgetRef = self.pWidgetRef
    local nWeaponId = self.tbTemplate.nId
    local bUnlocked = GetPreparationComponent():IsItemUnlocked(nWeaponId)
    local nActiveWeaponId = GetPreparationComponent():GetActiveWeaponId(self.tbTemplate.nSubCategory)
    if bUnlocked then
        ShowUnlockState(self, nActiveWeaponId, nWeaponId)
    else
        local nSourceType = self.tbTemplate.nSourceType
        if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
            ShowBuyState(self, nWeaponId)
        else
            ShowCannotBuyState(self, nSourceType)
        end
    end

    local tbTipsData = BuildShipWeaponTipsContentHelper.GetTipsData(self.tbTemplate.nBattleItemId)
    local tbProperties = tbTipsData.tbDatas
    pWidgetRef.txtAttack:SetText(tbTipsData.nDamage)
    pWidgetRef.ktxtShipWeaponContent:SetText(tbTipsData.szDesc)

    -- 需要注意可能会存在没有激活武器的情况，比如新增一个武器分类，老账号没有发默认武器
    local tbActiveTemplate = ItemSystem:GetItemTemplate(nActiveWeaponId)
    local tbActiveDatas = tbActiveTemplate and BuildShipWeaponTipsContentHelper.GetTipsData(tbActiveTemplate.nBattleItemId)
    local tbActiveProperties = tbActiveDatas and tbActiveDatas.tbDatas

    ClearGridPanels(self)
    FillGridPanels(self, tbProperties, tbActiveProperties)
end

function ULLobbyShipWeaponDetail:SetWeaponTemplate(tbTemplate)
    self.tbTemplate = tbTemplate
    if tbTemplate then
        self.pWidgetRef.txtName:SetText(tbTemplate.l10nName)
        self:RefreshActivateState(self)
        self.pWidgetRef.wsRightContent:SetActiveWidgetIndex(TAB_INDEX_DETAIL)
    else
        self.pWidgetRef.wsRightContent:SetActiveWidgetIndex(TAB_INDEX_EMPTY)
    end
end

return ULLobbyShipWeaponDetail