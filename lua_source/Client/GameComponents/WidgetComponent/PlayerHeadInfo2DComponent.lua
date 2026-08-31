-----------------------------------------------------
--File Name    : PlayerHeadInfo2DComponent.lua
--Author       : Ran Jie
--Create Time  : 2019-01-22
--Description  : 队友头顶信息UI
-----------------------------------------------------

local luaclass = require("luaclass")
local HeadInfoComponentBase = require("HeadInfoComponentBase")
local PlayerHeadInfo2DComponent = luaclass("PlayerHeadInfo2DComponent", HeadInfoComponentBase)

local UIDef = require("UIDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local TeamHeadNameSystem = require("TeamHeadNameSystem")
local TeamWatchClientHelper = require("TeamWatchClientHelper")
local HeadInfoDef = require("HeadInfoDef")


PlayerHeadInfo2DComponent.szUEComponentName = "HeadInfo"

function PlayerHeadInfo2DComponent:OnWidgetCreated( pWidgetRef )
    PlayerHeadInfo2DComponent.super.OnWidgetCreated(self, pWidgetRef)
    
    --logdebug("PlayerHeadInfo2DComponent:OnWidgetCreated,bTeammate,nInstanceId, name=", bTeammate, nInstanceId, self.Owner:GetName())
    local bPlayerOther = self.Owner:GetObjectType() == GameObjectTypeDef.PlayerOther
    if bPlayerOther then
        local nInstanceId = self.Owner:GetServerInstanceId()
        local bTeammate = TeamWatchClientHelper.IsInSameTeam(nInstanceId)
        if bTeammate and not self.Owner:IsDead() and TeamHeadNameSystem:IsShowTeamHead() then
            self:CreateTeammateHeadWidget()
            local tbMemberData = TeamHeadNameSystem:GetMemberObjByInstanceId(nInstanceId)
            if tbMemberData then
                local tbParams = {}
                tbParams.nType = HeadInfoDef.Type.NAME
                tbParams.nInstanceId = nInstanceId
                tbParams.nIndex = tbMemberData.nIndex
                tbParams.szName = tbMemberData.szName
                tbParams.nState = tbMemberData.nState
                self:RefreshHeadWidget(tbParams)
            end
        end
    end

end

function PlayerHeadInfo2DComponent:CreateTeammateHeadWidget()
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME, false)
    if not pbWidget then
        self:CreateWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME)
        return true
    end
    --self:SetVisibility(true)
    return false
end

function PlayerHeadInfo2DComponent:SetTeammateHeadWidgetVisibility(bVisible)
    self:SetWidgetVisibility(UIDef.UP_TEAM_HEAD_NAME, bVisible)
end

function PlayerHeadInfo2DComponent:RefreshHeadWidget(tbParams)
    self:RefreshWidget(UIDef.UP_TEAM_HEAD_NAME, tbParams)
end

function PlayerHeadInfo2DComponent:GetTeammateHeadWidget()
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME, false)
    return pbWidget
end

function PlayerHeadInfo2DComponent:HideTeammateName(bHideName)
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME, false)
    if pbWidget then
        pbWidget:HideName(bHideName)
    end
end

function PlayerHeadInfo2DComponent:HideTeamRelation(bHide)
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME, false)
    if pbWidget then
        pbWidget:HideRelation(bHide)
    end
end   

function PlayerHeadInfo2DComponent:HideDistanceAndState(bHide)
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME, false)
    if pbWidget then
        pbWidget:HideDistanceAndState(bHide)
    end
end

function PlayerHeadInfo2DComponent:HideTeammateDistance(bHideDistance)
    local pbWidget = self:GetWidgetPrefab(UIDef.UP_TEAM_HEAD_NAME, false)
    if pbWidget then
        pbWidget:HideDistance(bHideDistance)
    end
end

function PlayerHeadInfo2DComponent:IsReady()
    return self.pWidgetRef ~= nil
end


return PlayerHeadInfo2DComponent