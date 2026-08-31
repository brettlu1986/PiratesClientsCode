local luaclass = require("luaclass")
local MessageProcessorBaseClass = require("MessageProcessorBase")
local CPPDelegateProcessorBase = luaclass("CPPDelegateProcessorBase", MessageProcessorBaseClass)
local CppDelegate = require("CppDelegate")

CPPDelegateProcessorBase.tbDelegateMap = nil

function CPPDelegateProcessorBase:Init()
    CPPDelegateProcessorBase.super.Init(self)
    self.tbDelegateMap = {}
    return true
end

function CPPDelegateProcessorBase:Uninit()
    self:UnregisterAll()
end

function CPPDelegateProcessorBase:RegisterMethod(pCppDelegate, tbSelf, fnCallback)
    if (pCppDelegate and tbSelf and fnCallback) then
        local tbDelegateHandler = CppDelegate:BindMethod(pCppDelegate, tbSelf, fnCallback)
        assert(tbDelegateHandler)
        table.insert(self.tbDelegateMap, tbDelegateHandler)
        return tbDelegateHandler
    end
    return nil
end

function CPPDelegateProcessorBase:Register(pCppDelegate, fnCallback)
    if (pCppDelegate and fnCallback) then
        local tbDelegateHandler = CppDelegate:Bind(pCppDelegate, fnCallback)
        assert(tbDelegateHandler)
        table.insert(self.tbDelegateMap, tbDelegateHandler)
        return tbDelegateHandler
    end
    return nil
end

function CPPDelegateProcessorBase:Unregister(tbDelegateHandler)
    if (tbDelegateHandler) then
        tbDelegateHandler:Unbind()

        local tbDelegateMap = self.tbDelegateMap
        for nIndex, tbHandler in ipairs(tbDelegateMap) do
            if(tbHandler == tbDelegateHandler) then
                table.remove(tbDelegateMap, nIndex)
                break
            end
        end
    end
end

function CPPDelegateProcessorBase:UnregisterAll()
    local tbDelegateMap = self.tbDelegateMap
    if(tbDelegateMap) then
        for _, tbDelegateHandler in pairs(tbDelegateMap) do
            tbDelegateHandler:Unbind()
        end
        self.tbDelegateMap = {}
    end
end

return CPPDelegateProcessorBase
