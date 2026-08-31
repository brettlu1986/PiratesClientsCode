-----------------------------------------------------
--File Name    : NpcAIStateComponent_C.lua
--Author       : Chen Jing
--Create Time  : 2019-03-28
--Description  : NPCAI显示信息
-----------------------------------------------------

local luaclass = require("luaclass")
local NpcAIStateComponent = require("NpcAIStateComponent")
local NpcAIStateComponent_C = luaclass("NpcAIStateComponent_C", NpcAIStateComponent)
local SelfTimerHelperClass = require("SelfTimerHelper")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local EventManager = require("EventManager")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local SelfEventHelperClass  = require("SelfEventHelper")

NpcAIStateComponent_C.tbNpcResetTimer = nil
NpcAIStateComponent_C.TimerHelper = nil
NpcAIStateComponent_C.nToastId = 1
NpcAIStateComponent_C.nResetTimeCount = 0
NpcAIStateComponent_C.EventHelper = nil
NpcAIStateComponent_C.tbAlertTargetInstanceIds = nil


-- luacheck: push ignore
local function LOG(...)
    log("CJ->NpcAIStateComponent_C:", ...)
end
-- luacheck: pop

local function GetNpcName(self)
    return self.Owner.szName
end

local function ClearNpcResetTimer(self)
    if self.tbNpcResetTimer then
        self.tbNpcResetTimer:Clear()
        self.tbNpcResetTimer = nil
        LOG("ClearNpcResetTimer")
    end
end

local function ShowNpcResetToast(self)
    local nResetTimeCount = self.nResetTimeCount
    local szNpcName = GetNpcName(self)
    if nResetTimeCount > 0 then
        UIUtils.ShowSpecialToast(self.nToastId, L10N:Format(UITextDef.NPC_RESET_NOTIFY, szNpcName,
        nResetTimeCount), nResetTimeCount, true)
    else
        UIUtils.ShowSpecialToast(self.nToastId, L10N:Format(UITextDef.NPC_RESET_NOTIFY_OVER ,szNpcName),  1, true)
    end
end

local function OnTickNpcReset(self)
    self.nResetTimeCount = self.nResetTimeCount - 1
    ShowNpcResetToast(self)
    if self.nResetTimeCount <= 0 then
        ClearNpcResetTimer(self)
    end
end

local function OnNotifyNpcReset(self, nNpcInstanceId , nTime)
    if nNpcInstanceId == self.Owner:GetServerInstanceId() then
        LOG("OnNotifyNpcReset", nTime)
        if nTime > 0 then
            self.nResetTimeCount = nTime
            if not self.tbNpcResetTimer then
                self.tbNpcResetTimer = self.TimerHelper:NewTimerMethod(self, OnTickNpcReset, 1, true)
            end
            ShowNpcResetToast(self)
        else
            local szNpcName = GetNpcName(self)
            UIUtils.ShowSpecialToast(self.nToastId, L10N:Format(UITextDef.NPC_RESET_NOTIFY_CANCEL, szNpcName),  1, true)
            ClearNpcResetTimer(self)
        end
    end
end


function NpcAIStateComponent_C:OnCreate(Owner, tbParams)
    NpcAIStateComponent_C.super.OnCreate(self, Owner, tbParams)
    local TimerHelper = SelfTimerHelperClass()
    local EventHelper = SelfEventHelperClass()
    self.TimerHelper  = TimerHelper
    self.EventHelper  = EventHelper
    self.tbNpcResetEvents = { }
    self.nToastId = self.Owner:GetServerInstanceId()
    LOG("toast id ", self.nToastId)
    EventHelper:RegisterEvent(ClientEventDef.EV_NPC_RESET_TIMER, self, OnNotifyNpcReset)
end

function NpcAIStateComponent_C:OnDestroy()
    self.EventHelper:UnregisterAll()
    NpcAIStateComponent_C.super.OnDestroy(self)
    if self.TimerHelper then
        self.TimerHelper:ClearAllTimer()
    end
end

function NpcAIStateComponent_C:OnActorCreated(pUEActor)
    NpcAIStateComponent_C.super.OnActorCreated(self, pUEActor)

end

function NpcAIStateComponent_C:OnBattleStateChanged(_Property, bNewBattleState)
    EventManager:OnFireEvent(ClientEventDef.EV_NPC_BATTLE_STATE_CHANGED, self.Owner, bNewBattleState)
    LOG("npc battle state changed to:",self.Owner.szName, bNewBattleState)
end

function NpcAIStateComponent_C:OnPropertyRiskAlertLevelChanged(_Property, nNewRiskAlertLevel)
    EventManager:OnFireEvent(ClientEventDef.EV_NPC_RISKALERTLEVEL_CHANGED, self.Owner, nNewRiskAlertLevel)
    LOG("npc risk alert level changed to:",self.Owner.szName, nNewRiskAlertLevel)
end

function NpcAIStateComponent_C:OnRiskAlertTargetChanged(_Property, nNewRiskAlertTarget)
    LOG("npc risk alert target changed to:",self.Owner.szName, nNewRiskAlertTarget)
    self.tbAlertTargetInstanceIds = self.tbAlertTargetInstanceIds or { }
    self.tbAlertTargetInstanceIds[2] = self.tbAlertTargetInstanceIds[1]
    self.tbAlertTargetInstanceIds[1] = nNewRiskAlertTarget
    EventManager:OnFireEvent(ClientEventDef.EV_NPC_RISKALERTTARGET_CHANGED, self.Owner, nNewRiskAlertTarget)
end

function NpcAIStateComponent_C:OnAttackTargetChanged(_Property, nNewAttackTarget)
    EventManager:OnFireEvent(ClientEventDef.EV_NPC_ATTACKTARGET_CHANGED, self.Owner, nNewAttackTarget)
    LOG("npc attack target changed to:",self.Owner.szName, nNewAttackTarget)
end

function NpcAIStateComponent_C:GetLastAlertTarget()
    if self.tbAlertTargetInstanceIds then
        return self.tbAlertTargetInstanceIds[2]
    end
end

function NpcAIStateComponent_C:GetAlertLevel()
    return self.rRiskAlertLevel:Get()
end

function NpcAIStateComponent_C:GetInBattleState()
    return self.rBattleState:Get()
end

return NpcAIStateComponent_C