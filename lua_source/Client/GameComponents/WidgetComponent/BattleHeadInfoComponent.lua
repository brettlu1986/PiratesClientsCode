-----------------------------------------------------
--File Name    : HeadInfoComponent.lua
--Author       : Song Fuhao
--Create Time  : 2017-03-02
--Description  : NPC头顶信息UI
-----------------------------------------------------

local luaclass = require("luaclass")
local HeadInfoComponentBase = require("HeadInfoComponentBase")
local BattleHeadInfoComponent = luaclass("BattleHeadInfoComponent", HeadInfoComponentBase)
local UIDef = require("UIDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GameNpcType = require("GameNpcType")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- local EventManager = require("EventManager")
-- -- local ClientEventDef = require("ClientEventDef")
-- local DGCollectionTable = require("DungeonCollectionTable")
-- local CommonEventDef = require("CommonEventDef")

BattleHeadInfoComponent.nMiddleDistanceId = -1
BattleHeadInfoComponent.nMinDistanceId = -1
BattleHeadInfoComponent.nMaxDistanceId = -1

function BattleHeadInfoComponent:OnWidgetCreated( pWidgetRef )
    BattleHeadInfoComponent.super.OnWidgetCreated(self, pWidgetRef)
    -- self:CreateWidgetPrefab(UIDef.UP_DIALOG_WIDGET)   
    -- self:CreateWidgetPrefab(UIDef.UP_NPC_HEAD_ICON_WIDGET)   
    local nHeadIcon = 0
	if self.Owner.tbNpcTemplateData then 
		nHeadIcon = self.Owner.tbNpcTemplateData.nHeadIcon
	end 
	if nHeadIcon > 0 then    
        self:CreateWidgetPrefab(UIDef.UP_NPC_HEAD_ICON_WIDGET)
    end     
    --在战斗副本中有采集物所以不初始化相关信息
    if self.Owner:GetObjectType() == GameObjectTypeDef.Npc and 
       (self.Owner:GetNpcType() ==  GameNpcType.BattleCollection or 
       self.Owner:GetNpcType() ==  GameNpcType.BattleHumanNpc) then
        self:CreateWidgetPrefab(UIDef.UP_NAME_WIDGET)
        if GlobalVariableSystem:IsInDungeon() and self.Owner:GetNpcType() ==  GameNpcType.BattleCollection then
            self:SetWidgetVisibility(UIDef.UP_NAME_WIDGET,false)
            self:CreateCollectionHeadDel()
        end
    else
        self:CreateWidgetPrefab(UIDef.UP_BATTLE_HEAD_INFO)
    end
end 

function BattleHeadInfoComponent:DestoryWidget()
    BattleHeadInfoComponent.super.DestoryWidget(self)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_ACTOR_AREA_ENTER, self, self.OnActorEnterArea)
    -- EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_ACTOR_AREA_LEAVE, self, self.OnActorLeaveArea)
    -- local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorAreaTriggerManager()
    -- if self.nMiddleDistanceId ~= -1 then 
    --     AreaTriggerManager:DestroyActorTrigger(self.nMiddleDistanceId)
    --     self.nMiddleDistanceId = -1
    -- end 
    -- if self.nMinDistanceId ~= -1 then 
    --     AreaTriggerManager:DestroyActorTrigger(self.nMinDistanceId)
    --     self.nMinDistanceId = -1
    -- end 
end

function BattleHeadInfoComponent:CreateCollectionHeadDel()
    -- local pWidgetComponent = self.Owner.pUEActor[self.szUEComponentName]
    -- local AreaTriggerManager = ClientShell.GetClient(GWorld):GetActorAreaTriggerManager()
    -- local tbPlayerSelf = GamePlayerSelfHelper:Get()
    -- local CollectionTable = DGCollectionTable:GetTemplate(self.Owner.nTemplateId)
    -- if CollectionTable ~= nil then
    --     self.nMiddleDistanceId = AreaTriggerManager:CreateActorTrigger(tbPlayerSelf.pUEActor, self.Owner.pUEActor, CollectionTable.nshowiconDistance)
    --     self.nMinDistanceId = AreaTriggerManager:CreateActorTrigger(tbPlayerSelf.pUEActor, self.Owner.pUEActor, CollectionTable.nshowAllDistance)
    --     EventManager:BindEventMethod(CommonEventDef.EV_GAME_ACTOR_AREA_ENTER, self, self.OnActorEnterArea)
    --     EventManager:BindEventMethod(CommonEventDef.EV_GAME_ACTOR_AREA_LEAVE, self, self.OnActorLeaveArea)
    --     pWidgetComponent.MinDistance = CollectionTable.nshowAllDistance
    --     pWidgetComponent.MaxDistance = CollectionTable.nshowiconDistance
    --     pWidgetComponent.ScaleRate = CollectionTable.nshowiconDistance/2
    -- else
    --     logerror("Can't found dungeon_collection.tab ID", self.Owner.nTemplateId)
    -- end
end

function BattleHeadInfoComponent:OnActorEnterArea(tbGameObject, nAreaID)
    if self.nMiddleDistanceId == nAreaID then
        self:SetWidgetVisibility(UIDef.UP_NAME_WIDGET,false)
    elseif self.nMinDistanceId == nAreaID then
        self:SetWidgetVisibility(UIDef.UP_NAME_WIDGET,true)
    end
end 

function BattleHeadInfoComponent:OnActorLeaveArea(tbGameObject, nAreaID)
    if self.nMiddleDistanceId == nAreaID then
        self:SetWidgetVisibility(UIDef.UP_NPC_HEAD_ICON_WIDGET,false)
    elseif self.nMinDistanceId == nAreaID then
         self:SetWidgetVisibility(UIDef.UP_NAME_WIDGET,false)
    end
end 


return BattleHeadInfoComponent