-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFullUIControl  = require("GuideActionFullUIControl")
local GuideActionSelectWidget   = luaclass("GuideActionSelectWidget", GuideActionFullUIControl)

local UIDef             = require("UIDef")
local ClientEventDef    = require("ClientEventDef")
local L10N              = require("L10N")
local GuideSystem       = require("GuideSystem")
----------------------------------------------------------
GuideActionSelectWidget.szRelatedWidgetName = nil
GuideActionSelectWidget.tbSelectWidgets     = nil
----------------------------------------------------------

function GuideActionSelectWidget:BindClickDelegate()
    local EventHelper = self.EventHelper
    if self.tbSelectWidgets then
        for k, v in ipairs(self.tbSelectWidgets)do
            if v then
                if v.OnClicked ~= nil then
                    EventHelper:RegisterCppDelegate(v.OnClicked,            self, self.OnSelect)
                end
                if v.OnDoubleClicked then
                    EventHelper:RegisterCppDelegate(v.OnDoubleClicked,      self, self.OnSelect)
                end
                if v.OnDisableClicked ~= nil then
                    EventHelper:RegisterCppDelegate(v.OnDisableClicked,     self, self.OnSelect)
                end
                if v.OnCheckStateChanged ~= nil then
                    EventHelper:RegisterCppDelegate(v.OnCheckStateChanged,  self, self.OnSelect)
                end
            end
        end
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_DOUBLE_FIRED, self, self.OnDoubleClick)
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_ITEM,   self, self.OnItemClick)
    EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_CHANGE, self, self.OnInteractionVisible)
end

function GuideActionSelectWidget:ExeOnece(tbTemplate)
    GuideActionSelectWidget.super.ExeOnece(self, tbTemplate)
    self:BindClickDelegate()
end

function GuideActionSelectWidget:DoAction(tbTemplate)
    GuideActionSelectWidget.super.DoAction(self, tbTemplate)
    local tbSelectWidgets = self:GetSelectWidgets()
    if not tbSelectWidgets then
        self:LogError("DoAction self.tbSelectWidgets is nil")
        self:ForceEndCurrentGroup()
        return
    end
    self:DebugLog("OnDelayTimerFunc tbSelectWidgets = " .. tostring(tbSelectWidgets) .. " count = " .. tostring(#tbSelectWidgets))
    local sType = type(tbSelectWidgets)
    self:DebugLog("sType == " .. sType .. " tbSelectWidgets = " .. tostring(tbSelectWidgets))
    if sType == "string" then
        if tbSelectWidgets == "skip" then
            self:EndAction() 
        end
    else
        if not tbSelectWidgets or #tbSelectWidgets == 0 then
            self:LogError("GuideActionSelectWidget GetSelectWidgets failed")
            self:ForceEndCurrentGroup()
            return
        end
    end
    self.tbSelectWidgets = tbSelectWidgets
    self:ShowSelectEffect()
end

function GuideActionSelectWidget:ShowSelectEffect()
    self:DebugLog(" ShowSelectEffect")
    local tbTemplate = self.tbTemplate
    local tbSelectWidgets = self.tbSelectWidgets
    if not tbSelectWidgets then
        self:LogError("ShowSelectEffect self.tbSelectWidgets is nil")
        self:ForceEndCurrentGroup()
        return
    end
    local SelectWidget = tbSelectWidgets[1]
    if SelectWidget == nil then
        self:LogError("Begin,SelectWidget is nil")
        self:ForceEndCurrentGroup()
        return
    end
    self.szRelatedWidgetName = tbTemplate.tbWidgetName[1]
    self:DebugLog("ShowSelectEffect,szVisibility="..tostring(self.tbTemplate.szVisibility))
    self.SelectWidget = SelectWidget
    self:SetSelectInfo(SelectWidget, tbTemplate)
end

function GuideActionSelectWidget:GetParentScale(tbTemplate)
    local tbScaleParent = tbTemplate.tbScaleParent
    local eLayoutType = 0
    local szScaleParentName = ""
    if tbScaleParent then
        eLayoutType = tonumber(tbScaleParent[1])
        szScaleParentName = tbScaleParent[2]
    end
    local Scale = GuideSystem:GetLayoutScale(eLayoutType, szScaleParentName) --RenderTransform.Scale
    return Scale
end

function GuideActionSelectWidget:SetSelectInfo(SelectWidget, tbTemplate)
    local pGeometry = SelectWidget:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
    local RenderTransform = SelectWidget.RenderTransform
    local pLocalScale = RenderTransform.Scale
    local nAngle = math.abs(RenderTransform.Angle)
    local pParentScale = self:GetParentScale(tbTemplate)
    local nOffsetX = 0
    local nOffsetY = 0
    local tbParam = tbTemplate.tbParam
    if tbParam and #tbParam > 1 then
        nOffsetX = tonumber(tbParam[1])
        nOffsetY = tonumber(tbParam[2])
    end
    local tbRealSize = {X = Size.X*math.abs(pParentScale.X)*pLocalScale.X+pLocalScale.X*nOffsetX*2, Y = Size.Y*math.abs(pParentScale.Y)*pLocalScale.Y+pLocalScale.Y*nOffsetY*2}
    local bRotation = 0
    if nAngle == 180 or (pLocalScale.X == -1 and pLocalScale.Y == -1) then
        bRotation = 180
    elseif nAngle == 90 then
        bRotation = nAngle
    end
    self:DebugLog("bRotation = " .. tostring(bRotation) .. " angle = " .. tostring(nAngle))
    self:DebugLog("tbTemplate SetSelectInfo szSelectWidgetName = " .. tbTemplate.szSelectWidgetName .. " bIsModal = " .. tostring(self.tbGuideTemplate.bIsModal) .. " bClickAnywhere = " .. tostring(tbTemplate.bClickAnywhere))
    self:CallSetSelectInfo({X = Pos.X - pLocalScale.X*nOffsetX, Y = Pos.Y - pLocalScale.Y*nOffsetY}, tbRealSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, bRotation, nil, tbTemplate.bMaskEffect)
    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if((tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") )then
        self:DebugLog("tbTemplate.szSelectWidgetName = nil")
        self:EndAction()
    end
    self:AfterShow()
end

function GuideActionSelectWidget:AfterShow()

end

function GuideActionSelectWidget:OnSelect()
    self:DebugLog("OnSelect1")
    if self.tbTemplate.bEffctOnly then
        return
    end
    if not self.tbTemplate.bDoubleClick then
        self:DebugLog("OnSelect2")
        self:EndAction()
    end
end

function GuideActionSelectWidget:OnItemClick()
    if self.tbTemplate.bEffctOnly then
        return
    end
    if self.SelectWidget and not self.SelectWidget.OnClicked then
        self:OnSelect()
    end
end


function GuideActionSelectWidget:OnDoubleClick()
    self:DebugLog("OnDoubleClick")
    if self.tbTemplate.bEffctOnly then
        return
    end
    if self.tbTemplate.bDoubleClick then
        self:CallShowSpaceScreen(true)
        self:EndAction()
    end
end

function GuideActionSelectWidget:OnInteractionVisible(bVisible, nInteractionType, pNpc)
    self:DebugLog("OnInteractionVisible,bVisible="..tostring(bVisible).." self.szRelatedWidgetName="..tostring(self.szRelatedWidgetName))
    if self.tbTemplate.szUIName == UIDef.UI_MAIN or self.tbTemplate.szUIName == UIDef.UI_BATTLE_MAIN 
    and self.szRelatedWidgetName == "btnInteraction" then
        if bVisible == false and not self.tbGuideTemplate.bIsModal then
            self:ForceEndCurrentGroup()
        end
    end
end

function GuideActionSelectWidget:OnCloseUI(szWndName)
    self:DebugLog("OnCloseUI, szWndName=".. szWndName .." self.tbTemplate.szUIName = "..self.tbTemplate.szUIName)
    if szWndName == UIDef.UI_GUIDE then
        self:DebugLog(" szWndName = UI_GUIDE")
        self:StopEffectSound()
        return
    end
    if self.tbTemplate.szUIName == szWndName then
--selectwidget是用于让玩家选择、点击某个按钮的，如果当目标引导UI被关闭时，只有此一步引导是非模态的
--如果设计如此，那么可以认定这个引导的目的是在于引导某个按钮并且当目标界面关闭时隐藏，再次打开时则再次显示
--所以在此应该只是隐藏引导界面而不是关闭
        self:ActiveGuideWnd(false)
    else
        self:IsShowTopUI()
    end
end

return GuideActionSelectWidget
