-----------------------------------------------------
--File Name    : GPerfSystemServer.lua
--Author       : WuJizhou
--Create Time  : 12/18/2019, 6:20:26 PM
--Description  : GPerfSystemServer
-----------------------------------------------------
local GPerfSystemServer = {}


local CommonEventDef       = require("CommonEventDef")
local SelfEventHelper      = require("SelfEventHelper")
local GameObjectTypeDef    = require("GameObjectTypeDef")
local BotAISystem          = dynamic_require("BotAISystem")
local GameObjectSystem     = dynamic_require("GameObjectSystem")
local WatchBattleSystem    = dynamic_require("WatchBattleSystem")
local BattleResultSystem   = dynamic_require("BattleResultSystem")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
GPerfSystemServer.bEnable = false

local tbFieldIndex =
{
    PlayerActiveCount   = 1,
    PlayerObserverCount = 2,
    BotActiveCount      = 3
}

local EventHelper = nil
GPerfSystemServer.bStart = false

local szCurrentSessionId = nil

local function DoStartGPerf(self)
    if self.bEnable then
        GPerfShell.StartGPerf(GWorld)
        szCurrentSessionId = BattleGameModeSystem:GetDungeonSessionId()
        GPerfShell.SetTag("dungeon_session_id", szCurrentSessionId)
        log("GPerfServer",  string.format("GPerfSystemServer do start, session id : %s", szCurrentSessionId))
    else
        logerror("GPerfSystem Start", "GPerfSystemServer is not enable")
    end
end

local function DoStopGPerf(self)

    if self.bEnable then
        if szCurrentSessionId == BattleGameModeSystem:GetDungeonSessionId() then
            log("GPerfServer",  string.format("GPerfSystemServer do stop, session id : %s", szCurrentSessionId))
            GPerfShell.StopGPerf()
            szCurrentSessionId = nil
        else
            log("GPerfSystem Stop", "GPerfSystem stop failed, id does not match")
        end
    else
        logerror("GPerfSystem Stop", "GPerfSystem is not enable")
    end
end

local function DoUploadGPerf(self)
    log("GPerfServer",  "GPerfSystemServer do upload")
    if self.bEnable then
        GPerfShell.UploadSession()
    else
        logerror("GPerfSystem Upload", "GPerfSystem is not enable")
    end
end
local function DoRefreshObserverCount(self)
    local ObserverCount = WatchBattleSystem:GetCurrentWatchCount()
    GPerfShell.SetIntFieldValue(tbFieldIndex.PlayerObserverCount, ObserverCount)
end

local function DoRefreshActivePlayerCount(self, nCount)
    GPerfShell.SetIntFieldValue(tbFieldIndex.PlayerActiveCount, nCount)
end

local function DoRefreshActiveBotCount(self, nCount)
    GPerfShell.SetIntFieldValue(tbFieldIndex.BotActiveCount, nCount)
end

local function OnGameSessionReceived(self)
    log("GPerfServer", "OnGameSessionReceived")
    self:Start()
end

local function OnGameModeEndPlay(self)
    self:Stop()
    self:Upload()
end

local function OnMemberEnterWatch(self)
    DoRefreshObserverCount(self)
end

local function OnMemberLeaveWatch(self)
    DoRefreshObserverCount(self)
end

local function RefreshActivePlayerCount(self)
    local nAlivePlayerCount = 0
    local nAliveBotCount = 0
    local tbObjects = GameObjectSystem:GetAllByObjectType(GameObjectTypeDef.PlayerSelf)
    for Object, _ in pairs(tbObjects) do
        local nInstanceId = Object:GetServerInstanceId()
        local bPlayerBattleEnd = BattleResultSystem:IsPlayerBattleEnd(nInstanceId)
        if  not bPlayerBattleEnd then
            if BotAISystem:IsBot(Object) then
                nAliveBotCount = nAliveBotCount + 1
            else
                nAlivePlayerCount = nAlivePlayerCount + 1
            end
        end
    end
    DoRefreshActivePlayerCount(self, nAlivePlayerCount)
    DoRefreshActiveBotCount(self, nAliveBotCount)
end

local function OnPawnDead(self)
    RefreshActivePlayerCount(self)

end

local function OnPlayerLogin(self)
    log("GPerfServer", "OnPlayerLogin", self.bStart)
    if self.bStart then
        RefreshActivePlayerCount(self)
    else
        log("GPerfServer", "OnPlayerLogin not start")
    end

end

function GPerfSystemServer:IsEnable()
    return self.bEnable
end

function GPerfSystemServer:EnableByIntValue(nEnableValue)
    GPerfShell.EnableGPerf(true)
    if nEnableValue == 1 then
        self.bEnable = true
    else
        self.bEnable = false
    end
end

function GPerfSystemServer:Enable(bEnable)
    log("GPerfServer", "Enable", bEnable)
    local nValue = 0
    if bEnable then
        nValue = 1
    end
    self:EnableByIntValue(nValue)
end


function GPerfSystemServer:Start()
    log("GPerfSystemServer", "GPerfSystemServer::Start", self.bStart)
    if not self.bStart then
        DoStartGPerf(self)
        self.bStart = true
    end
end

function GPerfSystemServer:Stop()
    log("GPerfSystemServer", "GPerfSystemServer::Stop", self.bStart)
    if self.bStart then
        DoStopGPerf(self)
        self.bStart = false
    end
end

function GPerfSystemServer:Upload()
    DoUploadGPerf(self)
end

function GPerfSystemServer:Init()
    log("GPerfServer", "Init")
    self:Enable(true)
    EventHelper = SelfEventHelper()
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_SESSION_RECEIVED, self, OnGameSessionReceived)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_END_PLAY, self, OnGameModeEndPlay)
    EventHelper:RegisterEvent(CommonEventDef.EV_MEMBER_ENTER_WATCH, self, OnMemberEnterWatch)
    EventHelper:RegisterEvent(CommonEventDef.EV_MEMBER_LEAVE_WATCH, self, OnMemberLeaveWatch)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, OnPlayerLogin)

    return true
end

function GPerfSystemServer:Uninit()
    log("GPerfServer", "Uninit")
    EventHelper:UnregisterAll()
    EventHelper = nil
    return true
end

return GPerfSystemServer