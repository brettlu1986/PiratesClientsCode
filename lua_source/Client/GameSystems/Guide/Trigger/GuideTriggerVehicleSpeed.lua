-----------------------------------------------------
--File Name    : GuideTriggerVehicleSpeed.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerVehicleSpeed = luaclass("GuideTriggerVehicleSpeed",GuideTrigger)

local CommonEventDef = require("CommonEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local SelfTimerHelperClass = require("SelfTimerHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local TIME_TICK = 1

GuideTriggerVehicleSpeed.tbSpeedTimer = nil
GuideTriggerVehicleSpeed.TimerHelper  = nil
GuideTriggerVehicleSpeed.nVehicleId = nil
GuideTriggerVehicleSpeed.nOverTime  = nil
GuideTriggerVehicleSpeed.nRequireTime = nil

local function OnVerfiyVehicleSpeed(self)
	if self.nVehicleId == nil then
		return
	end
	local tbVehicleObj = GameObjectSystem:FindByInstanceId(self.nVehicleId)
	if tbVehicleObj == nil or tbVehicleObj.pUEActor == nil then
		return
	end
	if tbVehicleObj.pUEActor.Speed > 0 then
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

	if nState == HumanVehicleStateDef.AttachToVehicle then
		self.nVehicleId = nVehicleId
		if self.tbSpeedTimer == nil then
			self.nOverTime = 0
			self.tbSpeedTimer = self.TimerHelper:NewTimerMethod(self, OnVerfiyVehicleSpeed, TIME_TICK, true)
		end
	else
		self.nVehicleId = nil
		if self.tbSpeedTimer ~= nil then
			self.TimerHelper:ClearTimer(self.tbSpeedTimer)
			self.tbSpeedTimer = nil
		end
	end
end

--override
function GuideTriggerVehicleSpeed:Begin()
	GuideTriggerVehicleSpeed.super.Begin(self)
	local tbParam = self.tbParam
	self.nRequireTime = tbParam and tonumber(tbParam[1]) or 0
	self.TimerHelper = SelfTimerHelperClass()
end

function GuideTriggerVehicleSpeed:End()
    GuideTriggerVehicleSpeed.super.End(self)
    self:DebugLog("end TimerHelper = " .. tostring(self.TimerHelper))
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
		self.TimerHelper = nil
    end
end

function GuideTriggerVehicleSpeed:BindEvent(EventHelper)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)
end

return GuideTriggerVehicleSpeed
