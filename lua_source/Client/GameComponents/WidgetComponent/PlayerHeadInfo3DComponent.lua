-----------------------------------------------------
--File Name    : PlayerHeadInfo3DComponent.lua
--Author       : lzheng
--Create Time  : 2019-09-28
--Description  : 头顶3d名字片逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local HeadInfoComponentBase = require("HeadInfoComponentBase")
local PlayerHeadInfo3DComponent = luaclass("PlayerHeadInfo3DComponent", HeadInfoComponentBase)

local UIDef = require("UIDef")
local PlayerHeadInfoHelper = require("PlayerHeadInfoHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")

PlayerHeadInfo3DComponent.szUEComponentName = "HeadInfoWorld"

local function SetWidgetVisibility(self, szName, bVisible)
    local pbWidget = self:GetWidgetPrefab(szName, false)
    if pbWidget and pbWidget.pWidgetRef then 
        self:SetVisibility(bVisible)
        pbWidget.pWidgetRef:SetVisibility(bVisible and ESlateVisibility_SelfHitTestInvisible or ESlateVisibility_Hidden)
        if self.pWidgetComponent then 
            self.pWidgetComponent:RequestRedraw()
        end
    end
end

local function CreateWidgetByName(self, szName)
    local pbWidget = self:GetWidgetPrefab(szName, false)
    if not pbWidget then
        return self:CreateWidgetPrefab(szName)
    end
    return nil
end

local function ShowPlayerName(self, bShow)
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_NAME_WIDGET)
    if bShow then
        if not pbWidget then
            self:CreateWidgetPrefab(UIDef.UP_NAME_WIDGET)
        end
        SetWidgetVisibility(self, UIDef.UP_NAME_WIDGET, true)
    elseif pbWidget then
        SetWidgetVisibility(self, UIDef.UP_NAME_WIDGET, false)
    end
end

function PlayerHeadInfo3DComponent:OnCreate(Owner, tbParams)
    PlayerHeadInfo3DComponent.super.OnCreate(self, Owner, tbParams)
end

function PlayerHeadInfo3DComponent:OnActorCreated(pUEActor)
    PlayerHeadInfo3DComponent.super.OnActorCreated(self, pUEActor)
    EventManager:BindEventMethod(ClientEventDef.EV_SHOW_PLAYER_NAME_HEAD, self, ShowPlayerName)
end

function PlayerHeadInfo3DComponent:OnActorDestroyed(pUEActor)
    PlayerHeadInfo3DComponent.super.OnActorDestroyed(self, pUEActor)
    EventManager:UnBindEventMethod(ClientEventDef.EV_SHOW_PLAYER_NAME_HEAD, self, ShowPlayerName)
end

function PlayerHeadInfo3DComponent:OnWidgetCreated( pWidgetRef )
    PlayerHeadInfo3DComponent.super.OnWidgetCreated(self, pWidgetRef)

    --设置3d widget ui在头顶的位置
    PlayerHeadInfoHelper.SetPlayerHeadInfoWorldPosition(self.Owner, self.pWidgetComponent)

    local bValidOther = not PlayerHeadInfoHelper.IsTeammate(self.Owner) and not self.Owner:IsDead()
    local bLocalSelf = self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf
    if bValidOther or bLocalSelf then
        local pWidget = CreateWidgetByName(self, UIDef.UP_PLAYER_HEAD_HP)
        SetWidgetVisibility(self, UIDef.UP_PLAYER_HEAD_HP, false)
        pWidget:SetHeadHpOwner(self.Owner)
    end

    --如需 添加新的 3d ui，写到下面， 判断条件写到 PlayerHeadInfoHelper 中
    self:SetVisibility(false)
    --AI 测试显示姓名
    if GlobalVariableSystem.bShowPlayerName then
        if (not PlayerHeadInfoHelper.IsTeammate(self.Owner) or self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf) and not self.Owner:IsDead() then
            self:CreateWidgetPrefab(UIDef.UP_NAME_WIDGET)
            SetWidgetVisibility(self, UIDef.UP_NAME_WIDGET, true)
        end
    end
end




return PlayerHeadInfo3DComponent