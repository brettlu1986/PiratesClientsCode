-----------------------------------------------------
--File Name    : GuideTriggerShipDropSail.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerShipDropSail = luaclass("GuideTriggerShipDropSail", GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

GuideTriggerShipDropSail.nRequirePosture = nil 

local function CheckShipPosture(self)
	local ShipMovementComponent = GamePlayerSelfHelper:Get().BattleShipMovementComponent
	if ShipMovementComponent then
		return ShipMovementComponent:GetPosture() == self.nRequirePosture
	end

	return false
end

local function OnShipSetPosture(self, nOldPosture, nCurPosture)
	local bIsTrigger = false 
	if nCurPosture and nOldPosture then
		bIsTrigger = nCurPosture == self.nRequirePosture and nCurPosture >= nOldPosture
	else
		bIsTrigger = CheckShipPosture(self)
	end
	if bIsTrigger then
		self:Trigger()
	end	
end

--override
function GuideTriggerShipDropSail:Begin()
	GuideTriggerShipDropSail.super.Begin(self)
	self.nRequirePosture = tonumber(self.tbTemplate.tbParam[1])
	OnShipSetPosture(self)
end

function GuideTriggerShipDropSail:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_SHIP_SET_POSTURE, self, OnShipSetPosture)
end

return GuideTriggerShipDropSail
