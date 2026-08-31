-----------------------------------------------------
--File Name    : UPLobbyPlayerTitle.lua
--Author       : Ran Jie
--Create Time  : 2019-03-12
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPLobbyPlayerTitle = luaclass("UPLobbyPlayerTitle", PrefabBase)

local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local GenderTypeDefine = require("GenderTypeDefine")
local HumanDataTable = require("HumanDataTable")
local Proto = require("ClientProtoNames")
local TeamSystem = require("TeamSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local MatchmakingSystem = require("MatchmakingSystem")
local ClientEventDef = require("ClientEventDef")
local RankDataTable = require("RankDataTable")
local L10N = require("L10N")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local DelayTimer = require("DelayTimer")
local SeasonHelper = require("SeasonHelper")
local CommonButtonListTypeDef = require("CommonButtonListTypeDef")

local COLLAPSED = ESlateVisibility.Collapsed
local VISIBLE = ESlateVisibility.Visible
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible
local tbNameUIPosOffsetY = {100, 0, 0, 100}
local tbNameUIPosOffsetX = {0, 0, 40, 20}
local tbNameDepth = {0, 1, 3, 2}
local FUNC_SCRREN_TO_WIDGET_ABSOLUTE = SlateBlueprintLibrary.ScreenToWidgetAbsolute
local FUNC_ABSOLUTE_TO_LOCAL = SlateBlueprintLibrary.AbsoluteToLocal
local FriendSystem = require("FriendSystem")
--local FUNC_LOCAL_TO_ABSOLUTE = SlateBlueprintLibrary.LocalToAbsolute
local SET_WIDGET_POS_DELAY = 0.1
local POP_MENU_ITEM_SIZE = {X = 230, Y = 80}

UPLobbyPlayerTitle.pbPlayerHead = nil
UPLobbyPlayerTitle.bInvite = nil
UPLobbyPlayerTitle.tbData = nil
UPLobbyPlayerTitle.tbMenuList = nil
UPLobbyPlayerTitle.tbWidgetDelayTimer = nil
UPLobbyPlayerTitle.tbDragIndex = nil
UPLobbyPlayerTitle.tbDragLastPos = nil

local function PreCheck(self)
    if MatchmakingSystem:IsMatchmaking() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_MATCH_MAKING"))
        return false
    end
    return true
end

local function CreateMenuData(self, nPlayerId)
    local tbPopMenu =
    {
        [1] =
        {
            szText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_VIEW_PLAYER_INFO"),
            szIcon = UIResourceDef.COMMON_MENU_SUMMARY,
            DoFunc = function() UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId}) end
        },
    }
    if TeamSystem:IsTeamLeader(GamePlayerSelfHelper:Get():GetPlayerId()) then
        local tbMenuItem1 =
        {
            szText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_KICK_OUT"),
            szIcon = UIResourceDef.COMMON_MENU_SUMMARY,
            DoFunc = function() 
                if not PreCheck(self) then
                    return
                end
                TeamSystem:KickOutTeamMember(nPlayerId)  
            end
        }
        local tbMenuItem2 =
        {
            szText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_TRANSFER_LEADER"),
            szIcon = UIResourceDef.COMMON_MENU_SUMMARY,
            DoFunc = function() 
                if not PreCheck(self) then
                    return
                end
                TeamSystem:TransferTeamLeader(nPlayerId)  
            end
        }
        table.insert(tbPopMenu, tbMenuItem1)
        table.insert(tbPopMenu, tbMenuItem2)
    end
    local FriendComponent = GamePlayerSelfHelper:Get().FriendComponent
    if FriendComponent and not FriendComponent:GetFriend(nPlayerId) then
        local tbMenuItem =
        {
            szText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_ADD_FRIEND"),
            szIcon = UIResourceDef.COMMON_MENU_SUMMARY,
            DoFunc = function() FriendSystem:RequestApplyFriend(nPlayerId, 
                L10N:ToString(UISetUtils.GetL10NTextByKey("FFA_APPLYFRIEND_MESSAGE_BYTEAM")),
                Proto.FriendSource.TEAM_RECENT)
            end
        }
        table.insert(tbPopMenu, tbMenuItem)
    end
    return tbPopMenu
end

local function OnQuitClicked(self)
    if not PreCheck(self) then
        return
    end 
    TeamSystem:LeaveTeam()
end

local function OnMicAnimPlayTimeOut(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbgVoiceLevel:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pbgVoiceLevel:SetPercent(0)
end


local function OnOpenMenuClicked(self)
    local pWidgetRef = self.pWidgetRef
    local pBtnOpenMenu = pWidgetRef.btnOpenMenu
    if UIUtils.DestroyCommonBtnList(pBtnOpenMenu) then
        pBtnOpenMenu:SetRenderTransformAngle(0)
        return
    else
        UIUtils.DestroyAllCommonBtnList()
    end
    self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_TEAM_POP_MENU, pBtnOpenMenu)
    pBtnOpenMenu:SetRenderTransformAngle(180)
    local tbMenuList = self.tbMenuList
    local tbArgs = {}
    if not tbMenuList then
        tbMenuList = CreateMenuData(self, self.tbData.nPlayerId)
        for k, v in pairs(tbMenuList) do
            UIUtils.AddCommonBtnListArgs(tbArgs, UIDef.UP_LOBBY_TEAM_POP_MENU_ITEM, v.szText, v.szIcon:load(), v.DoFunc)
        end
    end
    --UIUtils.ToggleCommonBtnList(self.pWidgetRef.btnOpenMenu, tbArgs)

    local pGeometry = pWidgetRef:GetCachedGeometry()
    local pGeometrySize = SlateBlueprintLibrary.GetLocalSize(pGeometry)
    local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry, 
    Vector2D{X = pGeometrySize.X - POP_MENU_ITEM_SIZE.X - 20, Y = - (POP_MENU_ITEM_SIZE.Y * #tbMenuList) - 2})
    UIUtils.ToggleCommonBtnList(pBtnOpenMenu, tbArgs, Pos, nil ,CommonButtonListTypeDef.LayoutType.Absulot)
end

local function SetWidgetPos(self, pWidget, pActor, nXOffset, nYOffset)
    --logdebug("SetWidgetPos:self.tbWidgetDelayTimer=",self.tbWidgetDelayTimer)
    if not LobbySystem:GetSub(LobbySubTypeDef.MAIN):IsSelfOrTeamMember(pActor) then
        return false
    end
    local pWorldLocation = pActor:K2_GetActorLocation()
    local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
    local bRet, pUIScreenPos = pPlayerController:ProjectWorldLocationToScreen(pWorldLocation, false)
    
    if bRet then
        local AbsoluteCoordinate = FUNC_SCRREN_TO_WIDGET_ABSOLUTE(GWorld, pUIScreenPos)
        local pRootWidget = pWidget:GetParent()-- self.pWidgetRef.cvsRoot
        local pGeometry = pRootWidget:GetCachedGeometry()
        local pLocalPos = FUNC_ABSOLUTE_TO_LOCAL(pGeometry, AbsoluteCoordinate)
        pLocalPos.X = pLocalPos.X + nXOffset
        pLocalPos.Y = pLocalPos.Y + nYOffset
        pWidget.Slot:SetPosition(pLocalPos)
        --logdebug("UILobbyTeam:SetWidgetPos",bRet,pLocalPos.X,pLocalPos.Y)
    end
    return bRet
end

local function OnLobbyMainBlendCameraEnd(self)
    --logdebug("OnLobbyMainBlendCameraEnd,self.tbWidgetDelayTimer=",self.tbWidgetDelayTimer,self.tbData)
    if not self.tbData or self.tbWidgetDelayTimer then
        return
    end
    local nPlayerId = self.tbData.nPlayerId
    local LobbyMain = LobbySystem:GetSub(LobbySubTypeDef.MAIN)
    local nPosIndex = LobbyMain:GetPlayerPos(nPlayerId)
    local pActor = LobbyMain:GetTeamMemberActor(nPlayerId)
    if pActor and isvalidhandle(pActor) then
        self.tbWidgetDelayTimer = self.TimerHelper:NewTimer(function()
            if SetWidgetPos(self, self.pWidgetRef, pActor, tbNameUIPosOffsetX[nPosIndex], tbNameUIPosOffsetY[nPosIndex]) then
                self.pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
                self.TimerHelper:ClearTimer(self.tbWidgetDelayTimer)
                self.tbWidgetDelayTimer = nil
            end
        end, SET_WIDGET_POS_DELAY, true)
    end
end

local function OnPopMenu(self, pTargetWidget)
    local pBtnOpenMenu = self.pWidgetRef.btnOpenMenu
    if pTargetWidget ~= pBtnOpenMenu then
        pBtnOpenMenu:SetRenderTransformAngle(0)
    end
end

local function OnExitUI(self, szWndName)
    if szWndName == UIDef.UI_COMMON_BUTTON_LIST_CONTENT then
        self.pWidgetRef.btnOpenMenu:SetRenderTransformAngle(0)
    elseif szWndName == UIDef.UI_LOADING then
        OnLobbyMainBlendCameraEnd(self)
    end
end

function UPLobbyPlayerTitle:OnLoad()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbgVoiceLevel:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pbgVoiceLevel:SetPercent(0)
end

function UPLobbyPlayerTitle:OnEnter()
    self.tbDragIndex = {}
    self.tbDragLastPos = {}
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
    self.pWidgetRef.btnOpenMenu:SetRenderTransformAngle(0)
end

function UPLobbyPlayerTitle:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnQuit.OnClicked, self, OnQuitClicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnOpenMenu.OnClicked, self, OnOpenMenuClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_GV_ON_MEMBER_VOICE_STATE, self, self.SetVoiceLevel)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBYMAIN_BLEND_CAMERA_END, self, OnLobbyMainBlendCameraEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_TEAM_POP_MENU, self, OnPopMenu)
    EventHelper:RegisterEvent(ClientEventDef.EV_POST_EXIT_UI, self, OnExitUI)
end

function UPLobbyPlayerTitle:OnExit()
    UIUtils.DestroyCommonBtnList(self.pWidgetRef.btnOpenMenu)
    if self.tbWidgetDelayTimer then
        DelayTimer:ClearTimer(self.tbWidgetDelayTimer)
        self.tbWidgetDelayTimer = nil
    end
end

function UPLobbyPlayerTitle:SetVoiceLevel(nIndex, nState, nMemberPlayerId)
    if not self.tbData then
        return
    end
    local nPlayerId = self.tbData.nPlayerId
    -- logdebug("======UPLobbyPlayerTitle:SetVoiceLevel====== nState = " .. tostring(nState) .. " nPlayerId = " .. nPlayerId .. type(nPlayerId) .. " nMemberPlayerId = " .. nMemberPlayerId .. type(nMemberPlayerId) )
    if nPlayerId ~= nMemberPlayerId then
        --logdebug("return not target player")
        return
    end
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.pbgVoiceLevel:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if nState == 0 then
        pWidgetRef.pbgVoiceLevel:SetVisibility(ESlateVisibility.Collapsed)
        self:StopAnimation("animMic")
        pWidgetRef.pbgVoiceLevel:SetPercent(0)
    elseif nState == 1 then
        self:PlayAnimation("animMic", 0, 3, EUMGSequencePlayMode.Forward, 1, function() OnMicAnimPlayTimeOut(self) end)
    elseif nState == 2 then
        self:PlayAnimation("animMic", 0, 3, EUMGSequencePlayMode.Forward, 1, function() OnMicAnimPlayTimeOut(self) end)
    end
end

function UPLobbyPlayerTitle:SetData(tbPlayerData)
    self.tbData = tbPlayerData
    --logdebug("UPLobbyPlayerTitle:SetData tbPlayerData = " .. tostring(tbPlayerData))
    if not tbPlayerData or not tbPlayerData.tbSummary then
        return
    end
    local tbSummary = tbPlayerData.tbSummary
    local nPlayerId = tbSummary.id
    local LobbyMain = LobbySystem:GetSub(LobbySubTypeDef.MAIN)
    local nPosIndex = LobbyMain:GetPlayerPos(nPlayerId)
    local pWidgetRef = self.pWidgetRef
    --pWidgetRef:SetVisibility(SELF_HIT_TEST_INVISIBLE)
    
    log("UPLobbyPlayerTitle:SetData, name, nStatus=",tbSummary.name, tbSummary.status)
    pWidgetRef.txtName:SetText(tbSummary.name)
    local tbHumanTemplate = HumanDataTable:GetTemplate(tbSummary.avatar_id)
    if tbHumanTemplate then
        local nGenderType = tbHumanTemplate.nGender
        local szGenderIcon = UIResourceDef.GENDER_FEMALE
        if nGenderType == GenderTypeDefine.MALE then
            szGenderIcon = UIResourceDef.GENDER_MALE
        end
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)
    end
    --logdebug("UPLobbyPlayerTitle:SetData,leader,selfplayerid=",TeamSystem:GetTeamLeader(),tbPlayerData.nPlayerId)
    if TeamSystem:IsTeamLeader(nPlayerId) then
        pWidgetRef.imgTeamLeader:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        pWidgetRef.imgReady:SetVisibility(COLLAPSED)
    else
        pWidgetRef.imgTeamLeader:SetVisibility(COLLAPSED)
        --logdebug("tbPlayerData.bIsReady=",tbPlayerData.bIsReady)
        if tbPlayerData.bIsReady then
            pWidgetRef.imgReady:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        else
            pWidgetRef.imgReady:SetVisibility(COLLAPSED)
        end
    end
    if GamePlayerSelfHelper:Get():GetPlayerId() == tbSummary.id then
        pWidgetRef.btnQuit:SetVisibility(VISIBLE)
        pWidgetRef.btnOpenMenu:SetVisibility(COLLAPSED)
    else
        pWidgetRef.btnQuit:SetVisibility(COLLAPSED)
        pWidgetRef.btnOpenMenu:SetVisibility(VISIBLE)
    end
    --logdebug("tbPlayerData.nStatus=",tbSummary.status)
    if tbSummary.status == Proto.PlayerStatus.OFFLINE then
        pWidgetRef.txtGame:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_OFFLINE"))
    elseif tbSummary.status == Proto.PlayerStatus.BATTLING then
        pWidgetRef.txtGame:SetText(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_BATTLING"))
    else
        pWidgetRef.txtGame:SetText("")
    end

    local szRankIcon, szLevelIcon = SeasonHelper.GetIcon(tbSummary.rank) 
    
    local tbRankTemplate = RankDataTable:GetTemplate(tbSummary.rank)
    --logdebug("szRankIcon, szLevelIcon",szRankIcon, szLevelIcon,tbRankTemplate,pWidgetRef.txtRank,pWidgetRef.imgRankIcon)
    if tbRankTemplate and pWidgetRef.txtRank and pWidgetRef.imgRankIcon then
        local szRankName = L10N:ToString(tbRankTemplate.l10nName)..tbRankTemplate.szRankLevelName
        pWidgetRef.txtRank:SetText(szRankName)
        if szRankIcon and szLevelIcon then
            local pRankIcon = szRankIcon:load()
            if pRankIcon then
                UISetUtils.SetImageBrushRes(pWidgetRef.imgRankIcon, pRankIcon)
            end
            local pLevelIcon = szLevelIcon:load()
            if pLevelIcon then
                UISetUtils.SetImageBrushRes(pWidgetRef.imgRankNumber, pLevelIcon)
            end
        end
    end
    pWidgetRef.Slot:SetZOrder(tbNameDepth[nPosIndex])
    if LobbySystem:GetSub(LobbySubTypeDef.MAIN):IsPlayerActorReady() then
        
        local pActor = LobbyMain:GetTeamMemberActor(nPlayerId)
        if not self.tbWidgetDelayTimer and pActor then
            self.tbWidgetDelayTimer = self.TimerHelper:NewTimer(function()
                if SetWidgetPos(self, pWidgetRef, pActor, tbNameUIPosOffsetX[nPosIndex], tbNameUIPosOffsetY[nPosIndex]) then
                    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
                    self.TimerHelper:ClearTimer(self.tbWidgetDelayTimer)
                    self.tbWidgetDelayTimer = nil
                end
            end, SET_WIDGET_POS_DELAY, true)
            --logdebug("self.tbWidgetDelayTimer=",self.tbWidgetDelayTimer,tbPlayerData.szName, debug.traceback())
        end
    end
end

function UPLobbyPlayerTitle:HideData()
    UIUtils.DestroyCommonBtnList(self.pWidgetRef.btnOpenMenu)
    if self.tbWidgetDelayTimer then
        self.TimerHelper:ClearTimer(self.tbWidgetDelayTimer)
        self.tbWidgetDelayTimer = nil
    end
    self.pWidgetRef:SetVisibility(COLLAPSED)
end

return UPLobbyPlayerTitle