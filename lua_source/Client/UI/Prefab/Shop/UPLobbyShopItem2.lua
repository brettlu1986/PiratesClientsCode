-----------------------------------------------------
--File Name    : UPLobbyShopItem2.lua
--Author       : lzheng
--Create Time  : 2019-10-08
--Description  : 商店的商品UP
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShopItem2 = luaclass("UPLobbyShopItem2", ListItemBase)

local UIDef = require("UIDef")
local ShopSystem = require("ShopSystem")
local UIResourceDef = require("UIResourceDef")
local ItemDataTable = require("ItemDataTable")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

function UPLobbyShopItem2:OnLoad()
    self.pItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItemNew, UIDef.UP_LOBBY_SHOP_DISPLAY_ITEMNEW)
    self.pItem:SetOnlyTip(true)
end

function UPLobbyShopItem2:OnBindEvent(EventHelper)
end

function UPLobbyShopItem2:OnRefresh(tbData)
    -- logdebug("UPLobbyShopItem2 refresh item ", tbData.nItemId, tbData.nCount)

    local pWidgetRef = self.pWidgetRef

    local tbItemTemplate = ItemDataTable:GetTemplate(tbData.nItemId) 
    pWidgetRef.txtName:SetText(tbItemTemplate.l10nName)
    self.pItem:SetDisplayItemData(tbData.nItemId, tbData.nCount, true)

    LobbyItemUiHelper.SetGradeHalfColorImage(UIResourceDef.ITEM_COLOR_GRADE_HALFBG, pWidgetRef, tbItemTemplate.nGrade)

    local bHasOwned = ShopSystem:HasOwned(tbData.nItemId)
    pWidgetRef.bdrNeed:SetVisibility(bHasOwned and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
end


return UPLobbyShopItem2
