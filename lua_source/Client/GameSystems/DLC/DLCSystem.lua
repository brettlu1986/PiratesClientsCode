-----------------------------------------------------
--File Name    : DLCSystem.lua
--Author       : ZhangWei
--Create Time  : 2020-10-21
--Description  : DLC (Downloadable Content) System, 游戏内可选资源分包下载
-----------------------------------------------------

local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")

local DLCSystem = {}

DLCSystem.pDLCUpdateProcedure = nil
DLCSystem.pDLCUpdateProcedureHolder = nil
DLCSystem.EventHelper = nil
DLCSystem.pOnDLCFinishedDelegate = nil
DLCSystem.pOnDLCFailedDelegate = nil
DLCSystem.pOnDLCProgressDelegate = nil


local function OnDLCFinished(self)
    log("DLC install finished successfully.")
    self.EventHelper:FireEvent(ClientEventDef.EV_DLC_FINISHED)
end

--[=[   ResultEnum: EHotUpdateDLCResult
        szErrorText: FText
        nErrorCode: int32
--]=]
local function OnDLCFailed(self, ResultEnum, szErrorText, nErrorCode)
    local nResult = enumtoint(ResultEnum)
    log("DLC install failed. nResult, ErrorText, nErrorCode: ", nResult, szErrorText, nErrorCode)
    self.EventHelper:FireEvent(ClientEventDef.EV_DLC_FAILED, nResult, szErrorText, nErrorCode)
end

--[=[   nCurrentInstallingChunkID: int32
        szCurrentSizeDesc: FString, "1.00KB", "0.66MB"
        szTotalSizeDesc: FString
        nProgress: float
--]=]
local function OnDLCProgress(self, nCurrentInstallingChunkID, szCurrentSizeDesc, szTotalSizeDesc, nProgress)
    log("DLC install in progress: nCurrentInstallingChunkID, szCurrentSizeDesc, szTotalSizeDesc, nProgress: ", nCurrentInstallingChunkID, szCurrentSizeDesc, szTotalSizeDesc, nProgress)
    self.EventHelper:FireEvent(ClientEventDef.EV_DLC_PROGRESS, nCurrentInstallingChunkID, szCurrentSizeDesc, szTotalSizeDesc, nProgress)
end

function DLCSystem:Init()
    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    self.pDLCUpdateProcedure = ExtendBlueprintFunctions.CreateObject(HotUpdateDLCProcedure, pGameInstance)
    self.pDLCUpdateProcedureHolder = luaholder(self.pDLCUpdateProcedure)

    self.EventHelper = SelfEventHelper()
    self.pOnDLCFinishedDelegate = self.EventHelper:RegisterCppDelegate(self.pDLCUpdateProcedure.OnDLCFinished, self, OnDLCFinished)
    self.pOnDLCFailedDelegate = self.EventHelper:RegisterCppDelegate(self.pDLCUpdateProcedure.OnDLCFailed, self, OnDLCFailed)
    self.pOnDLCProgressDelegate = self.EventHelper:RegisterCppDelegate(self.pDLCUpdateProcedure.OnDLCProgress, self, OnDLCProgress)

    log("DLCSystem init.")
    return true
end

function DLCSystem:Uninit()
    if self.EventHelper ~= nil then
    	self.EventHelper:UnregisterAll()
    end

    self.pOnDLCFinishedDelegate = nil
    self.pOnDLCFailedDelegate = nil
    self.pOnDLCProgressDelegate = nil

    self.pDLCUpdateProcedureHolder = nil
    self.pDLCUpdateProcedure = nil

    log("DLCSystem uninit.")
end

--[=[   
        ChunkID: int32
--]=]
function DLCSystem:InstallChunk(ChunkID)
    if not self.pDLCUpdateProcedure then
        logerror("[DLCSystem InstallChunk]: pDLCUpdateProcedure is nil. Not initialized??")
        return
    end
    self.pDLCUpdateProcedure:InstallChunk(ChunkID)
end

function DLCSystem:UninstallChunk(ChunkID)
    if not self.pDLCUpdateProcedure then
        logerror("[DLCSystem UninstallChunk]: pDLCUpdateProcedure is nil. Not initialized??")
        return
    end
    self.pDLCUpdateProcedure:UninstallChunk(ChunkID)
end

function DLCSystem:CancelInstallChunk(ChunkID)
    if not self.pDLCUpdateProcedure then
        logerror("[DLCSystem CancelInstallChunk]: pDLCUpdateProcedure is nil. Not initialized??")
        return
    end
    self.pDLCUpdateProcedure:CancelInstallChunk(ChunkID)
end

function DLCSystem:CancelAllInstall()
    if not self.pDLCUpdateProcedure then
        logerror("[DLCSystem CancelAllInstall]: pDLCUpdateProcedure is nil. Not initialized??")
        return
    end
    self.pDLCUpdateProcedure:CancelAllInstall()
end

function DLCSystem:IsChunkInstalled(ChunkID)
    return HotUpdateDLCFunctionLibrary.IsChunkInstalled(ChunkID)
end

return DLCSystem