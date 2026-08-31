local DataTableExporter = {}

-- private definition
local StringUtil        = require("StringUtil")
local L10N              = require("L10N")

local EditorTargetType = require("EditorTargetType")
local EditorExportHelper = require("EditorExportHelper")

local szRootPath = getcontentdir()..'GameData/'
local fnGetLines = EngineExtShell.LoadFileLines


local tbAllExportInfo = {}
local tbTempLineData = nil
local tbTempKeys = nil
local szTempFileName = nil
local nTempCurrentLine = 0
local tbTempArrayLine = {}
local szTempTableKey = nil
local tbCurrentExportInfo = nil
local tbTempDefineInfo = nil


-- for loc string
local tbTempL10NKey = {}
local tbTempL10NKeyIdx = {}
local tbTempL10NText = {}
local bTempValidL10N = false
local szTempL10NKey = nil
local nTempL10NColumnIndex = 0
local nTempFileCountL10N = 0

-- declare private functions
local LoadFile
local ResetTempParams
local ParseTable
local OutputError
local NewTemplateFunc
local ParseL10N
local ParseL10NKeyIdx

local ExportDataTable
local ExportSingle
local InitDataTable
local NewExportInfo

------------------------------------------------------------------------------------------------------
-- 各种转换函数
DataTableExporter.TypeInt = 0
DataTableExporter.TypeString = 1
DataTableExporter.TypeFloat = 2
DataTableExporter.TypeBool = 3
DataTableExporter.TypeL10N = 4
DataTableExporter.TypeArrayInt = 5
DataTableExporter.TypeArrayString = 6
DataTableExporter.TypeArrayFloat = 7
DataTableExporter.TypeArrayBool = 8
DataTableExporter.TypeArrayL10N = 9

local Converter = {}
local function ConvertToArrayByType(szValue, Type)
    local tbTemp = StringUtil.Split(szValue, ',')
    tbTempArrayLine = {}
    local fnConvert = Converter[Type]
    if fnConvert == nil then
        error('DataTableExporter:ConvertToArrayByType read a nil function, type : '..Type)
        return
    end
    for i,v in ipairs(tbTemp) do
        table.insert(tbTempArrayLine, fnConvert(v))
    end
    return tbTempArrayLine
end

Converter[DataTableExporter.TypeInt] = tonumber
Converter[DataTableExporter.TypeString] = function(szValue)
    return szValue
end
Converter[DataTableExporter.TypeFloat] = tonumber
Converter[DataTableExporter.TypeBool] = StringUtil.ToBool
Converter[DataTableExporter.TypeL10N] = function(szValue)
    local szNamespace = tostring(nTempFileCountL10N)
    local szKey = string.format("%d.%s", nTempL10NColumnIndex, szTempL10NKey)
    return L10N:MakeText(szNamespace, szKey, szValue)
end
Converter[DataTableExporter.TypeArrayInt] = function(szValue)
    return ConvertToArrayByType(szValue, DataTableExporter.TypeInt)
end
Converter[DataTableExporter.TypeArrayString] = function(szValue)
    return ConvertToArrayByType(szValue, DataTableExporter.TypeString)
end
Converter[DataTableExporter.TypeArrayFloat] = Converter[DataTableExporter.TypeArrayInt]
Converter[DataTableExporter.TypeArrayBool] = function(szValue)
    return ConvertToArrayByType(szValue, DataTableExporter.TypeBool)
end
Converter[DataTableExporter.TypeArrayL10N] = function(szValue)
    return ConvertToArrayByType(szValue, DataTableExporter.TypeL10N)
end

------------------------------------------------------------------------------------------------------
-- pulic functions
function DataTableExporter:Export(nMode)    
    EditorExportHelper:Register(self, EditorTargetType.Common, "DataTableExportRegisterCommon")
    EditorExportHelper:Register(self, EditorTargetType.Client, "DataTableExportRegisterClient")

    EditorExportHelper:SetCurrentExportDir("DataTables/")
    EditorExportHelper:MarkLuaFileIgnored("DataTableExporter")
    EditorExportHelper:MarkLuaFileIgnored("DataTableExportRegisterClient")
    EditorExportHelper:MarkLuaFileIgnored("DataTableExportRegisterCommon")

    for _, tbInfo in ipairs(tbAllExportInfo) do
        ExportSingle(self, tbInfo)
    end

    EditorExportHelper:CopyOtherLuaFileToExportDir()

    local tbTable
    for _, tbInfo in ipairs(tbAllExportInfo) do
        tbTable = tbInfo.tbTable
        if(tbTable.OnAllTablesExported) then
            tbTable:OnAllTablesExported()
        end
    end
        
    return true
end

function DataTableExporter:Register(szTableName)
    local tbTable = require(szTableName)
    for _,v in ipairs(tbAllExportInfo) do
        if szTableName == v.szTableName then
            error("DataTable register duplicated : " .. szTableName)
        end
    end
    local tbInfo = NewExportInfo(szTableName, tbTable)
    table.insert(tbAllExportInfo, tbInfo)
end

function DataTableExporter:SetEnableIterateKey(bEnable)
    tbCurrentExportInfo.bEnableIterateKey = bEnable
end

function DataTableExporter:ForceExportNewTable(szTableName, tbTable)
    local tbNewInfo = NewExportInfo(szTableName, tbTable)
    tbNewInfo.szExportDir = EditorExportHelper:GetExportDir(tbTable.szFileName)

    local tbOldInfo = tbCurrentExportInfo
    local bRet = ExportSingle(self, tbNewInfo)
    tbCurrentExportInfo = tbOldInfo
    return bRet   
end

function DataTableExporter:Define(szKey, szColumnName, DefaultValue, nType, bMustExist)
    local tbInfo = {}
    tbInfo.szKey = szKey
    tbInfo.szColumnName = szColumnName
    tbInfo.DefaultValue = DefaultValue
    tbInfo.nType = nType
    tbInfo.bMustExist = bMustExist
    table.insert(tbTempDefineInfo.tbKeys, tbInfo)

    local tbDefaultValues = tbTempDefineInfo.tbDefaultValues
    if(tbDefaultValues == nil) then
        tbDefaultValues = {}
        tbTempDefineInfo.tbDefaultValues = tbDefaultValues
    end
    tbDefaultValues[szKey] = DefaultValue
end

function DataTableExporter:GetCurrentLineData()
    return tbTempLineData
end

function DataTableExporter:GetCurrentKeys()
    return tbTempKeys
end

-- 新加载方法
function DataTableExporter:Load(tbDataTable)
    if not tbDataTable then
        error('DataTableExporter:Load read a nil table')
        return false
    end

    ResetTempParams()
    if not tbDataTable.szFileName then
        error('szFileName is nil')
        return false
    end
    szTempFileName = tbDataTable.szFileName

    -- if not tbDataTable.tbContainer then
    --     OutputError('Container is nil')
    --     return false
    -- end

    -- if not tbDataTable.OnParseLine then
    --     OutputError('OnParseLine is nil')
    --     return false
    -- end    

    -- load file
    local tbFile = LoadFile(tbDataTable.szFileName)
    if tbFile == nil then
        error('DataTableExporter:Load() load file failed, filename : '..tbDataTable.szFileName)
        return false
    end

    if(not ParseTable(self, tbFile, tbDataTable)) then
        OutputError('Parse table failed')
        return false;
    end

    ResetTempParams()
    return true
end 

function DataTableExporter:Get(szColumnName, DefaultValue, nType, bMustExist)
    if(szColumnName == nil or tbTempLineData == nil or tbTempKeys == nil) then
        OutputError('Invalid params')
        return nil;
    end

    local nColumnIndex = tbTempKeys[szColumnName]
    if nType == DataTableExporter.TypeL10N then
        if not bTempValidL10N then
            if(bMustExist == nil or bMustExist == true) then
                OutputError('L10N metadata is not valid.')
                return nil
            else
                return DefaultValue
            end
        end
        local bFound = false
        for i,v in ipairs(tbTempL10NText) do
            if v == szColumnName then
                bFound = true
                break
            end
        end
        if not bFound then
            if(bMustExist == nil or bMustExist == true) then
                OutputError('Cannot find L10N metadata column key: '..szColumnName)
                return nil
            else
                return DefaultValue
            end
        end
        for i,v in ipairs(tbTempL10NKeyIdx) do
            if i == 1 then
                szTempL10NKey = tbTempLineData[v]
            else
                szTempL10NKey = szTempL10NKey .. "_" .. tbTempLineData[v]
            end
        end
        nTempL10NColumnIndex = nColumnIndex
    end

    if(nColumnIndex == nil) then
        if(bMustExist == nil or bMustExist == true) then
            OutputError('Cannot find column key: '..szColumnName)
            return nil
        else
            return DefaultValue
        end
    end

    if(nColumnIndex > #tbTempLineData) then
        OutputError('Parse data failed, cannot find column '..szColumnName)
        return nil
    end

    -- 空数据用默认值
    local szValue = tbTempLineData[nColumnIndex]
    if(string.len(szValue) == 0) then
        return DefaultValue
    end

    local ConvertFunc = Converter[nType]
    if(ConvertFunc == nil) then
        OutputError('Cannot find convert function: '..nType)
    end

    return ConvertFunc(szValue)
end

function DataTableExporter:SetKey(szKey)
    szTempTableKey = szKey
end

------------------------------------------------------------------------------------------------------
-- private functions
NewExportInfo = function(szTableName, tbTable)
    assert(tbTable)
    assert(szTableName)
    assert(tbTable.szFileName ~= nil)

    local tbInfo = {}
    tbInfo.tbTable = tbTable
    tbInfo.szTableName = szTableName
    tbInfo.bEnableIterateKey = tbTable.bEnableIterateKey
    tbInfo.bEnableOptimizeString = false
    tbInfo.tbTableToDefaultValue = {}    
    
    return tbInfo
end

LoadFile = function( szConfigPath )
    local szFullPath = szRootPath .. szConfigPath
    local bLoadResult, tbFile = fnGetLines(szFullPath)
    if bLoadResult then
        return tbFile
    end
    return nil
end

ParseL10N = function()
    if #tbTempLineData < 1 then
        return
    end
    local szMetaData = string.sub( tbTempLineData[1], 2)
    local tbMetaData = StringUtil.Split(szMetaData, ' ')
    for i,v in ipairs(tbMetaData) do
        if StringUtil.StartsWith(v, 'l10n_key_columns=') then
            local szKeyColumns = string.sub(v, string.len('l10n_key_columns=') + 1)
            tbTempL10NKey = StringUtil.Split(szKeyColumns, ',')
        elseif StringUtil.StartsWith(v, 'l10n_text_columns=') then
            local szTextColumns = string.sub(v, string.len('l10n_text_columns=') + 1)
            tbTempL10NText = StringUtil.Split(szTextColumns, ',')
        end
    end
end

ParseL10NKeyIdx = function()
    for _,v in ipairs(tbTempL10NKey) do
        if tbTempKeys[v] then
            table.insert(tbTempL10NKeyIdx, tbTempKeys[v])
        end
    end
    bTempValidL10N = (#tbTempL10NKey ~= 0) and (#tbTempL10NKey == #tbTempL10NKeyIdx)
end

-- luacheck: push ignore 542
ParseTable = function(self, tbFile, tbDataTable)
    local bReadKeys = false
    local bRet = true
    local nColumnCount = 0
    local tbNewTemplate
    
    InitDataTable(self, tbDataTable)
    local tbContainer = tbDataTable.tbContainer
    if(tbDataTable.OnEditorDefine ~= nil) then
        tbDataTable:OnEditorDefine(self)
    end    

    if(tbDataTable.OnEditorParseBegin ~= nil) then
        tbDataTable:OnEditorParseBegin()
    end

    local bEmptyLine = false
    for k,szLine in ipairs(tbFile) do
        nTempCurrentLine = k
        if szLine ~= nil and string.len(szLine) > 0 then
            szLine = string.gsub(szLine,"\\n","\n")
            tbTempLineData = StringUtil.Split(szLine, '\t')

            bEmptyLine = true
            for _, szTempString in ipairs(tbTempLineData) do
                if(string.len(szTempString) > 0) then
                    bEmptyLine = false
                    break
                end
            end
            if(bEmptyLine) then
                -- Do nothing
            elseif StringUtil.StartsWith(szLine, '#') then
                if k == 1 then
                    ParseL10N()
                end
                if(tbDataTable.OnEditorParseAnnotation) then
                    tbDataTable.OnEditorParseAnnotation(tbDataTable, tbTempLineData)
                end
            else
                if not bReadKeys then
                    nColumnCount = #tbTempLineData
                    for nColumnIndex, nColumnName in pairs(tbTempLineData) do
                        tbTempKeys[nColumnName] = nColumnIndex
                    end
                    ParseL10NKeyIdx()
                    bReadKeys = true
                    nTempFileCountL10N = nTempFileCountL10N + 1
                else             
                    if(string.len(szLine) <= nColumnCount) then
                        OutputError('the line data may be empty.')
                        bRet = false;
                        break;
                    end
                    if(#tbTempLineData < nColumnCount) then
                        OutputError('the column count in line is less then title column.')
                        bRet = false;
                        break;
                    end

                    tbNewTemplate = NewTemplateFunc(self)
                    if(szTempTableKey ~= nil) then
                        local Key = tbNewTemplate[szTempTableKey]
                        if(tbContainer[Key] ~= nil) then
                            OutputError('the key is duplicated: '..Key)
                            bRet = false
                            break
                        else
                            tbContainer[Key] = tbNewTemplate
                        end                        
                    end

                    if(tbDataTable.OnEditorParseLine == nil) then
                        if(szTempTableKey == nil) then
                            OutputError('Table key is not defined: '..szTempFileName)
                        end
                    elseif(not tbDataTable:OnEditorParseLine(self, tbContainer, tbNewTemplate)) then
                        OutputError('Parse line failed:['..k..']')
                        bRet = false
                        break
                    end -- elseif(not tbDataTable:OnEditorParseLine(self, tbContainer, tbNewTemplate)) then
                end -- if not bReadKeys then
            end -- if StringUtil.StartsWith(szLine, '#') then
        end -- if szLine ~= nil and string.len(szLine) > 0 then
    end -- for k,szLine in ipairs(tbFile) do
    
    if(bRet) then
        if(tbDataTable.OnEditorParseFinished ~= nil) then
            tbDataTable:OnEditorParseFinished()
        end
    end

    return bRet
end
-- luacheck: pop

OutputError = function(szInfo)
    error("DataTableExporter parse failed["..szTempFileName..
        "], line: "..nTempCurrentLine..
        ", "..szInfo)
end

ResetTempParams = function()
    tbTempLineData = nil
    tbTempKeys = {}
    szTempFileName = nil
    nTempCurrentLine = 0
    tbTempDefineInfo = nil

    -- for loc string
    tbTempL10NKey = {}
    tbTempL10NKeyIdx = {}
    tbTempL10NText = {}
    bTempValidL10N = false
    szTempL10NKey = nil
    nTempL10NColumnIndex = 0
    szTempTableKey = nil
end

NewTemplateFunc = function(self)
    local tbTemplate = {}
    for _, tbInfo in ipairs(tbTempDefineInfo.tbKeys) do
        tbTemplate[tbInfo.szKey] = self:Get(tbInfo.szColumnName, 
            tbInfo.DefaultValue, tbInfo.nType, tbInfo.bMustExist)
    end  

    tbCurrentExportInfo.tbTableToDefaultValue[tbTemplate] = tbTempDefineInfo.tbDefaultValues
    
    return tbTemplate
end

InitDataTable = function(self, tbDataTable)
    tbTempDefineInfo = {}
    tbTempDefineInfo.tbKeys = {}
    local tbDefineInfos = tbCurrentExportInfo.tbDefineInfos
    if(tbDefineInfos == nil) then
        tbDefineInfos = {}
        tbCurrentExportInfo.tbDefineInfos = tbDefineInfos
    end
    -- 一个Info里可能会有多张子表，所以Define可能会有多份
    table.insert(tbDefineInfos, tbTempDefineInfo)
    
    if(tbDataTable.tbContainer == nil) then
        tbDataTable.tbContainer = {}
    end
end

ExportDataTable = function(self, tbInfo)    
    EditorExportHelper:SetExportBaseInfo(tbInfo.szTableName, tbInfo.tbTable)
    EditorExportHelper:SetSpecialExportFileDir(tbInfo.szExportDir)

    local ExportType = EditorExportHelper.ExportType
    EditorExportHelper:AddExportIgnoreInfo("DataTableExporter", ExportType.Require)
    EditorExportHelper:AddExportIgnoreInfo("DescriptorExporter", ExportType.Require)
    EditorExportHelper:AddExportIgnoreInfo("szFileName", ExportType.Variable)
    EditorExportHelper:AddExportIgnoreInfo("bEnableIterateKey", ExportType.Variable)
    EditorExportHelper:AddExportIgnoreInfo("bEnableOptimizeString", ExportType.Variable)

    EditorExportHelper:AddExportForceInfo("tbContainer", ExportType.Variable)
    EditorExportHelper:AddExportForceInfo("OnGameRequired", ExportType.Function)

    local szFileName = tbInfo.tbTable.szFileName
    if(szFileName) then
        EditorExportHelper:SetForceCheckChangedFile("Content/GameData/"..szFileName)
    end
    if(not tbInfo.bEnableIterateKey) then
        EditorExportHelper:SetExportDefautValues(tbInfo.tbTableToDefaultValue)
    end

    return EditorExportHelper:ExportCommit()
end

ExportSingle = function(self, tbInfo)
    tbCurrentExportInfo = tbInfo
    if(not self:Load(tbInfo.tbTable)) then
        error("Load table failed: "..tbInfo.szTableName)
        return false
    end
    if(not ExportDataTable(self, tbInfo)) then
        error("Export table failed: "..tbInfo.szTableName)
        return false
    end
    return true
end

return DataTableExporter
