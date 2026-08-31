-----------------------------------------------------
--File Name    : GuideTriggerWorkShopUseable.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerWorkShopUseable = luaclass("GuideTriggerWorkShopUseable",GuideTrigger)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

--override
function GuideTriggerWorkShopUseable:Begin()
	GuideTriggerWorkShopUseable.super.Begin(self)
	local WorkshopComponent = GamePlayerSelfHelper:Get().WorkshopComponent
	local tbProgress = WorkshopComponent:GetProgressById(1)
	if(tbProgress == nil)then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end



function GuideTriggerWorkShopUseable:IsTrigger()
	local WorkshopComponent = GamePlayerSelfHelper:Get().WorkshopComponent
	local tbProgress = WorkshopComponent:GetProgressById(1)
	if(tbProgress == nil)then
		self.bIsTrigger = true
	else
		self.bIsTrigger = false
	end
	return self.bIsTrigger
end

return GuideTriggerWorkShopUseable
