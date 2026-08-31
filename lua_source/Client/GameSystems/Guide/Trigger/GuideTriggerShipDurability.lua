-----------------------------------------------------
--File Name    : GuideTriggerTradeTimes.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerShipDurability = luaclass("GuideTriggerShipDurability",GuideTrigger)

local DockSystem = require("DockSystem")

--override
function GuideTriggerShipDurability:Begin()
	GuideTriggerShipDurability.super.Begin(self)
	if(self:IsShipDurabilityEnable())then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end

function GuideTriggerShipDurability:IsShipDurabilityEnable()
	local DockComponent = DockSystem.GetSelfDockComponent()
	local tbShipPropertyHelper = DockComponent:GetFlagShipPropertyHelper()
    local tbShip = tbShipPropertyHelper:GetShipPropertyCollection()
    local nMaxDurability = tbShip:GetProperty("nDurability")
    local ship_data = DockComponent:GetFlagShipData()
    local nCurrentDurability = ship_data.durability
	local bIsDurability = nCurrentDurability == nMaxDurability
	self:DebugLog("IsShipDurabilityEnable,bIsDurability="..tostring(bIsDurability))
	
	return bIsDurability == self.tbTemplate.bIsShipDurabilityFull
end

function GuideTriggerShipDurability:IsTrigger()
	self.bIsTrigger = self:IsShipDurabilityEnable()
	return self.bIsTrigger
end

return GuideTriggerShipDurability
