-----------------------------------------------------
--File Name    : Uitl.lua
--Author       : yangyankun
--Create Time  : 2016-06-22
--Description  : 提供一些基础的工具类
-----------------------------------------------------
local Util = {}

function Util:ReadOnly(tb)
    local tbProxy = {}
    local tbMeta =
    { -- create metatable
        __tag = 'ReadOnly',
        __index = tb,
        __newindex = function (_t,_k,_v)
            error("attempt to update a read-only table ")
        end
    }
    setmetatable(tbProxy, tbMeta)
    return tbProxy
end

function Util:ConvertTableToJsonString(tbToPrint)
    if tbToPrint == nil then
        return ""
    end

    local json = require("dkjson")
    local szRet = json.encode(tbToPrint)

    if self:IsTableEmpty(tbToPrint) == true then
        szRet = ""
        local meta = getmetatable(tbToPrint)
        if type(meta) == 'table' and type(meta.__index) == 'table' then
            szRet = szRet .. json.encode(meta.__index)
        end
    end
    return szRet
end

function Util:PrintTable(tbToPrint, nLogLevel)
    local szRet = self:ConvertTableToJsonString(tbToPrint)

    if nLogLevel == nil then
        log(szRet)
    elseif nLogLevel == 1 then
        logwarning(szRet)
    elseif nLogLevel == 2 then
        logerror(szRet)
    elseif nLogLevel == 3 then
        -- luacheck: push ignore 113
        logdebug(szRet)
        -- luacheck: pop
    end
end

function Util:IsTableEmpty(tb)
    if next(tb) == nil then
        local mt = getmetatable(tb)
        if mt == nil then
            return true
        elseif mt.__tag == 'ReadOnly' then
            return next(mt.__index) == nil
        end
    else
        return false
    end
end

function Util:LightCopyTable(tb)
    local newtable = {}
    for k,v in pairs(tb) do
        rawset(newtable, k, v)
    end
    return newtable
end

local function ContainsItemByKey( tb, element )
    for key,_ in pairs(tb) do
        if key == element then
            return true
        end
    end
    return false
end

local function ContainsItemByValue( tb, element )
    for _,value in pairs(tb) do
        if value == element then
            return true
        end
    end
    return false
end

function Util:ContainsByKey( tb, ... )
    local elements = table.pack(...)
    if (tb == nil) or (#elements <= 0) then
        return false
    end
    for _,element in ipairs(elements) do
        if not ContainsItemByKey(tb, element) then
            return false
        end
    end
    return true
end

function Util:ContainsByValue( tb, ... )
    local elements = table.pack(...)
    if (tb == nil) or (#elements <= 0) then
        return false
    end
    for _,element in ipairs(elements) do
        if not ContainsItemByValue(tb, element) then
            return false
        end
    end
    return true
end

function Util:GetTableCount(tb)
    local nCount = 0
    if tb then
        local nIndex = next(tb)
        while(nIndex ~= nil) do
            nIndex = next(tb, nIndex)
            nCount = nCount + 1
        end
    end
    return nCount
end

function Util:CheckEqual(ValueA, ValueB)
    assert(GWithEditor)
    if((not ValueA and ValueB) or (ValueA and not ValueB) ) then
        return false
    end
    if(ValueA == ValueB) then
        return true
    end

    local szTypeA = type(ValueA)
    local szTypeB = type(ValueB)
    if(szTypeA ~= szTypeB) then
        return false
    end

    if(szTypeA ~= 'table') then
        if(szTypeA == 'number' and not isInteger(ValueA) and not isInteger(ValueB)) then
            -- 判断float是否相等，真tm麻烦
            return KismetMathLibrary.EqualEqual_FloatFloat(ValueA, ValueB)
        else
            return ValueA == ValueB
        end
    end

    local nACount = 0
    for k, v in pairs(ValueA) do
        nACount = nACount + 1
    end
    local nBCount = 0
    for k, v in pairs(ValueB) do
        nBCount = nBCount + 1
    end
    if(nACount ~= nBCount) then
        return false
    end

    local temp
    for k, v in pairs(ValueA) do
        temp = nil
        if(type(k) == 'table') then
            for m, n in pairs(ValueB) do
                if(type(m) == 'table' and self:CheckEqual(k, m)) then
                    temp = n
                    break
                end
            end
        else
            temp = ValueB[k]
        end
        if(not self:CheckEqual(v, temp)) then
            return false
        end
    end

    return true
end

--[[
local Account = {balance = 0}

function Account:withdraw(v)
    self.balance = self.balance -v
end

function Account:geValueAlance()
    return self.balance
end

local a1 = Account
Account = nil
a1:withdraw(100)
print(a1:geValueAlance())
print(Account:geValueAlance())
]]

local TableToString = nil
local TableValueToString = nil
local TAB = "    "

local TableKeyToString = function( k, blank )
    if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
        return k
    else
        return "[" .. TableValueToString( k, blank..TAB ) .. "]"
    end
end

TableValueToString = function( v, blank )
    if "string" == type( v ) then
        v = string.gsub( v, "\n", "\\n" )
        if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
    else
        return "table" == type( v ) and TableToString( v, blank..TAB ) or
            tostring( v )
    end
end

local SortTable = function(tbl)
    local FuncSort = function(valueA, valueB)
        local kA = valueA.k
        local kB = valueB.k
        local lenA = string.len(kA)
        local lenB = string.len(kB)
        local lenMin = math.min(lenA, lenB)
        for i=1,lenMin do
            local jA = string.sub(kA, i, i)
            local jB = string.sub(kB, i, i)
            if jA ~= jB then
                return jA < jB
            end
        end
        if lenA ~= lenB then
            return lenA < lenB
        end
        return false
    end

    local tbResults = {}
    for k, v in pairs( tbl ) do
        local value = {}
        value.k = k
        value.v = v
        table.insert( tbResults, value )
    end
    table.sort( tbResults, FuncSort)
    return tbResults
end

TableToString = function( tbl, blank )
    local result = ""
    local done = {}

    for k, v in ipairs( tbl ) do
        result = result .. "\n" .. blank..TableValueToString( v, blank ) .. ","
        done[ k ] = true
    end
    result = result .. "\n"

    local tbResults = SortTable(tbl)
    for _, v in ipairs( tbResults ) do
        local k = v.k
        local value = v.v
        if not done[ k ] then
            result = result .. blank .. TableKeyToString( k, blank ) ..
                " = " .. TableValueToString( value, blank ) .. ",\n"
        end
    end

    return "{" .. result .. string.sub(blank, 1, string.len(blank)-string.len(TAB)) .."}"
end

function Util:ConvertTableToRawString(tbTable)
    return TableValueToString(tbTable, "")
end

function Util:IsNumber(Value)
    return type(Value) == "number"
end

return Util
