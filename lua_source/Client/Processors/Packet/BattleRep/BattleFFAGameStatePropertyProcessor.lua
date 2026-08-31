local luaclass = require("luaclass")
local BattleGameStatePropertyProcessorClass = require("BattleGameStatePropertyProcessor")
local BattleFFAGameStatePropertyProcessor = luaclass("BattleFFAGameStatePropertyProcessor", BattleGameStatePropertyProcessorClass)

local BattleTeammateSystem = require("BattleTeammateSystem")
local PropNameGameState = require("PropNameGameState")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")

local function LOG(...)
    log("[BattleFFAGameStatePropertyProcessor] ", ...)
end

local function OnCountDownEndTimeChanged(self, nFFACountDownEndTime)
    LOG("OnCountDownEndTimeChanged: ", nFFACountDownEndTime)

    local tbPacket = {nCountDownEndTime = nFFACountDownEndTime}
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_SETTING, tbPacket)
end

local function OnAlivePlayerCountChanged(self, nAliveCount)
    LOG("OnAlivePlayerCountChanged: ", nAliveCount)

    local tbPacket = {nAlivePlayerCount = nAliveCount}
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_INFO_CHANGED, tbPacket)
end

local function OnTeamModeIdChanged(self, nFFATeamModeId)
    LOG("OnTeamModeIdChanged: ", nFFATeamModeId)
    BattleTeammateSystem:SetTeamMode(nFFATeamModeId)

    local tbPacket = {nTeamModeId = nFFATeamModeId}
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_MODE_INFO, tbPacket)
end

local function OnStateChanged(self, nState)
end

local function OnWaitStageChanged(self, bFFAWaitStage)
    LOG("OnWaitStageChanged: ", bFFAWaitStage)

    local tbPacket = {bWaitStage = bFFAWaitStage}
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_WAIT_STAGE_STATE_CHANGED, tbPacket)
end

local function OnTransportInfoChanged(self, rTransportInfo)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_TRANSPORT_INFO_NEW, rTransportInfo)
end

local function OnPoisonCircleInfoChanged(self, rPoisonCircleInfo)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_POISONCIRCLE_UPDATE, rPoisonCircleInfo)
end

-- 注册处理包
function BattleFFAGameStatePropertyProcessor:RegisterPackets()
    self:Bind(PropNameGameState.nFFACountDownEndTime,    self, OnCountDownEndTimeChanged,    true)
    self:Bind(PropNameGameState.nFFAAlivePlayerCount,    self, OnAlivePlayerCountChanged,    true)
    self:Bind(PropNameGameState.nFFATeamModeId,          self, OnTeamModeIdChanged,          true)
    self:Bind(PropNameGameState.nFFAProcessState,        self, OnStateChanged,               true)
    self:Bind(PropNameGameState.bFFAWaitStage,           self, OnWaitStageChanged,           true)
    self:Bind(PropNameGameState.rFFANewTransportInfos,   self, OnTransportInfoChanged,       true)
    self:Bind(PropNameGameState.rFFAPoisonCircleInfo,    self, OnPoisonCircleInfoChanged,    true)
end

return BattleFFAGameStatePropertyProcessor
