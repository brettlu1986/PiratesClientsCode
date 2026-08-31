-----------------------------------------------------
--File Name    : GuideTriggerNpcBattleState.lua
--Description  : 指引触发
-----------------------------------------------------
local luaclass = require("luaclass")
local GuideTrigger = require("GuideTrigger")
local GuideTriggerNpcBattleState = luaclass("GuideTriggerNpcBattleState",GuideTrigger)

local ClientEventDef = require("ClientEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GuideSharedInfoHelper = require("GuideSharedInfoHelper")

local function CheckBattleStateTrigger(self, nTargetInstanceId)
    self:DebugLog("GuideTriggerNpcBattleState:CheckBattleStateTrigger,nTargetInstanceId=",nTargetInstanceId)
    if nTargetInstanceId ~= GamePlayerSelfHelper:GetServerInstanceId() then
        return false
    end
    self:DebugLog("GuideTriggerNpcBattleState:CheckBattleStateTrigger,=",nTargetInstanceId,GamePlayerSelfHelper:GetServerInstanceId())
    return true
end

local function OnNPCBattleStateChanged(self, tbGameObject, bBattleState)
    self:DebugLog("GuideTriggerNpcBattleState:OnNPCBattleStateChanged,bBattleState=",tbGameObject:GetName(),bBattleState)
    if not bBattleState then
        return
    end
    local nTargetInstanceId = tbGameObject.NpcAIStateComponent.rRiskAlertTargetInstanceId:Get()
    if(CheckBattleStateTrigger(self, nTargetInstanceId))then
        GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, tbGameObject)
        self:Trigger()
    end
end

local function OnNpcAttackTargetChanged(self, tbGameObject, nNewAttackTarget)
    self:DebugLog("GuideTriggerNpcBattleState:OnNpcAttackTargetChanged,nNewAttackTarget=",tbGameObject:GetName(),nNewAttackTarget)
    if(CheckBattleStateTrigger(self, nNewAttackTarget))then
        GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, tbGameObject)
        self:Trigger()
    end
end

local function CheckAllNpcBattleState(self)
    local tbObjects = GameObjectSystem:GetAllGameObjects()
    for k, v in pairs(tbObjects) do
        local nObjType = v:GetObjectType()
        if nObjType == GameObjectTypeDef.Npc then
            if v.NpcAIStateComponent then
                local nTargetInstanceId = v.NpcAIStateComponent.rNpcAttackTarget:Get()
                if CheckBattleStateTrigger(self, nTargetInstanceId) then
                    GuideSharedInfoHelper.FillObjectNameToSharedInfo(self, v)
                    self:Trigger()
                end
            end
        end
    end
end

--override
function GuideTriggerNpcBattleState:Begin()
    GuideTriggerNpcBattleState.super.Begin(self)
    CheckAllNpcBattleState(self)
end

function GuideTriggerNpcBattleState:BindEvent(EventHelper)
    GuideTriggerNpcBattleState.super.BindEvent(self, EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_NPC_BATTLE_STATE_CHANGED, self, OnNPCBattleStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_NPC_ATTACKTARGET_CHANGED, self, OnNpcAttackTargetChanged)
end

-- function GuideTriggerNpcBattleState:IsTrigger()
--     self.bIsTrigger = CheckBattleStateTrigger(self)
--     return self.bIsTrigger
-- end

return GuideTriggerNpcBattleState
