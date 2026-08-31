-- 这里期望用法就是逻辑里自己继承个SimpleStateMachine，然后每个state都是个table，写在一个文件就得了
-- 这个类只想弄的简单点，不想每个state都继承出来，那样太重

local luaclass = require("luaclass")
local SimpleStateMachine = luaclass("SimpleStateMachine")

--[[
    State:
        szName 名称，最好有，打log用
        OnActived 激活时触发
        OnDeactived 反激活时触发
]]

SimpleStateMachine.tbStates = nil
SimpleStateMachine.tbCurrentState = nil
SimpleStateMachine.tbBlackboard = nil
SimpleStateMachine.tbInitState = nil


function SimpleStateMachine:Init()
    self.tbStates = {}
    self.tbLinkers = {}
    self.tbCurrentState = nil
    self.tbBlackboard = nil
    self.tbInitState = nil
end

function SimpleStateMachine:Uninit()
    if(self.tbCurrentState) then
        self:DeactiveState(self.tbCurrentState)
    end
    self.tbStates = nil
    self.tbLinkers = nil
    self.tbBlackboard = nil
    self.tbInitState = nil
    self.tbCurrentState = nil    
end

function SimpleStateMachine:SetBlackboard(tbBlackboard)
    self.tbBlackboard = tbBlackboard
end

function SimpleStateMachine:SetInitState(tbState)
    assert(self.tbInitState == nil)
    self:AddState(tbState)
    self.tbInitState = tbState
end

function SimpleStateMachine:AddState(tbState)
    self.tbStates[tbState] = {}
end

function SimpleStateMachine:TryCompleteState(tbState)
    local tbLinkers = self.tbStates[tbState]
    local tbBlackboard = self.tbBlackboard
    local tbFromState = tbState
    for tbToState, fnFunc in pairs(tbLinkers) do
        if(fnFunc(tbFromState, tbToState, tbBlackboard)) then
            self:DeactiveState(tbFromState)
            self:ActiveState(tbToState)
            self:OnStateChanged(tbFromState, tbToState)        
            return true
        end
    end
    return false    
end

function SimpleStateMachine:Link(tbFromState, tbToState, fnFunc)
    assert(tbFromState and tbToState)
    local tbLinkers = self.tbStates[tbFromState]
    if(tbLinkers == nil) then
        error("SimpleStateMachine:Link failed, can not find tbFromState")
        return
    end

    tbLinkers[tbToState] = fnFunc
end

function SimpleStateMachine:Start()    
    self:ActiveState(self.tbInitState)
end

function SimpleStateMachine:GetCurrentState()
    return self.tbCurrentState
end

function SimpleStateMachine:ActiveState(tbState)
    if(tbState.OnActived) then
        tbState:OnActived(self.tbBlackboard)
    end
    self.tbCurrentState = tbState
end

function SimpleStateMachine:DeactiveState(tbState)
    if(tbState.OnDeactived) then
        tbState:OnDeactived(self.tbBlackboard)
    end
    if(self.tbCurrentState == tbState) then
        self.tbCurrentState = nil
    end
end

function SimpleStateMachine:OnStateChanged(tbFromState, tbToState)
end

return SimpleStateMachine