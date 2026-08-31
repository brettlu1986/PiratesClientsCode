-----------------------------------------------------
--File Name    : UPFFAbuffTips.lua
--Author       : Song Fuhao
--Create Time  : 2019-06-17
--Description  : UPFFAbuffTips
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPTipBase = require("UPTipBase")
local UPFFAbuffTips = luaclass("UPFFAbuffTips",UPTipBase)

local UISetUtils = require("UISetUtils")

--public interface
function UPFFAbuffTips:OnSetData(tbTipData)
    UPFFAbuffTips.super.OnSetData(self,tbTipData)
    local pWidget = self.pWidgetRef
    --标题
    if tbTipData.szTitle then
        pWidget.txtName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidget.txtName:SetText(tbTipData.szTitle)
    else
        pWidget.txtName:SetVisibility(ESlateVisibility.Collapsed)
    end
    --描述信息
    if tbTipData.szDetail then
        pWidget.kmtxtDesc:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidget.kmtxtDesc:SetText(tbTipData.szDetail)
    else
        pWidget.kmtxtDesc:SetVisibility(ESlateVisibility.Collapsed)
    end
    --描述信息
    if tbTipData.szIconPath then
        pWidget.imgIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UISetUtils.SetImageBrushRes(pWidget.imgIcon, tbTipData.szIconPath:load(), true)
    else
        pWidget.imgIcon:SetVisibility(ESlateVisibility.Collapsed)
    end
end


return UPFFAbuffTips

