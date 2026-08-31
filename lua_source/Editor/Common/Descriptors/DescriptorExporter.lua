local DescriptorExporter = {}

local LevelJsonTableHelper = require("LevelJsonTableHelper")
local BaseUtil = require("BaseUtil")
local JsonConfigSystem = require("JsonConfigSystem")
local EditorExportHelper = require("EditorExportHelper")
local EditorTargetType = require("EditorTargetType")

local tbAllExporter = nil

function DescriptorExporter:Register(szName)
    local tbLua = require(szName)
    table.insert(tbAllExporter, tbLua)
end

local function GetExportedPath(bWild, szDescriptorPath)
    local szExportPath
    if(bWild) then
        szExportPath = "client/"
    else
        szExportPath = "common/"
    end
    local szLuaName = string.match(szDescriptorPath, ".*[/\\](%S+)")
    return szExportPath.."descriptors/"..szLuaName..".lua", szLuaName
end

local function GetExportedFullPath(szPath)
    return getcontentdir() .. "GameDataGenerated/"..szPath
end

local function IsValidString(szString)
    return szString ~= nil and szString ~= ""
end

local IsSameTable
IsSameTable = function(Source, Target)
    if(Target == nil) then
        return false
    end

    local szSourceType = type(Source)
    local szExportType = type(Target)
    if(szSourceType ~= szExportType) then
        return false
    end

    if(szSourceType ~= 'table') then
        return Source == Target
    end

    local tbKeys = {}
    for k, _ in pairs(Target) do
        tbKeys[k] = true
    end

    for k, v in pairs(Source) do
        tbKeys[k] = nil
        if(false == IsSameTable(v, Target[k])) then
            return false
        end
    end
    return next(tbKeys) == nil
end

local function ExportData(tbData, szDescriptorPath, tbAllDescriptors, bWild, szExportedKeyName, szSaveFilePath)
    if(not IsValidString(szDescriptorPath)) then
        return false
    end

    local SourceDescriptor = tbAllDescriptors[szDescriptorPath]
    if(SourceDescriptor) then
        -- 导出过了
        local _, szLuaName = GetExportedPath(bWild, szSaveFilePath or szDescriptorPath)
        tbData[szExportedKeyName] = szLuaName
        return true
    end

    SourceDescriptor = LevelJsonTableHelper:LoadJsonByFilePathRecursively(szDescriptorPath, nil)

    if(SourceDescriptor == nil) then
        error("LoadJsonByFilePathRecursively failed, path: "..szDescriptorPath)
        return false
    end
    tbAllDescriptors[szDescriptorPath] = SourceDescriptor

    local tbOutExportedDescriptor = {}
    local szFunction = bWild and "ExportWildSceneData" or "ExportDungeonSceneData"
    for _, Exporter in ipairs(tbAllExporter) do
        if(Exporter[szFunction]) then
            Exporter[szFunction](Exporter, tbData, SourceDescriptor.tbContainer, tbOutExportedDescriptor)
        end
    end

    -- 检查是否是空table
    if(next(tbOutExportedDescriptor) == nil) then
        return true
    end

    -- 检查是否是一样的表
    local szFullPath, szLuaName = GetExportedPath(bWild, szSaveFilePath or szDescriptorPath)
    tbData[szExportedKeyName] = szLuaName
    local szFullPathWithGameDataGenerated = "GameDataGenerated/"..szFullPath
    if(file_exists(szFullPathWithGameDataGenerated)) then
        local bSuccess, tbExportTable = requirewithfullpath(szFullPathWithGameDataGenerated)
        if(bSuccess and tbExportTable ~= nil) then
            if(IsSameTable(tbExportTable, tbOutExportedDescriptor)) then
                return true
            end
        end
    end

    -- 开始导table
    local szExportedData = "return "..BaseUtil:ConvertTableToRawString(tbOutExportedDescriptor)
    if(not EditorExtendFunctions.SaveStringToFile(GetExportedFullPath(szFullPath), szExportedData)) then
        error("Write scene descriptor failed: ".. szFullPath)
        return false
    end

    log("Exported descriptor", szFullPath)
    return true
end

function DescriptorExporter:ExportWildSceneData(tbContainer, szExportedKeyName)
    local tbAllDescriptors = {}
    for _, tbSceneData in pairs(tbContainer) do
        if(IsValidString(tbSceneData.szDescriptorPath)) then
            ExportData(tbSceneData, tbSceneData.szDescriptorPath, tbAllDescriptors, true, szExportedKeyName)
        end
    end
end

function DescriptorExporter:ExportSingleDungeonSceneData(tbDungeonData, tbAllDescriptors, szExportedKeyName)
    local szDescriptorPath, szSaveFilePath = LevelJsonTableHelper:GetDungeonDescriptorFolderPath(tbDungeonData.nResID, tbDungeonData.szLogicLevelName)
    ExportData(tbDungeonData, szDescriptorPath, tbAllDescriptors, false, szExportedKeyName, szSaveFilePath)
end

function DescriptorExporter:ExportDungeonSceneData(tbContainer, szExportedKeyName)
    local tbAllDescriptors = {}
    -- local szDescriptorPath
    for _, tbDungeonData in pairs(tbContainer) do
        --if(IsValidString(tbDungeonData.szLogicLevelName)) then
            -- szDescriptorPath = LevelJsonTableHelper:GetDungeonDescriptorFolderPath(tbDungeonData.nResID, tbDungeonData.szLogicLevelName)
            -- ExportData(tbDungeonData, szDescriptorPath, tbAllDescriptors, false, szExportedKeyName)
        --end

        -- 多 Mode 模式在 DungeonDataTable 中 Export
        if #tbDungeonData.tbModes == 0 then
            self:ExportSingleDungeonSceneData(tbDungeonData, tbAllDescriptors, szExportedKeyName)
        end
    end
end

function DescriptorExporter:ExportSingleSceneData(tbAllDescriptors, tbSceneData, nSceneResId, szLogicLevelName, szExportedKeyName)
    local szDescriptorPath, szSaveFilePath = LevelJsonTableHelper:GetDungeonDescriptorFolderPath(nSceneResId, szLogicLevelName)
    ExportData(tbSceneData, szDescriptorPath, tbAllDescriptors, true, szExportedKeyName, szSaveFilePath)
   
end

function DescriptorExporter:OnAllDataTablesExported()
    for _, Exporter in ipairs(tbAllExporter) do
        if(Exporter.OnAllDataTablesExported) then
            Exporter:OnAllDataTablesExported()
        end
    end
end

local function Init(self)
    JsonConfigSystem:Init()
    tbAllExporter = {}
    EditorExportHelper:Register(self, EditorTargetType.Common, "DescriptorRegisterCommon")
    EditorExportHelper:Register(self, EditorTargetType.Client, "DescriptorRegisterClient")
end
Init(DescriptorExporter)

return DescriptorExporter