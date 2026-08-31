-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionFullUIControl          = require("GuideActionFullUIControl")
local GuideActionSelectWidgetByIndex    = luaclass("GuideActionSelectWidgetByIndex",GuideActionFullUIControl)

local ClientEventDef    = require("ClientEventDef")
local L10N              = require("L10N")


----------------------------------------------------------


GuideActionSelectWidgetByIndex.szRelatedWidgetName  = nil
GuideActionSelectWidgetByIndex.SelectWidget         = nil

function GuideActionSelectWidgetByIndex:Begin()
    GuideActionSelectWidgetByIndex.super.Begin(self)
    local tbTemplate = self.tbTemplate
    local SelectWidget = self:GetParentUserWidget()
    if(SelectWidget == nil)then
        self:LogError("GuideActionSelectWidgetByIndex:Begin,SelectWidget is nil")
        self:ForceEndCurrentGroup()
        return
    end
    if not tbTemplate.tbListIndex or not tbTemplate.tbListIndex[1] then
        self:LogError("GuideActionSelectWidgetByIndex:Begin,list index is nil")
        return
    end
    local nSelectIndex = math.max(0, tbTemplate.tbListIndex[1] - 1 )
    SelectWidget = SelectWidget:GetChildAt(nSelectIndex)
    if not SelectWidget then
        self:LogError("GuideActionSelectWidgetByIndex:Begin,SelectWidget is nil, index=", nSelectIndex)
        return
    end
    local szWidgetName = tbTemplate.tbWidgetName[1]
    if szWidgetName then
        SelectWidget = SelectWidget[szWidgetName]
    end
    self.SelectWidget = SelectWidget
    self.szRelatedWidgetName = szWidgetName
    self:DebugLog("GuideActionSelectWidgetByIndex:Begin,szVisibility="..tostring(self.tbTemplate.szVisibility))
    SelectWidget:SetVisibility(ESlateVisibility[tbTemplate.szVisibility])
    local EventHelper = self.EventHelper
    if SelectWidget.OnClicked then
        EventHelper:RegisterCppDelegate(SelectWidget.OnClicked, self, self.OnSelect)
    end
    if(SelectWidget.OnDisableClicked ~= nil)then
        EventHelper:RegisterCppDelegate(SelectWidget.OnDisableClicked, self, self.OnSelect)
    end
    if(SelectWidget.OnCheckStateChanged ~= nil)then
        EventHelper:RegisterCppDelegate(SelectWidget.OnCheckStateChanged, self, self.OnSelect)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_ITEM, self, self.OnItemClick)
    
end

function GuideActionSelectWidgetByIndex:End()
    GuideActionSelectWidgetByIndex.super.End(self)
end

function GuideActionSelectWidgetByIndex:DoAction(tbTemplate)
    GuideActionSelectWidgetByIndex.super.DoAction(self, tbTemplate)
    local pGeometry = self.SelectWidget:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})

    self:CallSetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self)
    
    self:DebugLog("tbTemplate.szSelectWidgetName="..tostring(tbTemplate.szSelectWidgetName))
    if((tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") )then
        self:EndAction()
    end
   
end

function GuideActionSelectWidgetByIndex:OnSelect()
    self:DebugLog("GuideActionSelectWidgetByIndex:OnSelect ")
    if(not self.tbTemplate.bDoubleClick)then
        self:EndAction()
    end
end

function GuideActionSelectWidgetByIndex:OnItemClick()
    if self.SelectWidget and not self.SelectWidget.OnClicked then
        self:OnSelect()
    end
end

return GuideActionSelectWidgetByIndex
