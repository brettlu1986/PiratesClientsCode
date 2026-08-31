-----------------------------------------------------
--File Name    : GuideActionSimpleSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                        = require("luaclass")
local GuideActionSelectWidget         = require("GuideActionSelectWidget")
local GuideActionSimpleSelectWidget   = luaclass("GuideActionSimpleSelectWidget", GuideActionSelectWidget)

local L10N              = require("L10N")
----------------------------------------------------------

function GuideActionSimpleSelectWidget:SetSelectInfo(SelectWidget, tbTemplate)
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
    local tbRealSize = {X = Size.X*math.abs(pParentScale.X)*pLocalScale.X+nOffsetX, Y = Size.Y*math.abs(pParentScale.Y)*pLocalScale.Y+nOffsetY}
    local bRotation = 0
    if nAngle == 180 or (pLocalScale.X == -1 and pLocalScale.Y == -1) then
        bRotation = 180
    elseif nAngle == 90 then
        bRotation = nAngle
    end
    self:DebugLog("GuideActionSelectWidget bRotation = " .. tostring(bRotation) .. " angle = " .. tostring(nAngle))
    self:DebugLog("tbTemplate SetSelectInfo szSelectWidgetName = " .. tbTemplate.szSelectWidgetName .. " bIsModal = " .. tostring(self.tbGuideTemplate.bIsModal) .. " bClickAnywhere = " .. tostring(tbTemplate.bClickAnywhere))
    self:CallSetSimpleSelectInfo({X = Pos.X - nOffsetX*0.5, Y = Pos.Y - nOffsetY*0.5}, tbRealSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, tbTemplate.nGuidePos, self, bRotation)
    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if(tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") then
        self:DebugLog("tbTemplate.szSelectWidgetName = nil")
        self:EndAction()
    end
    self:AfterShow()
end

function GuideActionSimpleSelectWidget:OnSelect()
    
end

function GuideActionSimpleSelectWidget:OnItemClick()
    
end


function GuideActionSimpleSelectWidget:OnDoubleClick()
   
end

return GuideActionSimpleSelectWidget
