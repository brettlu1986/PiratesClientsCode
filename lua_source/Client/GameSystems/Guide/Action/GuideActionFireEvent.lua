-----------------------------------------------------
--File Name    : GuideActionFireEvent.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass              = require("luaclass")
local GuideActionFunctional = require("GuideActionFunctional")
local GuideActionFireEvent  = luaclass("GuideActionFireEvent",GuideActionFunctional)

--import
local ClientEventDef        = require("ClientEventDef")
local CommonEventDef        = require("CommonEventDef")
--local 
GuideActionFireEvent.szEventName = ""

function GuideActionFireEvent:Begin()
    self:DebugLog(" GuideActionFireEvent Begin")
    GuideActionFireEvent.super.Begin(self)
    self.szEventName = self.tbTemplate.tbParam[1]
end

function GuideActionFireEvent:DoAction(tbTemplate)
    GuideActionFireEvent.super.DoAction(self, tbTemplate)
    self:DebugLog(" GuideActionFireEvent:DoAction")
    local szEventName = self.szEventName
    if not szEventName or szEventName == "" then
        self:EndAction()
        return
    end
    local EventName = ClientEventDef[szEventName]
    if not EventName then
        EventName = CommonEventDef[szEventName]
    end
    self:DebugLog(" GuideActionFireEvent:BindEvent, EventNameid = " .. EventName .. " EventName = " .. szEventName)
    self.EventHelper:FireEvent(EventName, self.tbTemplate.tbParam)
end

return GuideActionFireEvent
