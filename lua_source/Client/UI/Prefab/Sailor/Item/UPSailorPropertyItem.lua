-----------------------------------------------------
--File Name    : UPSailorPropertyItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-20
--Description  : 水手装备页面中属性汇总Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPSailorPropertyItem = luaclass("UPSailorPropertyItem", ListItemBase)

local UIResourceDef = require("UIResourceDef")

function UPSailorPropertyItem:OnRefresh(tbData)
    local bUseColor = tbData.bHasColor ~= nil and tbData.bHasColor == true
    self.pWidgetRef.txtPropertyName:SetColorAndOpacity(bUseColor and UIResourceDef.COLOR.ORANGE["SLATE_COLOR"] or UIResourceDef.COLOR.WHITE["SLATE_COLOR"])
    self.pWidgetRef.txtPropertyValue:SetColorAndOpacity(bUseColor and UIResourceDef.COLOR.ORANGE["SLATE_COLOR"] or UIResourceDef.COLOR.WHITE["SLATE_COLOR"])

    self.pWidgetRef.txtPropertyName:SetText(tbData.l10nDisplayName)
    self.pWidgetRef.txtPropertyValue:SetText(tbData.szDisplayValue)
end

return UPSailorPropertyItem