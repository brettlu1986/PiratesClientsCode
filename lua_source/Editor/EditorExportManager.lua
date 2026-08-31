local EditorExportManager = {}

local EditorLaunchParams = require("EditorLaunchParams")
local EditorExportModeDefine = require("EditorExportModeDefine")
local EditorExportHelper = require("EditorExportHelper")

local tbExporters = nil
local szContentDir = getcontentdir()
local SOURCE_ROOT_DIR = szContentDir.."GameData/"
local EXPORTED_ROOT_DIR = szContentDir.."GameDataGenerated/"
local CHECK_FILE_PATH = EXPORTED_ROOT_DIR.."temp/check_file_info.txt"
local tbCheckDir = {
    szContentDir.."GameData",
    szContentDir.."Scripts"
}

local function ExportImp(self)
    local nMode
    local szValue = EditorLaunchParams:GetParam("ExportMode")
    if(szValue == "Full") then
        nMode = EditorExportModeDefine.Full        
    else
        if(false == EditorExportHelper:CollectFileModifiedInfo()) then
            nMode = EditorExportModeDefine.Full            
        else
            if(szValue == "Check") then
                nMode = EditorExportModeDefine.Check
            else
                nMode = EditorExportModeDefine.Iterate
            end
        end
    end

    if(nMode == EditorExportModeDefine.Full) then
        EditorExportHelper:DeleteExportedDir()
    end

    log("Export mode:", nMode)

    for _, tbExporter in ipairs(tbExporters) do
        EditorExportHelper:Reset()
        tbExporter:Export(nMode)
    end

    -- 重新更新    
    if(GPlayInEditor) then
        EditorExportHelper:SaveFileModifiedInfo()
    end
end

function EditorExportManager:Register(szFile)
    local tbFile = require(szFile)
    if(tbFile.Export == nil) then
        error(string.format("File '%s' must has function 'Export'", szFile))
    end
    table.insert(tbExporters, tbFile)
end

function EditorExportManager:Export()
    tbExporters = {}
    EditorExportHelper:Init(SOURCE_ROOT_DIR, EXPORTED_ROOT_DIR, CHECK_FILE_PATH, tbCheckDir)

    local Register = require("EditorExportRegister")
    Register:Register(self)

    ExportImp(self)
end

return EditorExportManager