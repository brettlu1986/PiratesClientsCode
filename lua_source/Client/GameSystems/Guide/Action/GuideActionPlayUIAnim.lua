-----------------------------------------------------
--File Name    : GuideActionPlayUIAnim.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideActionFullUIControl      = require("GuideActionFullUIControl")
local GuideActionPlayUIAnim         = luaclass("GuideActionPlayUIAnim", GuideActionFullUIControl)

local UIManager             = require("UIManager")
local ClientEventDef        = require("ClientEventDef")
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local L10N                  = require("L10N")
----------------------------------------------------------
GuideActionPlayUIAnim.AnimWnd           = nil
GuideActionPlayUIAnim.szAnimName        = nil
GuideActionPlayUIAnim.szAnimWndName     = nil
GuideActionPlayUIAnim.bClickHandle      = nil
GuideActionPlayUIAnim.pSelectWidget     = nil
----------------------------------------------------------
function GuideActionPlayUIAnim:DoAction(tbTemplate)
    GuideActionPlayUIAnim.super.DoAction(self, tbTemplate)
    local pSelectWidget = self.pSelectWidget
    if pSelectWidget then
        local pGeometry = pSelectWidget:GetCachedGeometry()
        local Size = SlateBlueprintLibrary.GetLocalSize(pGeometry)
        local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=0,Y=0})
        self:DebugLog("OnDelayTimerFunc pSelectWidget = " .. tostring(pSelectWidget) .. " Size.x = " .. Size.X .. " Pos.x = " .. Pos.X)
        self:CallSetSelectInfo(Pos, Size, tbTemplate.szSelectWidgetName, L10N:ToString(tbTemplate.l10nGuideText),
        tbTemplate.szGuidePicPath, self.tbGuideTemplate.bIsModal, tbTemplate.bClickAnywhere, tbTemplate.nGuidePos, self)
    end
    self:DebugLog("Begin WndName = " .. tostring(self.szAnimWndName) .. " AnimName = " .. tostring(self.szAnimName))
    local pAnimWnd = self.AnimWnd
    if pAnimWnd and pAnimWnd.pWidgetRef then
        pAnimWnd:PlayAnimation(self.szAnimName, 0, 0, EUMGSequencePlayMode.Forward, 1)
    end
end

function GuideActionPlayUIAnim:Begin()
    self:DebugLog("Begin ")
    GuideActionPlayUIAnim.super.Begin(self)  
    local tbTemplate = self.tbTemplate
    if tbTemplate.tbParam then
        local szEndTrigger = tbTemplate.tbParam[1]
        if szEndTrigger == "Joystick" then
            self.EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, self, self.OnMoveTypeChange)
        end
    end
    local szAnimWndName = tbTemplate.tbUIAnim[1]
    local szAnimName = tbTemplate.tbUIAnim[2]
    if not szAnimWndName or not szAnimName then
        self:LogError("invalid szAnimWndName or szAnimName=", szAnimWndName, szAnimName)
        return
    end
    self.szAnimWndName = szAnimWndName
    self.AnimWnd = UIManager:GetWnd(szAnimWndName)
    if not self.AnimWnd or not UIManager:IsWndOpen(szAnimWndName) then
        self.AnimWnd = UIManager:OpenWnd(szAnimWndName)
    end
    if not self.AnimWnd then
        self:LogError("invalid AnimWnd, szAnimWndName, szAnimName=", szAnimWndName, szAnimName)
        return
    end
    --选中的widget
    local tbSelectWidgets = self:GetSelectWidgets()
    if tbSelectWidgets and #tbSelectWidgets > 0 and tbSelectWidgets[1] ~= nil then
        local pSelectWidget = tbSelectWidgets[1]
        self.pSelectWidget = pSelectWidget 
        if pSelectWidget.OnClicked ~= nil and not self.bClickHandle then
            self.bClickHandle = self.EventHelper:RegisterCppDelegate(pSelectWidget.OnClicked, self, self.OnSelect)
            self.EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_CLICK_SELECT, self, self.OnSelect)
        end
    end
    if tbTemplate.bClickAnywhere then
        self:CallShowSpaceScreen(true)
        -- self:CallSetDelayClickAnyWhere()
    end
    --绑定AnimWnd userwidget的事件
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_DEACTIVE, self.tbTemplate.szUIName, true)
    self.szAnimName = szAnimName
end

function GuideActionPlayUIAnim:End()
    self:DebugLog("End")
    local AnimWnd = UIManager:GetWnd(self.szAnimWndName)
    if self.szAnimName and AnimWnd and AnimWnd.pWidgetRef then
        AnimWnd:StopAnimation(self.szAnimName)
        self.szAnimName = nil
    end
    GuideActionPlayUIAnim.super.End(self)
end

function GuideActionPlayUIAnim:OnMoveTypeChange(nState)
    if self.tbTemplate.bEffctOnly then
        return
    end
    if nState == HumanWeaponCalculator.SpreadEnum.MOVE_RUN then
        self:EndAction()
    end
end

function GuideActionPlayUIAnim:OnClickAnywhere()
    self:OnSelect()
end

function GuideActionPlayUIAnim:OnSelect()
    self:DebugLog(" GuideActionPlayUIAnim:OnSelect")
    if self.tbTemplate.bEffctOnly then
        return
    end
    if self.tbGuideTemplate.bIsModal then
        self:CallShowSpaceScreen(true)
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_UI_DEACTIVE, self.tbTemplate.szUIName, false)
    self:EndAction()
end

function GuideActionPlayUIAnim:OnTimerFunc()
    self:DebugLog(" GuideAction:OnTimerFunc")
    local szSimpleEnd = self.tbTemplate.tbParam[2]    
    if not szSimpleEnd then
        self:EndAction()
    else
        if tonumber(szSimpleEnd) > 0 then
            self:CallUIFunc("HideTextGuide", nil)
        end
    end
end

return GuideActionPlayUIAnim
