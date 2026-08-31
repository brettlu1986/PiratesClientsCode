-----------------------------------------------------
--File Name    : ULBattleInfo.lua
--Description  : ffa战斗基本信息，击杀人数、剩余人数等
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULBattleInfo = luaclass("ULBattleInfo", UILogicBase)

local ClientEventDef = require("ClientEventDef")
local GlobalVariableSystem_C = require("GlobalVariableSystem_C")
local Proto = require("DungeonRepProtoNames")
local UIResourceDef = require("UIResourceDef")
local PoisonCircleSystem = require("PoisonCircleSystem")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local EventManager = require("EventManager")

local SHOW_KILL_COUNT_TIME = 3
local SHOW_KILL_COUNT_MIN_TIME = 1
local DELAY_TIME = 1
local CLOCK_IMAGE_SIZE = 40
ULBattleInfo.OneSecondTimer = nil
ULBattleInfo.nTime = nil
ULBattleInfo.nState = nil
ULBattleInfo.nInstanceId = nil
ULBattleInfo.bInWaitTime = false
ULBattleInfo.szCurTimeRes = nil
ULBattleInfo.ShowKillCountTimer = nil
ULBattleInfo.WaitTimer = nil
ULBattleInfo.tbWaitList = nil

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
        if nTime <= 10 and nTime > 0 and self.nState == Proto.rFFAPoisonCircleInfo_EStageState.WAIT then
            EventManager:OnFireEvent(ClientEventDef.EV_FFA_POISONCIRCLE_LAST_TEN_SEC)
        elseif nTime <= 0 and self.nState == Proto.rFFAPoisonCircleInfo_EStageState.WAIT then
            EventManager:OnFireEvent(ClientEventDef.EV_FFA_POISONCIRCLE_TIME_UP)
        end
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
    self.nTime = tbInfo ~= nil and tbInfo.nEndTime - GlobalVariableSystem_C:GetServerTimeUtc() or 0
    self.nState = tbInfo ~= nil and tbInfo.nState or nil
    log("ULBattleInfo:OnFFAPoisonCircleTimerUpdate", self.nState)
    self.nInstanceId = tbInfo ~= nil and tbInfo.nPoisonCircleId
    if self.nState == Proto.rFFAPoisonCircleInfo_EStageState.WAIT then
        StartTimer(self)
    else
        StopTimer(self, false)
    end
end

local function OnFFARepairStepTimer(self, nTime)
    -- log("ULBattleInfo:OnFFARepairStepTimer", self.nState)
    -- if self.nState then
    --     -- 断线重连后，先收到毒圈后收到stepremaintime,所以收到毒圈信息后，不再理睬stepremaintime
    --     return
    -- end
    -- if nTime > 0 then
    --     self.nEndTime = nTime + GlobalVariableSystem_C:GetLocalTime()
    --     StartTimer(self)
    -- else
    --     StopTimer(self, true)
    -- end
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
    if tbPacket.nKillCount == 0 then
        return
    end
    self.pWidgetRef.txtKillPlayer:SetText(tbPacket.nKillCount)
    if self.ShowKillCountTimer then
        table.insert(self.tbWaitList, tbPacket.nKillCount)
    else
        ShowFFAToastKill(self, tbPacket.nKillCount)
    end
end

local function InitInterface(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtRemainPlayer:SetText("0")
    pWidgetRef.txtKillPlayer:SetText("0")
    pWidgetRef.txtToastKill:SetVisibility(ESlateVisibility.Collapsed)

    local tbInfo = PoisonCircleSystem:GetPoisonCircleInfo()
    OnFFAPoisonCircleTimerUpdate(self, tbInfo)
end

function ULBattleInfo:OnCreate()
    if self.tbWaitList == nil then
        self.tbWaitList = {}
    end
    self.OneSecondTimer = self.TimerHelper:NewTimerMethod(self, function()
            if self.nTime ~= nil then
                self.nTime = self.nTime - DELAY_TIME
            end
            OnOneSecondPass(self) 
        end,
        DELAY_TIME, true)
end

function ULBattleInfo:OnShow()
    InitInterface(self)
end

function ULBattleInfo:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_POISONCIRCLE_TIMERUPDATE, self, OnFFAPoisonCircleTimerUpdate)
    EventHelper:RegisterEvent(ClientEventDef.EV_GAME_STATE_ON_RECV_STEP_REMAIN_TIME, self, OnRecvRepairStepRemainTime)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_STATE_CHANGED, self, OnFFATransportChanged)    
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_INFO_CHANGED, self, OnFFAInfoChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_KILLINFO, self, OnFFAKillInfo)
end

function ULBattleInfo:OnDestroy()
    DestroyTimer(self)
end

return ULBattleInfo