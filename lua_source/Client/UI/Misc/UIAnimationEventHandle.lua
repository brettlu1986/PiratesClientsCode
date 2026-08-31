-----------------------------------------------------
--File Name    : UIAnimationEventHandle.lua
--Author       : Song Fuhao
--Create Time  : 2017-03-01
--Description  : UIAnimationEventHander
-----------------------------------------------------

-- Private implementations --
local luaclass = require("luaclass")
local UIAnimationEventHandleImpl = luaclass("UIAnimationEventHandleImpl")

UIAnimationEventHandleImpl.pWidgetRef = nil
UIAnimationEventHandleImpl.szEventName = nil

function UIAnimationEventHandleImpl:Bind(pWidgetRef, szEventName, fnCallback, tbSelf)
    self.pWidgetRef = pWidgetRef
    self.szEventName = szEventName

    local fnFinalCallback, szInfo
    if(GEnableNewLua) then
        szInfo = getdebuginfo_f(fnCallback)
        fnFinalCallback = function(...)
            return (tbSelf == nil) and fnCallback(...) or fnCallback(tbSelf, ...)
        end
    else
        fnFinalCallback = function(_, ...)
            return (tbSelf == nil) and fnCallback(...) or fnCallback(tbSelf, ...)
        end
    end
    self.fnFinalCallback = fnFinalCallback
    local pDelegate = createDelegate(U4LDelegateProxy.Fire, fnFinalCallback, szInfo)
    pWidgetRef:BindAnimationEvent(szEventName, pDelegate)
    self.pDelegate = pDelegate
end

function UIAnimationEventHandleImpl:Unbind()
    self.pDelegate = nil
    if not self.pWidgetRef then
        return
    end
    self.pWidgetRef:UnbindAnimationEvent(self.szEventName)
end
-- Private implementations END --

-- Public interfaces --
local UIAnimationEventHandle = {}

function UIAnimationEventHandle:Bind(pWidgetRef, szEventName, fnCallback, tbSelf)
    local tbImpl = UIAnimationEventHandleImpl()
    tbImpl:Bind(pWidgetRef, szEventName, fnCallback, tbSelf)
    return tbImpl
end

return UIAnimationEventHandle
-- Public interfaces END --
