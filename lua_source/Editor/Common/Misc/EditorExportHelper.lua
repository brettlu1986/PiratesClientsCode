local EditorExportHelper = {}

local EditorTargetType = require("EditorTargetType")
local LuaFileExporter = require("LuaFileExporter")

-- 照抄一遍Type，为了外面访问方便，反正这东西也没什么人改
EditorExportHelper.ExportType = {
    Function = LuaFileExporter.ExportType.Function,
    Require = LuaFileExporter.ExportType.Require,
    Variable = LuaFileExporter.ExportType.Variable,
}

-- 各种配置目录
EditorExportHelper.szSourceRootFullDir = nil
EditorExportHelper.szExportedRootFullDir = nil      -- GameDataGenerated
EditorExportHelper.szInfoFileFullPath = nil
EditorExportHelper.tbCheckFullDir = nil
EditorExportHelper.nTargetType = nil

-- 文件的改动信息
EditorExportHelper.tbChangedLuaFiles = nil
EditorExportHelper.tbChangedAllFiles = nil

EditorExportHelper.tbLuaFilesWithoutCopy = nil
EditorExportHelper.tbSourceLuaFiles = nil
EditorExportHelper.tbOldExportedLuaFiles = nil
EditorExportHelper.szCurrentExportDir = nil         -- 各种Exporter的导出路径比如xxx/DataTables

-- 初始化
function EditorExportHelper:Init(szSourceRootFullDir, szExportedRootFullDir, szInfoFileFullPath, tbCheckFullDir)
    self.szSourceRootFullDir = szSourceRootFullDir
    self.szExportedRootFullDir = szExportedRootFullDir
    self.szInfoFileFullPath = szInfoFileFullPath
    self.tbCheckFullDir = tbCheckFullDir

    self.tbChangedLuaFiles = {}
    self.tbChangedAllFiles = {}
    self.tbOldExportedLuaFiles = nil

    self:Reset()
end

function EditorExportHelper:Reset()
    self.tbSourceLuaFiles = {}
    self.tbLuaFilesWithoutCopy = {}
    self.szCurrentExportDir = nil
end

-------------------------------------------------------------------------------
-- 注册用的各种函数
function EditorExportHelper:GetTargetType()
    if(self.nTargetType == nil) then
        local nTargetType = EditorTargetType:From(require("EditorLaunchParams"):GetParam("TargetType"))
        if(nTargetType == nil) then
            nTargetType = EditorTargetType.All
        end
        self.nTargetType = nTargetType
    end
    return self.nTargetType
end

function EditorExportHelper:RegisterWithParams(Exporter, nTargetType, Register, szPath)
    if((self:GetTargetType() & nTargetType) ~= nTargetType) then
        return false
    end

    if(Register.Register == nil) then
        error("Exporter must has function Register")
        return false
    end

    Register:Register(Exporter)

    if(szPath ~= nil) then
        local szLuaFileName
        local tbPaths = EditorExtendFunctions.CollectPaths(getcontentdir()..szPath, ".lua", true)
        for _, szTempPath in ipairs(tbPaths) do
            szLuaFileName = self:GetFileNameByFullPath(szTempPath, ".lua")
            assert(self.tbSourceLuaFiles[szLuaFileName] == nil)
            self.tbSourceLuaFiles[szLuaFileName] = szTempPath
        end
    end
    return true
end

function EditorExportHelper:Register(Exporter, nTargetType, szRegister)
    local TempRegister = require(szRegister)
    return self:RegisterWithParams(Exporter, nTargetType, TempRegister, TempRegister.szPath)
end

-------------------------------------------------------------------------------
-- 操作目录或者文件的各种函数
function EditorExportHelper:DeleteExportedDir()
    EditorExtendFunctions.DeleteDirectory(self.szExportedRootFullDir)
    self.tbOldExportedLuaFiles = nil
end

function EditorExportHelper:CollectFileModifiedInfo()
    if(not file_exists(self:GetRelativePathWithoutContent(self.szInfoFileFullPath))) then
        return false
    end

    local bRet, tbFileModifiedInfo = EditorExtendFunctions.CheckFileModified(self.tbCheckFullDir,
        self.szInfoFileFullPath)
    if(bRet == false) then
        error("EditorExportHelper check file failed.")
        return false
    end

    local szFileName
    for _, Info in ipairs(tbFileModifiedInfo) do
        szFileName = self:GetFileNameByFullPath(Info.Path, ".lua")
        if(szFileName ~= nil) then
            self.tbChangedLuaFiles[szFileName] = Info.Path
        end
        self.tbChangedAllFiles[Info.Path] = true
    end

    local tbFind, szLuaFileName
    self.tbOldExportedLuaFiles = {}
    local tbPaths = EditorExtendFunctions.CollectPaths(self.szExportedRootFullDir, ".lua", true)
    for _, szTempPath in ipairs(tbPaths) do
        szLuaFileName = self:GetFileNameByFullPath(szTempPath, ".lua")
        tbFind = self.tbOldExportedLuaFiles[szLuaFileName]
        if(tbFind == nil) then
            self.tbOldExportedLuaFiles[szLuaFileName] = szTempPath
        else
            if(type(tbFind) ~= 'table') then
                local tbNew = {}
                table.insert(tbNew, tbFind)
                tbFind = tbNew
                self.tbOldExportedLuaFiles[szLuaFileName] = tbFind
            end
            table.insert(tbFind, szTempPath)
        end
    end
    return true
end

function EditorExportHelper:SaveFileModifiedInfo()
    return EditorExtendFunctions.SaveFileModifiedInfo(self.tbCheckFullDir, self.szInfoFileFullPath)
end

function EditorExportHelper:MarkLuaFileExported(szLuaFileName)
    self.tbLuaFilesWithoutCopy[szLuaFileName] = true
end

function EditorExportHelper:MarkLuaFileIgnored(szLuaFileName)
    self.tbLuaFilesWithoutCopy[szLuaFileName] = true
end

function EditorExportHelper:CopyOtherLuaFileToExportDir()
    local tbWithoutCopy = self.tbLuaFilesWithoutCopy
    local szNewPath
    for k, v in pairs(self.tbSourceLuaFiles) do
        if(not tbWithoutCopy[k]) then
            szNewPath = self:GetLuaExportFullPath(k)
            self:DeleteOldExportedFile(k)
            EditorExtendFunctions.CopyFile(szNewPath, v)
            log('Copy', self:GetRelativePathWithContent(szNewPath))
        end
    end
end

function EditorExportHelper:DeleteOldExportedFile(szLuaFileName)
    local tbLuaPaths = self.tbOldExportedLuaFiles
    if(tbLuaPaths == nil) then
        return
    end

    local Find = tbLuaPaths[szLuaFileName]
    if(Find) then
        if(type(Find) == 'table') then
            for _, v in ipairs(Find) do
                EditorExtendFunctions.DeleteFile(v)
            end
        else
            EditorExtendFunctions.DeleteFile(Find)
        end

        tbLuaPaths[szLuaFileName] = nil
    end
end

-------------------------------------------------------------------------------
-- 各种路径帮助函数
function EditorExportHelper:SetCurrentExportDir(szDir)
    self.szCurrentExportDir = szDir
end

function EditorExportHelper:GetFileNameByFullPath(szFullPath, szExtention)
    if(szExtention == nil) then
        return string.match(szFullPath, ".*[%/\\](.*)%.%w*")
    else
        return string.match(szFullPath, ".*[%/\\](.*)%"..szExtention)
    end
end

function EditorExportHelper:GetPathDir(szFullPath)
    return string.match(szFullPath, "(.*)[/\\].*%.%w+").."/"
end

function EditorExportHelper:GetRelativePathWithContent(szFullPath)
    return string.match(szFullPath, ".*[/\\](Content[/\\].*)")
end

function EditorExportHelper:GetRelativePathWithoutContent(szFullPath)
    return string.match(szFullPath, ".*[/\\]Content[/\\](.*)")
end

function EditorExportHelper:GetRelativePathWithoutGameData(szFullPath)
    return string.match(szFullPath, ".*[/\\]GameData[/\\](.*)")
end

function EditorExportHelper:GetExportDir(szFullPath)
    local szExportPath
    if(string.match(szFullPath, ".*[Cc]ommon[/\\].*") ~= nil) then
        szExportPath = 'common/'
    elseif(string.match(szFullPath, ".*[Cc]lient[/\\].*") ~= nil) then
        szExportPath = 'client/'
    else
        szExportPath = 'server/'
    end
    return self.szExportedRootFullDir..szExportPath..string.lower(self.szCurrentExportDir)
end

function EditorExportHelper:GetLuaExportFullPath(szLuaFileName, szExportDir)
    local szPath
    if(szExportDir ~= nil) then
        szPath = szExportDir
    else
        szPath = self:GetLuaSourceFullPath(szLuaFileName)
        if(szPath == nil) then
            error("GetLuaSourceFullPath failed: szLuaFileName: "..szLuaFileName)
        end
        szPath = self:GetExportDir(szPath)
    end

    return szPath..szLuaFileName..".lua"
end

function EditorExportHelper:GetLuaSourceFullPath(szLuaFileName)
    return self.tbSourceLuaFiles[szLuaFileName]
end

-------------------------------------------------------------------------------
-- 终于开始导出啦~~
local szTempTableName
local tbTempSourceTable
local tbTempTableToDefaultValue
local tbTempIgnoreInfo
local tbTempForceExportInfo
local bTempEnableOptimizeString
local szTempCustomData
local szTempSpecialExportFileDir
local szTempForceCheckChangedFile

function EditorExportHelper:SetExportBaseInfo(szTableName, tbSourceTable)
    szTempTableName = szTableName
    tbTempSourceTable = tbSourceTable
    tbTempTableToDefaultValue = {}
    tbTempIgnoreInfo = {}
    tbTempForceExportInfo = {}
    bTempEnableOptimizeString = false
    szTempCustomData = nil
    szTempSpecialExportFileDir = nil
    szTempForceCheckChangedFile = nil
end

function EditorExportHelper:AddExportIgnoreInfo(szKey, nType)
    assert(type(szKey) == 'string')
    tbTempIgnoreInfo[szKey] = nType
end

function EditorExportHelper:AddExportForceInfo(szKey, nType)
    assert(type(szKey) == 'string')
    tbTempForceExportInfo[szKey] = nType
end

local function SetExportAll(nType)
    local szKey = LuaFileExporter.KEY_ALL
    local nValue = tbTempForceExportInfo[szKey]
    if(nValue == nil) then
        tbTempForceExportInfo[szKey] = nType
    else
        tbTempForceExportInfo[szKey] = nValue | nType
    end
end

function EditorExportHelper:SetExportAllFunctions()
    SetExportAll(self.ExportType.Function)
end

function EditorExportHelper:SetExportAllVariables()
    SetExportAll(self.ExportType.Variable)
end

function EditorExportHelper:SetExportDefautValues(tbTableToDefaultValue)
    tbTempTableToDefaultValue = tbTableToDefaultValue
end

function EditorExportHelper:SetExportEnableOptimizeString(bEnable)
    bTempEnableOptimizeString = bEnable
end

function EditorExportHelper:SetExportCustomData(szCustomData)
    szTempCustomData = szCustomData
end

function EditorExportHelper:SetSpecialExportFileDir(szDir)
    szTempSpecialExportFileDir = szDir
end

function EditorExportHelper:SetForceCheckChangedFile(szFilePath)
    szTempForceCheckChangedFile = szFilePath
end

function EditorExportHelper:ExportCommit()
    local szSourceLuaFullPath = self:GetLuaSourceFullPath(szTempTableName)
    local szExportFullPath = self:GetLuaExportFullPath(szTempTableName, szTempSpecialExportFileDir)

    local bForceExport = self.tbOldExportedLuaFiles == nil
    if(not bForceExport) then
        local OldExportedInfo = self.tbOldExportedLuaFiles[szTempTableName]
        if(OldExportedInfo ~= nil and type(OldExportedInfo) == 'table') then
            -- 已经导出的文件有重名的，强制导出
            bForceExport = true
        elseif(self.tbChangedLuaFiles[szTempTableName]) then
            -- 原始lua文件变了
            bForceExport = true
        elseif(szTempForceCheckChangedFile ~= nil) then
            -- 判断特定文件是否修改
            bForceExport = self.tbChangedAllFiles[szTempForceCheckChangedFile] ~= nil
        end
    end

    if(bForceExport) then
        self:DeleteOldExportedFile(szTempTableName)
    end

    self:MarkLuaFileExported(szTempTableName)

    return LuaFileExporter.Export(szTempTableName,
        tbTempSourceTable,
        szSourceLuaFullPath,
        szExportFullPath,
        tbTempTableToDefaultValue,
        tbTempIgnoreInfo,
        tbTempForceExportInfo,
        not bForceExport,
        bTempEnableOptimizeString,
        szTempCustomData)
end

return EditorExportHelper