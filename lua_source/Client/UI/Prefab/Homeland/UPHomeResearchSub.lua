-----------------------------------------------------
--File Name    : UPHomeResearchSub.lua
--Author       : zhiyuan
--Create Time  : 2019-05-15
--Description  : 研发的左侧UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomeResearchSub = luaclass("UPHomeResearchSub", PrefabBase)

local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local HomelandSystem = require("HomelandSystem")
local BuildingDataTable = require("BuildingDataTable")
local UISetUtils = require("UISetUtils")
local ResearchBuildingDescDataTable = require("ResearchBuildingDescDataTable")
local L10N = require("L10N")
local UITextDef = require("UITextDef")
local UIResourceDef = require("UIResourceDef")

UPHomeResearchSub.nLandmarkType = nil

local function SetBuildingName(self, l10nName)
    self.pWidgetRef.txtTitle:SetText(l10nName)
end

local function SetBuildingImg(self, szIcon)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBuilding, szIcon:load())
end

local function SetDesc(self, nCurrentGrade, tbDescTemplate)
    local nGrade = tbDescTemplate.nGrade
    local l10nContent = tbDescTemplate.l10nContent
    local l10nName = L10N:Format(UITextDef.LANDMARK_RESEARCH_BUILDING_GRADE, nGrade)

    self.pWidgetRef["kmtxtLevelName"..nGrade]:SetText(l10nName)
    local kmtxtDesc = self.pWidgetRef["kmrichtxtDesc"..nGrade]
    kmtxtDesc:SetText(l10nContent)
    if nCurrentGrade >= nGrade then
        kmtxtDesc:SetColorAndOpacity(UIResourceDef.COLOR.GREEN.LINEAR_COLOR)
    else
        kmtxtDesc:SetColorAndOpacity(UIResourceDef.COLOR.GREY.LINEAR_COLOR)
    end
end

local function Refresh(self, nLandmarkType)
    local tbLandmarkTypeTemplate = LandmarkBuildingTypeDataTable:GetTemplate(nLandmarkType)
    SetBuildingName(self, tbLandmarkTypeTemplate.l10nName)

    local nGrade = HomelandSystem:GetLandmarkGrade(nLandmarkType)
    local nCurrentSceneId = HomelandSystem:GetCurrentSceneId()
    local tbBuildingTemplate = BuildingDataTable:GetLandmarkTemplate(nCurrentSceneId, nLandmarkType, nGrade)
    SetBuildingImg(self, tbBuildingTemplate.szIcon)

    local tbDescTemplates = ResearchBuildingDescDataTable:GetTemplatesByType(nLandmarkType)
    for _, v in pairs(tbDescTemplates) do
        SetDesc(self, nGrade, v)
    end
    self:SetVisibility(true)
end

----------life cycle----------

function UPHomeResearchSub:SetData(nLandmarkType)
    self.nLandmarkType = nLandmarkType
    Refresh(self, nLandmarkType)
end

function UPHomeResearchSub:SetVisibility(bVisible)
    self.pWidgetRef:SetVisibility(bVisible and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
end

function UPHomeResearchSub:OnLoad()
end

function UPHomeResearchSub:OnShow()
end

function UPHomeResearchSub:OnBindEvent(EventHelper)
end

return UPHomeResearchSub