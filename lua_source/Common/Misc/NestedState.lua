-----------------------------------------------------
--Description  : 嵌套状态基类
-----------------------------------------------------
local luaclass      = require("luaclass")
local BaseState     = require("BaseState")
local NestedState   = luaclass("NestedState", BaseState)
local StateMachine  = require("BaseStateMachine")

NestedState.tbStateMachine = nil
NestedState.bDefine        = false

function NestedState:Init(szName, tbParams)
    NestedState.super.Init(self, szName, tbParams)

    self.tbStateMachine = StateMachine()
    self.tbStateMachine:Init()
    self.tbStateMachine:SetBlackboard(self)
    -- self:DefineAll()
end

function NestedState:Uninit()
    self.tbStateMachine:Uninit()
    self.tbStateMachine = nil

    NestedState.super.Uninit(self)
end

function NestedState:DefineAll()
    self.bDefine = true
end

function NestedState:DefineState(szClassName, tbParams, szName)
    return self.tbStateMachine:DefineState(szClassName, tbParams, szName)
end

function NestedState:DefineInitState(szClassName, tbParams, szName)
    return self.tbStateMachine:DefineInitState(szClassName, tbParams, szName)
end

function NestedState:Active(tbParams)
    if not self.bDefine then
        self:DefineAll()
    end
    
    NestedState.super.Active(self, tbParams)
    self.tbStateMachine:Start(tbParams)
end

function NestedState:Deactive()
    self.tbStateMachine:Stop()    
    NestedState.super.Deactive(self)
end

function NestedState:Link(tbFromState, tbToState, fnFunc)
    self.tbStateMachine:Link(tbFromState, tbToState, fnFunc)
end

function NestedState:TryTransfer(tbParams)
    return self.tbStateMachine:TryTransfer(tbParams)
end

function NestedState:CanTransfer(tbParams)
    return self.tbStateMachine:CanTransfer(tbParams)
end

function NestedState:GetCurrentState()
    return self.tbStateMachine:GetCurrentState()
end

return NestedState