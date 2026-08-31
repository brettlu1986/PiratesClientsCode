-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectWidget       = require("GuideActionSelectWidget")
local GuideActionSelectMultiWidget  = luaclass("GuideActionSelectMultiWidget", GuideActionSelectWidget)

local L10N              = require("L10N")
----------------------------------------------------------
local GetLocalSize = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute = SlateBlueprintLibrary.LocalToAbsolute
----------------------------------------------------------

function GuideActionSelectMultiWidget:Begin()
    GuideActionSelectMultiWidget.super.Begin(self)
end

function GuideActionSelectMultiWidget:ShowSelectEffect()
    self:DebugLog(" GuideActionSelectMultiWidget:ShowSelectEffect")
    local tbTemplate = self.tbTemplate
    local tbSelectWidgets = self.tbSelectWidgets
    if not tbSelectWidgets then
        self:LogError(" GuideActionSelectMultiWidget:ShowSelectEffect tbSelectWidgets is nil")
        self:ForceEndCurrentGroup()
        return
    end
    local SelectWidget = tbSelectWidgets[1]
    if(SelectWidget == nil)then
        logwarning("GuideActionSelectMultiWidget:Begin,SelectWidget is nil")
        self:ForceEndCurrentGroup()
        return
    end

    self.szRelatedWidgetName = tbTemplate.tbWidgetName[1]
    self:DebugLog("GuideActionSelectMultiWidget:ShowSelectEffect,szVisibility="..tostring(self.tbTemplate.szVisibility))
    for k, Widget in ipairs(tbSelectWidgets) do
        Widget:SetVisibility(ESlateVisibility[tbTemplate.szVisibility])
    end

    self:SetSelectInfo(tbSelectWidgets, tbTemplate)

    self:DebugLog("self.tbTemplate.nShowDuration="..tostring(self.tbTemplate.nShowDuration))
    if(self.tbTemplate.nShowDuration >0)then
        self.TimerHelper:NewTimerMethod(self,self.OnTimerFunc, self.tbTemplate.nShowDuration, false)
    end
end

function GuideActionSelectMultiWidget:SetSelectInfo(tbSelectWidgets, tbTemplate)
    local tbPos = {}
    local tbSize = {}
    local tbRotate = {}
    local pParentScale = self:GetParentScale(tbTemplate)
    for i, Widget in ipairs(tbSelectWidgets) do
        local pGeometry = Widget:GetCachedGeometry()
        local Size = GetLocalSize(pGeometry)
        local Pos = LocalToAbsolute(pGeometry, Vector2D{X=0,Y=0})
        self:DebugLog(" GuideActionSelectMultiWidget Size.X = " .. Size.X .. " Size.Y = " .. Size.Y .. " Pos.X = " .. Pos.X .. " Pos.Y = " .. Pos.Y)
        local RenderTransform = Widget.RenderTransform
        local nAngle = math.abs(RenderTransform.Angle)
        local pLocalScale = RenderTransform.Scale
        if nAngle == 180 or (pLocalScale.X == -1 and pLocalScale.Y == -1) then
            table.insert(tbRotate, true)
        else
            table.insert(tbRotate, false)
        end
        local tbRealSize = {X = Size.X*math.abs(pParentScale.X)*pLocalScale.X, Y = Size.Y*math.abs(pParentScale.Y)*pLocalScale.X}
        table.insert(tbPos, Pos)
        table.insert(tbSize, tbRealSize)
    end
    self:DebugLog("tbTemplate SetSelectInfo szSelectWidgetName = " .. tbTemplate.szSelectWidgetName .. " bIsModal = " .. tostring(self.tbGuideTemplate.bIsModal) .. " bClickAnywhere = " .. tostring(tbTemplate.bClickAnywhere))
    self:CallSetSelectInfo(tbPos, tbSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, tbRotate, true, tbTemplate.bMaskEffect)
    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if((tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") )then
        self:EndAction()
    end
end

return GuideActionSelectMultiWidget
