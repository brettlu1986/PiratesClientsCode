local luaclass = require("luaclass")
local GlobalGameCppDelegateProcessor = require("GlobalGameCppDelegateProcessor")
local GlobalGameCppDelegateProcessor_C = luaclass("GlobalGameCppDelegateProcessor_C", GlobalGameCppDelegateProcessor)

local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UIStateDef = require("UIStateDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ReplicatedPropertyGenerateSystem = require("ReplicatedPropertyGenerateSystem")
local ReconnectSystem = require("ReconnectSystemNew")

local function OnAbortNavMove()
    -- Only Client
    local AbortTypeDef = require("AbortTypeDef")
    EventManager:OnFireEvent(ClientEventDef.EV_COMMON_ABORT, AbortTypeDef.MOVE)
end

local function OnRequestExitGame()
    local pChannelSdkManager = GlobalVariableSystem:GetChannelSdkManager()
    pChannelSdkManager:Exit()
end

local function OnEnterCinematicMode()
    --UIManager:SetCinematicMode(true)
    UIManager:PushState(UIStateDef.StateName.UI_TEMP_HIDE_STATE, nil )
end

local function OnExitCinematicMode()
    --UIManager:SetCinematicMode(false)
    if UIManager:GetInCinematicMode() then
        UIManager:PopState(UIStateDef.StateName.UI_TEMP_HIDE_STATE)
    end
end

local function OnApplicationWillDeactivateDelegate()
    EventManager:OnFireEvent(ClientEventDef.EV_APP_WILL_DEACTIVE)
end

local function OnApplicationWillEnterBackgroundDelegate()
    log("OnApplicationWillEnterBackgroundDelegate")
    EventManager:OnFireEvent(ClientEventDef.EV_APP_WILL_ENTER_BACKGROUND)
end

local function OnApplicationHasEnteredForegroundDelegate()
    log("OnApplicationHasEnteredForegroundDelegate")
    EventManager:OnFireEvent(ClientEventDef.EV_APP_HAS_ENTERED_FOREGROUND)
end


local function OnDungeonTimeout(bTimeout)
    log("Battle Connect TimeOut ", bTimeout)

    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_TIMEOUT, bTimeout)
end

local function OnRepControllerPropertyCRC(tbCRCs)
    log("OnRepControllerPropertyCRC")

    if(BattleGameModeSystem.bRetraveling) then
        BattleGameModeSystem.bRetraveling = false
    else
        if(not ReplicatedPropertyGenerateSystem:CheckReplicationCRC(tbCRCs)) then
            ReconnectSystem:OnRepPropTypeMismatch()
            return
        end
    end

    EventManager:OnFireEvent(ClientEventDef.EV_REPLICATION_CRC_CHECK_SUCCESS)
end

local function OnViewportResized()
    log("OnViewportResized")
    EventManager:OnFireEvent(ClientEventDef.EV_VIEWPORT_RESIZED)
end

function GlobalGameCppDelegateProcessor_C:Init()
    GlobalGameCppDelegateProcessor_C.super.Init(self)

    -- Register Gameplay Delegate
    local DelegateMgr = ClientShell.GetClient(GWorld):GetClientDelegateManager()
    local pGameMisc = DelegateMgr.GameMisc
    self:Register(pGameMisc.OnAbortNavMove    , OnAbortNavMove)
    self:Register(pGameMisc.OnRequestExitGame , OnRequestExitGame)
    self:Register(pGameMisc.OnEnterCinematicMode , OnEnterCinematicMode)
    self:Register(pGameMisc.OnExitCinematicMode , OnExitCinematicMode)

    self:Register(pGameMisc.OnApplicationWillDeactivateDelegate, OnApplicationWillDeactivateDelegate)
    self:Register(pGameMisc.OnApplicationWillEnterBackgroundDelegate, OnApplicationWillEnterBackgroundDelegate)
    self:Register(pGameMisc.OnApplicationHasEnteredForegroundDelegate, OnApplicationHasEnteredForegroundDelegate)

    self:Register(pGameMisc.OnIpConnectionTimeout, OnDungeonTimeout)
    self:Register(pGameMisc.OnRepControllerPropertyCRC, OnRepControllerPropertyCRC)
    self:Register(pGameMisc.OnViewportResized, OnViewportResized)
    return true
end

return GlobalGameCppDelegateProcessor_C
