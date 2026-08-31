-----------------------------------------------------
--File Name    : GuideActionEndTriggerReachLevel.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerReachLevel           = luaclass("GuideActionEndTriggerReachLevel", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function GetLobbyPropertyComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = PlayerSelf.LobbyPropertyComponent
    return LobbyPropertyComponent
end

local function OnPlayerLevelUp(self)
    self:DebugLog("OnPlayerReachLevel")
    local LobbyPropertyComponent = GetLobbyPropertyComponent()
	local nLevel = LobbyPropertyComponent:GetPlayerLevel()
	local szTriggerLevel = self.tbParam[1]
    local nTriggerLevel = nil
    if szTriggerLevel then
        nTriggerLevel = tonumber(szTriggerLevel)
    end
    if nTriggerLevel and nLevel >= nTriggerLevel then
        self:Triggered()
    end
end

function GuideActionEndTriggerReachLevel:BindEvent(tbParam)
    GuideActionEndTriggerReachLevel.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW, self, OnPlayerLevelUp)
end

return GuideActionEndTriggerReachLevel
