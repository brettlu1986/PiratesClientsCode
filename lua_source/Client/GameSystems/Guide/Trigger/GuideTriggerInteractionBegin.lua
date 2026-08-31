-----------------------------------------------------
--File Name    : GuideTriggerInteractionBegin.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerInteractionBegin = luaclass("GuideTriggerInteractionBegin",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerInteractionBegin:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_START, self, self.OnInteractionStart)
end

function GuideTriggerInteractionBegin:OnInteractionStart()
    self:Trigger()
end

return GuideTriggerInteractionBegin
