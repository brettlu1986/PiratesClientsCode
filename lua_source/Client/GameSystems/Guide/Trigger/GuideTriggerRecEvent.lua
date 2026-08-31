-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideTrigger          = require("GuideTrigger")
local GuideTriggerRecEvent  = luaclass("GuideTriggerRecEvent", GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
local CommonEventDef    = require("CommonEventDef")
-----------------------------------------------------

function GuideTriggerRecEvent:OnReciveEvent()
    self:DebugLog("GuideTriggerRecEvent:OnReciveEvent, EventName = " .. self.tbTemplate.szEventName)
    self:Trigger()
end

--override
function GuideTriggerRecEvent:Begin()
    GuideTriggerRecEvent.super.Begin(self)
end

function GuideTriggerRecEvent:BindEvent(EventHelper)
    local tbTemplate = self.tbTemplate
    if not tbTemplate.szEventName or tbTemplate.szEventName == "" then
        return
    end
    local EventName = ClientEventDef[tbTemplate.szEventName]
    if not EventName then
        EventName = CommonEventDef[tbTemplate.szEventName]
    end
    self:DebugLog("BindEvent, EventNameid = " .. EventName .. " EventName = " .. tbTemplate.szEventName)
    EventHelper:RegisterEvent(EventName, self, self.OnReciveEvent)
end

return GuideTriggerRecEvent
