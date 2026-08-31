-----------------------------------------------------
--File Name    : GuideTriggerTradeTimes.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerTradeTimes = luaclass("GuideTriggerTradeTimes",GuideTrigger)


--override
function GuideTriggerTradeTimes:Begin()
	GuideTriggerTradeTimes.super.Begin(self)
	if(self:IsTradeEnable())then
		self:Trigger()
	else
		self.bIsTrigger = false
	end
end

function GuideTriggerTradeTimes:IsTradeEnable()
	--local TradeComponent = GamePlayerSelfHelper:Get().TradeComponent
	local nRemainCount = 0
	-- local nRemainCount = TradeComponent:GetRemainedTradeTimes()
	self:DebugLog("IsTradeEnable,nRemainCount="..nRemainCount)
	return nRemainCount > 0
end

function GuideTriggerTradeTimes:IsTrigger()
	self.bIsTrigger = self:IsTradeEnable()
	return self.bIsTrigger
end

return GuideTriggerTradeTimes
