-----------------------------------------------------
--File Name    : LuaDelegate.lua
--Author       : Song Fuhao
--Create Time  : 2016-06-21
--Description  : 创建、维护一个Lua的Delegate
-----------------------------------------------------
local luaclass = require ("luaclass")
local LuaDelegate = luaclass("LuaDelegate")

LuaDelegate.tbHandles = nil
LuaDelegate.fnBindCallback = nil

function LuaDelegate:construct()
    self.tbHandles = {}
end

function LuaDelegate:SetBindCallback(fnBindCallback)
    self.fnBindCallback = fnBindCallback
end

-- 绑定一个方法
-- @param Func
-- @param Obj 如果是本地方法，可不传Obj
function LuaDelegate:Bind(Func, Obj)
    if not Func then
        logwarning('Lua delegate bind failed. Func is nil.')
        logwarning("LuaCallStack:", debug.traceback())
        return
    end

    for _,tbHandle in ipairs(self.tbHandles) do
        if (tbHandle.Func == Func) and (tbHandle.Obj == Obj) then
            logwarning('Lua delegate bind failed. Func is already bind.')
            logwarning("LuaCallStack:", debug.traceback())
            break
        end
    end

    local tbHandle = {}
    tbHandle.Func = Func
    tbHandle.Obj = Obj
    table.insert(self.tbHandles, tbHandle)

    if self.fnBindCallback then
        self.fnBindCallback()
    end
end

-- 解绑一个方法
function LuaDelegate:Unbind(Func, Obj)
    for i,tbHandle in ipairs(self.tbHandles) do
        if (tbHandle.Func == Func) and (tbHandle.Obj == Obj) then
            table.remove(self.tbHandles, i)
            return
        end
    end
    if not Obj then
        logerror('LuaDelegate Unbind failed, your obj param is nil.', debug.traceback())
    end
end

-- 解绑所有方法
function LuaDelegate:UnbindAll()
    self.tbHandles = {}
end

-- 判断是否有被绑定过
function LuaDelegate:IsBinded()
    return #self.tbHandles > 0
end

-- Call这个Delegate
function LuaDelegate:Fire(...)
    -- 为了避免在Fire期间有unbind的行为，这块需要倒序遍历
    for i = #self.tbHandles, 1, -1 do
        local tbHandle = self.tbHandles[i]
        if tbHandle.Obj then
            tbHandle.Func(tbHandle.Obj, ...)
        else
            tbHandle.Func(...)
        end
    end
end

return LuaDelegate
