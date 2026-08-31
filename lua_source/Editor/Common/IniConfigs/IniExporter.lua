-----------------------------------------------------
--File Name    : IniExporter.lua
--Author       : Song Fuhao
--Create Time  : 2016-12-20
--Description  : 用于读取Ini配置表
-----------------------------------------------------
local IniExporter = {}

local StringUtil = require("StringUtil")
local L10N = require("L10N")

local szRootPath = getcontentdir() .. 'GameData/'
local fnGetLines = EngineExtShell.LoadFileLines

local EditorTargetType = require("EditorTargetType")
local EditorExportHelper = require("EditorExportHelper")

-- 临时数据
local tbTempIniData = nil
local szTempFileName = nil
local tbTempArrayLine = {}
local tbAllExportInfo = {}


IniExporter.TypeNumber 		= 0
IniExporter.TypeString 		= 1
IniExporter.TypeBool 		= 2
IniExporter.TypeL10N 		= 3
IniExporter.TypeArrayNumber = 4
IniExporter.TypeArrayString = 5

--[[
	Coverter
]]
local Converter = {}

local function ConvertToArray(tbValue, ConvertFunc)
	local tbContainer = {}
	for i,v in ipairs(tbValue) do
		tbContainer[i] = ConvertFunc(v)
	end
    return tbContainer
end

local function ConvertString(szValue)
	local szStr = string.match(szValue, "\"(.+)\"")
	if szStr then
		return szStr
	end
	return szValue
end

local function ConvertLocString(szValue)
	local szNamespace, szKey, szText = string.match(szValue, "NSLOCTEXT%(\"(.+)\", *\"(.+)\", *\"(.+)\"%)")
	if szNamespace and szKey and szText then
		return L10N:MakeText(szNamespace, szKey, szText)
	end
end

local function ConvertToArrayByType(szValue, Type)
    local tbMetaData = StringUtil.Split(szValue, ',')
    tbTempArrayLine = {}
    local fnConvert = Converter[Type]
    if fnConvert == nil then
        error('IniExporter:ConvertToArrayByType read a nil function, type : '..Type)
        return
    end
    for _,v in ipairs(tbMetaData) do
        table.insert(tbTempArrayLine, fnConvert(v))
    end
    return tbTempArrayLine
end

local function ConvertArrayNumber(szValue)
	return ConvertToArrayByType(szValue, IniExporter.TypeNumber)
end

local function ConvertArrayString(szValue)
	return ConvertToArrayByType(szValue, IniExporter.TypeString)
end

Converter[IniExporter.TypeNumber] = tonumber
Converter[IniExporter.TypeString] = ConvertString
Converter[IniExporter.TypeBool] = StringUtil.ToBool
Converter[IniExporter.TypeL10N] = ConvertLocString
Converter[IniExporter.TypeArrayNumber] = ConvertArrayNumber
Converter[IniExporter.TypeArrayString] = ConvertArrayString


-----------------------------------------------------------------------
local function OutputError(szInfo)
    error("IniExporter parse failed["..szTempFileName.."], "..szInfo)
end

local function Transform( szStr )
	local szResult = szStr
	szResult = szResult:gsub("\\;", "#_!36!_#") -- to keep \;
	szResult = szResult:gsub("\\=", "#_!71!_#") -- to keep \=
	return szResult
end

local function DeTransform( szStr )
	local szResult = szStr
	szResult = szResult:gsub("#_!36!_#", ";")
	szResult = szResult:gsub("#_!71!_#", "=")
	return szResult
end

-- Load an IniExporter file
-- path: path of the file to read
local function LoadFile( tbFile )
	local tbData = {}
	local szCurrentTag = nil
    for _,szLine in ipairs(tbFile) do
		szLine = Transform(szLine)

		-- Delete Comments
		local SplitComment = StringUtil.Split(szLine, ";")
		if #SplitComment >= 2 then
			szLine = SplitComment[1]
		end

		-- Delete Comments
		SplitComment = StringUtil.Split(szLine, "#")
		if #SplitComment >= 2 then
			szLine = SplitComment[1]
		end

		szLine = StringUtil.Trim(szLine)
		if szLine ~= nil and string.len(szLine) > 0 then
			if szLine:sub(1, 1) == "[" and szLine:sub(szLine:len(), szLine:len()) == "]" then
				-- Find tag
				szCurrentTag = szLine:sub(2, szLine:len()-1)
				tbData[szCurrentTag] = {}
			else
				-- Find key&value
				local equalCharIdx = string.find(szLine, "=")
				if equalCharIdx then
					local szKey = StringUtil.Trim(string.sub(szLine, 1, equalCharIdx - 1))
					local szValue = StringUtil.Trim(string.sub(szLine, equalCharIdx + 1))

					szKey = DeTransform(szKey)
					szValue = DeTransform(szValue)
            		szValue = string.gsub(szValue,"\\n","\n")

					if tbData[szCurrentTag][szKey] == nil then
						tbData[szCurrentTag][szKey] = szValue
					elseif type(tbData[szCurrentTag][szKey]) == 'table' then
						table.insert( tbData[szCurrentTag][szKey], szValue )
					else
						local lastValue = tbData[szCurrentTag][szKey]
						tbData[szCurrentTag][szKey] = { lastValue, szValue }
					end
				else
					--error('Bad IniExporter file structure, filename : '..szPath)
					return nil
				end
			end
		end
	end
	return tbData
end

local function Load(self, tbInfo)
    local tbTable = tbInfo.tbTable
    szTempFileName = tbTable.szFileName
    if not szTempFileName then
        error('Ini config lua must had szFileName: '..tbInfo.szTableName)
    end

    local szFullPath = szRootPath .. szTempFileName
    local bLoadResult, tbLineData = fnGetLines(szFullPath)
    if not bLoadResult or tbLineData == nil then
        error("IniExporter load file failed, filename : " .. szTempFileName)
		return false
    end

    tbTempIniData = LoadFile(tbLineData)
    if tbTempIniData == nil or tbTable.OnParse == nil then
        error("IniExporter has no parse function "..tbInfo.szTableName)
        return false
    end

    tbTable:OnParse(self)
    return true
end

function IniExporter:Get(szTag, szKey, DefaultValue, nType)
    if (szTag == nil) or (szKey == nil) or (tbTempIniData == nil) then
        OutputError('Invalid params')
        return nil
    end
	
    -- Use default value when data is nil
    local szValue = nil
	if tbTempIniData[szTag] then
		szValue = tbTempIniData[szTag][szKey]
	end
	if szValue == nil then
		return DefaultValue
	end

	-- Coverte by function
	local ConvertFunc = Converter[nType]
	if ConvertFunc == nil then
		OutputError('Cannot find convert function, type index: ' .. tostring(nType))
	end
	local retValue = nil
	if type(szValue) == 'table' then
		retValue = ConvertToArray(szValue, ConvertFunc)
	else
		retValue = ConvertFunc(szValue)
	end
	if szValue == nil then
		retValue = DefaultValue
	end
	return retValue
end

function IniExporter:Register(szTableName)
    local tbTable = require(szTableName)
    local tbInfo = {}
    tbInfo.tbTable = tbTable
    tbInfo.szTableName = szTableName
    table.insert(tbAllExportInfo, tbInfo)
end

-------------------------------------------------------------------------------------------------
local ExportTable = function(self, tbInfo) 
    EditorExportHelper:SetExportBaseInfo(tbInfo.szTableName, tbInfo.tbTable)    

    local ExportType = EditorExportHelper.ExportType
    EditorExportHelper:AddExportIgnoreInfo("IniExporter", ExportType.Require)
    EditorExportHelper:AddExportIgnoreInfo("szFileName", ExportType.Variable)

    EditorExportHelper:SetExportAllVariables()
    EditorExportHelper:AddExportForceInfo("OnGameRequired", ExportType.Function)

    return EditorExportHelper:ExportCommit()
end

local ExportSingle = function(self, tbInfo)
    if(not Load(self, tbInfo)) then
        error("Load table failed: "..tbInfo.szTableName)
        return false
    end
    if(not ExportTable(self, tbInfo)) then
        error("Export table failed: "..tbInfo.szTableName)
        return false
    end
    return true
end

function IniExporter:Export(nMode)    
    EditorExportHelper:Register(self, EditorTargetType.Common, "IniExportRegisterCommon")
    EditorExportHelper:Register(self, EditorTargetType.Client, "IniExportRegisterClient")

    EditorExportHelper:SetCurrentExportDir("IniConfigs/")
    EditorExportHelper:MarkLuaFileIgnored("IniExporter")
    EditorExportHelper:MarkLuaFileIgnored("IniExportRegisterCommon")
    EditorExportHelper:MarkLuaFileIgnored("IniExportRegisterClient")
    
    for _, tbInfo in ipairs(tbAllExportInfo) do
        ExportSingle(self, tbInfo)
    end

    EditorExportHelper:CopyOtherLuaFileToExportDir()
    return true
end

return IniExporter
