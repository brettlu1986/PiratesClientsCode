local luaclass = require("luaclass")
local CommonAwardSession = require("CommonAwardSession")
local SeasonAwardSession = luaclass("SeasonAwardSession", CommonAwardSession)
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local UIDef = require("UIDef")
local AwardSystem = require("AwardSystem")
local Proto = require("ClientProtoNames")

SeasonAwardSession.EventHelper = nil

local function OnCloseUI(self, szWndName)
    if szWndName == UIDef.UI_LOBBY_AWARD_ITEM then
        self.EventHelper:FireEvent(ClientEventDef.EV_ON_AWARD_SEASON)
    end
end

function SeasonAwardSession:OnStarted(tbParams)
    SeasonAwardSession.super.OnStarted(self, tbParams)
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)
end

function SeasonAwardSession:OnFinished()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    SeasonAwardSession.super.OnFinished(self)
    AwardSystem:ShowCacheAward()
end

function SeasonAwardSession:TryFinish()

end

function SeasonAwardSession:CheckShowAward(nSourceType)
    local AwardSourceType = Proto.AwardSourceType
    if nSourceType == AwardSourceType.SEASON_BATTLE_PASS then
        return false
    else
        return true
    end
end

return SeasonAwardSession