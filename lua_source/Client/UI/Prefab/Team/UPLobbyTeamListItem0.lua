-----------------------------------------------------
--File Name    : UPLobbyTeamListItem0.lua
--Author       : Ran Jie
--Create Time  : 2019-03-12
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPLobbyTeamListItem0 = luaclass("UPLobbyTeamListItem0", ListItemBase)

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
local EventManager = require("EventManager")
local MatchmakingSystem = require("MatchmakingSystem")

local COLLAPSED = ESlateVisibility.Collapsed
local VISIBLE = ESlateVisibility.Visible
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible

local L10N_CLASSIC_MODE = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_MODE_CLASSIC")
local L10N_MATCHMAKING = UISetUtils.GetL10NTextByKey("UI_LOBBY_MATCHMAKING")
local L10N_OFFLINE = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_OFFLINE")
local L10N_IDLE = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IDLE")


UPLobbyTeamListItem0.pbPlayerHead = nil
UPLobbyTeamListItem0.bInvite = nil


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
            DoFunc = function() UIManager:OpenWnd(UIDef.UI_PLAYER_INFO, {nPlayerId = nPlayerId})  end
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
            DoFunc = function() EventManager:OnFireEvent(ClientEventDef.EV_OPEN_LOBBY_CHAT_FRIEND, nPlayerId) end
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
    -- local pbPopMenu = self.Owner.pbLobbyTeam.pbPopMenu
    -- local nPlayerId = self.tbData.id
    -- if pbPopMenu.nGroupId == nPlayerId then
    --     pbPopMenu:HideMenu()
    --     return
    -- end

    -- local tbMenuList = CreateMenuData(self, nPlayerId)
    -- --logdebug("self.Owner=")
    -- pbPopMenu:SetData(tbMenuList, nPlayerId)
    -- local pGeometry =self.pWidgetRef.btnHead:GetCachedGeometry()
    -- local ScreenPos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry,Vector2D{X=120,Y=0})
    -- local pRootGeometry = self.Owner.pWidgetRef:GetCachedGeometry()
    -- local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(pRootGeometry, ScreenPos)
    -- pbPopMenu.pWidgetRef.Slot:SetPosition(LocalPos)
end

function UPLobbyTeamListItem0:OnLoad()
    self.pbPlayerHead = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbPlayerHead)
end

function UPLobbyTeamListItem0:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnOperation.OnClicked, self, OnOperationClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHead.OnClicked, self, OnHeadClicked)
end

function UPLobbyTeamListItem0:OnRefresh(tbPlayerData)
    if not tbPlayerData then
        return
    end
    local tbTeamMemberData = TeamSystem:GetTeamMemberData(tbPlayerData.id)
    local nStatus = tbPlayerData.status
    local nStatusTime = tbPlayerData.status_time
    local nTeamSize = tbPlayerData.team_size

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

    local szOperationIcon = nil
    local szStatus = ""
    self.bInvite = false
    pWidgetRef.imgBlack:SetVisibility(COLLAPSED)
    --logdebug("tbTeamMemberData=",tbTeamMemberData)
    local nTeamMemberCountLimit = TeamSystem:GetTeamMemberCountLimit()
    if nStatus == Proto.PlayerStatus.IDLE then
        if nTeamSize > 0 then
            if not tbTeamMemberData and nTeamSize < nTeamMemberCountLimit then
                szOperationIcon = UIResourceDef.LOBBY_PLAYER_TEAM_APPLY
            end
            szStatus = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IN_TEAM"), nTeamSize, nTeamMemberCountLimit)
        else
            if #TeamSystem:GetTeamMemberIds() < nTeamMemberCountLimit then
                szOperationIcon = UIResourceDef.LOBBY_PLAYER_TEAM_INVITE
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
        szStatus = L10N:Format(UISetUtils.GetL10NTextByKey("LOBBY_TEAM_IN_BATTLE"), L10N_CLASSIC_MODE, nMinute)
        log("Update Friend Status Time: ", nCurTime, nStatusTime, nCurTime - nStatusTime, tbPlayerData.name, GlobalVariableSystem:GetLocalTime())
    elseif nStatus == Proto.PlayerStatus.MATCHMAKING then
        szStatus = L10N_MATCHMAKING
    elseif nStatus == Proto.PlayerStatus.OFFLINE then
        szStatus = L10N_OFFLINE
        pWidgetRef.imgBlack:SetVisibility(SELF_HIT_TEST_INVISIBLE)
    end

    if szOperationIcon then
        local pOperationIcon = szOperationIcon:load()
        UISetUtils.SetButtonBrushRes(pWidgetRef.btnOperation, pOperationIcon)
        pWidgetRef.btnOperation:SetVisibility(VISIBLE)
    else
        pWidgetRef.btnOperation:SetVisibility(COLLAPSED)
    end
    pWidgetRef.txtStatus:SetText(szStatus)
end

return UPLobbyTeamListItem0