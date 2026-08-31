-----------------------------------------------------
--File Name    : WidgetAnimationHandle.lua
--Author       : Song Fuhao
--Create Time  : 2020-06-02
--Description  : 用于处理WidgetAnimation的开始结束事件绑定
-----------------------------------------------------

local InputType = {
    None        = 0,
    Started     = 1,
    Finished    = 2
}

-- Private implementations --
local luaclass = require("luaclass")
local WidgetAnimationHandleImpl = luaclass("WidgetAnimationHandleImpl")

local DELEGATE_SIGNATURE = U4LDelegateProxy.Fire

WidgetAnimationHandleImpl.nType = InputType.None
WidgetAnimationHandleImpl.pWidget = nil
WidgetAnimationHandleImpl.pWidgetAnimation = nil
WidgetAnimationHandleImpl.pDelegate = nil
WidgetAnimationHandleImpl.fnFinalCallback = nil

local function CreateDelegate(fnCallback, tbSelf)
    local fnFinalCallback = fnCallback
    if tbSelf then
        fnFinalCallback = function()
            fnCallback(tbSelf)
        end
    end
    return createDelegate(DELEGATE_SIGNATURE, fnFinalCallback), fnFinalCallback
end

function WidgetAnimationHandleImpl:Bind(nType, pWidget, pWidgetAnimation, fnCallback, tbSelf)
    if self.nType ~= InputType.None then
        return
    end

    assert(pWidget)
    assert(pWidgetAnimation)
    assert(fnCallback)

    self.nType = nType
    self.pWidget = pWidget
    self.pWidgetAnimation = pWidgetAnimation
    self.pDelegate, self.fnFinalCallback = CreateDelegate(fnCallback, tbSelf)

    if nType == InputType.Started then
        pWidget:BindToAnimationStarted(pWidgetAnimation, self.pDelegate)
    elseif nType == InputType.Finished then
        pWidget:BindToAnimationFinished(pWidgetAnimation, self.pDelegate)
    end
end

function WidgetAnimationHandleImpl:Unbind()
    if self.nType == InputType.None then
        return
    end

    if self.nType == InputType.Started then
        self.pWidget:UnbindToAnimationStarted(self.pWidgetAnimation, self.pDelegate)
    elseif self.nType == InputType.Finished then
        self.pWidget:UnbindFromAnimationFinished(self.pWidgetAnimation, self.pDelegate)
    end

    self.nType = InputType.None
    self.pWidget = nil
    self.pWidgetAnimation = nil
    self.pDelegate = nil
    self.fnFinalCallback = nil
end
-- Private implementations END --

-- Public interfaces --
local WidgetAnimationHandle = {}

function WidgetAnimationHandle:BindToAnimationStarted(pWidget, pWidgetAnimation, fnCallback, tbSelf)
    local tbImpl = WidgetAnimationHandleImpl()
    tbImpl:Bind(InputType.Started, pWidget, pWidgetAnimation, fnCallback, tbSelf)
    return tbImpl
end

function WidgetAnimationHandle:BindToAnimationFinished(pWidget, pWidgetAnimation, fnCallback, tbSelf)
    local tbImpl = WidgetAnimationHandleImpl()
    tbImpl:Bind(InputType.Finished, pWidget, pWidgetAnimation, fnCallback, tbSelf)
    return tbImpl
end

return WidgetAnimationHandle
-- Public interfaces END --
