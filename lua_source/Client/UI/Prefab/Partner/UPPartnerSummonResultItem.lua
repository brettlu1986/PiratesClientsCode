-----------------------------------------------------
--File Name    : UPPartnerSummonResultItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-07
--Description  : 伙伴抽奖单个小Item
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPPartnerSummonResultItem = luaclass("UPPartnerSummonResultItem", PrefabBase)

local UISetUtils = require("UISetUtils")
local ItemDataTable = require("ItemDataTable")
local ItemCategoryDef = require("ItemCategoryDef")
local PartnerGradeDataTable = require("PartnerGradeDataTable")

local MAX_LEVEL_NUM = 6
local GRADE_SSR = 4
local GRADE_SR = 3

local function SetLevel(self, nLevel)
    for i=1,MAX_LEVEL_NUM do
        self.pWidgetRef.hboxStar:GetChildAt(i - 1):SetVisibility((i <= nLevel) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

function UPPartnerSummonResultItem:SetSummonResult(tbSummonResult)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = ItemDataTable:GetTemplate(tbSummonResult.template_id)
    local tbResTemplate = ItemDataTable:GetResTemplate(tbSummonResult.template_id)
    self.nGrade = tbTemplate.nGrade
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGrade, PartnerGradeDataTable:GetIconRes(tbTemplate.nGrade):load(), true)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbResTemplate.szIconPath:load())
    self.bFragment = tbTemplate.nCategory == ItemCategoryDef.CURRENCY
    if self.bFragment then
        pWidgetRef.hboxStar:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgFragmentIcon:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtFragment:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtFragment:SetText("x".. tbSummonResult.count)
    else
        SetLevel(self, 1)
    end
end

function UPPartnerSummonResultItem:ShowGradeEffect()
    if not self.bFragment then
        if self.nGrade == GRADE_SSR then
            self:PlayAnimation("animGlowSSR", 0, 1, EUMGSequencePlayMode.Forward, 1)
            return
        elseif self.nGrade == GRADE_SR then
            self:PlayAnimation("animGlowSR", 0, 1, EUMGSequencePlayMode.Forward, 1)
            return
        end
    end
    self:PlayAnimation("animGlowCommon", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

return UPPartnerSummonResultItem