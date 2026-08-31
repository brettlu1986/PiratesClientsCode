-----------------------------------------------------
--File Name    : UPLobbyShopDisplayItem.lua
--Author       : zhiyuan
--Create Time  : 2019-07-22
--Description  : 商店里显示道具icon
-----------------------------------------------------
local luaclass          = require ("luaclass")
local PrefabBase        = require("PrefabBase")
local UPLobbyShopDisplayItem    = luaclass("UPLobbyShopDisplayItem", PrefabBase)

local LobbyItemUiHelper = require("LobbyItemUiHelper")
local ItemDataTable = require("ItemDataTable")
local UIToolTipHelper = require("UIToolTipHelper")
local ItemCategoryDef = require("ItemCategoryDef")
local ClientEventDef = require("ClientEventDef")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local ShopSystem = require("ShopSystem")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local Human3DItemShowDataHelper  = require("Human3DItemShowDataHelper")

UPLobbyShopDisplayItem.nItemTemplateId = nil
UPLobbyShopDisplayItem.nGoodsId = nil


local function DisplayHumanFashionItem(self, nItemTemplateId)
    local tbData = Human3DItemShowDataHelper.MakeHumanFashionShowData(nItemTemplateId)
    LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, tbData)
end

local function DisplayHumanWeaponFashionItem(self, nItemTemplateId)
    local tbData = Human3DItemShowDataHelper.MakeHumanWeaponFashionShowData(nItemTemplateId)
    LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, tbData)
end

local function OnItemButtonClicked(self)
    UIToolTipHelper:HideTip(true)
    local nItemTemplateId = self.nItemTemplateId
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.SHIP then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP, nShipTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    elseif nCategory == ItemCategoryDef.SHIP_SKIN then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP_SKIN, nShipTemplateId = tbItemTemplate.nShipItemId, nShipSkinTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    elseif nCategory == ItemCategoryDef.FASHION then
        DisplayHumanFashionItem(self, nItemTemplateId)
    elseif nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        DisplayHumanWeaponFashionItem(self, nItemTemplateId)
    elseif nCategory == ItemCategoryDef.DECORATION then  
        --LobbySystem:Activate(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.DECORATION, nTemplateId = nItemTemplateId })
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.DECORATION, nTemplateId = nItemTemplateId })
    elseif nCategory == ItemCategoryDef.SHIP_WEAPON then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP_WEAPON, nItemTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    elseif nCategory == ItemCategoryDef.SHIP_PART then
        local tbLobbyShip = LobbySystem:GetSub(LobbySubTypeDef.SHIP)
        LobbySystem:ActivateNextSub(LobbySubTypeDef.SHOW, {nCategory = ItemCategoryDef.SHIP_PART, nItemTemplateId = nItemTemplateId, OwnerSub = tbLobbyShip })
    elseif nCategory == ItemCategoryDef.GIFT_BOX then
        if not ShopSystem:HasOwned(nItemTemplateId) then
            UIManager:OpenWnd(UIDef.UI_LOBBY_SHOP_GIFTBOX_PURCHASE, {nItemTemplateId = nItemTemplateId, nGoodsId = self.nGoodsId})
        end

    end
end

local function OnItemButtonPressed(self)

    local nItemTemplateId = self.nItemTemplateId

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.SHIP
        or nCategory == ItemCategoryDef.SHIP_SKIN
        or nCategory == ItemCategoryDef.FASHION
        or nCategory == ItemCategoryDef.SHIP_WEAPON
        or nCategory == ItemCategoryDef.SHIP_PART
        or nCategory == ItemCategoryDef.GIFT_BOX 
        or nCategory == ItemCategoryDef.DECORATION then
        return
    end

    local tbTipData = {}
    local pWidgetRef = self.pWidgetRef.btnItem
    tbTipData.tbResTemplate = ItemDataTable:GetResTemplate(nItemTemplateId)
    tbTipData.tbTemplate = tbItemTemplate
    UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
end

local function OnItemButtonReleased(self)
    UIToolTipHelper:HideTip()
end

local function OnAutoReleased(self, szWndName)
    if szWndName ~= UIDef.UI_TOOL_TIP then
        OnItemButtonReleased(self)
    end
end

function UPLobbyShopDisplayItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnItemButtonClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnPressed, self, OnItemButtonPressed)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnReleased, self, OnItemButtonReleased)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPEN_UI, self, OnAutoReleased)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnAutoReleased)
end

function UPLobbyShopDisplayItem:SetVisible(bVisible)
    self.pWidgetRef:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

function UPLobbyShopDisplayItem:SetDisplayItemData(nItemTemplateId, nGoodsId)
    self:SetVisible(true)
    self.nItemTemplateId = nItemTemplateId

    self.nGoodsId = nGoodsId

    local pWidgetRef = self.pWidgetRef

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)

    local nGrade = tbItemTemplate.nGrade
    local nCategory = tbItemTemplate.nCategory
    LobbyItemUiHelper.SetGradeColorImage(pWidgetRef, tbItemTemplate.nGrade)
    LobbyItemUiHelper.SetIconImage(pWidgetRef, nItemTemplateId)
    LobbyItemUiHelper.SetGradeImage(pWidgetRef, nCategory, nGrade)

    LobbyItemUiHelper.SetSelected(pWidgetRef, false)
    LobbyItemUiHelper.SetCount(pWidgetRef, "")

    LobbyItemUiHelper.SetButtonCanClick(pWidgetRef, true)

    LobbyItemUiHelper.ShowTryTxt(pWidgetRef, nItemTemplateId)
end

return UPLobbyShopDisplayItem
