-----------------------------------------------------
--File Name    : GuideActionMoveForward.lua
--Author       : Edward J
--Create Time  : 2019-09-02
--Description  : 指引向前走
-----------------------------------------------------
local luaclass                  = require("luaclass")
local GuideActionFunctional     = require("GuideActionFunctional")
local GuideActionMoveForward    = luaclass("GuideActionMoveForward", GuideActionFunctional)

local UIManager                 = require("UIManager")
local UIDef                     = require("UIDef")
local UPHumanVirtualJoystick    = require("UPHumanVirtualJoystick")
local L10N                      = require("L10N")
--local ClientEventDef            = require("ClientEventDef")
-----------------------------------------------------
GuideActionMoveForward.pJoystick = nil
-----------------------------------------------------

local function SetVirtualJoystickEnable(self)
    local tbTemplate = self.tbTemplate
    local bP1 = tonumber(tbTemplate.tbParam[1]) >= 1
    local bP2 = tonumber(tbTemplate.tbParam[2]) >= 1
    local bP3 = tonumber(tbTemplate.tbParam[3]) >= 1
    local bP4 = tonumber(tbTemplate.tbParam[4]) >= 1
    UPHumanVirtualJoystick.LockDirections(bP1, bP2, bP3, bP4)  
    local tbSelectWidgets = self:GetSelectWidgets()
    if not tbSelectWidgets or #tbSelectWidgets == 0 then
        self:ForceEndCurrentGroup()
        return
    end
    local SelectWidget = tbSelectWidgets[1]
    local pGeometry = SelectWidget:GetCachedGeometry()
    local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
    local RenderTransform = SelectWidget.RenderTransform
    local pLocalScale = RenderTransform.Scale
    local tbRealSize = {X = Size.X*pLocalScale.X, Y = Size.Y*pLocalScale.X}
    self:DebugLog(" Pos.X = " .. Pos.X .. " Pos.Y = " .. Pos.Y .. " tbRealSize.X = " .. tbRealSize.X .. " tbRealSize.Y = " .. tbRealSize.Y)
    self:CallSetSelectInfo(Pos, tbRealSize, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
    tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self, nil, nil, tbTemplate.bMaskEffect)
end

function GuideActionMoveForward:Begin()
    GuideActionMoveForward.super.Begin(self)
    local pMainWnd = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    if not pMainWnd then
        self:EndAction()
        return
    end
    local pJoystick = pMainWnd.pWidgetRef.pbVirtualJoystick
    if not pJoystick then
        self:EndAction()
        return
    end
    SetVirtualJoystickEnable(self)
end

return GuideActionMoveForward
