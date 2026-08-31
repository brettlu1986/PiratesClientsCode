local luaclass = require("luaclass")
local CommonAwardSession = require("CommonAwardSession")
local SeasonResultAwardSession = luaclass("SeasonResultAwardSession", CommonAwardSession)
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local AwardSystem = require("AwardSystem")
local Proto = require("ClientProtoNames")

SeasonResultAwardSession.EventHelper = nil

local function OnShowSeasonResultAward(self)
    self:FinishSelf()
end

function SeasonResultAwardSession:OnStarted(tbParams)
    SeasonResultAwardSession.super.OnStarted(self, tbParams)
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_SEASON_RESULT_AWARD_GET, self, OnShowSeasonResultAward)
end

function SeasonResultAwardSession:OnFinished()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    SeasonResultAwardSession.super.OnFinished(self)
    AwardSystem:ShowCacheAward()
end

function SeasonResultAwardSession:TryFinish()

end

function SeasonResultAwardSession:CheckShowAward(nSourceType)
    local AwardSourceType = Proto.AwardSourceType
    if nSourceType == AwardSourceType.SEASON then
        return false
    else
        return true
    end
end

return SeasonResultAwardSession