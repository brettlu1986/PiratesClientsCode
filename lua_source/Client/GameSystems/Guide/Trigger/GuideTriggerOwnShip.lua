-----------------------------------------------------
--File Name    : GuideTriggerOwnShip.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerOwnShip = luaclass("GuideTriggerOwnShip",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function CheckOwnedShip(self)
	local DockComponent = GamePlayerSelfHelper:Get().DockComponent
	local bOwned = DockComponent:IsShipOwned(self.tbTemplate.tbItemId[1])
	self:DebugLog("CheckOwnedShip:bOwned="..tostring(bOwned).." shipid="..tostring(self.tbTemplate.tbItemId[1]).." isenable="..tostring(self.tbTemplate.bIsEnable))
	return bOwned == self.tbTemplate.bIsEnable
end

--override
function GuideTriggerOwnShip:Begin()
	GuideTriggerOwnShip.super.Begin(self)
	self:OnShipChange()
end

function GuideTriggerOwnShip:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ADD_SHIP, self, self.OnShipChange)
	EventHelper:RegisterEvent(ClientEventDef.EV_SELL_SHIP_SUCCESS, self, self.OnShipChange)
	EventHelper:RegisterEvent(ClientEventDef.EV_REDEEM_SHIP_SUCCESS, self, self.OnShipChange)
end

function GuideTriggerOwnShip:OnShipChange()
	self:DebugLog("OnShipChange")
	local bTrigger = CheckOwnedShip(self)
	if(bTrigger)then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end

function GuideTriggerOwnShip:IsTrigger()
	self:DebugLog("IsTrigger")
	self.bIsTrigger = CheckOwnedShip(self)

	return self.bIsTrigger
end

return GuideTriggerOwnShip
