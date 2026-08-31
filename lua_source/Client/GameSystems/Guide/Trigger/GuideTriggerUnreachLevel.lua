-----------------------------------------------------
--File Name    : GuideTriggerUnreachLevel.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerUnreachLevel = luaclass("GuideTriggerUnreachLevel",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function CheckPlayerLevel(self)
    local tbPlayer = GamePlayerSelfHelper:Get()
	local LobbyPropertyComponent = tbPlayer.LobbyPropertyComponent
	if not LobbyPropertyComponent then
		return true
	end
	local nLevel = LobbyPropertyComponent:GetPlayerLevel()
	if nLevel < self.tbTemplate.nLevel then
		return true
	end
	return false
end

local function OnPlayerLevelUp(self)
	local bIsTrigger = CheckPlayerLevel(self)
	self:DebugLog("OnPlayerLevelUp " .. tostring(bIsTrigger))
	if bIsTrigger then
		self:Trigger()
	end
end

--override
function GuideTriggerUnreachLevel:Begin()
	GuideTriggerUnreachLevel.super.Begin(self)
	OnPlayerLevelUp(self)
end

function GuideTriggerUnreachLevel:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW, self, OnPlayerLevelUp)
end

function GuideTriggerUnreachLevel:IsTrigger()
	self.bIsTrigger = CheckPlayerLevel(self)
	return self.bIsTrigger
end

return GuideTriggerUnreachLevel
