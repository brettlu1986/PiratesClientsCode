-----------------------------------------------------
--File Name    : GuideTriggerUIAnimationEnd.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerUIAnimationEnd = luaclass("GuideTriggerUIAnimationEnd",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override


function GuideTriggerUIAnimationEnd:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_ANIMATION_END, self, self.OnUIAnimEnd)
end

function GuideTriggerUIAnimationEnd:OnUIAnimEnd(szUIName, szAnimName)
    self:DebugLog("OnUIAnimEnd,szUIName="..tostring(szUIName).." self.szuiname="..tostring(self.tbTemplate.szOpenUIName) .. " szAnimName="..tostring(szAnimName))
    local tbTemplate = self.tbTemplate
    if szUIName == tbTemplate.szOpenUIName and (not tbTemplate.tbWidgetName or tbTemplate.tbWidgetName[1] == szAnimName) then
        self:DebugLog("OnUIAnimEnd,Trigger Start")
        self:Trigger()
    end
end



return GuideTriggerUIAnimationEnd
