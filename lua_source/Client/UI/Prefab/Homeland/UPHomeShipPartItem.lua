-----------------------------------------------------
--File Name    : UPHomeShipPartItem.lua
--Author       : zhiyuan
--Create Time  : 2019-05-16
--Description  : 家园零件研发的up
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")
local UPHomeShipPartItem = luaclass("UPHomeShipPartItem", ListItemBase)

local L10N = require("L10N")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ItemResearchDataTable = require("ItemResearchDataTable")
local HomelandSystem = require("HomelandSystem")
local UIResourceDef = require("UIResourceDef")

local function OnClickedItem(self)
    self:ToogleSelectItem()
end

function UPHomeShipPartItem:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnItem.OnClicked, self, OnClickedItem)
end

function UPHomeShipPartItem:OnRefresh(tbTemplate)
    local nTemplateId = tbTemplate.nId
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.imgSelected:SetVisibility(self:IsSelected() and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    pWidgetRef.txtName:SetText(tbTemplate.l10nName)
    local tbItemResearchTemplate = ItemResearchDataTable:GetTemplate(nTemplateId)
    local nUnlockLandmarkType = tbItemResearchTemplate.nUnlockLandmarkType
    local nUnlockLandmarkGrade = tbItemResearchTemplate.nUnlockLandmarkGrade
    local nCurrentGrade = HomelandSystem:GetLandmarkGrade(nUnlockLandmarkType)
    if ItemSystem:GetItemCount(nTemplateId) > 0 then
        pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtName:SetColorAndOpacity(UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
        pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_SHIP_PART_DESC_FORMAT"), ItemSystem:GetItemIntro(nTemplateId)))
    else
        if nCurrentGrade >= nUnlockLandmarkGrade then
            pWidgetRef.imgLock:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef.imgLock:SetVisibility(ESlateVisibility.HitTestInvisible)
        end
        pWidgetRef.txtName:SetColorAndOpacity(UIResourceDef.COLOR.GREY.SLATE_COLOR)
        pWidgetRef.txtDesc:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("HOME_SHIP_PART_LOCK_DESC_FORMAT"), ItemSystem:GetItemIntro(nTemplateId)))
    end
end

return UPHomeShipPartItem