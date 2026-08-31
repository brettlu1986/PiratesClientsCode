local luaclass              = require("luaclass")
local ReconnectedBaseNew    = require("ReconnectedBaseNew")
local ReconnectedHubNew     = luaclass("ReconnectedHubNew", ReconnectedBaseNew)
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")
local ReconnectedLoginNew   = require("ReconnectedLoginNew")
local UIDef                 = require("UIDef")
local UIManager             = require("UIManager")
local ReconnectIni          = require("ReconnectIni")
local ProcedureTool         = require("ProcedureTool")
local NetworkManager        = dynamic_require("NetworkManager")
local DisconnectType        = require("DisconnectTypeNew") 
local ClientEventDef        = require("ClientEventDef")
local ProcedureManager      = require("ProcedureManager")
local ManagerRoot           = require("ManagerRoot")
local ManagerGroupDef       = require("ManagerGroupDef")
local GameObjectSystem      = dynamic_require("GameObjectSystem")
local UITextDef             = require("UITextDef")
local TimeUtil              = require("TimeUtil")
local L10N                  = require("L10N")
local Proto                 = require("ClientProtoNames")
local UIUtils               = require("UIUtils")
-- local DelayTimer            = require("DelayTimer")
local EnterLastDungeonHelper = require("EnterLastDungeonHelper")
local LoginResponseHelper    = require("LoginResponseHelper")
-- local TutorialDungeonIni     = require("TutorialDungeonIni")
local GamePlayerSelfHelper   = require("GamePlayerSelfHelper")

ReconnectedHubNew.nStep           = nil
ReconnectedHubNew.nDisconnectTime = nil
ReconnectedHubNew.nRetryStartTime = nil
ReconnectedHubNew.nRetryCount     = nil
ReconnectedHubNew.ReconnectedLogin= nil
ReconnectedHubNew.nConnectState   = nil
ReconnectedHubNew.PersistentTimerHandle     = nil
ReconnectedHubNew.ExplicitReconnectTimer    = nil
ReconnectedHubNew.bDungeonExplicitReconnect = nil

ReconnectedHubNew.nRetryConnectInterval = nil
ReconnectedHubNew.nLastRetryConnectTime = nil

-- 副本内杀进程，重进
ReconnectedHubNew.bShowEnterDungeonDialog  = nil
ReconnectedHubNew.nDungeonId      = nil

ReconnectedHubNew.bEnterGame      = nil
-- ReconnectedHubNew.tbDelayTimer    = nil

local ReconnectStep = {
    None        = 0,
    Auto        = 1,
    Manual      = 2,
    Disconnect  = 3,
    Connected   = 4,
}

local ConnectState = {
    None        = 0,
    DoConnect   = 1,
    Failed      = 2,
}

local NetState = 
{
    DisconnectionState  = 0,
    WifiState = 1,
    MobileState = 2
}

local tbCloseWnds = {
    UIDef.UI_SATISFACTION,
}

local RECONNECT_INTERVAL = 1
local RECONNECT_INTERVAL_MAX = 16

local NO_EXPLICIT_RECONNECT_MAX_TIME = 60

local function CloseWnds()
    for i, v in ipairs(tbCloseWnds) do
        UIManager:CloseWnd(v)
    end
end

-- 显式的重连
local function IsExplicitReconnect(self)
    if GlobalVariableSystem:IsInDungeon() then
        -- 不能单纯的用IsInDungeon判断是否显式的重连
        -- 因为有可能在loading过程中，NetDriver还没有建立，断线了
        -- 就会出现卡住loading界面的问题
        -- 所以添加60秒timer, 
        -- 60秒后还是没有任何断线表现，就强制显示
        if UIManager:IsWndVisible(UIDef.UI_WAIT_CONNECT_DIALOG) or
            UIManager:IsWndVisible(UIDef.UI_RETRY_CONNECT_DIALOG) then
            return false
        else
            return self.bDungeonExplicitReconnect
        end
    end
    return true
end

local function SetStep(self, nStep)
    self.nStep = nStep
    if self.nStep == ReconnectStep.Auto then
        log("[ReconnectSystem] reconnect base set step auto")
    elseif self.nStep == ReconnectStep.Manual then
        self:ShowRetryConnectDialog(DisconnectType.with_lobby_config_cancel)
    elseif self.nStep == ReconnectStep.Disconnect then
        self:ShowDisconnectDialog(DisconnectType.with_lobby_config)
    elseif self.nStep == ReconnectStep.Connected then
        log("[ReconnectSystem] Reconnected base set step connected")
        self:CloseRetryConnectDialog()
    end
end

local function OverReconnectTime(self)
    local nReconnectTime = ReconnectIni.nWildWorldReconnectTime
    return GlobalVariableSystem:GetLocalTime() - self.nDisconnectTime >= nReconnectTime
end

local function StepAutoReconnect(self)
    local tbReconnectConfig = ReconnectIni
    local bOver = GlobalVariableSystem:GetLocalTime() - self.nDisconnectTime >= tbReconnectConfig.nAutoReconnectTime
    if bOver then
        log("[ReconnectSystem] over auto reconnect time")
        SetStep(self, ReconnectStep.Manual)
    end
    return not bOver
end

local function StepManualReconnectTime(self)
    local tbReconnectConfig = ReconnectIni
    local bOverTime = GlobalVariableSystem:GetLocalTime() - self.nRetryStartTime >= tbReconnectConfig.nManualReconnectTime
    if bOverTime then

        local bOverCount = self.nRetryCount + 1 > tbReconnectConfig.nManualReconnectCount
        if bOverCount then
            SetStep(self, ReconnectStep.Disconnect)
        else
            SetStep(self, ReconnectStep.Manual)
        end
    end

    return not bOverTime
end

local function GetRetryConnectInterval(self)
    local nResult = self.nRetryConnectInterval
    return nResult
end

local function CanRetryConnect(self)
    if self.nConnectState ~= ConnectState.DoConnect then 
        log("[ReconnectSystem] connect hub but state is ", self.nConnectState)
        return false
    end
    return GlobalVariableSystem:GetLocalTime() - self.nLastRetryConnectTime >= GetRetryConnectInterval(self)
end

local function DoConnect(self)
    if self.nConnectState == ConnectState.Failed then
        log("[ReconnectSystem] connect hub but is failed")
        return
    end

    self.nConnectState = ConnectState.DoConnect

    local fnReconnect = function()
        -- 重连失败返回，再次重连
        if not CanRetryConnect(self) then 
            return
        end

        if self.ReconnectedLogin then
            self.nConnectState = ConnectState.None
            self.nLastRetryConnectTime = GlobalVariableSystem:GetLocalTime()
            self.nRetryConnectInterval = math.min(self.nRetryConnectInterval * 2, RECONNECT_INTERVAL_MAX)
            log("[ReconnectSystem] reconnecting ", self.nRetryConnectInterval)
            self.ReconnectedLogin:Reconnect()
        else
            logerror("not find reconnectedlogin")
        end
    end

    if not self.PersistentTimerHandle then
        self.PersistentTimerHandle = self.PersistentTimerHelper:NewTimer(function()
            fnReconnect()
        end, RECONNECT_INTERVAL, true)
    end
end

local function TryConnect(self)
    if not self.ReconnectedLogin then
        log("[ReconnectSystem] ToReconnect not reconnected Login")
        return
    end
    if self.nStep == ReconnectStep.Connected then
        log("[ReconnectSystem] ToReconnect is connected")
        return
    end

    if IsExplicitReconnect(self) then
        if OverReconnectTime(self) then
            if self.bPendingDialog then
                log("[ReconnectSystem] over reconnectTime but no playercontroller")
                self:Disconnect()
            else
                SetStep(self, ReconnectStep.Disconnect)
            end
        else
            local bRet = false
            if self.nStep == ReconnectStep.Auto then
                bRet = StepAutoReconnect(self)
            elseif self.nStep == ReconnectStep.Manual then
                bRet = StepManualReconnectTime(self)
            else
                log("[ReconnectSystem] ReconnectedHubNew.ToReconnect step is valid ", self.nStep)
                SetStep(self, ReconnectStep.Disconnect)
            end
            log("[ReconnectSystem] step ", self.nStep, bRet)
            if bRet then
                DoConnect(self)
            end            
        end
    else
        DoConnect(self)
    end
end

local function OnConnectedHubFailed(self)
    log("[ReconnectSystem] OnConnectedHubFailed")
    TryConnect(self)
end

local function OnConnectedHydraFailed(self)
    if IsExplicitReconnect(self) then
        log("[ReconnectSystem] not in dungeon to connect hydra failed")
        self:ShowDisconnectDialog()
    else
        log("[ReconnectSystem] in dungeon to connect hydra failed")
    end
end

local function ClearTimer(self)
    if self.PersistentTimerHandle ~= nil then
        self.PersistentTimerHelper:ClearTimer(self.PersistentTimerHandle)
        self.PersistentTimerHandle = nil
    end
    self:DestroyUITimerHandle()
end

local function ClearExplicitReconnectTimer(self)
    if self.ExplicitReconnectTimer ~= nil then
        self.PersistentTimerHelper:ClearTimer(self.ExplicitReconnectTimer)
        self.ExplicitReconnectTimer = nil
    end
    self.bDungeonExplicitReconnect = false
end

local function OnConnectedHubResult(self, bResult)
    log("[ReconnectSystem] OnConnectedHubResult ", bResult)
    if bResult then
        ClearTimer(self)
        ClearExplicitReconnectTimer(self)
        SetStep(self, ReconnectStep.Connected)
        -- self:OnConnected()
        self.EventHelper:FireEvent(ClientEventDef.EV_RECONNECTED)
        self.ReconnectedLogin:SendLoginToHubServer()        
    else
        OnConnectedHubFailed(self)
    end
end

local function CreateExplicitReconnectTimer(self)
    if (UIManager:IsWndVisible(UIDef.UI_LOADING_NEW)) or (UIManager:IsWndVisible(UIDef.UI_LOADING)) then
        self.ExplicitReconnectTimer = self.PersistentTimerHelper:NewTimer(function()
            log("on explicit reconnect")
            self.bDungeonExplicitReconnect = true
        end, NO_EXPLICIT_RECONNECT_MAX_TIME)
    end
end

-- 切网
local function OnNetStateChanged(self, pNetState)
    local nNetState = enumtoint(pNetState)
    log("[ReconnectSystem] OnNetStateChanged ", nNetState)
    if nNetState ~= NetState.DisconnectionState then
        if self:IsActivate() then
            if self.nStep == ReconnectStep.Auto or self.nStep == ReconnectStep.Manual then
                log("[ReconnectSystem] OnNetStateChanged already try connecting ", self.nStep)
            else
                local DefaultNetworkProxy = NetworkManager:GetHubServerProxy()
                DefaultNetworkProxy:Disconnect(nil, nil, DefaultNetworkProxy.DisconnectReason.Disconnect_Passivity)
            end
        else
            log("[ReconnectSystem] OnNetStateChanged not connected hub")
        end
    end
end

local function ShowDisconnectDialogWithProtoReason(self, nReason, Param)
    ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
    local szText = UITextDef.DISCONNECT_SERVER_UNKNOWN
    if nReason == Proto.s2c_Disconnect_Reason.UNKNOWN then
        log("[ReconnectSystem] ShowDisconnectDialog unknown")
    elseif nReason == Proto.s2c_Disconnect_Reason.KICK_OUT then
        log("[ReconnectSystem] ShowDisconnectDialog kick out")
    elseif nReason == Proto.s2c_Disconnect_Reason.DOUBLE_LOGIN then
        szText = UITextDef.DISCONNECT_DOUBLE_LOGIN
    elseif nReason == Proto.s2c_Disconnect_Reason.SERVER_FULL then
        szText = UITextDef.DISCONNECT_SERVER_FULL
    elseif nReason == Proto.s2c_Disconnect_Reason.SERVER_MAINTENANCE then
        szText = UITextDef.DISCONNECT_SERVER_MAINTENANCE
    elseif nReason == Proto.s2c_Disconnect_Reason.PING_MISSING then
        log("[ReconnectSystem] ShowDisconnectDialog ping missing")
    elseif nReason == Proto.s2c_Disconnect_Reason.BANNED then
        if Param and Param.nDuration > 0 then
            local szTime = TimeUtil.GetTimeFormatString(GlobalVariableSystem:GetServerTimeUtc() + Param.nDuration, "%Y-%m-%d %H:%M")
            szText = L10N:Format(UITextDef.USER_BANNED_LOGIN, szTime)
        else
            szText = UITextDef.USER_BANNED_LOGIN_FOREVER
        end
    elseif nReason == Proto.s2c_Disconnect_Reason.ANTI_ADDICTION then
        szText = UITextDef.ANTIADDICTION_TICKOUT
    end
    self:ShowDisconnectDialog(DisconnectType.disconnected, szText, false)
end

--==============================--
-- 副本内杀进程，重进 start
-- lihui
--==============================-----------------

-- local function ClearDelayTimer(self)
--     if self.tbDelayTimer ~= nil then
--         log("clear enter lobby timer")
--         self.tbDelayTimer:Clear()
--         self.tbDelayTimer = nil
--     end
-- end

local function OnNewPlayerDataSync(self, tbPacket)
    local fnReturnStartGame = function()
        ClientShell.GetClient(GWorld):GetDungeonShell():DisconnectFromDungeonServer(false)
        NetworkManager:GetHubServerProxy():Disconnect()
        ProcedureTool:ReturnToStartGame()
    end
    if tbPacket == nil then
        log("[ReconnectSystem] recv new player but in dungeon")
        fnReturnStartGame()
        return
    end

    self.bEnterGame = true

    local bIsInDungeon     = EnterLastDungeonHelper:IsInLastDungeon(tbPacket)
    local nDungeonId       = EnterLastDungeonHelper:GetLastDungeonId(tbPacket)
    local tbPlayerSelf     = GamePlayerSelfHelper:Get()
    local bClientInDungeon = GlobalVariableSystem:IsInDungeon() and tbPlayerSelf and tbPlayerSelf.bReady

    self.bShowEnterDungeonDialog = false
    self.nDungeonId = nDungeonId

    if bIsInDungeon then
        if bClientInDungeon then --Lobby表示玩家在副本中，客户端环境也是副本内，回复Lobby我已经在副本中了
            local nSessionId = GlobalVariableSystem:GetDungeonSessionId()
            if tbPacket.data.dungeon.game_session_id ~= nSessionId then
                log("[ReconnectSystem]OnNewPlayerDataSync session is dif ", nSessionId)
                GlobalVariableSystem:SetDungeonSessionId(tbPacket.data.dungeon.game_session_id)
                ProcedureManager:ActiveProcedure()
                EnterLastDungeonHelper:EnterLastDungeon(self.nDungeonId)
            else
                EnterLastDungeonHelper:AlreadyInDungeon()
            end
        else
            self.bShowEnterDungeonDialog = EnterLastDungeonHelper:ShouldShowDialog(tbPacket)
        end
    else
        if bClientInDungeon then
            log("[ReconnectSystem] client in dungeon, but server is not in dungeon.")
            fnReturnStartGame()
        end        
    end
end

local function OnNewLobbyReady(self)
    if self.bShowEnterDungeonDialog then
        local funcOK = function() 
            EnterLastDungeonHelper:EnterLastDungeon(self.nDungeonId)
        end
    
        local funcCancel = function() 
            EnterLastDungeonHelper:RefuseEnterLastDungeon()
        end
    
        local l10nTitle   = EnterLastDungeonHelper:GetTitle(self.nDungeonId)
        local l10nMessage = EnterLastDungeonHelper:GetMessage(self.nDungeonId)
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, funcOK,funcCancel)
        self.bShowEnterDungeonDialog = false
    end
end
--==============================--
-- 副本内杀进程, 重进 end
--==============================---------------

function ReconnectedHubNew:Activate()
    ReconnectedHubNew.super.Activate(self)

    self.EventHelper:RegisterEvent(ClientEventDef.EV_CONNECTED, self, OnConnectedHubResult)
    local pSystemInfoMgr = ClientShell.GetClient(GWorld):GetSystemInfoManager()
    self.EventHelper:RegisterCppDelegate(pSystemInfoMgr.OnNetStateChanged, self, OnNetStateChanged)

    -- 副本内杀进程, 重进 事件
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnNewLobbyReady)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnNewPlayerDataSync)

    self.bDungeonExplicitReconnect = false 
end

function ReconnectedHubNew:Deactivate()  
    self.bEnterGame = nil  
    ClearTimer(self)
    -- ClearDelayTimer(self)
    ClearExplicitReconnectTimer(self)
    if self.ReconnectedLogin then
        self.ReconnectedLogin:Uninit()
        self.ReconnectedLogin = nil
    end    
    ReconnectedHubNew.super.Deactivate(self)
end

function ReconnectedHubNew:DisconnectFromHubServer(nReason, Param)
    ClearExplicitReconnectTimer(self)
    if nReason == -1 then
        
        CloseWnds(self)

        if IsExplicitReconnect(self) then
            self:ShowWaitConnectDialog()
        end

        if not self.ReconnectedLogin then
            self.ReconnectedLogin = ReconnectedLoginNew()
            self.ReconnectedLogin:Init({tbHandle = self, fnConnectedHubFailed = OnConnectedHubFailed, fnConnectedHydraFailed = OnConnectedHydraFailed })
        end
        self.nRetryConnectInterval = RECONNECT_INTERVAL
        self.nLastRetryConnectTime = 0
        self.nRetryStartTime = 0
        self.nRetryCount = 0
        self.nDisconnectTime = GlobalVariableSystem:GetLocalTime()
        self.nStep = ReconnectStep.Auto
        self.nConnectState = ConnectState.None
        TryConnect(self)

        CreateExplicitReconnectTimer(self)
    else
        ShowDisconnectDialogWithProtoReason(self, nReason, Param)
    end
end

function ReconnectedHubNew:Disconnect()
    log("[ReconnectSystem] hub disconnect and return to start game")
    ClearTimer(self)
    -- ClearDelayTimer(self)
    ClearExplicitReconnectTimer(self)
    NetworkManager:GetHubServerProxy():Disconnect()
    ProcedureTool:ReturnToStartGame()
end

function ReconnectedHubNew:RetryConnect()
    if not OverReconnectTime(self) then
        log("[ReconnectSystem] ReconnectedHubNew:ShowDisconnectDialog and close")
        self:CloseRetryConnectDialog()
    end

    self.nRetryStartTime= GlobalVariableSystem:GetLocalTime()
    self.nRetryCount    = self.nRetryCount + 1

    TryConnect(self)    
end

function ReconnectedHubNew:ShowDisconnectDialog(nLevel, l10nText, bQuitGame)
    self.nConnectState = ConnectState.Failed
    ReconnectedHubNew.super.ShowDisconnectDialog(self, nLevel, l10nText, bQuitGame)
end

function ReconnectedHubNew:Rebuild(tbPlayerData)
    if self.ReconnectedLogin then
        self.ReconnectedLogin:Uninit()
        self.ReconnectedLogin = nil
    end    

    if self.bEnterGame then 
    
        log("[ReconnectSystem] uninstall lobby")
        ProcedureManager:ActiveProcedure()
        ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID)
        
        log("[ReconnectSystem] install lobby", tbPlayerData)
        ManagerRoot:InitGroup(ManagerGroupDef.nDefaultGroupID)
        GameObjectSystem:CreatePlayerSelfWithHubLoginData(tbPlayerData)
        self.EventHelper:FireEvent(ClientEventDef.EV_PLAYERDATA_SYNC, tbPlayerData, true)

        local bEnterLastDungeon = EnterLastDungeonHelper:ShouldGotoLastDungeon(tbPlayerData)
        if bEnterLastDungeon then
            GameObjectSystem:RestorePlayerSelfObject(false, tbPlayerData.data.id, nil, true)
            GameObjectSystem:DestroyAll()
            EnterLastDungeonHelper:EnterLastDungeon(EnterLastDungeonHelper:GetLastDungeonId(tbPlayerData))
        else
            local tbParam = {}
            tbParam.tbPlayerData = tbPlayerData
            ProcedureTool:EnterLobby(tbParam)
        end

        self:CloseWaitConnectDialog()    
    else
        self:Disconnect()
    end
end

function ReconnectedHubNew:ReconnectedNewPlayer()
    -- ShowDisconnectDialogWithProtoReason(self, Proto.s2c_Disconnect_Reason.UNKNOWN)
    if self.ReconnectedLogin then
        self.ReconnectedLogin:Uninit()
        self.ReconnectedLogin = nil
    end 
    self:CloseWaitConnectDialog()

    log("[ReconnectSystem] uninstall")
    ProcedureManager:ActiveProcedure()
    ManagerRoot:UninitGroup(ManagerGroupDef.nDefaultGroupID)
    log("[ReconnectSystem] install")
    ManagerRoot:InitGroup(ManagerGroupDef.nDefaultGroupID)

    LoginResponseHelper:HideLoadingUI(LoginResponseHelper.LOGIN_OP.HUB_LOGIN_NEWPLAYER)

    self.EventHelper:FireEvent(ClientEventDef.EV_NEW_PLAYER)
    -- local pSaveGameMgr = ClientShell.GetClient(GWorld):GetSaveGameManager()
    -- local szCompleteSingel = pSaveGameMgr:GetStringData("GUIDE_SINGLE_BE_COMPLETE")
    -- local bComplete = szCompleteSingel =="1"
    -- if TutorialDungeonIni.bEnabled then
    --     UIManager:OpenWnd(UIDef.UI_SELECTLEVEL)
    -- else
    ProcedureTool:EnterCreateRole()
    -- end   
    -- self:Disconnect() 
end

return ReconnectedHubNew
