-----------------------------------------------------
--File Name    : GuideTriggerSeasonRefreshFinish.lua
--Author       : Edward J
--Create Time  : 2019-05-14
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerSeasonRefreshFinish   = luaclass("GuideTriggerSeasonRefreshFinish",GuideTrigger)

local ClientEventDef          = require("ClientEventDef")
-----------------------------------------------------
--override

function GuideTriggerSeasonRefreshFinish:OnChanllengeRefreshFinish()
    self:Trigger()
end

function GuideTriggerSeasonRefreshFinish:Begin()
    GuideTriggerSeasonRefreshFinish.super.Begin(self)
end

function GuideTriggerSeasonRefreshFinish:BindEvent(EventHelper)
    GuideTriggerSeasonRefreshFinish.super.BindEvent(self, EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_CHALLENGE_REFRESH_FINISH, self, self.OnChanllengeRefreshFinish)
end

return GuideTriggerSeasonRefreshFinish
