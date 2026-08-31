-----------------------------------------------------
--File Name    : UPLobbyShipSkinItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-11
--Description  : 伙伴皮肤Item
-----------------------------------------------------
local luaclass = require("luaclass")
local GalleryItemBase = require("GalleryItemBase")
local UPLobbyShipSkinItem = luaclass("UPLobbyShipSkinItem", GalleryItemBase)

local L10N = require("L10N")
local UITextDef = require("UITextDef")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ShopSystem = require("ShopSystem")
local ItemDataTable = require("ItemDataTable")
local ShopDataTable = require("ShopDataTable")
local ItemSourceDataTable = require("ItemSourceDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ShipSkinItemDataTableHelper = require("ShipSkinItemDataTableHelper")

local BUTTON_TYPE_NULL = 0
local BUTTON_TYPE_EQUIP = 1
local BUTTON_TYPE_PURCHASE = 2
local EXPIRATION_TIME_REFRESH_INTERVAL = 1

UPLobbyShipSkinItem.nShipSkinItemId = -1
UPLobbyShipSkinItem.nButtonType = BUTTON_TYPE_NULL

local function GetShipPreparationComponent()
    return GamePlayerSelfHelper:Get().ShipPreparationComponent
end

local function ShowPurchaseDialog(self)
    local tbTemplate = self.tbData
    local nItemTemplateId = tbTemplate.nId
    local tbGoodsTemplate = ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
    if tbGoodsTemplate then
        ShopSystem:OnBuyButtonClick(tbGoodsTemplate)
    end
end

local function OnClickedBtnItem(self)
    self:SelectItem()
end

local function OnClickedBtnOk(self)
    if self.nButtonType == BUTTON_TYPE_EQUIP then
        GetShipPreparationComponent():RequestEquipShipSkin(self.nShipSkinItemId)
    elseif self.nButtonType == BUTTON_TYPE_PURCHASE then
        ShowPurchaseDialog(self)
    end
end

local function OnExpirationTimeEnd(self)
    self:RefreshSelf()
end

local function RefreshBuyButtonWhenSelect(self)
    local nShipSkinItemId = self.nShipSkinItemId
    local tbItemTemplate = ItemDataTable:GetTemplate(nShipSkinItemId)
    local nSourceType = tbItemTemplate.nSourceType
    if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
        self.nButtonType = BUTTON_TYPE_PURCHASE
        self.pWidgetRef.txtOk:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_PURCHASE"))
    else
        self.pWidgetRef.btnOk:SetVisibility(ESlateVisibility.Collapsed)
        local l10nSourceDesc = ItemSourceDataTable:GetSourceDesc(nSourceType)
        if l10nSourceDesc ~= nil then
            self.pWidgetRef.txtTips:SetText(l10nSourceDesc)
        else
            self.pWidgetRef.txtTips:SetText("")
        end
    end
end

local function RefreshBuyButtonWhenNotSelect(self)
    local nShipSkinItemId = self.nShipSkinItemId
    local tbItemTemplate = ItemDataTable:GetTemplate(nShipSkinItemId)
    local nSourceType = tbItemTemplate.nSourceType
    if ItemSourceDataTable:IfShowBuyButton(nSourceType) then
        self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_CAN_PURCHASE"))
    else
        local l10nSourceDesc = ItemSourceDataTable:GetSourceDesc(nSourceType)
        if l10nSourceDesc ~= nil then
            self.pWidgetRef.txtTips:SetText(l10nSourceDesc)
        else
            self.pWidgetRef.txtTips:SetText("")
        end
    end
end

function UPLobbyShipSkinItem:OnRefresh(tbData)
    self.nShipSkinItemId = tbData.nId
    self.nButtonType = BUTTON_TYPE_NULL
    local nShipItemId = tbData.nShipItemId
    local ShipPreparationComponent = GetShipPreparationComponent()
    local nExpirationTime = ShipPreparationComponent:GetItemExpirationTime(self.nShipSkinItemId)
    local bExperienced = nExpirationTime ~= ShipPreparationComponent.PERMANENT_ITEM_TIME
    local bShipUnlocked = ShipPreparationComponent:IsItemUnlocked(nShipItemId)
    if bExperienced and bShipUnlocked and (nExpirationTime > 0) then
        self.pWidgetRef.txtExpirationTime:StartTimer(nExpirationTime, EXPIRATION_TIME_REFRESH_INTERVAL, UITextDef.TIMER_TEXT_BLOCK_FORMAT_FULL, EMinTimeUnit.Second)
        self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        self.pWidgetRef.txtExpirationTime:StopTimer()
        self.pWidgetRef.hboxExpirationTime:SetVisibility(ESlateVisibility.Collapsed)
    end

    if ShipPreparationComponent:IsEquippedShipSkin(nShipItemId, self.nShipSkinItemId) then
        if bExperienced then
            self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_EXPERIENCED"))
        else
            self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_USED"))
        end
    else
        if ShipPreparationComponent:IsItemUnlocked(nShipItemId) then
            if self:IsSelected() then
                if ShipPreparationComponent:IsItemUnlocked(self.nShipSkinItemId) then
                    self.nButtonType = BUTTON_TYPE_EQUIP
                    self.pWidgetRef.txtOk:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_USE"))
                else
                    if ShipPreparationComponent:IsShipItemPurchased(nShipItemId) then
                        RefreshBuyButtonWhenSelect(self)
                    else
                        self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_SHIP_LOCKED"))
                    end
                end
            else
                local bSkinUnlocked = ShipPreparationComponent:IsItemUnlocked(self.nShipSkinItemId)
                if bShipUnlocked and bSkinUnlocked then
                    self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_CAN_USE"))
                elseif ShipPreparationComponent:IsShipItemPurchased(nShipItemId) then
                    RefreshBuyButtonWhenNotSelect(self)
                else
                    self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_SHIP_LOCKED"))
                end
            end
        else
            self.pWidgetRef.txtTips:SetText(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_SKIN_SHIP_LOCKED"))
        end
    end

    if self.nButtonType == BUTTON_TYPE_NULL then
        self.pWidgetRef.txtTips:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.btnOk:SetVisibility(ESlateVisibility.Collapsed)
    else
        self.pWidgetRef.btnOk:SetVisibility(ESlateVisibility.Visible)
        self.pWidgetRef.txtTips:SetVisibility(ESlateVisibility.Collapsed)
    end

    -- 设置皮肤图片
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBg, ShipSkinItemDataTableHelper.GetVerticalPosterPath(self.nShipSkinItemId):load())

    -- 设置皮肤名字
    local tbShipSkinTemplate = ItemSystem:GetItemTemplate(self.nShipSkinItemId)
    self.pWidgetRef.txtSkinName:SetText(tbShipSkinTemplate.l10nPrefixName)
    self.pWidgetRef.txtSkinName:SetColorAndOpacity(KMUMGLibrary.GetSlateColorFromHex(L10N:ToString(UITextDef.ITEM_GRADE_COLOR_TEXT[tbShipSkinTemplate.nGrade])))

    -- 设置舰船名字
    local tbShipTemplate = ItemSystem:GetItemTemplate(nShipItemId)
    self.pWidgetRef.txtShipName:SetText(tbShipTemplate.l10nName)
end

function UPLobbyShipSkinItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedBtnItem)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnOk.OnClicked, self, OnClickedBtnOk)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.txtExpirationTime.OnCompleteTimer, self, OnExpirationTimeEnd)
end

return UPLobbyShipSkinItem