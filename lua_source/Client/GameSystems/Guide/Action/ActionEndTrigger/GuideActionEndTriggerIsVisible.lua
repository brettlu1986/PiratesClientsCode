-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerIsVisible        = luaclass("GuideActionEndTriggerIsVisible", GuideActionEndTriggerBase)

local TIME_TICK = 1 / 30
-----------------------------------------------------
function GuideActionEndTriggerIsVisible:CheckIsVisible()
    local szType = self.tbParam[1]
    local tbSelectWidgets = self:GetSelectWidgets()
    if not tbSelectWidgets or #tbSelectWidgets == 0 then
        self:DebugLog("CheckIsVisible1 tbSelectWidgets is nil")
        tbSelectWidgets = self:GetSelectPrefab()
    end
    if not tbSelectWidgets or #tbSelectWidgets == 0 then
        self:LogError("CheckIsVisible2 tbSelectWidgets is nil")
        return
    end
    
    local Widget = tbSelectWidgets[1]
    if not Widget then
        self:LogError("CheckWidgetVisible Widget is nil")
        return
    end
    local bVisible = Widget:IsVisible()
    self:DebugLog("CheckIsVisible bVisible = " .. tostring(bVisible))
    if szType == "visible" and bVisible then
        self:Triggered()
    elseif szType == "invisible" and not bVisible then
        self:Triggered()
    end
end

function GuideActionEndTriggerIsVisible:BindEvent(tbParam)
    GuideActionEndTriggerIsVisible.super.BindEvent(self, tbParam)
    self.TimerHelper:NewTimerMethod(self, self.CheckIsVisible, TIME_TICK, true)
end

return GuideActionEndTriggerIsVisible
