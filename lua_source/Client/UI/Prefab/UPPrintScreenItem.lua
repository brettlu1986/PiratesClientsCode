-----------------------------------------------------
--File Name    : UPPrintScreenItem.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-17
--Description  : 用于打印文本到屏幕上（替代引擎的PrintScreen），UIPrintScreen的Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPrintScreenItem = luaclass("UPPrintScreenItem", ListItemBase)

local UISetUtils = require("UISetUtils")

local DEFAULT_FONT_SIZE = 12

function UPPrintScreenItem:OnRefresh(tbData)
    local txtLog = self.pWidgetRef.txtLog
    txtLog:SetText(tbData.szMessage)
    txtLog:SetColorAndOpacity(tbData.pSlateColor)
    UISetUtils.SetTextblockFontSize(txtLog, DEFAULT_FONT_SIZE * tbData.nScale)
end

return UPPrintScreenItem
