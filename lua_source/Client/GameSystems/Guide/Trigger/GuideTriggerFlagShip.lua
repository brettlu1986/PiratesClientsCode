-----------------------------------------------------
--File Name    : GuideTriggerFlagShip.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerFlagShip = luaclass("GuideTriggerFlagShip",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function CheckFlagShip(self)
	local DockComponent = GamePlayerSelfHelper:Get().DockComponent
	local ShipData = DockComponent:GetFlagShip()
	local bEqual = ShipData:GetTemplateID() == self.tbTemplate.tbItemId[1]
	self:DebugLog("CheckFlagShip:flagship="..tostring(ShipData:GetTemplateID()).." shipid="..tostring(self.tbTemplate.tbItemId[1]).." isenable="..tostring(self.tbTemplate.bIsEnable))
	return bEqual == self.tbTemplate.bIsEnable
end

--override
function GuideTriggerFlagShip:Begin()
	GuideTriggerFlagShip.super.Begin(self)
	self:OnFlagShipChange()
end

function GuideTriggerFlagShip:BindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_SWITCH_FLAG_SHIP_SUCCESS, self, self.OnFlagShipChange)
end

function GuideTriggerFlagShip:OnFlagShipChange()
	self:DebugLog("OnFlagShipChange")
	local bTrigger = CheckFlagShip(self)
	if(bTrigger)then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end

function GuideTriggerFlagShip:IsTrigger()
	self:DebugLog("IsTrigger")
	self.bIsTrigger = CheckFlagShip(self)
	return self.bIsTrigger
end

return GuideTriggerFlagShip
