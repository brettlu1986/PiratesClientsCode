local luaclass              = require("luaclass")
local ReconnectedBaseNew    = luaclass("ReconnectedBaseNew")
local SelfEventHelper       = require("SelfEventHelper")
local ClientEventDef        = require("ClientEventDef")
local DelayTimer            = require("DelayTimer")
local UIUtils               = require("UIUtils")
local UIDef                 = require("UIDef")
local UITextDef             = require("UITextDef")
local UISetUtils            = require("UISetUtils")
local DisconnectType        = require("DisconnectTypeNew") 
local PersistentTimerHelper = require("PersistentTimerHelper")
local UIManager             = require("UIManager")

ReconnectedBaseNew.tbOwner              = nil
ReconnectedBaseNew.EventHelper          = nil
ReconnectedBaseNew.bActivate            = nil
ReconnectedBaseNew.PersistentTimerHelper= nil

ReconnectedBaseNew.bPlayerReady         = nil
ReconnectedBaseNew.bPendingDialog       = nil

local RECONNECT_INTERVAL = 1
local RETRY_CONNECT_L10N = UISetUtils.GetL10NTextByKey("RECONNECTEDBASE_RECONNECTL10N")
local RETURN_L10N = UISetUtils.GetL10NTextByKey("UI_STATIC_SETTING_RETURN")

local function OnPlayerSelfReady(self)
    self.bPlayerReady = true
    if self.bPendingDialog then
        log("[ReconnectSystem] ReconnectedBase:OnPlayerSelfReady and show Dialog")
        self:ShowWaitConnectDialog()
    end
end

function ReconnectedBaseNew:Init(Owner)
    log("[ReconnectSystem] ReconnectedBaseNew:Init ", self.szName)

    self.tbOwner = Owner
    self.EventHelper = SelfEventHelper()
    self.PersistentTimerHelper = PersistentTimerHelper()
    self.bActivate = false

    return true
end

function ReconnectedBaseNew:Uninit()
    log("[ReconnectSystem] ReconnectedBaseNew:Uninit ", self.szName)
    self:DestroyUITimerHandle()
    
    self.bActivate   = nil
    self.bPlayerReady= nil
    self.bPendingDialog = nil

    self.PersistentTimerHelper:ClearAllTimer()
    self.PersistentTimerHelper = nil

    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.tbOwner = nil
end

function ReconnectedBaseNew:Activate()
    log("[ReconnectSystem] ReconnectedBaseNew:Activate ", self.szName)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERSELF_READY, self, OnPlayerSelfReady)
    self.bPlayerReady= false
    self.bPendingDialog = false
    self.bActivate   = true
end

function ReconnectedBaseNew:Deactivate()
    self.bActivate = false
    self.EventHelper:UnregisterAll()
    self.PersistentTimerHelper:ClearAllTimer()
    log("[ReconnectSystem] ReconnectedBaseNew:Deactivate ", self.szName)
end

function ReconnectedBaseNew:IsActivate()
    return self.bActivate
end

function ReconnectedBaseNew:RetryConnect()
    log("[ReconnectSystem] ReconnectedBaseNew:RetryConnect")
end

function ReconnectedBaseNew:Disconnect()
    log("[ReconnectSystem] ReconnectedBaseNew:Disconnect")
end

-- 第一步
function ReconnectedBaseNew:ShowWaitConnectDialog()
    if self.bPlayerReady then
        if self.UITimerHandle == nil then
            self.UITimerHandle = DelayTimer:DelayRun(function()
                UIManager:OpenWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
                self:DestroyUITimerHandle()
            end, RECONNECT_INTERVAL)
        else
            log("[ReconnectSystem] ReconnectedBase:ShowWaitConnectDialog is showing")
        end
        return true
    else
        self.bPendingDialog = true
        log("[ReconnectSystem] ReconnectedBase:ShowWaitConnectDialog but not playercontroller")
        return false
    end
end

function ReconnectedBaseNew:CloseWaitConnectDialog(bForce)
    self.bPendingDialog = false
    UIManager:CloseWnd(UIDef.UI_WAIT_CONNECT_DIALOG)
    self:DestroyUITimerHandle()
end

-- 第二步
function ReconnectedBaseNew:ShowRetryConnectDialog(nLevel)
    if not self.bPlayerReady then
        log("[ReconnectSystem] ReconnectedBaseNew:ShowRetryConnectDialog but not playercontroller")
        self:RetryConnect()
        return false
    end

    if nLevel == nil then
        nLevel = DisconnectType.with_lobby_config_cancel
    end
    
    local l10nText = UITextDef.DISCONNECT_SERVER_TORECONNECT
    UIUtils.ShowRetryConnectDialog(l10nText, RETRY_CONNECT_L10N, RETURN_L10N, function()
        self:RetryConnect()
    end,
    function()
        self:Disconnect()
    end, nLevel)

    return true
end

function ReconnectedBaseNew:CloseRetryConnectDialog()
    UIUtils.CloseConnectDialog()
end

-- 第三步
function ReconnectedBaseNew:ShowDisconnectDialog(nLevel, l10nText, bQuitGame)
    if nLevel == nil then
        nLevel = DisconnectType.disconnected
    end

    if l10nText == nil then
        l10nText = UITextDef.DISCONNECT_SERVER_UNKNOWN
    end
    UIUtils.ShowDisconnectDialog(l10nText, UITextDef.L10N_OK, function() 
        if bQuitGame then
            KismetSystemLibrary.QuitGame(GWorld, nil, EQuitPreference.Quit)
        else        
            self:Disconnect()
        end
    end, nLevel)
end

function ReconnectedBaseNew:DestroyUITimerHandle()
    if self.UITimerHandle ~= nil then
        log("ReconnectedBaseNew:DestroyUITimerHandle")
        DelayTimer:ClearTimer(self.UITimerHandle)
        self.UITimerHandle = nil
    end
end

return ReconnectedBaseNew
