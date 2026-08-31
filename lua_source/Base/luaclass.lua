local ClassMetatable = {}
local InstanceMetatable = {}

local function isclass(value)
    -- if type(value) == "table" and value.isclass then
    --     return true
    -- end
    -- return false
    return type(value) == "table" and value.__isclass
end

-- local function iscclass(value)
--     --return uetype(value) == "UClass"
--     return false
-- end

-- local GetClass = GameplayStatics.GetObjectClass
-- local ClassIsChildOf = KismetMathLibrary.ClassIsChildOf

-- local function ischildinstancedof(value, type)
--     return ClassIsChildOf(GetClass(value), type)
-- end

local function isinstance(value)
    -- if type(value) == "table" and value.class and value.isinstance then
    --     return true
    -- end
    -- return false
    return type(value) == "table" and value.__class ~= nil
end

local function deepcopytable(table)
    local newtable = {}
    for k,v in pairs(table) do
        if type(v) == "table" then
            rawset(newtable, k, deepcopytable(v))
        elseif v ~= nil then
            rawset(newtable, k, v)
        end
    end
    return newtable
end

local function deepcopyinstance(instance)
    assert(isinstance(instance), "value must be an instance.")
    local newinstance = instance.__class()
    for k,v in pairs(instance) do
        if isinstance(v) then
            rawset(newinstance, k, v())
        elseif type(v) == "table" and (not isclass(v)) then
            rawset(newinstance, k, deepcopytable(v))
        elseif v ~= nil then
            rawset(newinstance, k, v)
        end
    end
    return newinstance
end

local function copyinstance(instance)
    assert(isinstance(instance), "value must be an instance.")
    local newinstance = instance.__class()
    for k,v in pairs(instance) do
        rawset(newinstance, k, v)
    end
    return newinstance
end

local function lightcopytable(table)
    local newtable = {}
    for k,v in pairs(table) do
        rawset(newtable, k, v)
    end
    return newtable
end

------------------------------------------------------------------------------------
ClassMetatable.__index = function(self, key)
    local Thisfind = rawget(self, key)
    if Thisfind ~= nil then
        return Thisfind
    else
        local super = rawget(self, "super")
        if super --[[ and not iscclass(super) ]] then
            local superfind = super[key]
            if isinstance(superfind) then
                superfind = copyinstance(superfind)
                rawset(self, key, superfind)
            elseif type(superfind) == "table" and (not isclass(superfind)) then
                superfind = lightcopytable(superfind)
                rawset(self, key, superfind)
            elseif superfind ~= nil then
                rawset(self, key, superfind)
            end
            return superfind
        end
        return nil
    end
end

ClassMetatable.__newindex = function(self, key, value)
    -- print("ClassMetatable.__newindex " .. tostring(self) .. " ".. tostring(key) .. " " .. tostring(value))
    local IndexGet = rawget(self, key)
    if IndexGet ~= nil then
        error(tostring(key) .. " is already exists.")
    else
        rawset(self, key, value)
    end
end

ClassMetatable.__call = function(self, _ptr)
    local Instance = {}
    Instance.__class = self

    local construct = self.construct
    if(construct) then
        construct(Instance)
    end

    setmetatable(Instance, InstanceMetatable)
    return Instance
end

ClassMetatable.__metatable = false

------------------------------------------------------------------------------------
InstanceMetatable.__index = function(table, key)
    --print("InstanceMetatable.__index " .. tostring(table) .. " " .. tostring(key))
    local Thisfind = rawget(table, key)
    if Thisfind ~= nil then
        return Thisfind
    else
        local ClassTable = rawget(table, "__class")
        -- 这里有个bug，当子类将成员变量设成nil后，会再次走到这个分支，
        -- 可以考虑在设成nil的时候将变量设成一个特殊值，在__index时判断是特殊值在返回nil
        local classfind = ClassTable[key]
        -- if (classfind == nil) and (table.class.extendcclass == true) then
        --     local ptrfind = table.ptr[key]
        --     if type(ptrfind) == "function" then
        --         local function wrapfunction(table, ...)
        --             return ptrfind(table.ptr, ...)
        --         end
        --         return wrapfunction
        --     elseif ptrfind ~= nil then
        --         return ptrfind
        --     end
        -- end
        if isinstance(classfind) then
            classfind = copyinstance(classfind)
            rawset(table, key, classfind)
        elseif type(classfind) == "table" and (not isclass(classfind)) then
            classfind = lightcopytable(classfind)
            rawset(table, key, classfind)
        elseif classfind ~= nil then
            rawset(table, key, classfind)
        end
        return classfind
    end
end

InstanceMetatable.__call = function(table)
    return deepcopyinstance(table)
end

InstanceMetatable.__metatable = false

local function luaclass(Classname, super)
    local ClassTable = {}
    ClassTable.super = super
    ClassTable.__isclass = true
    setmetatable(ClassTable, ClassMetatable)
    return ClassTable
end

-- local function luaclass(Classname, super)
--     local ClassTable = {}
--     local ClassMetatable = {}

--     -- if iscclass(super) then
--     --     ClassMetatable.extendcclass = true
--     --     ClassMetatable.supercclass = super
--     -- else
--     -- if super then
--     --     ClassMetatable.extendcclass = super.extendcclass
--     -- else
--     --     ClassMetatable.extendcclass = false
--     -- end

--     ClassMetatable.name = Classname

--     ClassMetatable.super = super
--     ClassMetatable.isclass = true
--     ClassMetatable.isinstance = false
--     ClassMetatable.class = ClassTable
--     setmetatable(ClassTable,ClassMetatable)
--     ClassMetatable.__index = function(self, key)
--         -- print("ClassMetatable.__index " .. tostring(self) .. " " .. tostring(key))
--         local Thisfind = rawget(ClassMetatable, key)
--         if Thisfind ~= nil then
--             return Thisfind
--         else
--             if super --[[ and not iscclass(super) ]] then
--                 local superfind = super[key]
--                 if isinstance(superfind) then
--                     superfind = copyinstance(superfind)
--                     rawset(ClassTable, key, superfind)
--                 elseif type(superfind) == "table" and (not isclass(superfind)) then
--                     superfind = lightcopytable(superfind)
--                     rawset(ClassTable, key, superfind)
--                 elseif superfind ~= nil then
--                     rawset(ClassTable, key, superfind)
--                 end
--                 return superfind
--             end
--             return nil
--         end
--     end

--     -- ClassMetatable.DefineProperty = function(szName, DefaultValue)
--     --     ClassTable["Get" .. szName] = function (self)
--     --         if self.__nilproperties[szName] then
--     --             return nil
--     --         end
--     --         return self.__properties[szName] or DefaultValue
--     --     end
--     --     ClassTable["Set" .. szName] = function (self, Value)
--     --         self.__properties[szName] = Value
--     --         self.__nilproperties[szName] = ((Value == nil) and true or nil)
--     --     end
--     -- end

--     ClassMetatable.__newindex = function(self, key, value)
--         -- print("ClassMetatable.__newindex " .. tostring(self) .. " ".. tostring(key) .. " " .. tostring(value))
--         local IndexGet = rawget(ClassMetatable, key)
--         if IndexGet ~= nil then
--             error(tostring(key) .. " is already exists.")
--         else
--             rawset(ClassMetatable, key, value)
--         end
--     end

--     ClassMetatable.callconstructor = function(instance)
--         local tempsuper = ClassMetatable.super
--         if tempsuper and (not iscclass(tempsuper)) then
--             tempsuper.callconstructor(instance)
--         end
--         local construct = ClassMetatable.construct
--         if construct then
--             construct(instance)
--         end
--     end

--     -- ClassMetatable.calldestructor = function(instance)
--     --     local destruct = ClassMetatable.destruct
--     --     if destruct then
--     --         destruct(instance)
--     --     end
--     --     local super = ClassMetatable.super
--     --     if super and (not iscclass(super)) then
--     --         super.calldestructor(instance)
--     --     end
--     -- end

--     ClassMetatable.__call = function(self, _ptr)
--         -- print("ClassMetatable.__call " .. tostring(self) .. " " .. tostring({...}))
--         -- if ClassMetatable.extendcclass then
--         --     if ptr == nil then
--         --         error(Classname .. " is an extend c class which require an instance ptr at arg 2")
--         --     end
--         --     assert(ischildinstancedof(ptr, self.supercclass), "wrong type")
--         --     self.ptr = ptr
--         -- end

--         local Instance = {}
--         local InstanceMetatable = {}
--         InstanceMetatable.isclass = false
--         InstanceMetatable.isinstance = true
--         --InstanceMetatable.__properties = {}
--         --InstanceMetatable.__nilproperties = {}
--         ClassMetatable.callconstructor(Instance)
--         InstanceMetatable.__index = function(table, key)
--             -- print("InstanceMetatable.__index " .. tostring(table) .. " " .. tostring(key))
--             local Thisfind = rawget(InstanceMetatable, key)
--             if Thisfind ~= nil then
--                 return Thisfind
--             else
--                 -- 这里有个bug，当子类将成员变量设成nil后，会再次走到这个分支，
--                 -- 可以考虑在设成nil的时候将变量设成一个特殊值，在__index时判断是特殊值在返回nil
--                 local classfind = ClassTable[key]
--                 -- if (classfind == nil) and (table.class.extendcclass == true) then
--                 --     local ptrfind = table.ptr[key]
--                 --     if type(ptrfind) == "function" then
--                 --         local function wrapfunction(table, ...)
--                 --             return ptrfind(table.ptr, ...)
--                 --         end
--                 --         return wrapfunction
--                 --     elseif ptrfind ~= nil then
--                 --         return ptrfind
--                 --     end
--                 -- end
--                 if isinstance(classfind) then
--                     classfind = copyinstance(classfind)
--                     rawset(table, key, classfind)
--                 elseif type(classfind) == "table" and (not isclass(classfind)) then
--                     classfind = lightcopytable(classfind)
--                     rawset(table, key, classfind)
--                 elseif classfind ~= nil then
--                     rawset(table, key, classfind)
--                 end
--                 return classfind
--             end
--         end

--         -- InstanceMetatable.__newindex = function(table, key, value)
--         --     if table.class.extendcclass and table.ptr then
--         --         local function ptrnewindex()
--         --             table.ptr[key] = value
--         --         end
--         --         if pcall(ptrnewindex) then
--         --             return
--         --         end
--         --     end
--         --     rawset(table, key, value)
--         -- end

--         InstanceMetatable.__call = function(table)
--             return deepcopyinstance(table)
--         end

--         InstanceMetatable.__tostring = function(table)
--             return "[instance:" .. Classname ..  "]"
--         end

--         -- InstanceMetatable.__gc = function(table)
--         --     ClassMetatable.calldestructor(table)
--         -- end

--         InstanceMetatable.__metatable = false

--         setmetatable(Instance, InstanceMetatable)
--         return Instance
--     end

--     ClassMetatable.__tostring = function(self)
--         return "[class:" .. Classname ..  "]"
--     end

--     ClassMetatable.__metatable = false

--     return ClassTable
-- end

return luaclass
