local OtherExporter = {}

local EditorExportHelper = require("EditorExportHelper")
local EditorTargetType = require("EditorTargetType")
local BaseUtil = require("BaseUtil")
local EXPORT_ROOT_PATH = "GameDataGenerated/"

local tbAll = nil

function OtherExporter:Register(szName)
    local tbLua = require(szName)
    if(tbLua.Export == nil) then
        error(szName.." must has function Export")
    end
    table.insert( tbAll, { Name = szName, Exporter = tbLua } )
end

local function SaveTable(szTargetDir, szFileName, tbTable, szCustomData)
    local szFullPath = EXPORT_ROOT_PATH..szTargetDir..szFileName..".lua"
    local szTableData = BaseUtil:ConvertTableToRawString(tbTable)
    local szExportedData
    if(szCustomData == nil) then
        szExportedData = "return "..szTableData
    else
        local tbStrings = {}
        table.insert(tbStrings, string.format("local %s = %s\n\n", szFileName, szTableData))
        table.insert(tbStrings, szCustomData)
        table.insert(tbStrings, "\n\nreturn "..szFileName)
        szExportedData = table.concat(tbStrings)
    end

    EditorExportHelper:DeleteOldExportedFile(szFileName)

    if(not EditorExtendFunctions.SaveStringToFile(getcontentdir()..szFullPath, szExportedData)) then
        error("Write file failed: ".. szFullPath)
        return false
    end
    return true
end

local function ExportTargets(self, nMode, nTargetType, szRegister)
    local szTargetDir
    if(nTargetType == EditorTargetType.Common) then
        szTargetDir = "common/others/"
    elseif(nTargetType == EditorTargetType.Client) then
        szTargetDir = "client/others/"
    else
        szTargetDir = "server/others/"
    end
    EditorExtendFunctions.DeleteDirectory(getcontentdir()..EXPORT_ROOT_PATH..szTargetDir)

    tbAll = {}
    if(not EditorExportHelper:Register(self, nTargetType, szRegister)) then
        return false
    end

    local szFileName, tbOut, szCustomData
    for i, e in ipairs(tbAll) do
        local v = e.Exporter
        local k = e.Name
        szFileName, tbOut, szCustomData = v:Export(nMode)
        if(v.bNeedSaveTable == nil or v.bNeedSaveTable == true) then
            if(szFileName == nil or tbOut == nil) then
                error(k.." Export failed, return value szFileName or tbOut is nil")
            end
            if(SaveTable(szTargetDir, szFileName, tbOut, szCustomData)) then
                log("Exported "..szTargetDir..k)
            end
        else
            log("Exported "..szTargetDir..k)
        end
    end
    return true
end

function OtherExporter:Export(nMode)
    ExportTargets(self, nMode, EditorTargetType.Common, "OtherExporterRegisterCommon")
    ExportTargets(self, nMode, EditorTargetType.Client, "OtherExporterRegisterClient")
end

return OtherExporter