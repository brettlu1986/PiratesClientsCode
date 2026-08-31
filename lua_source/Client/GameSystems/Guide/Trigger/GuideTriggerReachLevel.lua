-----------------------------------------------------
--File Name    : GuideTriggerReachLevel.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerReachLevel = luaclass("GuideTriggerReachLevel",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function GetLobbyPropertyComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local LobbyPropertyComponent = PlayerSelf.LobbyPropertyComponent
    return LobbyPropertyComponent
end

local function CheckPlayerLevel(self)
	local LobbyPropertyComponent = GetLobbyPropertyComponent()
	local nCurrentLevel = LobbyPropertyComponent:GetPlayerLevel()
	if nCurrentLevel == self.tbTemplate.nLevel then
		return true
	end
	local tbParam = self.tbTemplate.tbParam
	if tbParam then
		for i,szLevel in ipairs(tbParam) do
			local nTriggerLevel = tonumber(szLevel)
			if nTriggerLevel and nCurrentLevel == nTriggerLevel then
				return true
			end
		end
	end
	return false
end

local function OnPlayerLevelUp(self)
	local bIsTrigger = CheckPlayerLevel(self)
	if bIsTrigger then
		self:Trigger()
	else
		self:Break()
	end
end

--override
function GuideTriggerReachLevel:Begin()
	GuideTriggerReachLevel.super.Begin(self)
	OnPlayerLevelUp(self)
end

function GuideTriggerReachLevel:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_LEVEL_UP_NEW, self, OnPlayerLevelUp)
end


-- function GuideTriggerReachLevel:IsTrigger()
-- 	self.bIsTrigger = CheckPlayerLevel(self)
-- 	return self.bIsTrigger
-- end

return GuideTriggerReachLevel
