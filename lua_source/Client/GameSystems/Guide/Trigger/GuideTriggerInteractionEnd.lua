-----------------------------------------------------
--File Name    : GuideTriggerInteractionEnd.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerInteractionEnd = luaclass("GuideTriggerInteractionEnd",GuideTrigger)

local ClientEventDef = require("ClientEventDef")

--override

function GuideTriggerInteractionEnd:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_INTERACTION_END, self, self.OnInteractionEnd)
end

function GuideTriggerInteractionEnd:OnInteractionEnd(nInteractionId)
    self:DebugLog("OnInteractionEnd,nInteractionId="..tostring(nInteractionId).." self.tbTemplate.nInteractionId="..tostring(self.tbTemplate.nInteractionId))
    if(nInteractionId == self.tbTemplate.nInteractionId)then
        self:Trigger()
    end
end



return GuideTriggerInteractionEnd
