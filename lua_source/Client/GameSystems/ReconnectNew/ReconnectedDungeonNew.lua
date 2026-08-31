local luaclass              = require("luaclass")
local ReconnectedBaseNew    = require("ReconnectedBaseNew")
local ReconnectedDungeonNew = luaclass("ReconnectedDungeonNew", ReconnectedBaseNew)
local ClientEventDef        = require("ClientEventDef")
local UISetUtils            = require("UISetUtils")
local NetworkManager        = dynamic_require("NetworkManager")
local ProtoDC               = require("DungeonCommonProtoNames")
local DisconnectType        = require("DisconnectTypeNew")
local UITextDef             = require("UITextDef")
local L10N                  = require("L10N")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local BattleGameModeSystem  = dynamic_require("BattleGameModeSystem")
local TutorialDungeonIni    = require("TutorialDungeonIni")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
local ProcedureTool         = require("ProcedureTool")
local LoadingSystem         = require("LoadingSystem")
local ReconnectIni          = require("ReconnectIni")
local UIDef                 = require("UIDef")
local ProtoDR               = require("DungeonRepProtoNames")

ReconnectedDungeonNew.nStartTime = nil

ReconnectedDungeonNew.nSendReconnectInfoInterval = nil
ReconnectedDungeonNew.nSendReconnectInfoCount = nil
ReconnectedDungeonNew.ReconnectInfoTimer = nil

ReconnectedDungeonNew.WaitConnectTimer  = nil
ReconnectedDungeonNew.RetravelTimer     = nil
ReconnectedDungeonNew.QuitTimer         = nil
ReconnectedDungeonNew.BackgroundTimer   = nil

ReconnectedDungeonNew.nProcessedType = nil

local PROCESSED_TYPE = {
    MAX = 0, -- 35秒出现菊花 正常情况
    MID = 1, -- 15秒出现菊花 切后台情况
    MIN = 2  -- 5秒出现菊花  跳伞情况
}

local SEND_RECONNECT_INFO_MAX_COUNT = 5
local SEND_RECONNECT_INFO_MID_COUNT = 3
local WAIT_CONNECTION_MIN_TIME      = 5

local function OnBattleDisconnected(self)
    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
    self:ShowDisconnectDialog(DisconnectType.disconnected, UITextDef.DISCONNECT_SERVER_UNKNOWN)
end

local function OnNetworkFailureWithString(self, pFailureType, szErrorString)
    local szText = UITextDef.DISCONNECT_SERVER_UNKNOWN
    local bQuitGame = false
    if (pFailureType == ENetworkFailure.ConnectionLost)
    or (pFailureType == ENetworkFailure.ConnectionTimeout) then
        -- 断开连接和超时此处不处理，System.ShowDisconnectDialogWithProtoReason会处理
        return
    else
        log("[ReconnectSystem] OnNetworkFailureWithString, EnumIndex =", enumtoint(pFailureType), ", ErrorString =", szErrorString)
        if pFailureType == ENetworkFailure.NetChecksumMismatch then
            -- 资源不匹配提示并关闭游戏
            szText = UISetUtils.GetL10NTextByKey("CLIENT_VERSION_MISMATCH")
            bQuitGame = true
        else
            szText = L10N:Format(UISetUtils.GetL10NTextByKey("CLIENT_NETWORK_FAILURE_UNKNOWN"), enumtoint(pFailureType))
        end
    end
    self:ShowDisconnectDialog(DisconnectType.disconnected, szText, bQuitGame)
end

local function TestNet(self)
    if self.nStartTime > 0 then
        log("[ReconnectSystem] ReconnectDungeon: test net")
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_TestNet)
    end
end

local function IsTutorialDungeon()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    if nDungeonId == TutorialDungeonIni.nDungeonId then
        return true
    end
    return false
end

-- 副本内不显示与hub断线的窗口，所以在副本连接上以后，不需要判断lobby是否还连着，就可以关闭一些重连相关窗口了
-- local function IsConnectWithLobby()

    -- if not GlobalVariableSystem:IsWithLobby() and GWithEditor then
    -- headlessclient 情况下会导致返回false, 所以去掉GWidthEditor判断
    -- if not GlobalVariableSystem:IsWithLobby() then
    --     return true
    -- end
    -- local Socket = NetworkManager:GetHubServerProxy()
    -- if Socket:IsConnect() then
    --     return true
    -- end

    -- return false
-- end

local function SendReconnectInfo(self)
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf == nil then
        logwarning("[ReconnectSystem] ReconnectedDungeon:SendReconnectInfo send reconnect info but player is nil.")
        return
    end

    if tbPlayerSelf:GetUEController() == nil then
        logwarning("[ReconnectSystem] ReconnectedDungeon:SendReconnectInfo send reconnect info but contoller is nil.")
        return
    end

    local bResult = ClientShell.GetClient(GWorld):GetDungeonShell():SendReconnectInfo(tbPlayerSelf.nPlayerId, GlobalVariableSystem.nDungeonToken)

    log("[ReconnectSystem] ReconnectedDungeon:SendReconnectInfo ", bResult, tbPlayerSelf.nPlayerId, GlobalVariableSystem.nDungeonToken)
    if bResult then
        log("[ReconnectSystem] ReconnectedDungeon:SendReconnectInfo send reconnect info succeed.")
    else
        logwarning("[ReconnectSystem] ReconnectedDungeon:SendReconnectInfo send reconnect info failed.")
    end
end

local function RetravelToServer(self)
    log("[ReconnectSystem] RetravelToServer and disconnect from dungeon")
    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)

    local nDungeonToken = GlobalVariableSystem.nDungeonToken
    local szLastTravelParam = GlobalVariableSystem.szLastTravelParam

    log("[ReconnectSystem] RetravelToServer and force enter Procedure_Battle ", nDungeonToken, szLastTravelParam)
    local tbParam = {}
    tbParam.nDungeonId = BattleGameModeSystem.nDungeonId
    tbParam.szDungeonSessionId = BattleGameModeSystem:GetDungeonSessionId()
	tbParam.bQuickBattleLoading = true
	tbParam.bStandalone = false
	tbParam.bRetraveling = true
    tbParam.szLoadingWnd = UIDef.UI_WAIT_CONNECT_DIALOG
    tbParam.nToken       = nDungeonToken
    tbParam.szLastTravelParam = szLastTravelParam
    tbParam.nEncryptionSeed = NetworkManager:GetRPCNetworkProxy():GetPacketEncryptionSeed()

    local tbEndParams = {}
    tbEndParams.bRetraveling = true
    ProcedureTool:EnterDungeon(tbParam, tbEndParams, true)
end

local function DestroyRetravelTimer(self)
    if self.RetravelTimer then
        self.PersistentTimerHelper:ClearTimer(self.RetravelTimer)
        self.RetravelTimer = nil
    end
    if self.QuitTimer then
        self.PersistentTimerHelper:ClearTimer(self.QuitTimer)
        self.QuitTimer = nil
    end
end

local function CreateRetravelTimer(self)
    -- 第三步
    -- 默认1 + 2 + 4 + 8 + 16 + 32 + 8 秒后显示 retravel
    -- 切后台1 + 2 + 4 + 8 秒后显示 retravel
    self.RetravelTimer = self.PersistentTimerHelper:NewTimer(function()
        log("[ReconnectSystem] dungeon retravel dialog")
        self:ShowRetryConnectDialog(DisconnectType.with_dungeon_config_cancel)
    end, ReconnectIni.nManualReconnectTime)

    -- 第四步
    -- 3分钟超时 断线
    local nConnectionTimeout = ClientShell.GetClient(GWorld):GetConnectionTimeout()
    if self.QuitTimer == nil then
        self.QuitTimer = self.PersistentTimerHelper:NewTimer(function()
            log("[ReconnectSystem] dungeon connection time out")
            self:ShowDisconnectDialog(DisconnectType.with_dungeon_config)
        end, nConnectionTimeout)
    end
end

local function DestroySendReconnectInfoTimer(self)
    if self.ReconnectInfoTimer then
        self.PersistentTimerHelper:ClearTimer(self.ReconnectInfoTimer)
        self.ReconnectInfoTimer = nil
    end
    self.nSendReconnectInfoInterval = nil
    self.nSendReconnectInfoCount = nil
    self.ReconnectInfoTimer = nil
end

local function OnSendReconnectInfoTimer(self, nMaxSendCount)
    local nSendReconnectInfoCount = self.nSendReconnectInfoCount + 1
    self.nSendReconnectInfoCount = nSendReconnectInfoCount

    local nSendReconnectInfoInterval = self.nSendReconnectInfoInterval * 2 -- 间隔时间每次乘2
    self.nSendReconnectInfoInterval = nSendReconnectInfoInterval

    if(nSendReconnectInfoCount > nMaxSendCount) then
        log("[ReconnectSystem] SendReconnectInfo too many times")
        DestroySendReconnectInfoTimer(self)
        CreateRetravelTimer(self)
    else
        SendReconnectInfo(self)
        log("[ReconnectSystem] SendReconnectInfo next time:", nSendReconnectInfoInterval)
        self.ReconnectInfoTimer = self.PersistentTimerHelper:NewTimer(function()
            OnSendReconnectInfoTimer(self, nMaxSendCount)
        end, nSendReconnectInfoInterval)
    end
end

local function DestroyWaitConnectTimer(self)
    if self.WaitConnectTimer then
        self.PersistentTimerHelper:ClearTimer(self.WaitConnectTimer)
        self.WaitConnectTimer = nil
    end
end

-- 第二步
local function CreateWaitConnectTimer(self)
    -- 默认30秒后出现菊花，切后台切回来10秒后转菊花
    local nTime = 0
    if self.nProcessedType == PROCESSED_TYPE.MID then
        nTime = WAIT_CONNECTION_MIN_TIME
    elseif self.nProcessedType == PROCESSED_TYPE.MAX then
        nTime = ReconnectIni.nDungeonWaitReconnectTime
    end
    log("[ReconnectSystem] create show wait connect dialog ", nTime)
    if nTime > 0 then    
        self.WaitConnectTimer = self.PersistentTimerHelper:NewTimer(function()
            log("[ReconnectSystem] show wait connect dialog")
            self:ShowWaitConnectDialog()
        end, nTime)
    else
        self:ShowWaitConnectDialog()
    end
end

-- 第一步
local function CreateSendReconnectInfoTimer(self)
    assert(self.ReconnectInfoTimer == nil)

    local bRet = ClientShell.GetClient(GWorld):GetDungeonShell():RecreateUDPSocketInClient()
    if bRet then
        log("[ReconnectSystem] ReconnectedDungeon:RecreateUDPSocketInClient succeed")
    else
        logwarning("[ReconnectSystem] ReconnectedDungeon:RecreateUDPSocketInClient failed")
    end

    SendReconnectInfo(self)
    self.nSendReconnectInfoInterval = 1
    self.nSendReconnectInfoCount = 1
    -- 默认重发5次信息，切后台重发3次信息
    local nMaxSendCount = SEND_RECONNECT_INFO_MAX_COUNT
    if self.nProcessedType == PROCESSED_TYPE.MID then
        nMaxSendCount = SEND_RECONNECT_INFO_MID_COUNT
    end
    log("[ReconnectSystem] SendReconnectInfo next time:", self.nSendReconnectInfoInterval, nMaxSendCount)

    self.ReconnectInfoTimer = self.PersistentTimerHelper:NewTimer(function()
        OnSendReconnectInfoTimer(self, nMaxSendCount)
    end, self.nSendReconnectInfoInterval)
end

local function SetProcessedType(self, nType)
    if nType < self.nProcessedType then
        logwarning("[ReconnectSystem] set processed type failed: ", nType, self.nProcessedType)
        return
    end
    self.nProcessedType = nType
end

local function SetDefaultProcessType(self)
    log("[ReconnectSystem] set processed type max")
    self.nProcessedType = PROCESSED_TYPE.MAX
    -- SetProcessedType(self, PROCESSED_TYPE.MAX)
end 

local function DestroyBackgroundTimer(self)
    if self.BackgroundTimer then
        self.PersistentTimerHelper:ClearTimer(self.BackgroundTimer)
        self.BackgroundTimer = nil
    end
end

local function  CreateBackgroundTimer(self)
    DestroyBackgroundTimer(self)
    self.BackgroundTimer = self.PersistentTimerHelper:NewTimer(function()
        SetDefaultProcessType(self)
        DestroyBackgroundTimer(self)
    end, 30)
end

local function GetPingStr()
    local nPing = ExtendBlueprintFunctions.GetPing(GWorld)
    return nPing.."ms"
end

local function ClearTimer(self)
    DestroySendReconnectInfoTimer(self)
    DestroyRetravelTimer(self)
    DestroyWaitConnectTimer(self)
    DestroyBackgroundTimer(self)
    self:DestroyUITimerHandle()
end

local function OnBattleTimeout(self, bTimeout)
    log("[ReconnectSystem] OnBattleTimeout ", bTimeout, GetPingStr())

    self.nStartTime = bTimeout and GlobalVariableSystem:GetLocalTime() or -1
    TestNet(self)
    ClearTimer(self)

    if bTimeout then
        CreateSendReconnectInfoTimer(self)
        CreateWaitConnectTimer(self)
    else
        self:CloseWaitConnectDialog()
        self:CloseRetryConnectDialog(self)
    end
    
    -- SetProcessedType(self, PROCESSED_TYPE.MAX)
end

local function OnEnterForeground(self)
    -- 切后台，转菊花和显示断线框的时间短一点
    log("[ReconnectSystem] OnEnterForeground")
    -- 因为切后台回来总会出现在很短时间内timeout true 然后timeout false，然后又timeout true的情况，导致切后台回来等待转菊花时间超长
    -- 所以加个30秒的timer,在30秒内nProcessedType 都为PROCESSED_TYPE.MID
    if self.nProcessedType < PROCESSED_TYPE.MID then
        log("[ReconnectSystem] Set processed type to mid")
        CreateBackgroundTimer(self)
        SetProcessedType(self, PROCESSED_TYPE.MID)
    end
end

-- local function OnRetravelToServerSuccessed(self)
--     log("[ReconnectSystem] OnRetravelToServerSuccessed")
--     OnBattleTimeout(self, false)
-- end

local function OnFFAProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.PARACHUTING then
        log("[ReconnectSystem] set processed type min")
        SetProcessedType(self, PROCESSED_TYPE.MIN)
    end
end

function ReconnectedDungeonNew:Activate()
    local bResult = ReconnectedDungeonNew.super.Activate(self)

    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_TIMEOUT, self, OnBattleTimeout)
    EventHelper:RegisterEvent(ClientEventDef.EV_BATTLE_DISCONNECTED, self, OnBattleDisconnected)
    EventHelper:RegisterEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND, self, OnEnterForeground)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_PARACHUTION_END, self, SetDefaultProcessType)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_ENTER_DUNGEON_IN_BATTLE, self, SetDefaultProcessType)

    local pGameInstance = GameplayStatics.GetGameInstance(GWorld)
    EventHelper:RegisterCppDelegate(pGameInstance.OnNetworkFailureWithString, self, OnNetworkFailureWithString)

    local DelegateMgr = CommonShell.GetCommon(GWorld):GetGameDelegateManager().GameMisc
    EventHelper:RegisterCppDelegate(DelegateMgr.OnRepPropTypeMismatch, self, self.OnRepPropTypeMismatch)

    -- EventHelper:RegisterEvent(ClientEventDef.EV_REPLICATION_CRC_CHECK_SUCCESS, self, OnRetravelToServerSuccessed)
    SetDefaultProcessType(self)
    self.nStartTime = -1

    return bResult
end

function ReconnectedDungeonNew:Deactivate()
    self.nStartTime = nil

    ClearTimer(self)
    ReconnectedDungeonNew.super.Deactivate(self)
end

function ReconnectedDungeonNew:OnRepPropTypeMismatch()
    log("[ReconnectSystem] ReconnectedDungeonNew:OnRepPropTypeMismatch")
    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
    self:ShowDisconnectDialog(DisconnectType.disconnected, UISetUtils.GetL10NTextByKey("CLIENT_VERSION_MISMATCH"), true)
end

function ReconnectedDungeonNew:ShowWaitConnectDialog()
    ReconnectedDungeonNew.super.ShowWaitConnectDialog(self)
    if self.bPendingDialog then
        log("[ReconnectSystem] ReconnectedDungeon loading system show disconnect dialog ")
        ClearTimer(self)
        local tbParam = {
            szBtnOkText = UITextDef.L10N_OK,
            funOK = function()
                ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
                NetworkManager:GetHubServerProxy():Disconnect()
                ProcedureTool:ReturnToStartGame()
            end,
            szMessage = UITextDef.DISCONNECT_SERVER_UNKNOWN
        }
        LoadingSystem:ShowDialogMessage(tbParam)
    end
end

function ReconnectedDungeonNew:Rebuild(tbPacket)
    if not GlobalVariableSystem:IsStandalone() then
        -- 可以在任何时候删除下面代码，此处只是加强和 dungeon 重连的响应，但实际上和 dungeon 的重连与和 hub 的重连没有关系
        -- 可以只依赖于 ReconnectHandler。此处添加基于目前的和 hub 连接的架构假设之上，今后会只依赖于和 dungeon 断开后尝试重连，那个时候
        -- 就可以删除下面一句了
        log("[ReconnectSystem] connected from hub")
        SendReconnectInfo(self)
    end

    if not IsTutorialDungeon() then
        self.EventHelper:FireEvent(ClientEventDef.EV_PLAYERDATA_SYNC, tbPacket, true)
    end
end

function ReconnectedDungeonNew:RetryConnect()
    log("[ReconnectSystem] ReconnectedDungeonNew:RetryConnect")
    self:CloseRetryConnectDialog()
    if GlobalVariableSystem.bDisconnectRetravel then
        RetravelToServer(self)
    end
end

function ReconnectedDungeonNew:Disconnect()
    log("[ReconnectSystem] ReconnectedDungeonNew:Disconnect")
    self:CloseRetryConnectDialog()
    DestroyRetravelTimer(self)
    local pClientShell = ClientShell.GetClient(GWorld)
    local bIsSmoothTravel = pClientShell:IsInSmoothTravel()
    pClientShell:GetDungeonShell():DisconnectFromDungeonServer(bIsSmoothTravel)
    NetworkManager:GetHubServerProxy():Disconnect()
    ProcedureTool:ReturnToStartGame()
end

return ReconnectedDungeonNew