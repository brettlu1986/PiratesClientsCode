-----------------------------------------------------
--File Name    : GuideTriggerSeasonFirstTime.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass                      = require("luaclass")
local GuideTrigger                  = require("GuideTrigger")
local GuideTriggerSeasonFirstTime   = luaclass("GuideTriggerSeasonFirstTime",GuideTrigger)

local ClientEventDef    = require("ClientEventDef")
local Proto             = require("ClientProtoNames")
-----------------------------------------------------
--override
function GuideTriggerSeasonFirstTime:OnRecSeasonStatus(nStatus)
    if Proto.PlayerSeasonStatus.FIRST_TIME == nStatus then
        self:Trigger()
    end
end

function GuideTriggerSeasonFirstTime:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_STATUS, self, self.OnRecSeasonStatus)
end

function GuideTriggerSeasonFirstTime:Begin()
    GuideTriggerSeasonFirstTime.super.Begin(self)
end

return GuideTriggerSeasonFirstTime
