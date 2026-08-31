-----------------------------------------------------
--File Name    : GuideTriggerItemRoomUseable.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerItemRoomUseable = luaclass("GuideTriggerItemRoomUseable",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ItemRoomDefine = require("ItemRoomDefine")
local DockSystem = require("DockSystem")

--override
function GuideTriggerItemRoomUseable:Begin()
	GuideTriggerItemRoomUseable.super.Begin(self)
	self:OnItemChange()
end

function GuideTriggerItemRoomUseable:BindEvent(EventHelper)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ITEM_CHANGE, self, self.OnItemChange)
	
	
end

function GuideTriggerItemRoomUseable:OnItemChange()
	local bIsFull = self:IsFull()
	self:DebugLog("OnItemChange,bIsFull="..tostring(bIsFull))
	if bIsFull then
		self.bIsTrigger = false
	else
		self:Trigger()
	end

end

function GuideTriggerItemRoomUseable:IsTrigger()
	
	local bIsFull = self:IsFull()
	self:DebugLog("IsTrigger,bIsFull="..tostring(bIsFull))
	self.bIsTrigger = not bIsFull
	
	return self.bIsTrigger
end

function GuideTriggerItemRoomUseable:IsFull()
	local ItemComponentOld = GamePlayerSelfHelper:Get().ItemComponentOld
	local ItemRoomUse = nil
	local bIsFull = false
	if(self.tbTemplate.nItemRoom == ItemRoomDefine.BACKPACK)then
		ItemRoomUse = ItemComponentOld:GetBackpack()
	elseif(self.tbTemplate.nItemRoom == ItemRoomDefine.SHIP_CABIN)then
		local DockComponent = GamePlayerSelfHelper:Get().DockComponent
		ItemRoomUse = ItemComponentOld:GetShipCabinRoom(DockComponent:GetFlagShipInstanceId())
		if(ItemRoomUse ~= nil)then
			local nTotalStackCount = 0
			for i, v in ipairs(ItemRoomUse.tbItemList) do
				nTotalStackCount = nTotalStackCount + v:GetStackCount() 
			end
			local nMaxCargoCapacity = DockSystem:GetFlagShipCabinCapacity()

			bIsFull = nTotalStackCount >= nMaxCargoCapacity
		else
			bIsFull = true
		end
	end
	return bIsFull
end
return GuideTriggerItemRoomUseable
