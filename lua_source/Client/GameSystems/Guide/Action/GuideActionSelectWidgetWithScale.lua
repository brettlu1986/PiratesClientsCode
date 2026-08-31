-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideActionSelectVisibleWidget    = require("GuideActionSelectVisibleWidget")
local GuideActionSelectWidgetWithScale  = luaclass("GuideActionSelectWidgetWithScale", GuideActionSelectVisibleWidget)

local L10N              = require("L10N")
----------------------------------------------------------

function GuideActionSelectWidgetWithScale:SetSelectInfo(SelectWidget, tbTemplate)
    local pGeometry = SelectWidget:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
    local RenderTransform = SelectWidget.RenderTransform
    local nAngle = math.abs(RenderTransform.Angle)
    local Scale = RenderTransform.Scale
    local tbParam = tbTemplate.tbParam
    if not tbParam then
        return
    end
    local nScaleX = tonumber(tbParam[1])
    local nScaleY = tonumber(tbParam[2])
    local nOffsetX = 0
    local nOffsetY = 0
    if #tbParam > 2 then
        nOffsetX = tonumber(tbParam[3])
        nOffsetY = tonumber(tbParam[4])
    end
    local pParentScale = self:GetParentScale(tbTemplate)
    self:DebugLog("ParentScale.X = " .. tostring(nScaleX) .. " ParentScale.Y = " .. tostring(nScaleY))
    local tbRealSize = {X = Size.X*nScaleX*pParentScale.X + nScaleX*nOffsetX*2, Y = Size.Y*nScaleY*pParentScale.Y + nScaleX*nOffsetY*2}
    local bRotation = 0
    if nAngle == 180 or (Scale.X == -1 and Scale.Y == -1) then
        bRotation = 180
    elseif nAngle == 90 then
        bRotation = nAngle
    end
    self:DebugLog("bRotation = " .. tostring(bRotation) .. " angle = " .. tostring(nAngle))
    self:DebugLog("tbRealSize.X = " .. tbRealSize.X .. " tbRealSize.Y = " .. tbRealSize.Y)
    self:DebugLog("tbTemplate SetSelectInfo szSelectWidgetName = " .. tbTemplate.szSelectWidgetName .. " bIsModal = " .. tostring(self.tbGuideTemplate.bIsModal) .. " bClickAnywhere = " .. tostring(tbTemplate.bClickAnywhere))
    self:CallSetSelectInfo({X = Pos.X - nScaleX*nOffsetX, Y = Pos.Y - nScaleX*nOffsetY}, tbRealSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, bRotation, nil, tbTemplate.bMaskEffect)
    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if (tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") then
        self:DebugLog("tbTemplate.szSelectWidgetName = nil")
        self:EndAction()
    end
    self:AfterShow()
end

return GuideActionSelectWidgetWithScale
