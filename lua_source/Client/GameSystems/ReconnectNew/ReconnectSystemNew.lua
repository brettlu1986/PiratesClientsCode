local ClientEventDef    = require("ClientEventDef")
local SelfEventHelper   = require("SelfEventHelper")
local ReconnectIni      = require("ReconnectIni")
local UITextDef         = require("UITextDef")
local ProcedureTool         = require("ProcedureTool")
local NetworkManager        = dynamic_require("NetworkManager")

local ReconnectSystemNew= {}
ReconnectSystemNew.tbReconnected                 = nil
ReconnectSystemNew.tbReconnectedHubProcessor     = nil
ReconnectSystemNew.tbReconnectedDungeonProcessor = nil
ReconnectSystemNew.bReturnStart = nil


local RECONNECTED_HUB     = "ReconnectedHubNew"
local RECONNECTED_DUNGEON = "ReconnectedDungeonNew"

function ReconnectSystemNew:OnRepPropTypeMismatch()
    log("[ReconnectSystem] OnRepPropTypeMismatch")
    if self.tbReconnectedDungeonProcessor:IsActivate() then
        self.tbReconnectedDungeonProcessor:OnRepPropTypeMismatch()
    else
        error("[ReconnectSystem] OnRepPropTypeMismatch but dungeon process is not activate")
    end
end

local function RegistConnect(self, ConnectedName)
    local ConnectedClass = require(ConnectedName)
    local RetConnected = ConnectedClass()
    RetConnected.szName = ConnectedName
    RetConnected:Init()

    self.tbReconnected[ConnectedName] = RetConnected
    return RetConnected
end

local function OnHubConnectResult(self, bResult)
    if bResult and not self.tbReconnectedHubProcessor:IsActivate() then
        if not self.bReturnStart then  
            self.tbReconnectedHubProcessor:Activate()
        else
            self.bReturnStart = nil
            log("connect success but send c2s_login ssl error: 5, other error: 0")
        end
    end
end

local function OnEnterLogin(self)
    if self.tbReconnectedHubProcessor and self.tbReconnectedHubProcessor:IsActivate() then
        self.tbReconnectedHubProcessor:Deactivate()
    end
end

local function OnEnterDungeon(self, bRetraveling)
    if not bRetraveling then
        self.tbReconnectedDungeonProcessor:Activate()
    else
        log("[ReconnectSytem] Enter Dungeon is Retraveling")
    end
end

local function OnLeaveDungeon(self, bRetraveling)
    if not bRetraveling then
        self.tbReconnectedDungeonProcessor:Deactivate()
    else
        log("[ReconnectSytem] Leave Dungeon is Retraveling")
    end
end

function ReconnectSystemNew:Init()
    self.tbReconnected = {}

    self.EventHelper = SelfEventHelper()
    local EventHelper = self.EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_CONNECTED, self, OnHubConnectResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOGIN, self, OnEnterLogin)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterDungeon)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_BATTLE, self, OnLeaveDungeon)

    self.tbReconnectedHubProcessor = RegistConnect(self, RECONNECTED_HUB)
    self.tbReconnectedDungeonProcessor = RegistConnect(self, RECONNECTED_DUNGEON)

    ClientShell.GetClient(GWorld):SetClientConnectionTimeOut(ReconnectIni.nDungeonDefaultSendReconnectInfoTime)

    return true
end

function ReconnectSystemNew:Uninit()
	self.EventHelper:UnregisterAll()
	self.EventHelper = nil

    for _, v in pairs(self.tbReconnected) do
        if v:IsActivate() then
            v:Deactivate()
        end
        v:Uninit()
    end
    self.tbReconnectedHubProcessor = nil
    self.tbReconnectedDungeonProcessor = nil

    self.tbReconnected = nil
end

function ReconnectSystemNew:DisconnectFromHubServer(reason, param)
    log("[ReconnectSystem] DisconnectFromHubServer", reason)
    if self.tbReconnectedHubProcessor:IsActivate() then
        self.tbReconnectedHubProcessor:DisconnectFromHubServer(reason, param)
    else
        -- 刚连上，发送c2s_login时断线
        log("[ReconnectSystem] DisconnectFromHubServer no connected")
        self.bReturnStart = true
        NetworkManager:GetHubServerProxy():Disconnect()
        ProcedureTool:ReturnToStartGame()
    end
end

function ReconnectSystemNew:EnterFailed()
    local l10nText = UITextDef.REVISION_CHECK_FAILED
    if self.tbReconnectedDungeonProcessor:IsActivate() then
        self.tbReconnectedDungeonProcessor:ShowDisconnectDialog(nil, l10nText)
    elseif self.tbReconnectedHubProcessor:IsActivate() then
        self.tbReconnectedHubProcessor:ShowDisconnectDialog(nil, l10nText)
    else
        error("[ReconnectSystem] EnterFailed ")
    end
end

function ReconnectSystemNew:TryEnter(tbPacket)
    if self.tbReconnectedDungeonProcessor:IsActivate() then
        log("[ReconnectSystem] TryEnterDungeon")
        self.tbReconnectedDungeonProcessor:Rebuild(tbPacket)
    elseif self.tbReconnectedHubProcessor:IsActivate() then
        if tbPacket ~= nil then
            log("[ReconnectSystem] TryEnterLobby")   
            self.tbReconnectedHubProcessor:Rebuild(tbPacket)
        else
            log("[ReconnectSystem] NewPlayer")   
            self.tbReconnectedHubProcessor:ReconnectedNewPlayer()
        end
    else
        error("[ReconnectSystem] TryEnter failed ")
    end
end

return ReconnectSystemNew