-----------------------------------------------------
--File Name    : InputHandle.lua
--Author       : Song Fuhao
--Create Time  : 2016-11-01
--Description  : InputHandle
-----------------------------------------------------

local FUNCTION_NAME = "Fire"

local InputType = {
    None = 0,
    Key = 1,
    Gesture = 2
}

-- Private implementations --
local luaclass = require("luaclass")
local InputHandleImpl = luaclass("InputHandleImpl")

InputHandleImpl.nType = InputType.None
InputHandleImpl.pDelegate = nil

function InputHandleImpl:Init(fnCallback, tbSelf, nType)
    self.nType = nType
    local szInfo
    local fnFinalCallback
    if(GEnableNewLua) then
        szInfo = getdebuginfo_f(fnCallback)
        fnFinalCallback = function(...)
            if tbSelf then
                return fnCallback(tbSelf, ...)
            else
                return fnCallback(...)
            end
        end
    else
        fnFinalCallback = function(_, ...)
            if tbSelf then
                return fnCallback(tbSelf, ...)
            else
                return fnCallback(...)
            end
        end
    end
    local pSignature = InputManager.FireKey
    if self.nType == InputType.Gesture then
        pSignature = InputManager.FireGesture
    end
    self.fnFinalCallback = fnFinalCallback
    self.pDelegate = createDelegate(pSignature, fnFinalCallback, szInfo)
end

function InputHandleImpl:Unbind()
    if self.pDelegate then
        local InputManager = ClientShell.GetClient(GWorld):GetInputManager()
        if self.nType == InputType.Key then
            InputManager:UnbindKey(self.pDelegate, FUNCTION_NAME)
        elseif self.nType == InputType.Gesture then
            InputManager:UnbindGesture(self.pDelegate, FUNCTION_NAME)
        end
    end
end

function InputHandleImpl:BindKeyPressed(pInputType, fnCallback, tbSelf)
    self:Init(fnCallback, tbSelf, InputType.Key)
    local InputManager = ClientShell.GetClient(GWorld):GetInputManager()
    InputManager:BindKeyPressed(self.pDelegate, FUNCTION_NAME, pInputType)
end

function InputHandleImpl:BindKeyReleased(pInputType, fnCallback, tbSelf)
    self:Init(fnCallback, tbSelf, InputType.Key)
    local InputManager = ClientShell.GetClient(GWorld):GetInputManager()
    InputManager:BindKeyReleased(self.pDelegate, FUNCTION_NAME, pInputType)
end

function InputHandleImpl:BindGestureActive(pGestureType, fnCallback, tbSelf)
    self:Init(fnCallback, tbSelf, InputType.Gesture)
    local InputManager = ClientShell.GetClient(GWorld):GetInputManager()
    InputManager:BindGestureActive(self.pDelegate, FUNCTION_NAME, pGestureType)
end

function InputHandleImpl:BindGestureDeactive(pGestureType, fnCallback, tbSelf)
    self:Init(fnCallback, tbSelf, InputType.Gesture)
    local InputManager = ClientShell.GetClient(GWorld):GetInputManager()
    InputManager:BindGestureDeactive(self.pDelegate, FUNCTION_NAME, pGestureType)
end
-- Private implementations END --

-- Public interfaces --
local InputHandle = {}
function InputHandle:BindKeyPressed(pInputType, fnCallback, tbSelf)
    local tbImpl = InputHandleImpl()
    tbImpl:BindKeyPressed(pInputType, fnCallback, tbSelf)
    return tbImpl
end

function InputHandle:BindKeyReleased(pInputType, fnCallback, tbSelf)
    local tbImpl = InputHandleImpl()
    tbImpl:BindKeyReleased(pInputType, fnCallback, tbSelf)
    return tbImpl
end

function InputHandle:BindGestureActive(pGestureType, fnCallback, tbSelf)
    local tbImpl = InputHandleImpl()
    tbImpl:BindGestureActive(pGestureType, fnCallback, tbSelf)
    return tbImpl
end

function InputHandle:BindGestureDeactive(pGestureType, fnCallback, tbSelf)
    local tbImpl = InputHandleImpl()
    tbImpl:BindGestureDeactive(pGestureType, fnCallback, tbSelf)
    return tbImpl
end
return InputHandle
