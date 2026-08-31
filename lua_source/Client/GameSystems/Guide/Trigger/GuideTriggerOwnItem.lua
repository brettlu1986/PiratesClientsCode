-----------------------------------------------------
--File Name    : GuideTriggerOwnItem.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerOwnItem = luaclass("GuideTriggerOwnItem",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ItemRoomDefine = require("ItemRoomDefine")

--override
function GuideTriggerOwnItem:Begin()
	GuideTriggerOwnItem.super.Begin(self)
	self:OnItemChange()
end

function GuideTriggerOwnItem:BindEvent(EventHelper)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ITEM_CHANGE, self, self.OnItemChange)
	
	
end

function GuideTriggerOwnItem:OnItemChange()
	
	local ItemComponentOld = GamePlayerSelfHelper:Get().ItemComponentOld
	local tbTemplate = self.tbTemplate
	local tbItemId = tbTemplate.tbItemId
	local nOwnCount = 0
	if(tbTemplate.nItemRoom == ItemRoomDefine.BACKPACK)then
		nOwnCount = ItemComponentOld:GetBackpackItemCount(tbItemId[1], tbItemId[2], tbItemId[3])
	elseif(tbTemplate.nItemRoom == ItemRoomDefine.SHIP_CABIN)then
		local DockComponent = GamePlayerSelfHelper:Get().DockComponent
		local ItemRoom = ItemComponentOld:GetShipCabinRoom(DockComponent:GetFlagShipInstanceId())
		nOwnCount = ItemRoom:GetCount(tbItemId[1], tbItemId[2], tbItemId[3])
	end
	self:DebugLog("OnItemChange,nOwnCount="..nOwnCount)
    if(nOwnCount > 0)then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end

function GuideTriggerOwnItem:IsTrigger()
	local ItemComponentOld = GamePlayerSelfHelper:Get().ItemComponentOld
	local tbTemplate = self.tbTemplate
	local tbItemId = tbTemplate.tbItemId
	local nOwnCount = 0
	if(tbTemplate.nItemRoom == ItemRoomDefine.BACKPACK)then
		nOwnCount = ItemComponentOld:GetBackpackItemCount(tbItemId[1], tbItemId[2], tbItemId[3])
	elseif(tbTemplate.nItemRoom == ItemRoomDefine.SHIP_CABIN)then
		local DockComponent = GamePlayerSelfHelper:Get().DockComponent
		local ItemRoom = ItemComponentOld:GetShipCabinRoom(DockComponent:GetFlagShipInstanceId())
		nOwnCount = ItemRoom:GetCount(tbItemId[1], tbItemId[2], tbItemId[3])
	end
	if(nOwnCount > 0)then
		self.bIsTrigger = true
	else
		self.bIsTrigger = false
	end
	return self.bIsTrigger
end
return GuideTriggerOwnItem
