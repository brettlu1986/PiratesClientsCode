-----------------------------------------------------
--File Name    : GuideTriggerVehicleDirection.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerVehicleDirection = luaclass("GuideTriggerVehicleDirection",GuideTrigger)

local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local SelfTimerHelperClass = require("SelfTimerHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local TIME_TICK = 1

GuideTriggerVehicleDirection.tbDirectionTimer = nil
GuideTriggerVehicleDirection.TimerHelper  = nil
GuideTriggerVehicleDirection.nVehicleId = nil
GuideTriggerVehicleDirection.nDirection = nil
GuideTriggerVehicleDirection.nOverTime  = nil
GuideTriggerVehicleDirection.nRequireTime = nil

local function OnVerfiyVehicleDirection(self)
	if self.nVehicleId == nil or self.nDirection == nil then
		return
	end
	local tbVehicleObj = GameObjectSystem:FindByInstanceId(self.nVehicleId)
	if tbVehicleObj == nil or tbVehicleObj.pUEActor == nil then
		return
	end
	if tbVehicleObj.pUEActor.Direction ~= self.nDirection or tbVehicleObj.pUEActor.Speed == 0 then
		self.nDirection = tbVehicleObj.pUEActor.Direction
		self.nOverTime = 0
		return
	end

	self.nOverTime = self.nOverTime + 1
	if self.nOverTime >= self.nRequireTime then
        self:Trigger()
	end
end

local function OnVehicleStateChange(self, Player, nState, nVehicleId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if Player.ObjectType ~= PlayerSelf.ObjectType then
		return
    end
	local tbVehicleObj = GameObjectSystem:FindByInstanceId(nVehicleId)
	if tbVehicleObj == nil or tbVehicleObj.pUEActor == nil then
		return
	end

	if nState == HumanVehicleStateDef.AttachToVehicle then
		self.nVehicleId = nVehicleId
		if self.tbDirectionTimer == nil then
			self.nOverTime = 0
			self.nDirection = tbVehicleObj.pUEActor.Direction
			self.tbDirectionTimer = self.TimerHelper:NewTimerMethod(self, OnVerfiyVehicleDirection, TIME_TICK, true)
		end
	else
		if self.tbDirectionTimer ~= nil then
			self.TimerHelper:ClearTimer(self.tbDirectionTimer)
			self.tbDirectionTimer = nil
		end
		self.nVehicleId = nil
		self.nDirection = nil
	end
end

--override
function GuideTriggerVehicleDirection:Begin()
	GuideTriggerVehicleDirection.super.Begin(self)
	local tbParam = self.tbParam
	self.nRequireTime = tbParam and tonumber(tbParam[1]) or 0
	self.TimerHelper = SelfTimerHelperClass()
end

function GuideTriggerVehicleDirection:End()
    GuideTriggerVehicleDirection.super.End(self)
    self:DebugLog("end TimerHelper = " .. tostring(self.TimerHelper))
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
		self.TimerHelper = nil
    end
end

function GuideTriggerVehicleDirection:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)
end

return GuideTriggerVehicleDirection
