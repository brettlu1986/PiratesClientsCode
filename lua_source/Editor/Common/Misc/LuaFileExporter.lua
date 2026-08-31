local LuaFileExporter = {}

local MAX_EXPORT_LOCAL_COUNT = 180
local MAX_SAME_STRING_COUNT = 2

local EXPORT_TABLE_PREFIX = "_v"
local EXPORT_STRING_TABLE_NAME = "_s"
local EXPORT_CLASS_NAME = "_c"

LuaFileExporter.ExportType = {
    Function = 1,
    Require =  1<<1,
    Variable = 1<<2,
}
LuaFileExporter.KEY_ALL = "__allkeys"

local CollectSourceData
local Optimize
local ExportToString
local CheckExportedTable
local GetContentRelativePath
local IsValidExportType

IsValidExportType = function(szType, bIncludeFunction)
    return (szType == 'boolean' or
        szType == 'number' or
        szType == 'string' or
        szType == 'table') or
        (bIncludeFunction and szType == 'function')
end


local tbHashGetter = {}
local GetHash = nil

local StringHashGetter =  function (szValue)
    local nValue = 0
    local nLength = #szValue
    for i = 1, nLength do
        nValue = 31 * nValue + string.byte(szValue, i)
    end
    return nValue
end

local BooleanHashGetter =  function (bValue)
    if bValue then
        return 1231
    else
        return 1237
    end
end

local NumberHashGetter =  function (nValue)
    return math.floor(nValue)
end

local TableHashGetter = function (tbValue)
    local nRet = 0
    for k, v in pairs(tbValue) do
        nRet = nRet + GetHash(k) + GetHash(v)
    end
    return nRet
end

tbHashGetter["number"] = NumberHashGetter
tbHashGetter["boolean"] = BooleanHashGetter
tbHashGetter["string"] = StringHashGetter
tbHashGetter["table"] = TableHashGetter


GetHash = function(value)
    local nValue
    local valueType = type(value)
    local fnHashGetter = tbHashGetter[valueType]
    if fnHashGetter ~= nil then
        nValue = fnHashGetter(value)
    else
        nValue = 0
    end
    return nValue
end


-- 根据tb中每个pair(即k-v)中k的hash值进行排序，生成新的list.
-- 注意: tb中每个pair(即k-v)在新生成的list中对应的数据结构是{k = pair.k, v = pair.v }
local SortTable = function(tb)
    local tbSortedList = {}
    for k, v in pairs(tb) do
        local element = {}
        element.k = k
        element.v = v
        element.sortId = GetHash(k)
        table.insert(tbSortedList, element)
    end
    table.sort(tbSortedList, function(e1, e2) return e1.sortId < e2.sortId end)
    return tbSortedList
end


-- 收集导出数据，包括标签
CollectSourceData = function(szTableName, tbSourceTable, szSourceFullPath,
    tbIgnoreInfo, tbForceExportInfo)

    local ExportType = LuaFileExporter.ExportType
    local szClassName = nil
    local tbExportedRootVariables = {}

    if(szTableName == nil or szSourceFullPath == nil) then
        -- 这里有可能是ForceExport出来的新表，直接用TableName当ClassName
        szClassName = szTableName
        for szName, nType in pairs(tbForceExportInfo) do
            if(nType == ExportType.Variable) then
                tbExportedRootVariables[szName] = false
            end
        end
        return szClassName, tbExportedRootVariables, ""
    end

    local bLoadResult, tbLines = EngineExtShell.LoadFileLines(szSourceFullPath)
    if(not bLoadResult) then
        error("Load failed, "..szTableName)
        return
    end

    local szMatch
    for i=#tbLines, 1, -1 do
        szMatch = string.match(tbLines[i], 'return%s*(.*).*')
        if(szMatch ~= nil) then
            szClassName = szMatch
            break
        end
    end
    szClassName = string.gsub(szClassName, " ", "")
    if(szClassName == nil) then
        error("ClassName is nil, "..szTableName)
        return
    end

    ---------------------------------------------------------------------
    local tbExportedLines = {}

    -- 匹配注释
    local bInAnnotation = false
    local nSingleLineAnnotation
    local MatchAnnotation = function(szLine)
        if(not bInAnnotation) then
            bInAnnotation = string.find(szLine, '%[%[') ~= nil
            if(not bInAnnotation) then
                nSingleLineAnnotation = string.find(szLine, '%-%-')
                return string.find(szLine, '%[EXPORT') == nil and nSingleLineAnnotation ~= nil and nSingleLineAnnotation == 1
            end
            return bInAnnotation
        else
            if(string.find(szLine, '%]%]') ~= nil) then
                bInAnnotation = false
            end
            return true
        end
    end

    -- 匹配{}
    local nBraceStack = 0
    local szLastLine
    local MatchBraces = function(szLine)
        if(szLastLine == szLine) then
            return nBraceStack
        end

        szLastLine = szLine
        local nFind = 0
        while(true) do
            nFind = string.find(szLine, '{', nFind+1)
            if(nFind == nil) then
                break
            end
            nBraceStack = nBraceStack + 1
        end
        nFind = 0
        while(true) do
            nFind = string.find(szLine, '}', nFind+1)
            if(nFind == nil) then
                break
            end
            nBraceStack = nBraceStack - 1
        end
        return nBraceStack
    end

    -- 匹配是否在函数内
    local bInFunction = false
    local bFunctionEnd = false
    local szFunctionName, szTempFind
    local MatchFunction = function(szLine)
        if(bFunctionEnd) then
            bInFunction = false
            bFunctionEnd = false
            szFunctionName = nil
        end

        if(not bInFunction) then
            szMatch = string.match(szLine, '.*function%s*(%S+)%(.*')
            if(szMatch ~= nil) then
                szTempFind = string.find(szLine, "local")
                if(szTempFind ~= nil and szTempFind == 1) then
                    -- local function
                    bInFunction = true
                    szFunctionName = szMatch
                else
                    szTempFind = string.match(szMatch, szClassName..":(%S+)")
                    if(szTempFind ~= nil) then
                        bInFunction = true
                        szFunctionName = szTempFind
                    end
                end
                --logdebug("MatchFunction", szFunctionName)
            end
            return bInFunction
        else
            szTempFind = string.find(szLine, 'end')
            if(szTempFind ~= nil and szTempFind == 1) then
                bFunctionEnd = true
            end
            return true
        end
    end

    -- 匹配Require
    local szRequireName
    local MatchRequire = function(szLine)
        szRequireName = nil
        if(bInFunction) then
            return false
        end
        szMatch = string.match(szLine, '.*require%s*[%(]?[\"\'](%S+)[\"\'].*')
        if(szMatch) then
            szRequireName = szMatch
            --logdebug("MatchRequire", szRequireName, szLine)
            return true
        end
        return false
    end

    -- 匹配Variable
    local szVariableMatch = szClassName..[[%.(%S+)%s*=.*]]
    local szVariableName
    local bLocalVariable = false
    local bVariableMatchEnd = false
    local MatchVariable = function(szLine)
        if(szVariableName ~= nil) then
            if(bInFunction or bVariableMatchEnd or MatchBraces(szLine) == 0) then
                --logdebug("MatchVariableEnd", szVariableName, bLocalVariable, szLine)
                szVariableName = nil
                bVariableMatchEnd = false
            end
        end
        if(szVariableName == nil) then
            szMatch = string.match(szLine, szVariableMatch)
            if(szMatch) then
                szVariableName = szMatch
                bLocalVariable = false
            else
                szMatch = string.match(szLine, 'local%s*(%S+)%s*=.*')
                if(szMatch and szMatch ~= szClassName) then
                    szVariableName = szMatch
                    bLocalVariable = true
                end
            end

            if(szVariableName ~= nil) then
                -- 这里不能立即吧szVariableName置成空，因为后面会用到
                bVariableMatchEnd = MatchBraces(szLine) == 0
                --logdebug("MatchVariable", szVariableName, bLocalVariable, bVariableMatchEnd, szLine)
                return true
            end
        end
        return false
    end

    local TryExportLine = function(szLine, bAddLine)
        if(szVariableName ~= nil and not bLocalVariable) then
            -- 非Local变量需要导出
            --logdebug("ExportVariable", szVariableName, szLine)
            tbExportedRootVariables[szVariableName] = false
            return true
        elseif(bAddLine) then
            --logdebug("ExportLine", szLine)
            table.insert(tbExportedLines, szLine..'\n')
            return true
        end
        return false
    end

    -- 匹配特定变量
    local bInfoMatched = false
    local MatchInfos = function(szLine, tbInfos, bExport)
        bInfoMatched = false
        for szName, nType in pairs(tbInfos) do
            if(nType == ExportType.Function) then
                bInfoMatched = bInFunction and szName == szFunctionName
            elseif(nType == ExportType.Require) then
                bInfoMatched = not bInFunction and szName == szRequireName
            elseif(nType == ExportType.Variable) then
                bInfoMatched = not bInFunction and szName == szVariableName
            end

            if(bInfoMatched) then
                --logdebug("MatchInfos", szName, nType, bExport, szLine)
                if(bExport) then
                    TryExportLine(szLine, true)
                else
                    -- 忽略导出Variable或者Function
                    tbExportedRootVariables[szName] = nil
                end
                return true
            end
        end
        return false
    end

    -- 匹配单行导出
    local bExportingSingleLine = false
    local ExportSingleLine = function(szLine)
        if(bInFunction) then
            return false
        end
        if(not bExportingSingleLine and string.find(szLine, '%[EXPORT%]') ~= nil) then
            bExportingSingleLine = true
            return true
        elseif(bExportingSingleLine) then
            bExportingSingleLine = false
            --logdebug("ExportSingleLine", szLine)
            TryExportLine(szLine, true)
            return true
        end
        return false
    end

    -- 匹配多行导出
    local bExportingMultiLine = false
    local ExportMultiLine = function(szLine)
        if(not bExportingMultiLine) then
            if(string.find(szLine, '%[EXPORT BEGIN%]') ~= nil) then
                bExportingMultiLine = true
                return true
            end
        else
            if(string.find(szLine, '%[EXPORT END%]') ~= nil) then
                bExportingMultiLine = false
                table.insert(tbExportedLines, '\n')
            else
                --logdebug("ExportMultiLine", szLine)
                TryExportLine(szLine, true)
            end
            return true
        end
        return false
    end

    -- -- 导出Require
    -- local ExportRequireLine = function(szLine)
    --     if(szRequireName ~= nil) then
    --         --logdebug("ExportRequireLine", szRequireName, szLine)
    --         table.insert(tbExportedLines, szLine..'\n')
    --         return true
    --     end
    --     return false
    -- end

    -- 导出function
    local ExportFunction = function(szLine)
        if(bInFunction) then
            --logdebug("ExportFunction", szLine)
            table.insert(tbExportedLines, szLine..'\n')
            return true
        end
        return false
    end

    -- local ExportVariable = function(szLine)
    --     return TryExportLine(szLine, false)
    -- end

    -- 检查强制导出
    local nFlag = tbForceExportInfo[LuaFileExporter.KEY_ALL]
    local bExportAllFunctions = nFlag ~= nil and (nFlag & ExportType.Function > 0) or false
    local bExportAllVariables = nFlag ~= nil and (nFlag & ExportType.Variable > 0) or false
    if(bExportAllVariables) then
        -- 将所有变量都标记下
        for k, v in pairs(tbSourceTable) do
            if(IsValidExportType(type(v)) and type(k) == 'string') then
                tbExportedRootVariables[k] = false
            end
        end
    end

    -- 主函数，导出各种东西
    local bMatched = false
    for _, szLine in ipairs(tbLines) do
        if(not MatchAnnotation(szLine)) then
            MatchFunction(szLine)
            MatchVariable(szLine)
            MatchRequire(szLine)

            bMatched = false
            bMatched = bMatched or MatchInfos(szLine, tbIgnoreInfo, false)
            bMatched = bMatched or MatchInfos(szLine, tbForceExportInfo, true)
            bMatched = bMatched or ExportSingleLine(szLine)
            bMatched = bMatched or ExportMultiLine(szLine)
            --bMatched = bMatched or ExportRequireLine(szLine)
            if(bExportAllFunctions) then
                bMatched = bMatched or ExportFunction(szLine)
            end
            -- if(bExportAllVariables) then
            --     bMatched = bMatched or ExportVariable(szLine)
            -- end
        end
    end

    if(not bExportAllVariables) then
        -- 将强制导出的变量设到tbExportedRootVariables中
        for szKey, nType in pairs(tbForceExportInfo) do
            if(nType == ExportType.Variable) then
                tbExportedRootVariables[szKey] = false
            end
        end
    end

    return szClassName, tbExportedRootVariables, table.concat(tbExportedLines)
end


--，收集所有引用的表，去掉重复的，将相同key的表进行整理
Optimize = function(szTableName, tbSourceTable, tbExportedRootVariables,
    tbTableToDefaultValue, bEnableOptimizeString)

    local tbTableElementCount = {}  -- 记录了每个table的元素个数
    local GetElementCount = function(tbTable, bForceCalculate)
        if(tbTable == nil) then
            return 0
        end
        if(not bForceCalculate) then
            local nFind = tbTableElementCount[tbTable]
            if(nFind ~= nil) then
                return nFind
            end
        end

        local nCount = 0
        for _k, _v in pairs(tbTable) do
            nCount = nCount + 1
        end
        tbTableElementCount[tbTable] = nCount
        return nCount
    end

    local bExportFunction = tbSourceTable.bExportFunction
    local tbNewTableToDefaultValue = {}
    local tbTempDefaultValues = {}
    local DeepCopyWithoutDefaultValue
    DeepCopyWithoutDefaultValue = function(tbOldTable)
        local tbNewTable = {}
        local tbDefaultValue = tbTableToDefaultValue[tbOldTable]
        local t, dv, bHasDefaultValue
        for k, v in pairs(tbOldTable) do
            t = type(v)
            if(tbDefaultValue) then
                dv = tbDefaultValue[k]
            else
                dv = nil
            end
            if(dv ~= nil and type(dv) == t and dv == v) then
                -- 与Default值相同的不拷贝
                bHasDefaultValue = true
            else
                if t == "table" then
                    rawset(tbNewTable, k, DeepCopyWithoutDefaultValue(v))
                elseif v ~= nil then
                    if(IsValidExportType(t, bExportFunction)) then
                        rawset(tbNewTable, k, v)
                    elseif(t == 'userdata') then
                        logerror(string.format('Cannot export type %s, key: %s, file: %s', t, tostring(k), szTableName))
                    end
                end
            end
        end

        -- 建立tbNewTableToDefaultValue
        if(tbDefaultValue and bHasDefaultValue) then
            --tbTempDefaultValues[tbDefaultValue] = true
            local bFind = false
            for _, v in ipairs(tbTempDefaultValues) do
                if(v == tbDefaultValue) then
                    bFind = true
                    break
                end
            end
            if(not bFind) then
                table.insert(tbTempDefaultValues, tbDefaultValue)
            end
            tbNewTableToDefaultValue[tbNewTable] = tbDefaultValue
        end

        -- 统计个数，后面要用
        GetElementCount(tbNewTable)
        return tbNewTable
    end

    -- 建立导出表
    local Temp, szType
    local tbRemoved = {}
    local tbSortedExportedRootVariable = SortTable(tbExportedRootVariables)
    for _, e in ipairs(tbSortedExportedRootVariable) do
        local szKey = e.k
        local v = e.v
        Temp = tbSourceTable[szKey]
        if(Temp ~= nil) then
            --logdebug("ExportVar", szKey)
            assert(type(v) == 'boolean' and v == false)
            szType = type(Temp)
            if(szType == 'table') then
                tbExportedRootVariables[szKey] = DeepCopyWithoutDefaultValue(Temp)
            elseif(IsValidExportType(szType)) then
                tbExportedRootVariables[szKey] = Temp
            end
        else
            table.insert(tbRemoved, szKey)
        end
    end

    for _, szKey in ipairs(tbRemoved) do
        tbExportedRootVariables[szKey] = nil
    end

    ------------------------------------------------------------------------------------
    local tbTableToIndex = {} -- table to global index
    local tbIndexToTable = {} -- global index to table

    local IsSameTable = function(tbA, tbB)
        local nACount = GetElementCount(tbA)
        local nBCount = GetElementCount(tbB)
        if(nACount ~= nBCount) then
            return false
        end

        -- 不同Default值的不能合
        if(tbTableToDefaultValue[tbA] ~= tbTableToDefaultValue[tbB]) then
            return false
        end

        -- 值不等的不能合
        for k, v in pairs(tbA) do
            if(tbB[k] ~= v) then
                return false
            end
        end
        return true
    end
    local FindSameTable = function(tbSource)
        if(tbTableToIndex[tbSource] ~= nil) then
            return tbSource
        end

        for _, tbDest in ipairs(tbIndexToTable) do
            if(IsSameTable(tbSource, tbDest)) then
                return tbDest
            end
        end
        return nil
    end
    local AddNewTable = function(tbTable, bAddType)
        assert(tbTableToIndex[tbTable] == nil)
        table.insert(tbIndexToTable, tbTable)
        tbTableToIndex[tbTable] = #tbIndexToTable
    end

    -- 合并相同的表
    local MergeTables
    MergeTables = function(tbTable, tbStack)
        local tbFind, t
        local tbTableSortList = SortTable(tbTable)
        for _, element in ipairs(tbTableSortList) do
            local k = element.k
            local v = element.v
            t = type(v)
            if(t == 'table') then
                if(tbStack[v] ~= nil) then
                    error("Table is circular reference: " ..szTableName..", key: "..tbStack[v])
                else
                    tbFind = FindSameTable(v)
                    if(tbFind) then
                        tbTable[k] = tbFind
                    else
                        tbStack[v] = k
                        MergeTables(v, tbStack)
                        tbStack[v] = nil
                    end -- if(tbFind) then
                end -- if(tbStack[v]) then
            else
                assert(IsValidExportType(t, bExportFunction))
            end
        end
        AddNewTable(tbTable)
    end

    -- 把Default表加到map中
    -- local tbSortedTempDefaultValues = SortTable(tbTempDefaultValues)
    -- local tbStack
    -- for _, element in ipairs(tbSortedTempDefaultValues) do
    --     local k = element.k
    --     if(type(k) == 'table') then
    --         tbStack = {}
    --         MergeTables(k, tbStack)
    --     end
    -- end

    local tbStack = {}
    MergeTables(tbTempDefaultValues, tbStack)
    table.remove(tbIndexToTable, #tbIndexToTable)
    tbTableToIndex[tbTempDefaultValues] = nil

    -- 重新调整DefaultTable的对应关系
    local tbFind
    for tbData, tbOldDefaultTable in pairs(tbNewTableToDefaultValue) do
        tbFind = FindSameTable(tbOldDefaultTable)
        if(tbFind) then
            tbNewTableToDefaultValue[tbData] = tbFind
        end
    end


    tbSortedExportedRootVariable = SortTable(tbExportedRootVariables)
    -- 合并表
    for _, element in ipairs(tbSortedExportedRootVariable) do
        local v = element.v
        if(type(v) == 'table') then
            tbStack = {}
            MergeTables(v, tbStack)
        end
    end

    local tbIndexToString = {}
    local tbStringToIndex = {}
    if(bEnableOptimizeString) then
        ---------------------------------------------------------------------
        -- 收集重复字符串信息
        local tbStringCount = {}
        local TryAddString = function(szString)
            local nCount = tbStringCount[szString]
            if(nCount ~= nil) then
                tbStringCount[szString] = nCount + 1
            else
                tbStringCount[szString] = 1
            end
        end

        for _, tbTable in ipairs(tbIndexToTable) do
            for k, v in pairs(tbTable) do
                if(type(k) == 'string') then
                    TryAddString(k)
                end
                if(type(v) == 'string') then
                    TryAddString(v)
                end
            end
        end

        for szString, nCount in pairs(tbStringCount) do
            if(nCount >= MAX_SAME_STRING_COUNT) then
                table.insert(tbIndexToString, szString)
                tbStringToIndex[szString] = #tbIndexToString
            end
        end
    end

    return tbIndexToTable, tbTableToIndex,
        tbNewTableToDefaultValue,
        tbStringToIndex, tbIndexToString
end

ExportToString = function(szTableName, szClassName, tbTable,
    tbIndexToTable, tbTableToIndex,
    tbNewTableToDefaultValue,
    tbStringToIndex, tbIndexToString,
    tbExportedRootVariables, szExportedLines,
    szCustomData)

    local ReplaceClassName = function(szString)
        local szRet = szString
        szRet = string.gsub(szRet, szClassName.."%.", EXPORT_CLASS_NAME..".")
        szRet = string.gsub(szRet, szClassName..":", EXPORT_CLASS_NAME..":")
        return szRet
    end

    local VerifyString = function(szString)
        szString = string.gsub(szString, "\\", "\\\\")
        szString = string.gsub(szString, "\"", "\\\"")
        szString = string.gsub(szString, "\n", "\\n")
        return szString
    end

    local ReplaceStringValue = function(szString)
        local nIndex = tbStringToIndex[szString]
        if(nIndex ~= nil) then
            return true, string.format("%s[%d]", EXPORT_STRING_TABLE_NAME, nIndex)
        else
            return false, szString
        end
    end

    local GetTableName = function(nIndex)
        if(nIndex == nil) then
            error(string.format("Index is invalid, file: %s", szTableName))
        end

        if(nIndex < MAX_EXPORT_LOCAL_COUNT) then
            return "_"..nIndex
        else
            return EXPORT_TABLE_PREFIX.."["..tostring(nIndex - MAX_EXPORT_LOCAL_COUNT + 1).."]"
        end
    end

    local ConvertToString
    local GenerateTableString
    ConvertToString = function(Value, bKey, bUseTableIndex)

        local szType = type(Value)
        if(szType == 'number') then
            return bKey and '['..tostring(Value)..']' or tostring(Value)
        elseif(szType == 'string') then
            local bReplaced
            bReplaced, Value = ReplaceStringValue(Value)
            if(not bReplaced) then
                Value = VerifyString(Value)
                Value = '\"'..Value..'\"'
            end

            if(bKey) then
                return '['..Value..']'
            else
                return Value
            end
        elseif(szType == 'boolean') then
            return bKey and '['..tostring(Value)..']' or tostring(Value)
        elseif(szType == 'table') then
            if(bKey) then
                error("The key is table, file: "..szTableName)
            else
                if(bUseTableIndex) then
                    return GetTableName(tbTableToIndex[Value])
                else
                    return GenerateTableString(Value, true, false)
                end
            end
        elseif(szType == 'function') then
            if(bKey) then
                error("Function can not be a key, file: "..szTableName)
            else
                local szData = Value()
                if(szData == nil or type(szData) ~= 'string') then
                    error("Export function failed, the return value must be a valid string, file: "..szTableName)
                end
                return szData
            end
        else
            error("Invalid export type "..szTableName..", type: "..szType)
        end
    end


    GenerateTableString = function(tbTempTable, bWithBracket, bUseTableIndex)
        local szRet = ""
        if(bWithBracket) then
            szRet = "{\n"
        end

        local tbSortList = SortTable(tbTempTable)
        for _, element in ipairs(tbSortList) do
            local k = element.k
            local v = element.v
            szRet = szRet..string.format("    %s = %s,\n",
                ConvertToString(k, true, bUseTableIndex),
                ConvertToString(v, false, bUseTableIndex))
        end

        if(bWithBracket) then
            szRet = szRet .. "}\n"
        end
        return szRet
    end

    ---------------------------------------------------------------------
    local tbOutput = {}
    table.insert(tbOutput, "-- Generated by script, DO NOT edit this file !!!\n\n")
    --table.insert(tbOutput, string.format("local %s = {}\n", szClassName))
    table.insert(tbOutput, string.format("local %s = {}\n", EXPORT_CLASS_NAME))

    local bPrintOnce = false
    local ResetPrintOnce = function()
        bPrintOnce = false
    end
    local PrintOnce = function(szString)
        if(not bPrintOnce) then
            bPrintOnce = true
            table.insert(tbOutput, szString)
        end
    end

    ---------------------------------------------------------------------
    -- Strings
    if(#tbIndexToString > 0) then
        table.insert(tbOutput, "\n-- String:\n")
        table.insert(tbOutput, string.format("local %s = {\n", EXPORT_STRING_TABLE_NAME))
        for nIndex, szString in ipairs(tbIndexToString) do
            table.insert(tbOutput, string.format("    [%d] = \"%s\",\n", nIndex, VerifyString(szString)))
        end
        table.insert(tbOutput, "}\n\n")
    end

    ---------------------------------------------------------------------
    -- All tables
    ResetPrintOnce()
    local szLocal = "local "
    for nIndex, tbTempTable in ipairs(tbIndexToTable) do
        PrintOnce("\n-- All tables:\n")
        if(nIndex == MAX_EXPORT_LOCAL_COUNT) then
            local szT =  string.format("local %s = {}\n", EXPORT_TABLE_PREFIX)
            table.insert(tbOutput,szT)
            szLocal = ""
        end
        local szTemp =  string.format("%s%s = %s", szLocal,
        GetTableName(nIndex), GenerateTableString(tbTempTable, true, true))
        table.insert(tbOutput, szTemp)

    end

    ---------------------------------------------------------------------
    -- Default values
    ResetPrintOnce()
    local szMetaFunction = [[
%s.__index = function(self, k)
    local v = rawget(self, k)
    if(v ~= nil) then
        return v
    else
        return rawget(%s, k)
    end
end
%s.__newindex = function(self, k, new)
    local v = self[k]
    if(v == nil) then
        rawset(self, k, new)
    else
        error("Cannot change old value, key: ".. tostring(k))
    end
end
]]
    local tbAllDefaultValues = {}
    local tbDefault
    for nIndex, tbTempTable in ipairs(tbIndexToTable) do
        tbDefault = tbNewTableToDefaultValue[tbTempTable]
        if(tbDefault ~= nil) then
            PrintOnce("\n-- Default values:\n")

            if(tbAllDefaultValues[tbDefault] == nil) then
                tbAllDefaultValues[tbDefault] = true
                szTableName = GetTableName(tbTableToIndex[tbDefault])
                table.insert(tbOutput, string.format(szMetaFunction, szTableName, szTableName, szTableName))
            end

            table.insert(tbOutput, string.format("setmetatable(%s, %s)\n",
                GetTableName(nIndex),
                GetTableName(tbTableToIndex[tbDefault])))
        end
    end

    ---------------------------------------------------------------------
    -- Root variables
    ResetPrintOnce()

    local tbSortList = SortTable(tbExportedRootVariables)
    for _, element in ipairs(tbSortList) do
        local szKey = element.k
        local Value = element.v
        PrintOnce("\n-- Root variables:\n")

        if(type(Value) == 'table') then

            table.insert(tbOutput, string.format("%s.%s = %s\n",
                EXPORT_CLASS_NAME, szKey, GetTableName(tbTableToIndex[Value])))
        else
            table.insert(tbOutput, string.format("%s.%s = %s\n",
                EXPORT_CLASS_NAME, szKey, ConvertToString(Value, false)))
        end
    end

    ---------------------------------------------------------------------
    -- Other data
    if(szExportedLines ~= nil and string.len(szExportedLines) > 0) then
        table.insert(tbOutput, "\n")
        table.insert(tbOutput, ReplaceClassName(szExportedLines))
    end

    ---------------------------------------------------------------------
    -- Custom data
    if(szCustomData ~= nil) then
        table.insert(tbOutput, "\n-- Custom data:\n")
        table.insert(tbOutput, ReplaceClassName(szCustomData))
    end

    ---------------------------------------------------------------------
    -- function OnGameRequired:
    if(tbTable.OnGameRequired) then
        table.insert(tbOutput, string.format("\n%s:OnGameRequired()\n", EXPORT_CLASS_NAME))
    end

    table.insert(tbOutput, "\nreturn "..EXPORT_CLASS_NAME)
    return table.concat(tbOutput)
end

CheckExportedTable = function(szSouceTableName, tbSourceTable,
    szTargetFullPath, tbExportedRootVariables, bEnableError)

    local szLastKey
    local OutputError = function(szDesc)
        if(bEnableError) then
            error(string.format("Check table [%s] failed, key: [%s], info: %s",
                szSouceTableName, szLastKey, szDesc))
        end
    end

    local CheckTable, szSourceType, szExportType
    local bExportFunction = tbSourceTable.bExportFunction
    CheckTable = function(tbSource, tbExport)
        if(tbExport == nil) then
            OutputError("value is nil")
            return false
        end

        szSourceType = type(tbSource)
        szExportType = type(tbExport)
        if(szSourceType ~= szExportType) then
            OutputError("value type is not same")
            return false
        end

        if(szSourceType ~= 'table') then
            if(tbSource ~= tbExport) then
                OutputError("value is not same")
                return false
            end
            return true
        end

        local tbKeys = {}
        if(tbExport.__metatable ~= nil) then
            local tbDefault = tbExport.__metatable
            for k, _ in pairs(tbDefault) do
                tbKeys[k] = true
            end
        end
        for k, _ in pairs(tbExport) do
            tbKeys[k] = true
        end

        local nSourceCount = 0
        for k, v in pairs(tbSource) do
            szSourceType = type(v)
            szLastKey = k
            tbKeys[k] = nil
            if(IsValidExportType(szSourceType, bExportFunction)) then
                nSourceCount = nSourceCount + 1
                if(false == CheckTable(v, tbExport[k])) then
                    return false
                end
            end
        end

        return next(tbKeys) == nil
    end

    local szExportFullPath = GetContentRelativePath(szTargetFullPath)
    szExportFullPath = string.gsub(szExportFullPath, "Content/", "")
    if(not file_exists(szExportFullPath)) then
        if(bEnableError) then
            error("Exported lua file is not existed: "..szExportFullPath)
        end
        return false
    end

    local bSuccess, tbExportTable = requirewithfullpath(szExportFullPath)
    if(not bSuccess) then
        if(bEnableError) then
            error("load export lua file failed: "..szExportFullPath)
        end
        return false
    end

    for szExportKey, _ in pairs(tbExportedRootVariables) do
        if(tbSourceTable[szExportKey] ~= nil) then
            szLastKey = szExportKey
            if(false == CheckTable(tbSourceTable[szExportKey], tbExportTable[szExportKey])) then
                return false
            end
        end
    end

    return true
end

GetContentRelativePath = function(szFullPath)
    return string.match(szFullPath, ".*[/\\](Content[/\\].*)")
end

LuaFileExporter.Export = function(szTableName, tbSourceTable,
    szSourceFullPath, szTargetFullPath,
    tbTableToDefaultValue,
    tbIgnoreInfo, tbForceExportInfo,
    bCheckNeedExport,
    bEnableOptimizeString,
    szCustomData)

    -- 收集原始文件信息
    local szClassName, tbExportedRootVariables, szExportedLines
        = CollectSourceData(szTableName, tbSourceTable,
            szSourceFullPath, tbIgnoreInfo, tbForceExportInfo)

    -- 如果需要检查那么Check下，一样的话就不导出了
    if(bCheckNeedExport) then
        if(CheckExportedTable(szTableName, tbSourceTable,
            szTargetFullPath, tbExportedRootVariables, false)) then
            -- 全一样，不导出
            return true
        end
    end

    log('Exporting', GetContentRelativePath(szTargetFullPath))

    -- 优化合并表
    local tbIndexToTable, tbTableToIndex,
        tbNewTableToDefaultValue,
        tbStringToIndex, tbIndexToString
        = Optimize(szTableName, tbSourceTable, tbExportedRootVariables,
            tbTableToDefaultValue, bEnableOptimizeString)

    -- 导出成字符串
    local szOutput = ExportToString(szTableName, szClassName, tbSourceTable,
        tbIndexToTable, tbTableToIndex,
        tbNewTableToDefaultValue,
        tbStringToIndex, tbIndexToString,
        tbExportedRootVariables, szExportedLines,
        szCustomData)

    -- 存文件
    if(not EditorExtendFunctions.SaveStringToFile(szTargetFullPath, szOutput)) then
        error("Export table failed: ".. szTargetFullPath)
        return false
    end

    -- 再次检查下
    if(not CheckExportedTable(tbSourceTable, szTableName,
        szTargetFullPath, tbExportedRootVariables, true)) then
        return false
    end

    return true
end

return LuaFileExporter