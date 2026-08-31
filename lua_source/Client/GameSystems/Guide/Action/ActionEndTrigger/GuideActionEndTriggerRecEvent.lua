-----------------------------------------------------
--File Name    : GuideActionEndTriggerRecEvent.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerRecEvent             = luaclass("GuideActionEndTriggerRecEvent", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
local CommonEventDef        = require("CommonEventDef")
-----------------------------------------------------

function GuideActionEndTriggerRecEvent:BindEvent(tbParam)
    GuideActionEndTriggerRecEvent.super.BindEvent(self, tbParam)
    local szEventName = tbParam[1]
        local EventName = ClientEventDef[szEventName]
        if not EventName then
            EventName = CommonEventDef[szEventName]
        end
        if not EventName then
            self:Triggered()
            return
        end
        self.EventHelper:RegisterEvent(EventName, self, self.Triggered)
end

return GuideActionEndTriggerRecEvent
