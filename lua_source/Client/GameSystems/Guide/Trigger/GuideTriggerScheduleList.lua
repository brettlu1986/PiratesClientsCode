-----------------------------------------------------
--File Name    : GuideTriggerScheduleList.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerScheduleList = luaclass("GuideTriggerScheduleList", GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerScheduleList:BindEvent(EventHelper)
    self:DebugLog("BindEvent")
    EventHelper:RegisterEvent(ClientEventDef.EV_GUIDE_ON_SCHEDULE_LIST, self, self.OnScheduleList)
end

function GuideTriggerScheduleList:OnScheduleList()
    self:DebugLog("OnScheduleList")
    self:Trigger()
end

return GuideTriggerScheduleList
