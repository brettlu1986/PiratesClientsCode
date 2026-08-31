local CopyFileExporter = {}

local EditorExportHelper = require("EditorExportHelper")
local EditorTargetType = require("EditorTargetType")

local szContentDir = getcontentdir()
local SOURCE_ROOT_DIR = szContentDir.."GameData/"
local EXPORTED_ROOT_DIR = szContentDir.."GameDataGenerated/"
local tbFiles = {}
local tbFolders = {}

function CopyFileExporter:RegisterFile(szPath)
    table.insert(tbFiles, szPath)
end

function CopyFileExporter:RegisterFolder(szPath)
    table.insert(tbFolders, szPath)
end

function CopyFileExporter:Export(nMode)
    tbFiles = {}
    tbFolders = {}
        
    EditorExportHelper:Register(self, EditorTargetType.Common, "CopyFileRegisterCommon")
    EditorExportHelper:Register(self, EditorTargetType.Client, "CopyFileRegisterClient")
    EditorExportHelper:Register(self, EditorTargetType.BattleServer, "CopyFileRegisterServer")

    local bRet
    for _, v in ipairs(tbFiles) do
        bRet = EditorExtendFunctions.CopyFile(EXPORTED_ROOT_DIR..v, SOURCE_ROOT_DIR..v)
        if(bRet) then
            log("Copy file", v)
        else
            error("Copy file failed, path: "..v)
        end
    end
    for _, v in ipairs(tbFolders) do
        bRet = EditorExtendFunctions.CopyDirectory(EXPORTED_ROOT_DIR..v, SOURCE_ROOT_DIR..v, true)
        if(bRet) then
            log("Copy folder", v)
        else
            error("Copy folder failed, path: "..v)
        end
    end    
end

return CopyFileExporter