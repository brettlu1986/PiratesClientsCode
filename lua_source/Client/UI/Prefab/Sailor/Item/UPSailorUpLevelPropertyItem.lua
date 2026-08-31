-----------------------------------------------------
--File Name    : UPSailorUpLevelPropertyItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-17
--Description  : 水手升级页面中属性汇总Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSailorUpLevelPropertyItem = luaclass("UPSailorUpLevelPropertyItem", ListItemBase)

function UPSailorUpLevelPropertyItem:OnRefresh(tbData)
    self.pWidgetRef.txtPropertyName:SetText(tbData.l10nDisplayName)
    self.pWidgetRef.txtOldValue:SetText(tbData.szOldDisplayValue)
    self.pWidgetRef.txtNewValue:SetText(tbData.szNewDisplayValue)
end

return UPSailorUpLevelPropertyItem