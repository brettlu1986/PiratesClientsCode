local luaclass          = require ("luaclass")
local UPLobbyDisplayItem    = require("UPLobbyDisplayItem")
local UPLobbyDisplayItemAsync = luaclass("UPLobbyDisplayItem", UPLobbyDisplayItem)
local LobbyItemUiHelper = require("LobbyItemUiHelper")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")

function UPLobbyDisplayItemAsync:SetItemIcon(nItemTemplateId)
    LobbyItemUiHelper.SetAsyncIconImage(self.pWidgetRef, nItemTemplateId)
end

function UPLobbyDisplayItemAsync:OnBindEvent(EventHelper)
end

function UPLobbyDisplayItemAsync:SetDisplayItemData(nItemTemplateId, nCount, bCanClick, bIsCost, nMultiple)
    UPLobbyDisplayItemAsync.super.SetDisplayItemData(self, nItemTemplateId, nCount, bCanClick, bIsCost, nMultiple)
    self.pWidgetRef.imgItem:SetVisibility(ESlateVisibility_HitTestInvisible)
    self.pWidgetRef.btnItem:SetVisibility(ESlateVisibility_Visible)
    UISetUtils.SetButtonBrushColor(self.pWidgetRef.btnItem, UIResourceDef.COLOR.TRANSPARENT)
end

function UPLobbyDisplayItemAsync:OnDestroy()
end

return UPLobbyDisplayItemAsync
