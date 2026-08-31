-----------------------------------------------------
--File Name    : HeadInfoComponent.lua
--Author       : Song Fuhao
--Create Time  : 2017-03-02
--Description  : NPC头顶信息UI
-----------------------------------------------------

local luaclass = require("luaclass")
local HeadInfoComponentBase = require("HeadInfoComponentBase")
local NpcHeadInfoComponent = luaclass("NpcHeadInfoComponent", HeadInfoComponentBase)

local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local PlayerHeadInfoHelper = require("PlayerHeadInfoHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")

NpcHeadInfoComponent.szUEComponentName = "HeadInfoWorld"

local NAME_UNKNOWN = "unknown"
local NPC_PEACE_STATE = 1

local function OnNPCBattleStateChanged(self, tbGameObj, bBattleState)
    if self.Owner:GetServerInstanceId() == tbGameObj:GetServerInstanceId() then
        local NpcAIStateComponent = tbGameObj.NpcAIStateComponent
        local tbParams = {}
        tbParams.nAlertLevel  = NpcAIStateComponent:GetAlertLevel()
        tbParams.bBattleState = NpcAIStateComponent:GetInBattleState()
        self:RefreshWidget(UIDef.UP_NPC_HEAD_NAME, tbParams)
    end
end

local function OnNPCAlertValueChanged(self, tbGameObj, nAlertLevel)
    if self.Owner:GetServerInstanceId() == tbGameObj:GetServerInstanceId() then
        local NpcAIStateComponent = tbGameObj.NpcAIStateComponent
        local tbParams = {}
        tbParams.nAlertLevel  = NpcAIStateComponent:GetAlertLevel()
        tbParams.bBattleState = NpcAIStateComponent:GetInBattleState()
        self:RefreshWidget(UIDef.UP_NPC_HEAD_NAME, tbParams)
    end
end

local function SetWidgetVisibility(self, szName, bVisible)
    local pbWidget = self:GetWidgetPrefab(szName, false)
    if pbWidget and pbWidget.pWidgetRef then
        if bVisible then
            self:SetVisibility(true)
        end
        pbWidget.pWidgetRef:SetVisibility(bVisible and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Hidden)
        if self.pWidgetComponent then
            self.pWidgetComponent:RequestRedraw()
        end
    end
end

local function OnPawnDead(self, tbGameObject)
    if tbGameObject:GetObjectType() == GameObjectTypeDef.Npc and tbGameObject == self.Owner then
        self:SetVisibility(false)
    end
end

local function RegisterEvent(self)
    local EventHelper = self.EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_NPC_BATTLE_STATE_CHANGED, self, OnNPCBattleStateChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_NPC_RISKALERTLEVEL_CHANGED, self, OnNPCAlertValueChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnPawnDead)
end

function NpcHeadInfoComponent:OnActorDestroyed(pUEActor)
    NpcHeadInfoComponent.super.OnActorDestroyed(self, pUEActor)
end

function NpcHeadInfoComponent:OnWidgetCreated( pWidgetRef )
    NpcHeadInfoComponent.super.OnWidgetCreated(self, pWidgetRef)
    -- self:CreateWidgetPrefab(UIDef.UP_QUEST_WIDGET)

    --统一设置 npc 3d ui的位置
    PlayerHeadInfoHelper.SetNpcHeadInfoWorldPosition(self.Owner, self.pWidgetComponent)

    if self.Owner.szName ~= NAME_UNKNOWN and not self.Owner:IsDead() then
        self:CreateWidgetPrefab(UIDef.UP_NPC_HEAD_NAME)

        --为可以受伤的npc创建血条
        local tbNpcTemplateData = self.Owner:GetTemplateData()
        if tbNpcTemplateData and tbNpcTemplateData.nInitState ~= NPC_PEACE_STATE then
            local pbWidget = self:CreateWidgetPrefab(UIDef.UP_PLAYER_HEAD_HP)
            SetWidgetVisibility(self, UIDef.UP_PLAYER_HEAD_HP, false)
            pbWidget:SetHeadHpOwner(self.Owner)
        end
    end

    local nHeadIcon = 0
	if self.Owner.tbNpcTemplateData then
		nHeadIcon = self.Owner.tbNpcTemplateData.nHeadIcon
	end
	if nHeadIcon > 0 and not self.Owner:IsDead() then
        self:CreateWidgetPrefab(UIDef.UP_NPC_HEAD_ICON_WIDGET)
    end

    RegisterEvent(self)
end

return NpcHeadInfoComponent