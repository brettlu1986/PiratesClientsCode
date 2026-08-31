local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBotBattleInfo = luaclass("ULWatchBotBattleInfo", UILogicBase)

local ClientEventDef = require("ClientEventDef")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local Proto = require("DungeonRepProtoNames")
local UIResourceDef = require("UIResourceDef")
local PoisonCircleSystem = require("PoisonCircleSystem")
local UISetUtils = require("UISetUtils")
local GameCoreWatchSystem = dynamic_require("GameCoreWatchSystem")

local DELAY_TIME = 1
local CLOCK_IMAGE_SIZE = 40
ULWatchBotBattleInfo.OneSecondTimer = nil
ULWatchBotBattleInfo.nTime = nil
ULWatchBotBattleInfo.nState = nil
ULWatchBotBattleInfo.nInstanceId = nil
ULWatchBotBattleInfo.bInWaitTime = false
ULWatchBotBattleInfo.szCurTimeRes = nil
ULWatchBotBattleInfo.ShowKillCountTimer = nil
ULWatchBotBattleInfo.WaitTimer = nil
ULWatchBotBattleInfo.tbWaitList = nil

local function DestroyTimer(self)
    if self.OneSecondTimer then
        self.TimerHelper:ClearTimer(self.OneSecondTimer)
        self.OneSecondTimer = nil
    end
    if self.ShowKillCountTimer then
        self.TimerHelper:ClearTimer(self.ShowKillCountTimer)
        self.ShowKillCountTimer = nil
    end
    if self.WaitTimer then
        self.TimerHelper:ClearTimer(self.WaitTimer)
        self.WaitTimer = nil
    end
end

local function OnOneSecondPass(self)
    if self.bInWaitTime then
        local nTime = math.max(self.nTime, 0)
        local txtCoolTime = self.pWidgetRef.cdtxtPoisonTimer
        local nMinute = math.floor(nTime / 60)
        local nSecond = nTime % 60
        local szTime = string.format("%02.0f:%02.0f", nMinute, nSecond)
        txtCoolTime:SetText(szTime)
    end
end

local function StartTimer(self)
    local pWidgetRef = self.pWidgetRef
    local txtCoolTime = pWidgetRef.cdtxtPoisonTimer
    local imgTimer = pWidgetRef.imgTimer
    self.bInWaitTime = true
    txtCoolTime:SetColorAndOpacity(UIResourceDef.COLOR.WHITE.SLATE_COLOR)
    if self.szCurTimeRes ~= UIResourceDef.FFA_REPARE_TIMER then 
        self.szCurTimeRes = UIResourceDef.FFA_REPARE_TIMER
        UISetUtils.SetImageBrushRes(imgTimer, self.szCurTimeRes:load(), false, true, CLOCK_IMAGE_SIZE, CLOCK_IMAGE_SIZE)
    end
    OnOneSecondPass(self)
end

local function StopTimer(self, bClock)
    local pWidgetRef = self.pWidgetRef
    local txtCoolTime = pWidgetRef.cdtxtPoisonTimer
    local imgTimer = pWidgetRef.imgTimer
    self.bInWaitTime = false
    txtCoolTime:SetText("--:--")
    if bClock then
        if self.szCurTimeRes ~= UIResourceDef.FFA_REPARE_TIMER then 
            self.szCurTimeRes = UIResourceDef.FFA_REPARE_TIMER
            UISetUtils.SetImageBrushRes(imgTimer, self.szCurTimeRes:load(), false, true, CLOCK_IMAGE_SIZE, CLOCK_IMAGE_SIZE)
        end
    else
        if self.szCurTimeRes ~= UIResourceDef.FFA_POISON_CIRCLE_TIMER then
            self.szCurTimeRes = UIResourceDef.FFA_POISON_CIRCLE_TIMER
            UISetUtils.SetImageBrushRes(imgTimer, self.szCurTimeRes:load())
        end
    end
end

local function OnFFAPoisonCircleTimerUpdate(self, tbInfo)
    self.nTime = tbInfo ~= nil and tbInfo.nEndTime - GlobalVariableSystem_C:GetLocalTime() or 0
    self.nState = tbInfo ~= nil and tbInfo.nState
    self.nInstanceId = tbInfo ~= nil and tbInfo.nPoisonCircleId
    if self.nState == Proto.rFFAPoisonCircleInfo_EStageState.WAIT then
        StartTimer(self)
    else
        StopTimer(self, false)
    end
end

local function OnFFARepairStepTimer(self, nTime)
    if nTime > 0 then
        self.nTime = nTime
        StartTimer(self)
    else
        StopTimer(self, true)
    end
end

local function OnRecvRepairStepRemainTime(self, rStepRemainTime)
    OnFFARepairStepTimer(self, rStepRemainTime.nTime)
end

local function OnFFATransportChanged(self, nState)
    OnFFARepairStepTimer(self, 0)
end

local function OnFFAInfoChanged(self, rInfo)
    self.pWidgetRef.txtRemainPlayer:SetText(rInfo.nAlivePlayerCount)
end

local function InitInterface(self)
    if GameCoreWatchSystem.tbFFAInfo then 
        self.pWidgetRef.txtRemainPlayer:SetText(GameCoreWatchSystem.tbFFAInfo.nAlivePlayerCount)
    end
    local tbInfo = PoisonCircleSystem:GetPoisonCircleInfo()
    OnFFAPoisonCircleTimerUpdate(self, tbInfo)
end

function ULWatchBotBattleInfo:OnCreate()
    if self.tbWaitList == nil then
        self.tbWaitList = {}
    end
    self.OneSecondTimer = self.TimerHelper:NewTimerMethod(self, function()
            if self.nTime ~= nil then
                self.nTime = self.nTime - DELAY_TIME
            end 
            OnOneSecondPass(self) 
        end, DELAY_TIME, true)
end

function ULWatchBotBattleInfo:OnShow()
    InitInterface(self)
end


function ULWatchBotBattleInfo:RefreshInfo(tbBotState)
    local nKills = tbBotState.state.kills
    if nKills == nil then  
        nKills = 0
    end
    self.pWidgetRef.txtKillPlayer:SetText(nKills)
end

function ULWatchBotBattleInfo:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_TIMERUPDATE, self, OnFFAPoisonCircleTimerUpdate)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvRepairStepRemainTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)    
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_INFO_CHANGED, self, OnFFAInfoChanged)

    
end

function ULWatchBotBattleInfo:OnDestroy()
    DestroyTimer(self)
end

return ULWatchBotBattleInfo