-----------------------------------------------------
--File Name    : GuideTrigger.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerShowSelectPointBtn    = luaclass("GuideTriggerShowSelectPointBtn", GuideTrigger)

local ClientEventDef                = require("ClientEventDef")
-----------------------------------------------------
function GuideTriggerShowSelectPointBtn:OnControlModeActivate()
    self:DebugLog("OnControlModeActivate ")
    self:Trigger()
end

--override
function GuideTriggerShowSelectPointBtn:Begin()
    GuideTriggerShowSelectPointBtn.super.Begin(self)
end

function GuideTriggerShowSelectPointBtn:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_SELECT_POINT_BTN, self, self.OnControlModeActivate)
end

return GuideTriggerShowSelectPointBtn
