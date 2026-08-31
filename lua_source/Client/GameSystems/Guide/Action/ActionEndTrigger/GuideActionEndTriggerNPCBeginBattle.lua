-----------------------------------------------------
--File Name    : GuideActionEndTriggerNPCBeginBattle.lua
--Description  : 指引动作
-----------------------------------------------------
local luaclass                                  = require("luaclass")
local GuideActionEndTriggerBase                 = require("GuideActionEndTriggerBase")
local GuideActionEndTriggerNPCBeginBattle       = luaclass("GuideActionEndTriggerNPCBeginBattle", GuideActionEndTriggerBase)

local ClientEventDef        = require("ClientEventDef")
local GamePlayerSelfHelper  = require("GamePlayerSelfHelper")
-----------------------------------------------------

local function CheckNpcBeginFight(self, Owner, bNewBattleState)
    self:DebugLog("[NpcForceEndStep] CheckNpcBeginFight".. tostring(bNewBattleState)..",".. Owner.NpcAIStateComponent.rRiskAlertTargetInstanceId:Get()..", ".. GamePlayerSelfHelper:GetServerInstanceId())
    if bNewBattleState and Owner.NpcAIStateComponent.rRiskAlertTargetInstanceId:Get() == GamePlayerSelfHelper:GetServerInstanceId() then
        self:DebugLog("[NpcForceEndStep] CheckNpcBeginFight end!".. Owner:GetServerInstanceId())
        self:Triggered()
    end
end

local function CheckNpcNewAttackTarget(self, Owner, nNewAttackTarget)
    self:DebugLog("[NpcForceEndStep] CheckNpcNewAttackTarget".. nNewAttackTarget..","..", ".. GamePlayerSelfHelper:GetServerInstanceId())
    if nNewAttackTarget == GamePlayerSelfHelper:GetServerInstanceId() then
        self:DebugLog("[NpcForceEndStep] CheckNpcNewAttackTarget end!".. Owner:GetServerInstanceId())
        self:Triggered()
    end
end

function GuideActionEndTriggerNPCBeginBattle:BindEvent(tbParam)
    GuideActionEndTriggerNPCBeginBattle.super.BindEvent(self, tbParam)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NPC_BATTLE_STATE_CHANGED, self, CheckNpcBeginFight)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_NPC_ATTACKTARGET_CHANGED, self, CheckNpcNewAttackTarget)
end

return GuideActionEndTriggerNPCBeginBattle
