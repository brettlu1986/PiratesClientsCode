-----------------------------------------------------
--File Name    : TimeCheaterCheck.lua
--Author       : Song Fuhao
--Create Time  : 2020-03-18
--Description  : 用于检测外挂使用
-----------------------------------------------------

local TimeCheaterCheck = {}

local Timer = require("Timer")
local Proto = require("DungeonCommonProtoNames")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local CheatingTypeDef = require("CheatingTypeDef")
local DungeonIni = require("DungeonIni")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")


local MIN_CHECK_INTERVAL = DungeonIni.tbCheaterCheck.nMinCheckInterval
local MAX_CHECK_INTERVAL = DungeonIni.tbCheaterCheck.nMaxCheckInterval
local TOLERANT_CHECK_INTERVAL = DungeonIni.tbCheaterCheck.nTolerantCheckInterval
local CHECK_COUNT_LIMIT = DungeonIni.tbCheaterCheck.nCheckCountLimit

---Server
TimeCheaterCheck.tbPlayerCheckDataMap = nil

---Client
TimeCheaterCheck.tbCheckTimer = nil
TimeCheaterCheck.nClientCheckInterval = 0

local function LOG(...)
    log('[CheaterCheckSystem]', ...)
end

-- local function LOG_WARNING(...)
--     logwarning('[CheaterCheckSystem]', ...)
-- end

local function LOG_ERROR(...)
    logerror('[CheaterCheckSystem]', ...)
end

---Server
---获得一个玩家的CheckData
local function GetPkayerCheckData(self, tbPlayer, bCreateIfNotFind)
    local tbPlayerCheckData = self.tbPlayerCheckDataMap[tbPlayer]
    if (not tbPlayerCheckData) and bCreateIfNotFind then
        tbPlayerCheckData = {}
        self.tbPlayerCheckDataMap[tbPlayer] = tbPlayerCheckData
    end
    return tbPlayerCheckData
end

---Server
---玩家重连后，需要重置上次Check时间，避免客户端互顶，导致发送间隔不对问题
local function OnPlayerRelogin(self, tbPlayer)
    local tbPlayerCheckData = GetPkayerCheckData(self, tbPlayer)
    if tbPlayerCheckData then
        tbPlayerCheckData.nLastPlayerCheckFrameTime = nil
        tbPlayerCheckData.nLastPlayerCheckRealTime = nil
    end
end

---Client
---获取一个随机的检测时间
local function GetRandomCheckTime()
    return math.random(MIN_CHECK_INTERVAL, MAX_CHECK_INTERVAL)
end

---Client
---向服务器请求检测
local function RequestCheckCheater(self)
    LOG("Request check cheater")
    local c2d_RequestCheckCheater = {
        check_interval = self.nClientCheckInterval
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_RequestCheckCheater, c2d_RequestCheckCheater)
end

---Client
---启动定时发包检测Timer
local function StartCheckTimer(self)
    RequestCheckCheater(self)

    self.nClientCheckInterval = GetRandomCheckTime()
    self.tbCheckTimer = Timer.NewTimerMethod(self, StartCheckTimer, self.nClientCheckInterval, false)
    LOG("Set next check timer, nClientCheckInterval =", self.nClientCheckInterval)
end

---Server
---记录一次玩家的欺骗行为
local function RecordCheating(self, tbPlayer)
    if not self.tbPlayerCheckDataMap then
        LOG_ERROR("RecordCheating, tbPlayerCheckDataMap is nil")
        return
    end

    local tbPlayerCheckData = GetPkayerCheckData(self, tbPlayer, true)
    if tbPlayerCheckData.nCheatingCount then
        tbPlayerCheckData.nCheatingCount = tbPlayerCheckData.nCheatingCount + 1
    else
        tbPlayerCheckData.nCheatingCount = 1
    end

    if tbPlayerCheckData.nCheatingCount >= CHECK_COUNT_LIMIT then
        EventManager:OnFireEvent(CommonEventDef.EV_CHEATER_CHECK, tbPlayer, CheatingTypeDef.TIME_CHECK)
    end
end

---Server
---由C2DDungeonPacketProcessor调用，处理客户端的外挂检测请求
function TimeCheaterCheck:HandleCheaterCheckRequest(tbPlayer, nClientCheckInterval)
    -- 开启服务器倍数模式之后，不进行检查（正常游戏中，不会开启倍数模式）
    local nGlobalTimeDilation = GameplayStatics.GetGlobalTimeDilation(GWorld)
    if nGlobalTimeDilation > 1 then
        return
    end

    local nCurrentFrameTime = getframebegintime()
    local nCurrentRealTime = getseconds()
    local tbPlayerCheckData = GetPkayerCheckData(self, tbPlayer, true)
    if tbPlayerCheckData.nLastPlayerCheckFrameTime and tbPlayerCheckData.nLastPlayerCheckRealTime then
        local nFrameTimeCheckDelta = nCurrentFrameTime - tbPlayerCheckData.nLastPlayerCheckFrameTime
        local nRealTimeCheckDelta = nCurrentRealTime - tbPlayerCheckData.nLastPlayerCheckRealTime
        if (nClientCheckInterval - nFrameTimeCheckDelta > TOLERANT_CHECK_INTERVAL)
        and (nClientCheckInterval - nRealTimeCheckDelta > TOLERANT_CHECK_INTERVAL) then
            -- 有一定的时间容错
            if (nFrameTimeCheckDelta > 0) then
                -- 理论上不会出现，服务器卡顿，导致同一帧里处理两个包
                LOG(tbPlayer.szName, ", check interval is illegal. nFrameTimeCheckDelta, nRealTimeCheckDelta, nClientCheckInterval =", nFrameTimeCheckDelta, nRealTimeCheckDelta, nClientCheckInterval)
                RecordCheating(self, tbPlayer)
            end
        elseif (tbPlayerCheckData.nCheatingCount and tbPlayerCheckData.nCheatingCount >= 1) then
            --如果没有连续的检测到时间非法，则有可能是弱网
            LOG(tbPlayer.szName, ", recount cheat count ", tbPlayerCheckData.nCheatingCount)
            tbPlayerCheckData.nCheatingCount = tbPlayerCheckData.nCheatingCount - 1
        end
    end
    tbPlayerCheckData.nLastPlayerCheckFrameTime = nCurrentFrameTime
    tbPlayerCheckData.nLastPlayerCheckRealTime = nCurrentRealTime
end

function TimeCheaterCheck:Init()
    if GlobalVariableSystem:IsDedicatedClient() then
        -- 只在纯单机模式下启用检测Timer
        StartCheckTimer(self)
    elseif GlobalVariableSystem:IsDedicatedServer() then
        self.tbPlayerCheckDataMap = {}
        EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerRelogin)
    end
end

function TimeCheaterCheck:Uninit()
    if self.tbCheckTimer then
        self.tbCheckTimer:Clear()
        self.tbCheckTimer = nil
    end
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerRelogin)
end

return TimeCheaterCheck