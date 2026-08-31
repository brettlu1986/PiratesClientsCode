-----------------------------------------------------
--File Name    : GuideTriggerPlayerSelfReady.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerPlayerSelfReady = luaclass("GuideTriggerPlayerSelfReady",GuideTrigger)

local ClientEventDef = require("ClientEventDef")


--override


function GuideTriggerPlayerSelfReady:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, self.OnPlayerSelfReady)
end

function GuideTriggerPlayerSelfReady:OnPlayerSelfReady()
    self:DebugLog("OnPlayerSelfReady")
    self:Trigger()
end



return GuideTriggerPlayerSelfReady
