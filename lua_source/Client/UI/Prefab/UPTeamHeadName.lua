-----------------------------------------------------
--File Name    : UPTeamHeadName.lua
--Author       : Ran Jie
--Create Time  : 2019-01-22
-----------------------------------------------------
local luaclass = require ("luaclass")
local UPWidgetBase = require("UPWidgetBase")
local UPTeamHeadName = luaclass("UPTeamHeadName", UPWidgetBase)
--local GameObjectTypeDef = require("GameObjectTypeDef")
local UIResourceDef = require("UIResourceDef")
local DCProto = require("DungeonCommonProtoNames")
local UISetUtils = require("UISetUtils")
local HeadInfoDef = require("HeadInfoDef")
local L10N = require("L10N")
local FriendRelationShipDataTable = require("FriendRelationShipDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamWatchClientHelper = require("TeamWatchClientHelper")

local SELF_HIT_TEST_IN_VISIBLE = ESlateVisibility.SelfHitTestInvisible
local HIT_TEST_IN_VISIBLE = ESlateVisibility.HitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed
local SINGLE = 1

function UPTeamHeadName:OnWidgetCreated()
    local pWidgetRef = self.pWidgetRef
    local Collapsed, Visible = ESlateVisibility.Collapsed, ESlateVisibility.Visible
    if  self.OwnerGameObject.szName ==  "unknown" then 
        self.pWidgetRef.txtName:SetText("")
        self.pWidgetRef:SetVisibility(Collapsed)
    else 
        self.pWidgetRef:SetVisibility(Visible)
        self.pWidgetRef.txtName:SetText(self.OwnerGameObject.szName)
    end 
    -- if self.OwnerGameObject.ObjectType ==  GameObjectTypeDef.PlayerOther then
    --     pWidgetRef.bdrDistanceBg:SetVisibility(HitTestInvisible)
    -- else
        pWidgetRef.bdrDistanceBg:SetVisibility(Collapsed)
    --end

    local nTeamMode = TeamWatchClientHelper.GetTeamCount()
    pWidgetRef.ovlStateExParent:SetVisibility(SINGLE == nTeamMode and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE)
    pWidgetRef.ovlState:SetVisibility(SINGLE == nTeamMode and COLLAPSED or HIT_TEST_IN_VISIBLE)
end 


function UPTeamHeadName:RefreshWidget(tbParams)
    if not tbParams then
        logerror("UPTeamHeadName:RefreshWidget, tbParams is nil, instance id=",self.OwnerGameObject:GetServerInstanceId())
    end

    local pWidgetRef = self.pWidgetRef
    if tbParams.nType == HeadInfoDef.Type.NAME then  
        if not tbParams or not tbParams.nIndex or not tbParams.nState then
            logerror("UPTeamHeadName:RefreshWidget, tbParams or index or state is nil, instance id=",self.OwnerGameObject:GetServerInstanceId())
        end

        pWidgetRef:SetVisibility(ESlateVisibility.Visible)
        
        local nIndex = tbParams.nIndex
        local nState = tbParams.nState
        pWidgetRef.txtName:SetVisibility(SELF_HIT_TEST_IN_VISIBLE)
        pWidgetRef.ovlStateEx:SetVisibility(COLLAPSED)
        pWidgetRef.txtName:SetText(tbParams.szName)
        local txtNameNumber = pWidgetRef.txtNameNumber
        local pColor = UIResourceDef.TEAM_INDEX_COLOR_TRANSPARENT[nIndex]
        if pColor then
            pWidgetRef.imgStateIcon:SetColorAndOpacity(pColor)
        end
        if nState == DCProto.TeamInfo_EState.NONE then 
            txtNameNumber:SetText(nIndex)
            txtNameNumber:SetVisibility(SELF_HIT_TEST_IN_VISIBLE)
        else
            txtNameNumber:SetVisibility(COLLAPSED)
        end
        local szIcon = UIResourceDef.TEAM_MEMBER_STATE_ICON[nState]
        if szIcon and szIcon ~= "" then
            local pIconObj = szIcon:load()
            if pIconObj then
                UISetUtils.SetImageBrushRes(pWidgetRef.imgStateIcon, pIconObj)
            else
                logerror("UPTeamHeadName:RefreshWidget, pIconObj is nil", nState, szIcon)
            end
        else
            logerror("UPTeamHeadName:RefreshWidget, szIcon is nil or empty", nState, szIcon)
        end

        
        local nTeamMode = TeamWatchClientHelper.GetTeamCount()
        pWidgetRef.ovlStateExParent:SetVisibility(SINGLE == nTeamMode and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE)
        pWidgetRef.ovlState:SetVisibility(SINGLE == nTeamMode and COLLAPSED or HIT_TEST_IN_VISIBLE)
    elseif tbParams.nType == HeadInfoDef.Type.RELATION then
        local PlayerSelf = GamePlayerSelfHelper:Get()
        local BattleTeamComponent = PlayerSelf.BattleTeamComponent

        self:HideRelation(false)
        local nRelationLevel = tbParams.tbInfo.nLevel
        local nRelationType = tbParams.tbInfo.nType
        pWidgetRef.txtRelationLevel:SetText(nRelationLevel)
        UISetUtils.SetBorderBrushRes(pWidgetRef.bdrRelation, UIResourceDef.FRIEND_RELATION_IMG[nRelationType]:load())

        local nInstanceId = BattleTeamComponent:GetInstanceIdByPlayerId(tbParams.tbInfo.nTargetPlayerId) 
        if nInstanceId then  
            local tbMemberInfo = BattleTeamComponent:GetMemberInfo(nInstanceId)
            if tbMemberInfo then
                local l10nName = FriendRelationShipDataTable:GetTemplate(nRelationType).l10nName
                local l10nTitle = L10N:Format(UISetUtils.GetL10NTextByKey("UI_HEAD_RELATION_INFO"), tbMemberInfo.name, l10nName)
                pWidgetRef.txtRelationName:SetText(l10nTitle)
            end
        end
    end
end 

function UPTeamHeadName:HideName(bHideName)
    local pVisibility = bHideName and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE
    self.pWidgetRef.txtName:SetVisibility(pVisibility)
end

function UPTeamHeadName:HideRelation(bHide)
    local pVisibility = bHide and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE
    self.pWidgetRef.hbRelation:SetVisibility(pVisibility)
end

function UPTeamHeadName:HideDistance(bHideDistance)
    local pVisibility = bHideDistance and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE
    self.pWidgetRef.ovlDistance:SetVisibility(pVisibility)
end

function UPTeamHeadName:HideDistanceAndState(bHide)
    local pVisibility = bHide and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE
    self.pWidgetRef.ovlDistance:SetVisibility(pVisibility)
    self.pWidgetRef.hbState:SetVisibility(pVisibility)
end

return UPTeamHeadName