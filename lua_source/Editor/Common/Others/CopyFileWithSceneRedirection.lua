local CopyFileWithSceneRedirection = {}

CopyFileWithSceneRedirection.bNeedSaveTable = false

local szContentDir = getcontentdir()
local SOURCE_ROOT_DIR = szContentDir.."GameData/"
local EXPORTED_ROOT_DIR = szContentDir.."GameDataGenerated/"

local function CopyFolder(szFolder, bDeleteSource)
    local szTargetFolder = EXPORTED_ROOT_DIR..szFolder
    EditorExtendFunctions.CopyDirectory(szTargetFolder, SOURCE_ROOT_DIR..szFolder, true)

    local SceneResDataTable = require("SceneResDataTable")
    local tbContainer = SceneResDataTable.tbContainer
    local tbSubFolders = EditorExtendFunctions.CollectDirs(szTargetFolder)
    for _, szSceneName in ipairs(tbSubFolders) do
        szSceneName = string.match(szSceneName, ".*[/\\](%S+)")
        for k, tbSceneResData in pairs(tbContainer) do
            if(tbSceneResData.szLogicRedirect and szSceneName == tbSceneResData.szLogicRedirect) then
                local szSource = szTargetFolder..'/'..tbSceneResData.szLogicRedirect
                EditorExtendFunctions.CopyDirectory(szTargetFolder..'/'..tbSceneResData.szMapName, szSource, true)
                if(bDeleteSource) then
                    EditorExtendFunctions.DeleteDirectory(szSource)
                end
                break
            end
        end
    end
end

function CopyFileWithSceneRedirection:Export()
    CopyFolder("common/navigation")
    CopyFolder("common/gridtype")
end

return CopyFileWithSceneRedirection