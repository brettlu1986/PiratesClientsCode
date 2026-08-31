local JsonConfigSystem = {}

-- private definition
--local BaseUtil          = require("BaseUtil")
local JsonUtil          = require("dkjson")

-- local szRootPath = getcontentdir()..'GameData/'
local szRootPath = 'GameData/'


--JsonConfigSystem.tbTableContainer = nil


-- local function ProtectTable( tbContainer, bProtect )
--     if bProtect ~= false then
--         return BaseUtil:ReadOnly(tbContainer)
--     end
--     return tbContainer
-- end

local function MergeJson(tbContainer, tbNew)
    local tbTemp, nCount
    for szKey, tbValue in pairs(tbNew) do
        tbTemp = tbContainer[szKey]
        if(tbTemp == nil) then
            tbContainer[szKey] = tbValue
        else
            nCount = #tbValue
            for i=1, nCount do
                table.insert(tbTemp, tbValue[i])
            end
        end
    end
    return true
end

local function LoadSingleJsonFile(tbContainer, szJsonFilePath, ignoreError)
    if not szJsonFilePath then
        error('szFileName is nil')
        return false
    end

    local tbJsonData
    local nLen = string.len(szJsonFilePath)
    local szPostfix = string.sub(szJsonFilePath, nLen-3, nLen)
    if(szPostfix == '.lua') then
        -- lua 直接require
        local bSuccess
        bSuccess, tbJsonData = requirewithfullpath(szJsonFilePath)
        if(not bSuccess) then
            error("JsonConfigSystem:LoadSingleJsonFile failed, lua file is invalid: "..szJsonFilePath)
            return false
        end
    elseif(szPostfix == 'json') then
        local bSuccess, szFileContent = getfilestring(szJsonFilePath)
        if not bSuccess or szFileContent == nil then
            if not ignoreError then
                error("JsonConfigSystem:LoadSingleJsonFile failed, szFileContent is nil "..szJsonFilePath)
            end 
            return false
        end

        tbJsonData = JsonUtil.decode(szFileContent)
    else
        -- ignore other files
        return true
    end

    if(tbJsonData == nil) then
        error("JsonConfigSystem:LoadSingleJsonFile decode failed " .. szJsonFilePath)
        return false
    end

    --log("LoadSingleJsonFile", szJsonFilePath)
    return MergeJson(tbContainer, tbJsonData)
end

local function LoadFolder(tbContainer, szFolderName, bRecursiveSearchFolder, ignoreError, szRecursiveSearchFileName)
    local szFind = szRecursiveSearchFileName ~= nil and szRecursiveSearchFileName or '*.*'
    local tbFilePaths = getdirfilepaths(szRootPath..szFolderName, bRecursiveSearchFolder, szFind)
    if(tbFilePaths == nil) then
        if not ignoreError then 
            error("JsonConfigSystem:LoadFolder failed "..szFolderName)
        end 
        return false
    end

    -- luacheck: push ignore 231
    local szPath, nStart, nEnd
    local nFileCount = #tbFilePaths
    for i=1, nFileCount do
        szPath = tbFilePaths[i]
        nStart, nEnd = string.find(szPath, szRootPath)
        szPath = string.sub(szPath, nStart)        
        if(not LoadSingleJsonFile(tbContainer, szPath, ignoreError)) then
            if not ignoreError then 
                error('JsonConfigSystem:LoadFolder failed, file data is invalid ' .. tbFilePaths[i])
            end 
            return false
        end
    end
    -- luacheck: pop
    return true
end

local function LoadImp(tbJsonTable, ignoreError)
    if not tbJsonTable then
        error('JsonConfigSystem:Load failed, read a nil table')
        return false
    end

    local szFolderName = tbJsonTable.szFolderName
    if szFolderName == nil then
        error('JsonConfigSystem:Load failed, folder name is nil')
        return false
    end

    local tbContainer = {}
    tbJsonTable.tbContainer = tbContainer
    local tbFileNames = tbJsonTable.tbFileNames
    local szSingleFileName = tbJsonTable.szFileName
    local szRecursiveSearchFileName = tbJsonTable.szRecursiveSearchFileName
    if(szSingleFileName ~= nil) then
        if(not LoadSingleJsonFile(tbContainer, szRootPath..szFolderName..'/'..szSingleFileName, ignoreError)) then
            if not ignoreError then 
                error('JsonConfigSystem:Load failed, file data is invalid ' .. szFolderName..szSingleFileName)
            end 
            return false
        end
    elseif(tbFileNames ~= nil) then
        -- 加载每个文件
        local nCount = #tbFileNames
        for i=1, nCount do
            if(not LoadSingleJsonFile(tbContainer, szRootPath..szFolderName..'/'..tbFileNames[i], ignoreError)) then
                if not ignoreError then 
                    error('JsonConfigSystem:Load failed, file data is invalid ' .. szFolderName..tbFileNames[i])
                end 
                return false
            end
        end
    else
        -- 加载整个文件夹
        local bRecursiveSearchFolder = false
        if(tbJsonTable.bRecursiveSearchFolder == true) then
            bRecursiveSearchFolder = true
        end
        if(not LoadFolder(tbContainer, szFolderName, bRecursiveSearchFolder, ignoreError, szRecursiveSearchFileName)) then
            if not ignoreError then 
                error('JsonConfigSystem:Load failed, folder data invalid ' .. szFolderName)
            end 
            return false
        end
    end

    --BaseUtil:ReadOnly(tbContainer)

   if(tbJsonTable.OnLoaded ~= nil) then
        tbJsonTable:OnLoaded()
    end
    return true
end

function JsonConfigSystem:Load(tbJsonTable, bIgnoreError)
    return LoadImp(tbJsonTable, bIgnoreError)
end

function JsonConfigSystem:Unload(tbJsonFile)
    tbJsonFile.tbContainer = nil
end

-- local function LoadAtLauncher(self)
--     -- 对于启动就加载的，直接加
--     local tbList = self.tbTableContainer.tbPersistList
--     for _, tbPersistTable in pairs(tbList) do
--         if (not Load(tbPersistTable)) then        
--             error('load file failed : '.. tbPersistTable.szFileName)
--         end
--     end
-- end

-- function JsonConfigSystem:RegisterAtLaunch(tbJsonFile)
--     if tbJsonFile ~= nil then
--         table.insert(self.tbTableContainer.tbPersistList, tbJsonFile)
--     else
--         logerror('JsonConfigSystem: nil')
--     end
-- end

-- function JsonConfigSystem:RegisterManual(tbJsonFile)
--     if tbJsonFile ~= nil then
--         table.insert(self.tbTableContainer.tbManualList, tbJsonFile)
--         tbJsonFile.Load = Load  -- 外部调用tbJsonFile:Load，自然会把self传给Load(tbJsonTable)
--         tbJsonFile.Unload = Unload  -- 同上
--     else
--         logerror('JsonConfigSystem: nil')
--     end
-- end

-- local function LoadAll(self)
--     -- 对于启动就加载的，直接加
--     for _, tbPersistTable in pairs(self.tbTableContainer.tbPersist) do
--         if (not self:Load(tbPersistTable)) then
--             log('load file failed : ', tbPersistTable.szFileName)
--         end
--     end

--     -- 对于跟场景加卸载相关的，需要监听事件
--     for _, tbSceneTable in pairs(self.tbTableContainer.tbSceneJsonConfig) do
--         if (self:Load(tbSceneTable)) then

--         else

--         end
--     end

--     return true
-- end

-- local function UnloadAll(self)
--     local tbTableContainer = self.tbTableContainer
--     for _, tbTable in pairs(tbTableContainer) do
--         Unload(tbTable)        
--     end
-- end

function JsonConfigSystem:Init()
    -- self.tbTableContainer = {
    --     -- table list
    --     tbPersistList = {},
    --     tbManualList = {},
    --     tbSceneJsonConfig = {}
    -- }
    -- local Register = dynamic_require("JsonConfigRegister")
    -- Register:RegisterConfigs(self)
    --LoadAtLauncher(self)
--    self:LoadAll()
    return true
end

function JsonConfigSystem:Uninit()
    --UnloadAll(self)
    --self.tbTableContainer = nil
end

return JsonConfigSystem
