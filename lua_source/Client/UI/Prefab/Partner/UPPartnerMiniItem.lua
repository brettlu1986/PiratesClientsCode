-----------------------------------------------------
--File Name    : UPPartnerMiniItem.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-07
--Description  : 伙伴单个小Item
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPPartnerMiniItem = luaclass("UPPartnerMiniItem", ListItemBase)

local UISetUtils = require("UISetUtils")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local PartnerGradeDataTable = require("PartnerGradeDataTable")

local MAX_LEVEL_NUM = 6

local function GetPartnerComponent()
    return GamePlayerSelfHelper:Get().PartnerComponent
end

local function OnClickedBtnItem(self)
    if not self:IsSelected() then
        self:SelectItem()
    end
end

local function SetLevel(self, nLevel)
    for i=1,MAX_LEVEL_NUM do
        self.pWidgetRef.hboxStar:GetChildAt(i - 1):SetVisibility((i <= nLevel) and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    end
end

function UPPartnerMiniItem:OnRefresh(tbData)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = tbData.tbTemplate
    local nLevel = tbData.nLevel

    local bPartnerCanUpLevelOrSummon = GetPartnerComponent():IsPartnerCanUpLevelOrSummon(tbData.nPartnerId)
    pWidgetRef.btnItem:HideTipIcon(not bPartnerCanUpLevelOrSummon)

    self:StopAnimation("animSynthetic")
    pWidgetRef.ImgSynthetic:SetVisibility(ESlateVisibility.Collapsed)

    if nLevel > 0 then
        SetLevel(self, nLevel)
        pWidgetRef.imgIcon:SetIsEnabled(true)
        pWidgetRef.ovlFragment:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.hboxStar:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        local nFragmentTotalCount = PartnerGradeDataTable:GetFragmentCountByGradeAndLevel(tbTemplate.nGrade, nLevel + 1)
        pWidgetRef.txtFragmentCount:SetText(tbData.nFragmentCount .. "/" .. nFragmentTotalCount)
        pWidgetRef.pgbFragment:SetPercent(tbData.nFragmentCount / nFragmentTotalCount)
        pWidgetRef.imgIcon:SetIsEnabled(false)
        pWidgetRef.ovlFragment:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.hboxStar:SetVisibility(ESlateVisibility.Collapsed)
        if bPartnerCanUpLevelOrSummon then
            self:PlayAnimation("animSynthetic", 0, 0, EUMGSequencePlayMode.PingPong, 1)
        end
    end
    if self:IsSelected() then
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.HitTestInvisible)
    else
        pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Collapsed)
    end
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGrade, PartnerGradeDataTable:GetIconRes(tbTemplate.nGrade):load(), true)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIcon, tbData.tbResTemplate.szIconPath:load())
end

function UPPartnerMiniItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedBtnItem)
end

return UPPartnerMiniItem