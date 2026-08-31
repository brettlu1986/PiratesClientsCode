-----------------------------------------------------
--File Name    : AbilityEvent_Begin.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-22
--Description  : 在事件Activate时执行TriggerDo，Deactivate时执行TriggerUndo
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_Begin = luaclass("AbilityEvent_Begin", AbilityEventBaseClass)

local Timer = require("Timer")
    
AbilityEvent_Begin.bRepeatActivate = true -- Override parent variable
AbilityEvent_Begin.DelayTimer = nil
AbilityEvent_Begin.bFirstDo = true

local function DelayTimeEnd(self)
    self:TriggerDo()
    self.DelayTimer = nil
end

function AbilityEvent_Begin:OnActivate()
    if self.tbParams.Delay and self.bFirstDo then
        self.DelayTimer = Timer.NewTimerMethod(self, DelayTimeEnd, self.tbParams.Delay)
    else
        self:TriggerDo()
    end
    if self.bFirstDo then
        self.bFirstDo = false
    end
end

function AbilityEvent_Begin:OnDeactivate()
    if self.DelayTimer then
        self.DelayTimer:Clear()
        self.DelayTimer = nil
    else
        self:TriggerUndo()
    end
end

return AbilityEvent_Begin
