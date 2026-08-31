-----------------------------------------------------
--File Name    : UPTextTips.lua
--Author       : zhiyuan
--Create Time  : 2019-07-16
--Description  : 纯文本tips
-----------------------------------------------------

local luaclass = require("luaclass")
local UPTipBase         = require("UPTipBase")
local UPTextTips   = luaclass("UPTextTips", UPTipBase)

local function Init(self)
    local tbTipData = self.tbTipData
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbTipData.szTitle)
    pWidgetRef.kmtxtDesc:SetText(tbTipData.szDetail)
end

function UPTextTips:OnShow()
    Init(self)
end

return UPTextTips