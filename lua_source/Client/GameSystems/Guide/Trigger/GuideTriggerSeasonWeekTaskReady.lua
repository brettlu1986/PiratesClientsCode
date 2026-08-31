-----------------------------------------------------
--File Name    : GuideTriggerCloseUI.lua
--Author       : Edward J
--Create Time  : 2019-05-15
--Description  : 指引触发
-----------------------------------------------------
local luaclass                          = require("luaclass")
local GuideTrigger                      = require("GuideTrigger")
local GuideTriggerSeasonWeekTaskReady   = luaclass("GuideTriggerSeasonWeekTaskReady",GuideTrigger)

local SeasonSystem                  = require("SeasonSystem")
local Proto                         = require("ClientProtoNames")
local ChallengeSubIndexDataTable    = require("ChallengeSubIndexDataTable")
local ClientEventDef                = require("ClientEventDef")
-----------------------------------------------------
local CHALLENGETYPE = Proto.ChallengeType.WEEKLY

local function RequestGetWeekChallenge()
    SeasonSystem:RequestGetChallenge(CHALLENGETYPE)
end

function GuideTriggerSeasonWeekTaskReady:OnRefreshSeasonChallenge()
    local tbSubId = self.tbTemplate.tbItemId
    local nSubId = tbSubId[1]
    local SeasonComponent = SeasonSystem:GetComponent()
    local tbTask = SeasonComponent:GetSeasonChallengeById(CHALLENGETYPE, nSubId)
    local bResult = false
    if tbTask then
        local tbTemplate = ChallengeSubIndexDataTable:GetTemplate(CHALLENGETYPE, nSubId)    
        if tbTemplate then
            bResult = (tbTask.progress == tbTemplate.nObjectiveEnd)
            self:DebugLog("progress = " .. tostring(tbTask.progress) .. "nObjectiveEnd" .. tostring(tbTemplate.nObjectiveEnd))
        end
    end
    self:DebugLog("CheckWeekTaskReady() = " .. tostring(bResult))
    if bResult then
        self:Trigger()
    end
end

--override
function GuideTriggerSeasonWeekTaskReady:Begin()
    GuideTriggerSeasonWeekTaskReady.super.Begin(self)
    RequestGetWeekChallenge()
end

function GuideTriggerSeasonWeekTaskReady:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE, self, self.OnRefreshSeasonChallenge)
end


return GuideTriggerSeasonWeekTaskReady