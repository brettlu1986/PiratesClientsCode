local luaclass = require("luaclass")

-- Private implementations --
local CppDelegateImpl = luaclass("CppDelegateImpl")

CppDelegateImpl.pCppDelegate = nil
CppDelegateImpl.pDelegate = nil

-- luacheck: push ignore 241
-- Holds all CppDelegateImpl so they are not GC-ed.
local tbDelegates = {}

function CppDelegateImpl:Bind(fnCallback, szInfo)
    local pCppDelegate = self.pCppDelegate
    if (not pCppDelegate) then
        return
    end

    self:Unbind()

    assert(fnCallback)

    szInfo = szInfo or getdebuginfo_f(fnCallback)
    self.szInfo = szInfo
    self.fnCallback = fnCallback
    --self.Handle = pCppDelegate:bind(fnCallback, szInfo)
    self.Handle = bindDelegate(pCppDelegate, fnCallback, szInfo)

    -- 编辑器模式记录堆栈方便修bug
    if GWithEditor then
        self.szStack = debug.traceback()
    end
    tbDelegates[self] = true
end

function CppDelegateImpl:Unbind()
    local pCppDelegate = self.pCppDelegate
    local Handle = self.Handle
    if(Handle ~= nil and pCppDelegate ~= nil) then
        if not isvalidhandle(pCppDelegate) then
            if(GWithEditor) then
                error("Cpp delegate is not valid! "..self.szStack)
            else
                error("Cpp delegate is not valid! "..tostring(self.szInfo))
            end
        end
        --pCppDelegate:unbind(Handle)
        unbindDelegate(pCppDelegate, Handle)
    end
    self.fnCallback = nil
    self.Handle = nil

    tbDelegates[self] = nil
end
-- Private implementations END --
-- luacheck: pop

-- Public interfaces --
local CppDelegate = {}

-- Bind a C++ delegate to a lua normal function
--  pCppDelegate: a C++ delegate in the "Unreal World"
--  fnCallback: a ordinary lua function (without "self")
-- Returns: a CppDelegateImpl that you can call Unbind() later.
--  if you do not need to unbind the delegate, simply ignore the return value.
function CppDelegate:Bind(pCppDelegate, fnCallback, szInfo)
    assert(pCppDelegate ~= nil)
    assert(fnCallback ~= nil)
    local tbImpl = CppDelegateImpl()
    tbImpl.pCppDelegate = pCppDelegate
    if(GEnableNewLua) then
        tbImpl:Bind(fnCallback, szInfo)
    else
        tbImpl:Bind(function(_, ...) return fnCallback(...) end)
    end
    return tbImpl
end

-- Bind a C++ delegate to a lua method function
--  pCppDelegate: a C++ delegate in the "Unreal World"
--  tbSelf: a lua table which is the owner of fnSelfCallback
--  fnSelfCallback: a lua method function which is a member of tbSelf
-- Returns: same as CppDelegate:Bind
function CppDelegate:BindMethod(pCppDelegate, tbSelf, fnSelfCallback, szInfo)
    assert(pCppDelegate ~= nil)
    assert(tbSelf ~= nil)
    assert(fnSelfCallback ~= nil)
    if(GEnableNewLua) then
        szInfo = szInfo or getdebuginfo_f(fnSelfCallback)
    end

    return self:Bind(pCppDelegate,
        function(...) return fnSelfCallback(tbSelf, ...) end,
        szInfo)

    -- local tbImpl = CppDelegateImpl()
    -- tbImpl.pCppDelegate = pCppDelegate
    -- tbImpl:Bind(function(_, ...) return fnSelfCallback(tbSelf, ...) end)
    -- return tbImpl
end

return CppDelegate
-- Public interfaces END --
