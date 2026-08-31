local LuaClassHelper = {}

local function isclass(value)
    if type(value) == "table" and value.isclass then
        return true
    end
    return false
end

local function isinstance(value)
    if type(value) == "table" and value.class and value.isinstance then
        return true
    end
    return false
end

function LuaClassHelper.DeepCopyTable(table)
    local newtable = {}
    for k,v in pairs(table) do
        if type(v) == "table" then
            rawset(newtable, k, LuaClassHelper.DeepCopyTable(v))
        elseif v ~= nil then
            rawset(newtable, k, v)
        end
    end
    return newtable
end

function LuaClassHelper.DeepCopyInstance(instance)
    assert(isinstance(instance), "value must be an instance.")
    local newinstance = instance.class()
    for k,v in pairs(instance) do
        if isinstance(v) then
            rawset(newinstance, k, v())
        elseif type(v) == "table" and (not isclass(v)) then
            rawset(newinstance, k, LuaClassHelper.DeepCopyTable(v))
        elseif v ~= nil then
            rawset(newinstance, k, v)
        end
    end
    return newinstance
end

-- If LuaClassA is a subclass of LuaClassB, return true
-- Otherwise, return false
function LuaClassHelper.IsSubLuaClassOf(LuaClassA, LuaClassB)
    assert(isclass(LuaClassA) and isclass(LuaClassB))
    local SuperClass = LuaClassA
    while SuperClass ~= LuaClassB do
        SuperClass = SuperClass.super
        if SuperClass == nil or (not isclass(SuperClass)) then
            return false
        end
    end
    return true
end

function LuaClassHelper.GetClassName(instance)
    assert(isinstance(instance), "value must be an instance.")
    return instance.name
end

return LuaClassHelper
