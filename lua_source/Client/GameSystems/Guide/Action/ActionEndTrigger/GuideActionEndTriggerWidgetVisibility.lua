-----------------------------------------------------
--File Name    : GuideActionEndTriggerWidgetVisibility.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerWidgetVisibility     = luaclass("GuideActionEndTriggerWidgetVisibility", GuideActionEndTriggerBase)

-----------------------------------------------------

local function IsWidgetVisible(self)
    local tbSelectWidgets = self:GetSelectWidgets()
    if not tbSelectWidgets then
        self:LogError("GuideActionForceEndStep tbSelectWidgets is nil")
        self:Triggered()
        return
    end
    local tbWidget = tbSelectWidgets[1]
    if not tbWidget then
        self:LogError("GuideActionForceEndStep tbWidget is nil")
        self:Triggered()
        return
    end
    local bVisible = tbWidget:IsVisible()
    local bEnable = self.tbTemplate.bEnable
    if not bEnable then
        bVisible = not bVisible
    end
    if bVisible then
        self:Triggered()
    end
end

function GuideActionEndTriggerWidgetVisibility:BindEvent(tbParam)
    GuideActionEndTriggerWidgetVisibility.super.BindEvent(self, tbParam)
    IsWidgetVisible(self)
end

return GuideActionEndTriggerWidgetVisibility
