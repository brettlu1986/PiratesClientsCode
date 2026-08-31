
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbySailorBagItem = luaclass("UPLobbySailorBagItem", ListItemBase)
local LobbySailorHelper = require("LobbySailorHelper")

UPLobbySailorBagItem.tbData = nil

local function OnSelected(self)
    self:SelectItem()
end

function UPLobbySailorBagItem:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef

    if tbData.nCount > 0 then
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtCount:SetText(tbData.nCount)
        LobbySailorHelper.RefreshSailorItemResState(pWidgetRef.imgItem,  pWidgetRef.imgPattern, true, tbData.nSailorId)
    else  
        pWidgetRef.txtCount:SetVisibility(ESlateVisibility.Collapsed)
        LobbySailorHelper.RefreshSailorItemResState(pWidgetRef.imgItem, pWidgetRef.imgPattern, false, tbData.nSailorId)
    end
    if self:IsSelected() then
        pWidgetRef.imgUp:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.imgUp:SetVisibility(ESlateVisibility.Collapsed)
    end
end

function UPLobbySailorBagItem:OnBindEvent( EventHelper )
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnSelected)
end


return UPLobbySailorBagItem