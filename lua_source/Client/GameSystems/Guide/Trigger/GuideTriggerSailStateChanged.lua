-----------------------------------------------------
--File Name    : GuideTriggerSailStateChanged.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerSailStateChanged = luaclass("GuideTriggerSailStateChanged",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override
function GuideTriggerSailStateChanged:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_QUIDE_SAIL_STATE_CHANGED, self, self.OnRefreshState)
end

function GuideTriggerSailStateChanged:OnRefreshState(bCruise)
    self:DebugLog("OnRefreshState,bCruise="..tostring(bCruise))
    if(bCruise)then
        self:Trigger()
    else
        self.bIsTrigger = false
    end
    
end

return GuideTriggerSailStateChanged
