
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbySailorPropertyItem = luaclass("UPLobbySailorPropertyItem", ListItemBase)

function UPLobbySailorPropertyItem:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtPropertyName:SetText(tbData.l10nDisplayName)
    pWidgetRef.txtOldValue:SetText(tbData.szOldDisplayValue)
    if tbData.szNewDisplayValue == nil then 
        pWidgetRef.imgMidArrow:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtPropertyValue:SetVisibility(ESlateVisibility.Collapsed)
    else 
        pWidgetRef.imgMidArrow:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtPropertyValue:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtPropertyValue:SetText(tbData.szNewDisplayValue)
    end
end

return UPLobbySailorPropertyItem