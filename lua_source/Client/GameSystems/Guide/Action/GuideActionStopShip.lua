-----------------------------------------------------
--File Name    : GuideActionSelectWidget.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionSelectMultiWidget  = require("GuideActionSelectMultiWidget")
local GuideActionStopShip           = luaclass("GuideActionStopShip", GuideActionSelectMultiWidget)

local UIManager         = require("UIManager")
local UIDef             = require("UIDef")
local ControlModeDef    = require("ControlModeDef")
local L10N              = require("L10N")
----------------------------------------------------------
local GetLocalSize = SlateBlueprintLibrary.GetLocalSize
local LocalToAbsolute = SlateBlueprintLibrary.LocalToAbsolute
local nReverse = 4
local nStopped = 3
----------------------------------------------------------
function GuideActionStopShip:CheckShipGear()
    local Wnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not Wnd then
        self:LogError("GuideActionStopShip:CheckShipGear Wnd is nil")
        return nil
    end
    local pShipJoystick = Wnd.tbControlModePrefab[ControlModeDef.SHIP].pbSailControl
    if not pShipJoystick then
        self:LogError("GuideActionStopShip:CheckShipGear pShipJoystick is nil")
        return nil
    end
    return pShipJoystick.nCurrentGearValue
end

function GuideActionStopShip:SetSelectInfo(tbSelectWidgets, tbTemplate)
    local nGear = self:CheckShipGear()
    self:DebugLog("GuideActionStopShip SetSelectInfo nGear = " .. tostring(nGear))
    local pParentScale = self:GetParentScale(tbTemplate)
    if nGear == nStopped then
        local tbPos = {}
        local tbSize = {}
        local tbRotate = {}
        for i, Widget in ipairs(tbSelectWidgets) do
            local pGeometry = Widget:GetCachedGeometry()
            local Size = GetLocalSize(pGeometry)
            local Pos = LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
            self:DebugLog(" GuideActionStopShip1 Size.X = " .. Size.X .. " Size.Y = " .. Size.Y .. " Pos.X = " .. Pos.X .. " Pos.Y = " .. Pos.Y)
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
    else
        local pWidget = tbSelectWidgets[1]
        self:DebugLog("GuideActionStopShip SetSelectInfo Reverse = " .. tostring(nReverse))
        if nGear == nReverse then
            self:DebugLog("GuideActionStopShip1111")
            pWidget = tbSelectWidgets[1]
        else
            pWidget = tbSelectWidgets[2]
            self:DebugLog("GuideActionStopShip2222")
        end
        local pGeometry = pWidget:GetCachedGeometry()
        local Size = GetLocalSize(pGeometry)
        local Pos = LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
        self:DebugLog(" GuideActionStopShip2 Size.X = " .. Size.X .. " Size.Y = " .. Size.Y .. " Pos.X = " .. Pos.X .. " Pos.Y = " .. Pos.Y)
        local RenderTransform = pWidget.RenderTransform
        local nAngle = math.abs(RenderTransform.Angle)
        local pLocalScale = RenderTransform.Scale
        local bRotation = false
        if nAngle == 180 or (pLocalScale.X == -1 and pLocalScale.Y == -1) then
            bRotation = true
        end
        local tbRealSize = {X = Size.X*math.abs(pParentScale.X)*pLocalScale.X, Y = Size.Y*math.abs(pParentScale.Y)*pLocalScale.X}
        self:CallSetSelectInfo(Pos, tbRealSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
        tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, bRotation, false, tbTemplate.bMaskEffect)
    end
    self:DebugLog("tbTemplate.szSelectWidgetName = "..tostring(tbTemplate.szSelectWidgetName))
    if (tbTemplate.szSelectWidgetName == nil or tbTemplate.szSelectWidgetName == "") and (L10N:ToString(tbTemplate.l10nGuideText) ~= nil and L10N:ToString(tbTemplate.l10nGuideText) ~= "") then
        self:EndAction()
    end
end

return GuideActionStopShip
