local luaclass = require ("luaclass")
local PoolHelper = luaclass("PoolHelper")

PoolHelper.fnCreateFunc = nil
PoolHelper.fnRecycleFunc = nil
PoolHelper.fnDestroyFunc = nil
PoolHelper.tbFreeList = nil

function PoolHelper:construct()
    self.tbFreeList = {}
end

function PoolHelper:SetCreateFunc(fnCreateFunc)
    self.fnCreateFunc = fnCreateFunc
end

function PoolHelper:SetRecycleFunc(fnRecycleFunc)
    self.fnRecycleFunc = fnRecycleFunc
end

function PoolHelper:SetDestroyFunc(fnDestroyFunc)
    self.fnDestroyFunc = fnDestroyFunc
end

function PoolHelper:Pick()
    local varObj
    if #self.tbFreeList == 0 then
        if self.fnCreateFunc == nil then
            varObj = {}
        else
            varObj = self.fnCreateFunc()
            assert(varObj ~= nil, "FAILED to pick object, CreateFunc return a nil value.")
        end
    else
        varObj = table.remove(self.tbFreeList)
        assert(varObj ~= nil, "FAILED to pick object, object in FreeList is nil.")
    end
    return varObj
end

function PoolHelper:Free(varObj)
    if varObj ~= nil then
        if self.fnRecycleFunc ~= nil then
            self.fnRecycleFunc(varObj)
        end
        table.insert(self.tbFreeList, varObj)
    else
        logerror("Cannot free a nil object.")
    end
end

function PoolHelper:FreeList(tbObjList)
    local fnRecycleFunc = self.fnRecycleFunc
    if fnRecycleFunc ~= nil then
        for _, varObj in ipairs(tbObjList) do
            if varObj ~= nil then
                fnRecycleFunc(varObj)
                table.insert(self.tbFreeList, varObj)
            else
                logerror("Cannot free a nil object.")
            end
        end
    else
        for _, varObj in ipairs(tbObjList) do
            if varObj ~= nil then
                table.insert(self.tbFreeList, varObj)
            else
                logerror("Cannot free a nil object.")
            end
        end
    end
    return {}
end

function PoolHelper:DestroyAll()
    if self.fnDestroyFunc ~= nil then
        local tbFreeList = self.tbFreeList
        for _, varObj in ipairs(tbFreeList) do
            self.fnDestroyFunc(varObj)
        end
    end
end

return PoolHelper