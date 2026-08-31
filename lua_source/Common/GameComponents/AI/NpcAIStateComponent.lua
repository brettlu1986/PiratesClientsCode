-----------------------------------------------------
--File Name    : NpcAIStateComponent.lua
--Author       : Chen Jing
--Create Time  : 2019-03-28
--Description  : NPCAI显示信息
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local NpcAIStateComponent = luaclass("NpcAIStateComponent", GameComponentBaseClass)
local PropName = require("PropName")

NpcAIStateComponent.rBattleState = nil  --是否在战斗状态
NpcAIStateComponent.rRiskAlertLevel = nil   --警戒值百分比，到100就进入攻击状态
NpcAIStateComponent.rRiskAlertTargetInstanceId = nil    --警戒目标的InstanceId
NpcAIStateComponent.rNpcAttackTarget = nil  --攻击目标的InstanceId

-- luacheck: push ignore
local function LOG(...)
    log("CJ->NpcAIStateComponent:", ...)
end
-- luacheck: pop

-- property changed callback implement in client
function NpcAIStateComponent:OnBattleStateChanged(_Property, bNewBattleState)
    -- body
end

function NpcAIStateComponent:OnPropertyRiskAlertLevelChanged(_Property, nNewRiskAlertLevel)
    -- body
end

function NpcAIStateComponent:OnRiskAlertTargetChanged(_Property, nNewRiskAlertTarget)
    -- body
end

function NpcAIStateComponent:OnAttackTargetChanged(_Property, nNewAttackTarget)
    -- body
end

function NpcAIStateComponent:OnCreate(Owner, tbParams)
    NpcAIStateComponent.super.OnCreate(self, Owner, tbParams)
end

function NpcAIStateComponent:OnDestroy()
    NpcAIStateComponent.super.OnDestroy(self)
end

function NpcAIStateComponent:OnActorCreated(pUEActor)
    NpcAIStateComponent.super.OnActorCreated(self, pUEActor)
    local rComponent = self.Owner.CustomReplicationComponent
    self.rBattleState = rComponent:BindMethod(PropName.bInBattleState, false, self,
        self.OnBattleStateChanged, true)
    self.rRiskAlertLevel = rComponent:BindMethod(PropName.nRiskAlertLevel, 0, self,
        self.OnPropertyRiskAlertLevelChanged, true)
    self.rRiskAlertTargetInstanceId = rComponent:BindMethod(PropName.nRiskAlertTarget, 0, self,
        self.OnRiskAlertTargetChanged, true)
    self.rNpcAttackTarget = rComponent:BindMethod(PropName.nNpcAttackTarget, 0, self,
        self.OnAttackTargetChanged, true)
end



return NpcAIStateComponent