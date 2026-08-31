-----------------------------------------------------
--File Name    : UPLobbyTeamListItem.lua
--Author       : Ran Jie
--Create Time  : 2019-03-12
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyTeamListItem = luaclass("UPLobbyTeamListItem", ListItemBase)

local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local L10N = require("L10N")
local GenderTypeDefine = require("GenderTypeDefine")
local HumanDataTable = require("HumanDataTable")
local Proto = require("ClientProtoNames")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TeamSystem = require("TeamSystem")
local FriendSystem = require("FriendSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIUtils = require("UIUtils")
local ClientEventDef = require("ClientEventDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local MatchmakingSystem = require("MatchmakingSystem")
local RankDataTable = require("RankDataTable")
local LobbyChatSystem = require("LobbyChatSystem")
local FriendIni = require("FriendIni")
local SeasonHelper = require("SeasonHelper")

local COLLAPSED = ESlateVisibility.Collapsed
local VISIBLE = ESlateVisibility.Visible
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible

local L10N_CLASSIC_MODE = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_MODE_CLASSIC")
local L10N_MATCHMAKING = UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING")
local L10N_OFFLINE = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_OFFLINE")
local L10N_IDLE = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IDLE")


UPLobbyTeamListItem.pbPlayerHead = nil
UPLobbyTeamListItem.bInvite = nil


local function PreCheck(self)
    if MatchmakingSystem:IsMatchmaking() then
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("TEAM_MATCH_MAKING"))
        return false
    end
    return true
end

local function OnOperationClicked(self)
    if not self.tbData then
        return
    end
    if not PreCheck(self) then
        return
    end
    local nPlayerId = self.tbData.id
    if self.bInvite then
        TeamSystem:RequestInvitePlayer(nPlayerId)
    else
        TeamSystem:RequestApplyJoin(nPlayerId)
    end
end

local function CreateMenuData(self, nPlayerId)
    local FriendComponent = GamePlayerSelfHelper:Get().FriendComponent
    local tbPopMenu =
    {
        [1] =
        {
            szText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_VIEW_PLAYER_INFO"),
            szIcon = UIResourceDef.COMMON_MENU_SUMMARY,
            DoFunc = function() UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId})
                UIManager:CloseWnd(UIDef.UI_LOBBY_TEAM_LIST)
            end
        }
    }
    if not FriendComponent:GetFriend(nPlayerId) then
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
    else
        local tbMenuItem =
        {
            szText = UISetUtils.GetL10NTextByKey("START_TO_CHAT"),
            szIcon = UIResourceDef.COMMON_MENU_SUMMARY,
            DoFunc = function() 
                local tbArgs = {}
                tbArgs.eChannel = LobbyChatSystem.CHAT_FRIEND
                tbArgs.nFriendId = nPlayerId
                UIManager:OpenWnd(UIDef.UI_LOBBY_CHAT, tbArgs)
                UIManager:CloseWnd(UIDef.UI_LOBBY_TEAM_LIST)
            end
        }
        table.insert(tbPopMenu, tbMenuItem)
    end
    return tbPopMenu
end

local function OnHeadClicked(self)
    if UIUtils.DestroyCommonBtnList(self.pWidgetRef.btnHead) then
        return
    else
        UIUtils.DestroyAllCommonBtnList()
    end
    if not PreCheck(self) then
        return
    end
    local nPlayerId = self.tbData.id
    local tbMenuList = self.tbMenuList
    local tbArgs = {}
    if not tbMenuList then
        tbMenuList = CreateMenuData(self, nPlayerId)
        for k, v in pairs(tbMenuList) do
            UIUtils.AddCommonBtnListArgs(tbArgs, UIDef.UP_LOBBY_TEAM_POP_MENU_ITEM, v.szText, v.szIcon:load(), v.DoFunc)
        end
    end
    
    UIUtils.ToggleCommonBtnList(self.pWidgetRef.btnHead, tbArgs)
end

local function RefreshStatus(self)
    local nPlayerId = self.tbData.id
    local tbTeamMemberData = TeamSystem:GetTeamMemberData(nPlayerId)
    local nStatus = self.tbData.status
    local nStatusTime = self.tbData.status_time
    local nTeamSize = self.tbData.team_size
    local nDungeonId = self.tbData.dungeon_id
    local szStatus = ""
    local szOperationText = nil
    local pWidgetRef = self.pWidgetRef
    self.bInvite = false
    
    local bWaiting = false
    --logdebug("tbTeamMemberData=",tbTeamMemberData)
    local nTeamMemberCountLimit = TeamSystem:GetTeamMemberCountLimit()
    self.pbPlayerHead:SetOfflineAppearance(false)
    pWidgetRef.imgSex:SetIsEnabled(true)
    pWidgetRef.imgRankIcon:SetIsEnabled(true)
    pWidgetRef.imgRankNumber:SetIsEnabled(true)
    pWidgetRef.btnOrder:SetVisibility(COLLAPSED)
    pWidgetRef.hbxAlreadyOrder:SetVisibility(COLLAPSED)
    if nStatus == Proto.PlayerStatus.IDLE then
        if TeamSystem:IsWaitingInvitedPlayer(nPlayerId) or TeamSystem:IsWaitingAppliedPlayer(nPlayerId) then
            --pWidgetRef.hbxWaiting:SetVisibility(SELF_HIT_TEST_INVISIBLE)
            bWaiting = true
        elseif nTeamSize > 0 then
            if not tbTeamMemberData and nTeamSize < nTeamMemberCountLimit then
                --szOperationIcon = UIResourceDef.LOBBY_PLAYER_TEAM_APPLY
                szOperationText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_APPLY")
            end
            szStatus = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IN_TEAM"), nTeamSize, nTeamMemberCountLimit)
        else
            if #TeamSystem:GetTeamMemberIds() < nTeamMemberCountLimit then
                --szOperationIcon = UIResourceDef.LOBBY_PLAYER_TEAM_INVITE
                szOperationText = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_INVITE")
                self.bInvite = true
            end
            szStatus = L10N_IDLE
        end
    elseif nStatus == Proto.PlayerStatus.BATTLING then
        local nCurTime = GlobalVariableSystem:GetServerTimeUtc()
        local nDiffSeconds = nCurTime - nStatusTime
        if nDiffSeconds < 60 then
            nDiffSeconds = 60
        end
        local nMinute = math.floor(nDiffSeconds / 60)
        if GlobalVariableSystem:IsInTrainingCamp(nDungeonId) then
            szStatus = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IN_BATTLE"), UISetUtils.GetL10NTextByKey("LOBBY_TEAM_TRAINING_MODE"), nMinute)
        else
            szStatus = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IN_BATTLE"), L10N_CLASSIC_MODE, nMinute)
        end

        local FriendComponent = FriendSystem:GetComponent()

        local nState = FriendSystem:GetReservationState(nPlayerId)
        self.pWidgetRef.hbxAlreadyOrder:SetVisibility(COLLAPSED)

        local ReservationStateDef = Proto.FriendReservation_FriendReservationState
        if nState == ReservationStateDef.ESTABLISHED then  
            self.pWidgetRef.btnOrder:SetVisibility(COLLAPSED)
            self.pWidgetRef.hbxAlreadyOrder:SetVisibility(VISIBLE)
            self.pWidgetRef.txtReservation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ALREADY_ORDER"))
        elseif nState == ReservationStateDef.APPLYING then 
            self.pWidgetRef.btnOrder:SetVisibility(COLLAPSED)
            self.pWidgetRef.hbxAlreadyOrder:SetVisibility(VISIBLE)
            self.pWidgetRef.txtReservation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ORDERING"))
        else  
            local nCurrentIntimacy = 0
            if FriendComponent then 
                local tbFriendInfo = FriendComponent:GetFriend(nPlayerId)
                if  tbFriendInfo and tbFriendInfo.player_intimacy then 
                    nCurrentIntimacy = tbFriendInfo.player_intimacy.intimacy_total
                end
            end
            local nOrderIntimacy = FriendIni.nOrderInimacy
            pWidgetRef.btnOrder:SetIsEnabled(nCurrentIntimacy >= nOrderIntimacy)
            pWidgetRef.btnOrder:SetVisibility(nCurrentIntimacy >= nOrderIntimacy and VISIBLE or COLLAPSED) 
            pWidgetRef.txtOrder:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ORDER"))
        end
        log("Update Friend Status Time: ", nCurTime, nStatusTime, nCurTime - nStatusTime, self.tbData.name, GlobalVariableSystem:GetLocalTime())
    elseif nStatus == Proto.PlayerStatus.MATCHMAKING then
        szStatus = L10N_MATCHMAKING
    elseif nStatus == Proto.PlayerStatus.OFFLINE then
        szStatus = L10N_OFFLINE
        self.pbPlayerHead:SetOfflineAppearance(true)
        pWidgetRef.imgSex:SetIsEnabled(false)
        pWidgetRef.imgRankIcon:SetIsEnabled(false)
        pWidgetRef.imgRankNumber:SetIsEnabled(false)
    end

    if szOperationText then
        -- local pOperationIcon = szOperationIcon:load()
        -- UISetUtils.SetButtonBrushRes(pWidgetRef.btnOperation, pOperationIcon)
        pWidgetRef.btnOperation:SetVisibility(VISIBLE)
        pWidgetRef.txtOperation:SetText(szOperationText)
    else
        pWidgetRef.btnOperation:SetVisibility(COLLAPSED)
    end
    
    pWidgetRef.txtStatus:SetText(szStatus)
    if bWaiting then
        pWidgetRef.hbxWaiting:SetVisibility(SELF_HIT_TEST_INVISIBLE)
        self:PlayAnimation("anim_Waiting", 0, 0, EUMGSequencePlayMode.Forward, 1)
    else
        pWidgetRef.hbxWaiting:SetVisibility(COLLAPSED)
        self:StopAnimation("anim_Waiting")
    end
end

local function OnInviteApplyRefresh(self, nPlayerId)
    if not self.tbData then
        return
    end
    if nPlayerId and nPlayerId == self.tbData.id then
        --logdebug("OnInviteApplyRefresh",TeamSystem:IsWaitingInvitedPlayer(nPlayerId),TeamSystem:IsWaitingAppliedPlayer(nPlayerId))
        RefreshStatus(self)
    end
end

local function OnAgreeOrderRefresh(self, tbReservation)
    if not self.tbData or not tbReservation then
        return
    end
    -- logdebug("on order refresh 1", tbReservation.player_send_reservation_id,tbReservation.player_get_reservation_id, tbReservation.accepted)
    local ReservationStateDef = Proto.FriendReservation_FriendReservationState
    if self.tbData.id == tbReservation.player_get_reservation_id then
        if  tbReservation.state == ReservationStateDef.ESTABLISHED then  
            self.pWidgetRef.btnOrder:SetVisibility(COLLAPSED)
            self.pWidgetRef.hbxAlreadyOrder:SetVisibility(VISIBLE)
            self.pWidgetRef.txtReservation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ALREADY_ORDER"))
        elseif tbReservation.state == ReservationStateDef.APPLYING then
            self.pWidgetRef.btnOrder:SetVisibility(COLLAPSED) 
            self.pWidgetRef.hbxAlreadyOrder:SetVisibility(VISIBLE)
            self.pWidgetRef.txtReservation:SetText(UISetUtils.GetL10NTextByKey("UI_STATIC_ORDERING"))
        end
        -- logdebug("on order refresh 2")
    end
end

local function OnClearReservationVisible(self, nReservationdId)
    if not self.tbData or not nReservationdId then
        return
    end
    if self.tbData.id == nReservationdId then  
        self.pWidgetRef.hbxAlreadyOrder:SetVisibility(COLLAPSED)
    end
end

local function OnOrderClicked(self)
    if not self.tbData then  
        return 
    end
    local nPlayerId = self.tbData.id
    FriendSystem:RequestSendFriendReservation(nPlayerId)
end

local function OnTeamInviteApplyWaitTimeOut(self, nPlayerId)
    if not self.tbData then
        return
    end
    if nPlayerId and nPlayerId == self.tbData.id then
        --logdebug("OnTeamInviteApplyWaitTimeOut",TeamSystem:IsWaitingInvitedPlayer(nPlayerId),TeamSystem:IsWaitingAppliedPlayer(nPlayerId))
        RefreshStatus(self)
    end
end

function UPLobbyTeamListItem:OnLoad()
    self.pbPlayerHead = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
end

function UPLobbyTeamListItem:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnOperation.OnClicked, self, OnOperationClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnOrder.OnClicked, self, OnOrderClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHead.OnClicked, self, OnHeadClicked)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_INVITE_APPLY_WAITING, self, OnInviteApplyRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_INVITE_APPLY_WAITING_REPLY, self, OnInviteApplyRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_NOTIFY_RESERVATION_RESULT, self, OnAgreeOrderRefresh)
    EventHelper:RegisterEvent(ClientEventDef.EV_UPDATE_CLEAR_RESERVATION, self, OnClearReservationVisible)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_TEAM_INVITE_APPLY_WAIT_TIME_OUT, self, OnTeamInviteApplyWaitTimeOut)
    
end

function UPLobbyTeamListItem:OnRefresh(tbPlayerData)
    if not tbPlayerData then
        return
    end
    local nRank = tbPlayerData.rank
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.txtName:SetText(tbPlayerData.name)
    local tbHumanTemplate = HumanDataTable:GetTemplate(tbPlayerData.avatar_id)
    if tbHumanTemplate then
        local nGenderType = tbHumanTemplate.nGender
        local szGenderIcon = UIResourceDef.GENDER_FEMALE
        if nGenderType == GenderTypeDefine.MALE then
            szGenderIcon = UIResourceDef.GENDER_MALE
        end
        UISetUtils.SetImageBrushRes(pWidgetRef.imgSex, szGenderIcon:load(), true)
    end
    self.pbPlayerHead:SetPlayerHead(tbPlayerData.avatar_id, tbPlayerData.level)

    RefreshStatus(self)
    local szRankIcon, szLevelIcon = SeasonHelper.GetIcon(nRank) 
    local tbRankTemplate = RankDataTable:GetTemplate(nRank)
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
end

return UPLobbyTeamListItem