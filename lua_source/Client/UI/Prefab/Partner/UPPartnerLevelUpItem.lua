-----------------------------------------------------
--File Name    : UPPartnerLevelUpItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-07
--Description  : 伙伴单个小Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPartnerLevelUpItem = luaclass("UPPartnerLevelUpItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local PartnerGradeDataTable = require("PartnerGradeDataTable")

local MAX_LEVEL_NUM = 6

local function SetLevel(self, nLevel)
    for i=1,MAX_LEVEL_NUM do
        self.pWidgetRef.hboxStar:GetChildAt(i - 1):SetVisibility((i <= nLevel) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

function UPPartnerLevelUpItem:SetPartnerInfo(tbPartnerInfo, nLevel, bForceDisable)
    local pWidgetRef = self.pWidgetRef
    if nLevel > 0 then
        pWidgetRef.imgIcon:SetIsEnabled(true)
        SetLevel(self, nLevel)
    else
        pWidgetRef.imgIcon:SetIsEnabled(false)
        pWidgetRef.hboxStar:SetVisibility(ESlateVisibility.Collapsed)
    end
    if bForceDisable then
        pWidgetRef.imgIcon:SetIsEnabled(false)
    end
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGrade, PartnerGradeDataTable:GetIconRes(tbPartnerInfo.tbTemplate.nGrade):load(), true)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbPartnerInfo.tbResTemplate.szIconPath:load())
end

return UPPartnerLevelUpItem