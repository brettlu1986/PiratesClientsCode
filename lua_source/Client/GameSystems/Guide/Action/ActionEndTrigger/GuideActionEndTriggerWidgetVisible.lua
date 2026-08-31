-----------------------------------------------------
--File Name    : GuideActionForceEndBase.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                              = require("luaclass")
local GuideActionEndTriggerBase             = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerWidgetVisible    = luaclass("GuideActionEndTriggerWidgetVisible", GuideActionEndTriggerBase)

-----------------------------------------------------
local function CheckWidgetVisible(self)
    local bCheckVisible = self.tbParam[1] == "1"
    local tbSelectWidgets = self:GetSelectWidgets()
    self:DebugLog("CheckWidgetVisible " .. tostring(tbSelectWidgets) .. " count = " .. tostring(#tbSelectWidgets))
    if not tbSelectWidgets or #tbSelectWidgets == 0 then
        self:LogError("CheckWidgetVisible widgets is nil")
        return
    end
    local tbWidget = tbSelectWidgets[1]
    local bVisble = tbWidget:IsVisible()
    self:DebugLog("CheckWidgetVisible bVisble = " .. tostring(bVisble))
    if not bCheckVisible then
        bVisble = not bVisble
    end
    if bVisble then
        self:Triggered()
    end
end

function GuideActionEndTriggerWidgetVisible:BindEvent(tbParam)
    GuideActionEndTriggerWidgetVisible.super.BindEvent(self, tbParam)
    CheckWidgetVisible(self)
end

return GuideActionEndTriggerWidgetVisible
