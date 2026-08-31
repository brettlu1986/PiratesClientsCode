local LevelJsonTableHelper = {}

local SceneResDataTable = require("SceneResDataTable")
local JsonConfigSystem = require("JsonConfigSystem")

local szSceneJsonRootPath = "common/scene/descriptors/"

function LevelJsonTableHelper:GetDungeonDescriptorFolderPath(nSceneResId, szLogicLevelName)
    if(szLogicLevelName == nil) then
        error("LevelJsonTableHelper:GetDungeonDescriptorPath failed, invalid szLogicLevelName " .. nSceneResId ..", ".. szLogicLevelName)
        return nil
    end
    local tbSceneResData = SceneResDataTable:GetTemplate(nSceneResId)
    if(tbSceneResData == nil) then
        error("LevelJsonTableHelper:GetDungeonDescriptorPath failed, invalid scene res" .. nSceneResId ..", ".. szLogicLevelName)
        return nil
    end

    local szDescriptorName
    if(tbSceneResData.szLogicRedirect) then
        szDescriptorName = tbSceneResData.szLogicRedirect
    else
        szDescriptorName = tbSceneResData.szMapName
    end
    local szDescriptorPath = szSceneJsonRootPath .. szDescriptorName
    local szFilePath = szSceneJsonRootPath .. tbSceneResData.szMapName
    if(szLogicLevelName and string.len(szLogicLevelName) > 0) then
        return szDescriptorPath..'/'..szLogicLevelName, szFilePath..'/'..szLogicLevelName
    else
        return szDescriptorPath, szFilePath
    end
end

function LevelJsonTableHelper:LoadJsonByFolder(nSceneResId, szLogicLevelName)
    local tbRet = {}
    tbRet.szFolderName = self:GetDungeonDescriptorFolderPath(nSceneResId, szLogicLevelName)
    if(not JsonConfigSystem:Load(tbRet)) then
        return nil
    end
    return tbRet
end

function LevelJsonTableHelper:LoadJsonByFilePath(szFolderName, szFileName, ignoreError)
    local tbRet = {}
    tbRet.szFolderName = szFolderName
    tbRet.szFileName = szFileName

    if(not JsonConfigSystem:Load(tbRet, ignoreError)) then
        return nil
    end
    return tbRet
end

function LevelJsonTableHelper:LoadJsonByFilePathRecursively(szFolderName, szFileName, ignoreError)
    local tbRet = {}
    tbRet.szFolderName = szFolderName
    tbRet.szFileName = nil
    tbRet.szRecursiveSearchFileName = szFileName
    tbRet.bRecursiveSearchFolder = true

    if(not JsonConfigSystem:Load(tbRet, ignoreError)) then
        return nil
    end
    return tbRet
end

return LevelJsonTableHelper
