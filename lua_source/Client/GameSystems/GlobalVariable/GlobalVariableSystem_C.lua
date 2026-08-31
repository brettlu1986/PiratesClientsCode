local luaclass = require("luaclass")
local GlobalVariableSystemClass = require("GlobalVariableSystem")
local GlobalVariableSystem_C = luaclass("GlobalVariableSystem_C", GlobalVariableSystemClass)

local TimeUtil = require("TimeUtil")
--local ShipVehicleControlModeDef = require("ShipVehicleControlModeDef")
local SaveGameDef = require("SaveGameDef")
local GMOpenModeDef = require("GMOpenModeDef")
local SelfEventHelper = require("SelfEventHelper")
local ClientEventDef = require("ClientEventDef")
local DungeonIni = require("DungeonIni")

--local JsonUtil = require("dkjson")

--local szURLJsonPath = "GameDataGenerated/client/url/"
-- local ClientEventDef = require("ClientEventDef")
-- local EventManager = require("EventManager")

-- local nSyncTimeInterval = 5*60  -- server时间同步间隔

GlobalVariableSystem_C.bFixedShipWeaponParamEnabled = false
GlobalVariableSystem_C.nFixedShipWeaponFiringInterval = -1
GlobalVariableSystem_C.nFixedShipWeaponLoadingInterval = -1

GlobalVariableSystem_C.nSelfLobbyPlayerId = nil
GlobalVariableSystem_C.tbServerList = nil
GlobalVariableSystem_C.tbCurrentServerData = nil
GlobalVariableSystem_C.szUserName = nil
GlobalVariableSystem_C.szUserPassword = nil
GlobalVariableSystem_C.nLoginMode = 0
GlobalVariableSystem_C.szToken      = nil
GlobalVariableSystem_C.nTokenTime  = 0
GlobalVariableSystem_C.nTokenMaxTime = 0
GlobalVariableSystem_C.SdkModuleManager = nil

GlobalVariableSystem_C.szPatchUrl = nil
GlobalVariableSystem_C.szHelpUrl = nil
GlobalVariableSystem_C.szResourceServerURL = nil
GlobalVariableSystem_C.szAnnourcementServerURL = nil
GlobalVariableSystem_C.szServerListServerURL = nil
GlobalVariableSystem_C.szVersion = nil

GlobalVariableSystem_C.bShowPlayer = true
GlobalVariableSystem_C.bShowCharacter = true
GlobalVariableSystem_C.bNewMeleeCamera = false
GlobalVariableSystem_C.DungeonEnterMaxWaitTime = 180
GlobalVariableSystem_C.bEnableAsyncLoadObject = false

GlobalVariableSystem_C.bBattleFullHeadInfo = false
GlobalVariableSystem_C.bCancelMerge = false

-- GlobalVariableSystem_C.SyncTimer = nil
GlobalVariableSystem_C.nServerSyncTimeStartTime = nil
GlobalVariableSystem_C.nServerSyncTimeEndTime = nil
GlobalVariableSystem_C.nDeltaTime = nil
GlobalVariableSystem_C.tbNewRole = nil

GlobalVariableSystem_C.nEnterDungeonIds = {}
--单机副本
GlobalVariableSystem_C.nEnterDungeonIds.nSingle = -1
--联网副本
GlobalVariableSystem_C.nEnterDungeonIds.nNetwork = -1
GlobalVariableSystem_C.bShowHeadInfo = false
GlobalVariableSystem_C.bUseLoadingScreen = false
GlobalVariableSystem_C.nDungeonToken = -1
-- GlobalVariableSystem_C.bDisconnected = false
GlobalVariableSystem_C.bDoubleFire = false

GlobalVariableSystem_C.bEnableAsynPickup = true

-- 签到界面
GlobalVariableSystem_C.bShowedCheckIn = false

GlobalVariableSystem_C.bDevMode = GWithEditor

GlobalVariableSystem_C.bGuideSkipCtrl = nil

GlobalVariableSystem_C.bOpenGuide = true

GlobalVariableSystem_C.bIosReviewMode = GWithEditor

GlobalVariableSystem_C.bParachutingNewLaunchTime = false
--拾取界面
GlobalVariableSystem_C.bUseNewPickupSystem = false
--登录模式
GlobalVariableSystem_C.LOGIN_WITH_ACCOUNT               = 0
GlobalVariableSystem_C.LOGIN_WITH_DEVICE_ID             = 1
GlobalVariableSystem_C.LOGIN_WITH_THIRD_PARTY_ACCOUNT   = 2
GlobalVariableSystem_C.LOGIN_MAP_ID = 70000
GlobalVariableSystem_C.CREATE_ROLE_MAP_ID = 70002
GlobalVariableSystem_C.LOGIN_MATINEE_ID = 5


GlobalVariableSystem_C.bNewReconnect = true
GlobalVariableSystem_C.bEnterLobbyLoading = false
GlobalVariableSystem_C.bQuickBattleLoading = false
GlobalVariableSystem_C.bDebugMapPath = false
GlobalVariableSystem_C.bShowPlayerName = false
GlobalVariableSystem_C.bNewBattleWatch = false

-- 船检测前有障碍时，是否打印命中Actor信息
GlobalVariableSystem_C.bPrintActorInfoWhenCheckMountain = false

GlobalVariableSystem_C.bDisconnectRetravel = true
GlobalVariableSystem_C.bEnterLobby3D = true
GlobalVariableSystem_C.bLoadAllLobbySublevel = true
GlobalVariableSystem_C.nDungeonSessionId = 0

GlobalVariableSystem_C.CandidateAvatarConfig =
{
    All = "all",
    MaleOnly = "male_only",
    FemaleOnly = "female_only"
}

GlobalVariableSystem_C.szAvatarSexConfig = GlobalVariableSystem_C.CandidateAvatarConfig.FemaleOnly

GlobalVariableSystem_C.bEnableReplicatedLog = false
GlobalVariableSystem_C.bEnableGVoiceAllRoom = true
GlobalVariableSystem_C.nDelayDestroyGameObjectTime = 5  -- 小于0则关闭延迟删除object

GlobalVariableSystem_C.nGMOpenMode = GMOpenModeDef.DOUBLE_CLICK

GlobalVariableSystem_C.bPrintSceneItem = false
GlobalVariableSystem_C.nLastUploadLogTime = 0

GlobalVariableSystem_C.tbDebugTimeSyncTimer = nil
GlobalVariableSystem_C.bEnableActorAsyncCreating = true
GlobalVariableSystem_C.bUseComponentDataSerializerInNetClient = false
GlobalVariableSystem_C.bUseSeparateBeginPlayInNetClient = true
GlobalVariableSystem_C.bShipSoundEnabled = true

GlobalVariableSystem_C.nEnterDungeonTime = nil

-- GM指令模拟作弊用
GlobalVariableSystem_C.nAttackCDTime = -1
GlobalVariableSystem_C.nReloadCDTime = -1

GlobalVariableSystem_C.bDestructibleObjectVisible = true

GlobalVariableSystem_C.bFFAPackageUseWeight = true

local function ClearDebugTimeSyncTimer(self)
    log("[GlobalVariableSystem]ClearDebugTimeSyncTimer")
    if self.tbDebugTimeSyncTimer ~= nil then
        self.tbDebugTimeSyncTimer:Clear()
        self.tbDebugTimeSyncTimer = nil
    end
end

local function StartDebugTimeSyncTimer(self)
    log("[GlobalVariableSystem]StartDebugTimeSyncTimer")
    if self.tbDebugTimeSyncTimer ~= nil then
        logerror("Already Start tbDebugTimeSyncTimer!")
        return
    end
    local FunCallback = function()
        local nServerTime = self:GetServerTimeUtc()
        local nLocalTime = os.time()
        log("[GlobalVariableSystem] time sync check", nServerTime, nLocalTime, nServerTime - nLocalTime)
    end
    self.tbDebugTimeSyncTimer = require("Timer").NewTimer(FunCallback, 10, true)
end

local function GetPlatformSeconds()
    return ExtendBlueprintFunctions.GetPlatformMilliseconds() / 1000
end

local function OnEnterLobby(self)
    log("[GlobalVariableSystem] OnEnterLobby")
    StartDebugTimeSyncTimer(self)
end

local function OnLeaveLobby(self)
    self.bInLobby = false
    log("[GlobalVariableSystem] OnLeaveLobby")
    ClearDebugTimeSyncTimer(self)
end

local function OnEnterBattle(self)
    log("[GlobalVariableSystem] OnEnterBattle")
    StartDebugTimeSyncTimer(self)
end

local function OnLeaveBattle(self)
    log("[GlobalVariableSystem] OnLeaveBattle")
    ClearDebugTimeSyncTimer(self)
end

function GlobalVariableSystem_C:Init()
    local bRet = GlobalVariableSystem_C.super.Init(self)

    self.bIsClient = true
    self.bIsInDungeon = false
    self.bIsStandalone = true

    self.pChannelSdkManager = ClientShell.GetClient(GWorld):GetChannelSdkManager()
    local bVaild = self.pChannelSdkManager:IsValidSdk()
    self.nLoginMode = bVaild and self.LOGIN_WITH_THIRD_PARTY_ACCOUNT or self.LOGIN_WITH_ACCOUNT
    log("[GlobalVariableSystem] bVaild = " .. tostring(bVaild) .. " login mode = " .. tostring(self.nLoginMode))

    -- 禁止自动锁屏
    KismetSystemLibrary.ControlScreensaver(false)

    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveBattle)
    return bRet
end

function GlobalVariableSystem_C:Uninit()
    self.EventHelper:UnregisterAll()
    ClearDebugTimeSyncTimer(self)
    GlobalVariableSystem_C.super.Uninit(self)
end

function GlobalVariableSystem_C:SetToken(szToken, nCurTime, nTokenMaxTime)
    self.szToken = szToken
    self.nTokenTime = nCurTime
    self.nTokenMaxTime = nTokenMaxTime
end

function GlobalVariableSystem_C:OnSendLoginRequest()
    self.nServerSyncTimeStartTime = GetPlatformSeconds()
    log("[GlobalVariableSystem] OnSendLoginRequest begin_platform_time", self.nServerSyncTimeStartTime)
end

function GlobalVariableSystem_C:OnRecvServerSyncTime(nServerUnixTimeMs, nTimezoneOffsetSeconds)
    self.bMock = false
    TimeUtil.SetTimezoneOffsetSeconds(nTimezoneOffsetSeconds)
    self.nServerSyncTimeEndTime = GetPlatformSeconds()
    self.nDeltaTime = nServerUnixTimeMs / 1000 - (self.nServerSyncTimeEndTime - self.nServerSyncTimeStartTime) / 2 - self.nServerSyncTimeStartTime
    log("[GlobalVariableSystem] OnRecvServerSyncTime begin_platform_time", self.nServerSyncTimeStartTime,
                                                    "end_platform_time", self.nServerSyncTimeEndTime,
                                                    "server_ms", nServerUnixTimeMs,
                                                    "delta_time", self.nDeltaTime,
                                                    "timezone_offset_seconds", nTimezoneOffsetSeconds)
end

function GlobalVariableSystem_C:SetMockDeltaTime()
    self.bMock = true
    self.nDeltaTime = 0
end

function GlobalVariableSystem_C:GetServerTimeUtc()
    if self.nDeltaTime == nil then
        logwarning("[GlobalVariableSystem] Cannot get server time!", debug.traceback())
        return os.time()
    end
    if self.bMock then
        return os.time()
    else
        local nServerTime = self.nDeltaTime + GetPlatformSeconds()
        return math.floor(nServerTime)
    end
end

function GlobalVariableSystem_C:IsDevMode()
    return self.bDevMode or GWithEditor
end

function GlobalVariableSystem_C:IsGuideSkipCtrl()
    return self.bGuideSkipCtrl
end

function GlobalVariableSystem_C:IsIosReviewMode()
    return self.bIosReviewMode
end

function GlobalVariableSystem_C:SetDevMode(bDevMode)
    self.bDevMode = bDevMode
end

function GlobalVariableSystem_C:SetGMOpenMode(nGMOpenMode)
    self.nGMOpenMode = nGMOpenMode
end

function GlobalVariableSystem_C:GetGMOpenMode()
    return self.nGMOpenMode
end

function GlobalVariableSystem_C:SetGuideSkipCtrl(bCtrl)
    self.bGuideSkipCtrl = bCtrl
end

function GlobalVariableSystem_C:IsOpenGuide()
    return self.bOpenGuide
end

function GlobalVariableSystem_C:SetOpenGuide(bOpen)
    self.bOpenGuide = bOpen
end

function GlobalVariableSystem_C:SetPatchUrl(szPatchUrl)
    self.szPatchUrl = szPatchUrl
end

function GlobalVariableSystem_C:GetPatchUrl()
    return self.szPatchUrl
end

function GlobalVariableSystem_C:SetHelpUrl(szHelpUrl)
    self.szHelpUrl = szHelpUrl
end

function GlobalVariableSystem_C:GetHelpUrl()
    return self.szHelpUrl
end

function GlobalVariableSystem_C:SetAnnouncementUrl(szAnnourcementServerURL)
    self.szAnnourcementServerURL = szAnnourcementServerURL
end

function GlobalVariableSystem_C:GetAnnouncementUrl()
    return self.szAnnourcementServerURL
end

function GlobalVariableSystem_C:SetServerListUrl(szServerListServerURL)
    self.szServerListServerURL = szServerListServerURL
end

function GlobalVariableSystem_C:GetServerListUrl()
    return self.szServerListServerURL
end

function GlobalVariableSystem_C:SetVersion(szVersion)
    self.szVersion = szVersion
end

function GlobalVariableSystem_C:GetVersion()
    return self.szVersion
end

function GlobalVariableSystem_C:SetAppVersion(szAppVersion)
    self.szAppVersion = szAppVersion
end

function GlobalVariableSystem_C:GetAppVersion()
    return self.szAppVersion
end

function GlobalVariableSystem_C:SetResVersion(szResVersion)
    self.szResVersion = szResVersion
end

function GlobalVariableSystem_C:GetResVersion()
    return self.szResVersion
end


function GlobalVariableSystem_C:SetIosReviewMode(bIosInReview)
    self.bIosReviewMode = bIosInReview
end

function GlobalVariableSystem_C:SetAvatarSexConfig(szConfig)
    if szConfig then
        local bValid = false
        for k, v in pairs(self.CandidateAvatarConfig) do
            if v == szConfig then
                bValid = true
                break
            end
        end
        if bValid then
            log("GlobalVariableSystem_C:SetAvatarSexConfig ", szConfig)
            self.szAvatarSexConfig = szConfig
        else
            logerror("GlobalVariableSystem_C:SetAvatarSexConfig invalid, ", szConfig)
        end
    else
        log("GlobalVariableSystem_C:SetAvatarSexConfig invalid, ", szConfig)
    end
end

function GlobalVariableSystem_C:GetAvatarSexConfig()
    return self.szAvatarSexConfig
end


function GlobalVariableSystem_C:GetChannelSdkManager()
    return self.pChannelSdkManager
end

function GlobalVariableSystem_C:SetNewRoleAvatarId(nAvatarId)
    if not self.tbNewRole then
        self.tbNewRole = {}
    end
    self.tbNewRole.nAvatarId = nAvatarId
end

function GlobalVariableSystem_C:HasNewRoldAvatarId()
    if not self.tbNewRole or not self.tbNewRole.nAvatarId then
        return false
    end
    return true
end
function GlobalVariableSystem_C:GetNewRoleAvatarId()
    if not self.tbNewRole or not self.tbNewRole.nAvatarId then
        return 1
    end
    return self.tbNewRole.nAvatarId
end

function GlobalVariableSystem_C:SetSkipGuide(bSkip)
    if not self.tbNewRole then
        self.tbNewRole = {}
    end
    self.tbNewRole.bSkipGuide = bSkip
end

function GlobalVariableSystem_C:IsSkipGuide()
    if not self.tbNewRole or not self.tbNewRole.bSkipGuide then
        return false
    end
    return self.tbNewRole.bSkipGuide
end

function GlobalVariableSystem_C:UseLoadingScreen(bUse)
    self.bUseLoadingScreen = bUse
end

function GlobalVariableSystem_C:SetParachutingNewLaunchTime(bNew)
    self.bParachutingNewLaunchTime = bNew
end

function GlobalVariableSystem_C:GetLobbyServerAddress()
    local tbCurrentServerData = self.tbCurrentServerData
    if(tbCurrentServerData) then
        return tbCurrentServerData.lobby_backup
            or tbCurrentServerData.lobby
            or tbCurrentServerData.hub
    end

    return nil
end

-- function GlobalVariableSystem_C:IsDisconnected()
--     return self.bDisconnected
-- end

-- function GlobalVariableSystem_C:SetDisconnected(bValue)
--     self.bDisconnected = bValue
-- end

function GlobalVariableSystem_C:EnableGVoiceAllRoom(bEnable)
    self.bEnableGVoiceAllRoom = bEnable
end

function GlobalVariableSystem_C:SetDisconnectRetravel(bDisconnectRetravel)
    self.bDisconnectRetravel = bDisconnectRetravel
end

function GlobalVariableSystem_C:SetOpenLobby3D(bOpenLobby3D)
    self.bEnterLobby3D = bOpenLobby3D
end

function GlobalVariableSystem_C:IsInTrainingCamp(nDungeonId)
    return nDungeonId == DungeonIni.nTrainingCampDungeonId
end

function GlobalVariableSystem_C:SetEnterDungeonTime(nTime)
    log("GlobalVariableSystem_C:SetEnterDungeonTime ", nTime)
    if nTime ~= nil then
        if self.nEnterDungeonTime == nil then
            self.nEnterDungeonTime = nTime
            local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
            pSaveGameMgr:AddIntData(SaveGameDef.DUNGEON_START_TIME, nTime)
            pSaveGameMgr:Save()
        end        
    else
        self.nEnterDungeonTime = nil
        -- ClientShell.GetClient(GWorld):GetSaveGameManager():AddIntData(SaveGameDef.DUNGEON_START_TIME, 0)
    end
end

function GlobalVariableSystem_C:IsFFAPackageUseWeight()
    return self.bFFAPackageUseWeight
end

function GlobalVariableSystem_C:SetDungeonSessionId(nId)
    self.nDungeonSessionId = nId
end

function GlobalVariableSystem_C:GetDungeonSessionId()
    return self.nDungeonSessionId
end

return GlobalVariableSystem_C()
