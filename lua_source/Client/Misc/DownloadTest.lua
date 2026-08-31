-----------------------------------------------------
--File Name    : DownloadTest
--Author       : Song Fuhao
--Create Time  : 2020-10-21
--Description  : DownloadTest
-----------------------------------------------------
local DownloadTest = {}

local CppDelegate = require("CppDelegate")

local nStartTime = getseconds()
local nTotalSize = 0
local OnDownloadStartDelegate = nil
local OnDownloadProgressDelegate = nil
local OnDownloadFailedDelegate = nil
local OnDownloadSuccessDelegate = nil
local pDownloadTask = nil

local function LOG(...)
    log("[DownloadTest]", ...)
end

local function UnbindDelegate()
    if OnDownloadStartDelegate then
        OnDownloadStartDelegate:Unbind()
    end
    if OnDownloadProgressDelegate then
        OnDownloadProgressDelegate:Unbind()
    end
    if OnDownloadFailedDelegate then
        OnDownloadFailedDelegate:Unbind()
    end
    if OnDownloadSuccessDelegate then
        OnDownloadSuccessDelegate:Unbind()
    end
end

local function OnFinalize()
    LOG("OnFinalize")
    UnbindDelegate()
    pDownloadTask = nil
end

local function OnStart(nInTotalSize)
    nTotalSize = nInTotalSize
    LOG("OnStart nTotalSize =", nTotalSize)
end

local function OnProgress(nDownloadedSize)
    local nSpeed = nDownloadedSize / (getseconds() - nStartTime) / 1024 / 1024
    LOG(string.format("OnProgress, nDownloadedSize = %dbyte, nSpeed = %fm/s.", nDownloadedSize, nSpeed))
end

local function OnFailed(...)
    LOG("OnFailed", ...)
    OnFinalize()
end

local function OnSuccess(...)
    local nSpeed = nTotalSize / (getseconds() - nStartTime) / 1024 / 1024
    LOG(string.format("OnSuccess, nTotalSize = %dbyte, nSpeed = %fm/s.", nTotalSize, nSpeed))
    OnFinalize()
end

function DownloadTest.Start(szUrl, nMaxRequestCount, szSavePath)
    DownloadTest.Cancel()

    szUrl = string.sub(szUrl, 2, -2)
    nMaxRequestCount = nMaxRequestCount or 1
    szSavePath = szSavePath or (BlueprintPathsLibrary.ProjectPersistentDownloadDir() .. "/" .. BlueprintPathsLibrary.GetCleanFilename(szUrl))

    LOG("Start download task.")
    LOG("-- szUrl :", szUrl)
    LOG("-- nMaxRequestCount :", nMaxRequestCount)
    LOG("-- szSavePath :", szSavePath)

    BlueprintFileUtilsBPLibrary.DeleteFile(szSavePath, false, false)
    BlueprintFileUtilsBPLibrary.DeleteDirectory(szSavePath .. ".temp", false, true)

    pDownloadTask = FileDownloaderBPLibrary.CreateDownloadTask(szUrl, szSavePath, "")
    OnDownloadStartDelegate = CppDelegate:Bind(pDownloadTask.OnStart, OnStart)
    OnDownloadProgressDelegate = CppDelegate:Bind(pDownloadTask.OnProgress, OnProgress)
    OnDownloadFailedDelegate = CppDelegate:Bind(pDownloadTask.OnFailed, OnFailed)
    OnDownloadSuccessDelegate = CppDelegate:Bind(pDownloadTask.OnSuccess, OnSuccess)
    pDownloadTask:SetMaxRequestCount(nMaxRequestCount)
    pDownloadTask:Start()
end

function DownloadTest.Cancel()
    if isvalidhandle(pDownloadTask) then
        LOG("Cancel last download task.")
        pDownloadTask:Cancel()
    end
end

return DownloadTest