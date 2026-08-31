local luaclass          = require("luaclass")
local BaseStateMachine  = luaclass("BaseStateMachine")

BaseStateMachine.tbStates       = nil
BaseStateMachine.tbBlackboard   = nil
BaseStateMachine.tbCurrentState = nil
BaseStateMachine.tbInitState    = nil

function BaseStateMachine:Init()
    self.tbStates = {}
    self.tbBlackboard   = nil
    self.tbCurrentState = nil
    self.tbInitState = nil

    self:DefineAll()

    return true
end

function BaseStateMachine:DefineAll()

end

function BaseStateMachine:Uninit()
    self:Stop()

    for k, _ in pairs(self.tbStates) do
        k:Uninit()
    end
    self.tbBlackboard = nil
    self.tbStates = nil
    self.tbInitState = nil
end

function BaseStateMachine:SetBlackboard(tbBlackboard)
    self.tbBlackboard = tbBlackboard
end

local function SetCurrentState(self, tbState, tbParams)
    if tbState and not self.tbStates[tbState] then
        logerror("BaseStateMachine set currentState but not find state ", tbState.szName)
        return
    end

    local tbFromState = self.tbCurrentState

    if tbFromState then
        tbFromState:Deactive()
    end
    self.tbCurrentState = tbState
    if tbState then
        tbState:Active(tbParams)
    end
    
    self:OnStateChanged(tbFromState, self.tbCurrentState, tbParams)            
end

local function AddState(self, tbState)
    self.tbStates[tbState] = {}
end

function BaseStateMachine:DefineState(szClassName, tbParams, szName)
    local StateClass = require(szClassName)
    local NewState   = StateClass()
    if not szName then
        szName = szClassName
    end
    NewState:Init(szName, tbParams)
    AddState(self, NewState)

    return NewState
end

function BaseStateMachine:DefineInitState(szClassName, tbParams, szName)
    assert(self.tbInitState == nil)
    local tbState = self:DefineState(szClassName, tbParams, szName)
    self.tbInitState = tbState
    return tbState
end

function BaseStateMachine:GetCurrentState()
    return self.tbCurrentState
end

function BaseStateMachine:Start(tbParams)
    if not self.tbInitState then
        error("BaseStateMachine:Start but not init state ")
        return false
    end
    SetCurrentState(self, self.tbInitState, tbParams)

    return true
end

function BaseStateMachine:Stop()
    if not self.tbCurrentState then 
        return
    end
    SetCurrentState(self, nil)
end

function BaseStateMachine:Link(tbFromState, tbToState, fnFunc)
    if not tbFromState or not tbToState or not fnFunc then
        error("BaseStateMachine:Link but not state ".. tbFromState.. tbToState.. fnFunc)
        return
    end
    local tbLinkers = self.tbStates[tbFromState]
    if not tbLinkers then
        logerror("BaseStateMachine:Link not find state")
        return
    end

    tbLinkers[tbToState] = fnFunc   
end

function BaseStateMachine:TryTransfer(tbParams)
    local tbFromState = self.tbCurrentState
    if not tbFromState then
        logerror("BaseStateMachine:TryTransfer but not currentstate ")
        return false
    end

    local tbLinkers = self.tbStates[tbFromState]
    if not tbLinkers then
        logerror("BaseStateMachine:TryTransfer but not currentstate link, state name:", tbFromState.szName)
        return false
    end

    local tbBlackboard = self.tbBlackboard
    for tbToState, fnFunc in pairs(tbLinkers) do
        if fnFunc(tbBlackboard, tbFromState, tbToState, tbParams) then
            SetCurrentState(self, tbToState, tbParams)
            return true
        end
    end

    return false
end

function BaseStateMachine:CanTransfer(tbParams)
    local tbFromState = self.tbCurrentState
    if not tbFromState then
        logerror("BaseStateMachine:CanTransfer but not currentstate ")
        return false
    end

    local tbLinkers = self.tbStates[tbFromState]
    if not tbLinkers then
        logerror("BaseStateMachine:CanTransfer but not currentstate link")
        return false
    end

    local tbBlackboard = self.tbBlackboard
    for tbToState, fnFunc in pairs(tbLinkers) do
        if fnFunc(tbBlackboard, tbFromState, tbToState, tbParams) then
            return true
        end
    end

    return false
end

function BaseStateMachine:OnStateChanged(tbFromState, tbToState, tbParams)
end

return BaseStateMachine