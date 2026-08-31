-----------------------------------------------------
--File Name    : GuideTriggerTradeTimes.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerShipSupply = luaclass("GuideTriggerShipSupply",GuideTrigger)

local DockSystem = require("DockSystem")

--override
function GuideTriggerShipSupply:Begin()
	GuideTriggerShipSupply.super.Begin(self)
	if(self:IsShipSupplyEnable())then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end

function GuideTriggerShipSupply:IsShipSupplyEnable()
	local DockComponent = DockSystem.GetSelfDockComponent() 
	local tbShipPropertyHelper = DockComponent:GetFlagShipPropertyHelper()
    local tbShip = tbShipPropertyHelper:GetShipPropertyCollection()
    local nMaxSupply = tbShip:GetProperty("nSupply")
    local ship_data = DockComponent:GetFlagShipData()
    local nCurrentSupply = ship_data.supply
    local bIsSupplyFull = nCurrentSupply == nMaxSupply
	

	self:DebugLog("IsShipSupplyEnable,bIsSupplyFull="..tostring(bIsSupplyFull))
	return bIsSupplyFull == self.tbTemplate.bIsShipSupplyFull
end

function GuideTriggerShipSupply:IsTrigger()
	self.bIsTrigger = self:IsShipSupplyEnable()
	return self.bIsTrigger
end

return GuideTriggerShipSupply
