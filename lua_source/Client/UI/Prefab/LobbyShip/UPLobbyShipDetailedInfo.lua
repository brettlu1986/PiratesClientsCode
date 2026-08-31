-----------------------------------------------------
--File Name    : UPLobbyShipDetailedInfo.lua
--Author       : chenyixin
--Description  : 舰船详情参数Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyShipDetailedInfo = luaclass("UPLobbyShipDetailedInfo", ListItemBase)

function UPLobbyShipDetailedInfo:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    if tbData.l10nPropName then
        pWidgetRef.txtCategoryName:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtCategoryName:SetText(tbData.l10nPropName)
    else
        pWidgetRef.txtCategoryName:SetVisibility(ESlateVisibility.Collapsed)
    end
    if tbData.l10nPropValue then
        pWidgetRef.txtScore:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.txtScore:SetText(tbData.l10nPropValue)
    else
        pWidgetRef.txtScore:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPLobbyShipDetailedInfo:OnBindEvent(EventHelper)
end

return UPLobbyShipDetailedInfo