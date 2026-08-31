-----------------------------------------------------
--File Name    : AbilityEvent_Timer.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-22
--Description  : 激活时开始一个循环Timer，每次Timer触发调用DoAction，OnDeactive时尝试UndoAction
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_Timer = luaclass("AbilityEvent_Timer", AbilityEventBaseClass)
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local Timer = require("Timer")

AbilityEvent_Timer.TickTimer = nil
AbilityEvent_Timer.nCount = 0
AbilityEvent_Timer.nTotalCount = nil

function AbilityEvent_Timer:OnActivate()
    if self.TickTimer == nil then
        local tbParams = self.tbParams
        self.TickTimer = Timer.NewTimerMethod(self, self.TriggerDo, tbParams.Interval, true)
        if tbParams.Immediately and (tbParams.Immediately ~= 0) then
            self:TriggerDo()
        end
    end
end

function AbilityEvent_Timer:OnDeactivate()
    if self.TickTimer then
        self.TickTimer:Clear()
        self.TickTimer = nil
    end
    self:TriggerUndo()
end

function AbilityEvent_Timer:TriggerDo(tbParams)
    AbilityEvent_Timer.super.TriggerDo(self, tbParams)
    self.nCount = self.nCount + 1
    if self.tbParams.Count and self.tbParams.Count <= self.nCount then
        EventManager:OnFireEvent(CommonEventDef.EV_TRIGGER_REMOVE_BUFF, self.Owner)
    end
end

return AbilityEvent_Timer
