-----------------------------------------------------
--File Name    : UIStateHelper.lua
--Author       : Ran Jie
--Create Time  : 2017-03-07
--Description  : UI状态管理
-----------------------------------------------------
local UIStateDef = require("UIStateDef")


local UIStateHelper = {}


UIStateHelper.tbState             = nil    -- 状态集合
UIStateHelper.tbStateStack        = nil    -- 状态堆栈


function UIStateHelper:Init()
    self.tbState = {}
    self.tbStateStack = {}
end

function UIStateHelper:Uninit()
    self:PopAllState()
    self.tbState = nil
    self.tbStateStack = nil
end

function UIStateHelper:PushState( szUIStateName, tbParam, bImmediateSwitch, bKeepStateCache )
    log("[UI]UIStateHelper:PushState,szUIStateName="..tostring(szUIStateName),bKeepStateCache)
    --logwarning("[UI]call back="..debug.traceback())
    local NextState = self.tbState[szUIStateName]
    if(NextState == nil)then
        local StateClass = require(szUIStateName)
        NextState = StateClass()
        NextState:Init(szUIStateName)
        self.tbState[szUIStateName] = NextState
    end
    if(bImmediateSwitch)then
        self:PopAllState(bKeepStateCache)
    end
    --logdebug("NextState name="..tostring(NextState.szName))
    --如果栈中有这个state，先弹出
    self:PopState(szUIStateName, bKeepStateCache)
    local TopState = self:GetActiveState()
    if TopState ~= nil then
        if TopState.nStateType == UIStateDef.StateType.CINEMATIC then
            self:PopState(nil, bKeepStateCache)
        else
            TopState:Pause()
        end
    end
    --再压入栈中
    table.insert(self.tbStateStack, NextState)
    NextState:Enter(tbParam)
    
    -- for i = 1, #self.tbStateStack do
    --     logwarning("[UI]UIStateHelper:PushState,i="..i.." "..tostring((self.tbStateStack[i]).szName))
    -- end
end

function UIStateHelper:PopState(szStateName, bKeepStateCache)
    local nCount = #self.tbStateStack
    log("[UI]UIStateHelper:PopState,nCount=", nCount, szStateName, bKeepStateCache)
    --logwarning("[UI]UIStateHelper:PopState,call back="..debug.traceback())
    if(nCount == 0) then
        return
    end
    for i = 1, nCount do
        log("[UI]UIStateHelper:PopState,i="..i.." "..tostring((self.tbStateStack[i]).szName))
    end
    local TopState = self:GetActiveState()
    if not TopState then
        return
    end
    if szStateName ~= nil and szStateName ~= TopState.szName then
        for i = 1, #self.tbStateStack do
            if self.tbStateStack[i].szName == szStateName then
                local RemoveState = table.remove(self.tbStateStack, i)
                RemoveState:Exit(bKeepStateCache)
                i = i - 1
            end
        end
    else
        table.remove(self.tbStateStack)
        TopState:Exit(bKeepStateCache)
        TopState = self:GetActiveState()
        if TopState then
            TopState:Resume()
        end
    end
end

function UIStateHelper:PopAllState(bKeepStateCache)
    if not self.tbStateStack then 
        return 
    end 
    local nCount = #self.tbStateStack
    log("[UI]UIStateHelper:PopAllState,nCount=",nCount,bKeepStateCache)
    --logwarning("[UI]UIStateHelper:PopAllState,call back="..debug.traceback())
    while(#self.tbStateStack > 0) do
        self:PopState(nil, bKeepStateCache)
    end
end

function UIStateHelper:GetActiveState()
    --logdebug("[UI]UIStateHelper:GetActiveState")
    local nCount = #self.tbStateStack
    -- for i = 1, nCount do
    --     log("[UI]UIStateHelper:GetActiveState,i="..i.." "..tostring((self.tbStateStack[i]).szName))
    -- end
    if(nCount == 0)then
        return nil
    end
    return self.tbStateStack[nCount]
end

function UIStateHelper:VerifyWndVisibility(Wnd)
    local CurrentState = self:GetActiveState()
    --logdebug("[UI]UIStateHelper:VerifyWndVisibility")
    if(CurrentState ~= nil)then
        --logdebug("[UI]UIStateHelper:VerifyWndVisibility,CurrentState="..tostring(CurrentState.szName))
        return CurrentState:VerifyWndVisibility(Wnd)
    end
    return true
end

function UIStateHelper:Reset()
    local CurrentState = self:GetActiveState()
    if(CurrentState ~= nil)then
        CurrentState:Reset()
    end
end

return UIStateHelper
