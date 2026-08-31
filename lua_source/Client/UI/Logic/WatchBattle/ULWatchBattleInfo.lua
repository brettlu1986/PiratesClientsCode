-----------------------------------------------------
--File Name    : ULBattleInfo.lua
--Description  : ffa战斗基本信息，击杀人数、剩余人数等
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULWatchBattleInfo = luaclass("ULWatchBattleInfo", UILogicBase)

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ClientEventDef = require("ClientEventDef")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local Proto = require("DungeonRepProtoNames")
local UIResourceDef = require("UIResourceDef")
local PoisonCircleSystem = require("PoisonCircleSystem")
local UISetUtils = require("UISetUtils")
local WatchBattleSystem = require("WatchBattleSystem_C")
local CommonEventDef = require("CommonEventDef")
local L10N = require("L10N")

local SHOW_KILL_COUNT_TIME = 3
local SHOW_KILL_COUNT_MIN_TIME = 1
local DELAY_TIME = 1
local CLOCK_IMAGE_SIZE = 40
ULWatchBattleInfo.OneSecondTimer = nil
ULWatchBattleInfo.nTime = nil
ULWatchBattleInfo.nState = nil
ULWatchBattleInfo.nInstanceId = nil
ULWatchBattleInfo.bInWaitTime = false
ULWatchBattleInfo.szCurTimeRes = nil
ULWatchBattleInfo.ShowKillCountTimer = nil
ULWatchBattleInfo.WaitTimer = nil
ULWatchBattleInfo.tbWaitList = nil

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
    self.pWidgetRef.txtNumLeft:SetText(rInfo.nAlivePlayerCount)
    self.pWidgetRef.txtRemainPlayer:SetText(rInfo.nAlivePlayerCount)
end

local function ClearShowKillCountTimer(self)
    if self.ShowKillCountTimer then
        self.TimerHelper:ClearTimer(self.ShowKillCountTimer)
        self.ShowKillCountTimer = nil
    end
end

local function FinishShowKillCount(self)
    self.pWidgetRef.txtToastKill:SetVisibility(ESlateVisibility.Collapsed)
    ClearShowKillCountTimer(self)
    if self.WaitTimer then
        self.TimerHelper:ClearTimer(self.WaitTimer)
        self.WaitTimer = nil
    end
end

local function ShowFFAToastKill(self, nKillCount)
    self.pWidgetRef.txtToastKill:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local szTxt = L10N:Format(UISetUtils.GetL10NTextByKey("FFA_UI_KILL_COUNT"), nKillCount)  
    self.pWidgetRef.txtToastKill:SetText(szTxt)
    ClearShowKillCountTimer(self)    
    self.ShowKillCountTimer = self.TimerHelper:NewTimerMethod(self, FinishShowKillCount, SHOW_KILL_COUNT_TIME, false)
    local CheckDelayShow = function()
        if self.tbWaitList and #self.tbWaitList > 0 then
            local nCount = self.tbWaitList[1]
            table.remove(self.tbWaitList, 1)
            ShowFFAToastKill(self, nCount)
        end
    end
    if self.WaitTimer == nil then
        self.WaitTimer = self.TimerHelper:NewTimerMethod(self, CheckDelayShow, SHOW_KILL_COUNT_MIN_TIME, true)
    end
end

local function OnFFAKillInfo(self, tbPacket)
    self.pWidgetRef.txtNumDefeat:SetText(tbPacket.nKillCount)
    self.pWidgetRef.txtKillPlayer:SetText(tbPacket.nKillCount)
    if self.ShowKillCountTimer then
        table.insert(self.tbWaitList, tbPacket.nKillCount)
    else
        ShowFFAToastKill(self, tbPacket.nKillCount)
    end
end

local function InitInterface(self)
    local pWidgetRef = self.pWidgetRef
    -- pWidgetRef.txtRemainPlayer:SetText("0")
    -- pWidgetRef.txtKillPlayer:SetText("0")
    pWidgetRef.txtToastKill:SetVisibility(ESlateVisibility.Collapsed)

    local tbInfo = PoisonCircleSystem:GetPoisonCircleInfo()
    OnFFAPoisonCircleTimerUpdate(self, tbInfo)
end

function ULWatchBattleInfo:OnCreate()
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

function ULWatchBattleInfo:OnShow()
    InitInterface(self)
end

function ULWatchBattleInfo:RefreshInfoCount()
    local tbGameState = BattleGameModeSystem:GetGameState()
    local survive_count = 0
    if tbGameState and tbGameState.nFFAAlivePlayerCount then
        survive_count = tbGameState.nFFAAlivePlayerCount:Get()
    end

    local pWidgetRef = self.pWidgetRef
    local tbWatchInfo = WatchBattleSystem.tbWatchMateInfo
    pWidgetRef.txtNumDefeat:SetText(tbWatchInfo.kill_count)
    pWidgetRef.txtNumLeft:SetText(survive_count)
    
    pWidgetRef.txtRemainPlayer:SetText(survive_count)
    pWidgetRef.txtKillPlayer:SetText(tbWatchInfo.kill_count)
end

function ULWatchBattleInfo:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_TIMERUPDATE, self, OnFFAPoisonCircleTimerUpdate)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvRepairStepRemainTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)    
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_INFO_CHANGED, self, OnFFAInfoChanged)
    --EventHelper:RegisterEvent(ClientEventDef.EV_FFA_KILLINFO, self, OnFFAKillInfo)

    EventHelper:RegisterEvent(CommonEventDef.EV_MATE_KILL_INFO_CHANGED, self, OnFFAKillInfo)
    
end

function ULWatchBattleInfo:OnDestroy()
    DestroyTimer(self)
end

return ULWatchBattleInfo