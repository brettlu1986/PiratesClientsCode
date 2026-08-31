-----------------------------------------------------
--File Name    : UILobbyTeam.lua
--Author       : Ranjie
--Create Time  : 2020-4-20
--Description  : 大厅组队
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbyTeam = luaclass("UILobbyTeam", WndBase)

local ClientEventDef = require("ClientEventDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local TeamSystem = require("TeamSystem")
local Proto = require("ClientProtoNames")
local LobbySystem = require("LobbySystem")
local EventManager  = require("EventManager")
local LobbySubTypeDef = require("LobbySubTypeDef")


UILobbyTeam.tbHumanActor = nil
UILobbyTeam.tbCurrentHumanPos = nil
UILobbyTeam.tbMemberTitlePrefab = nil
UILobbyTeam.tbActorListener = nil
UILobbyTeam.tbDragIndex = nil
UILobbyTeam.tbDragLastPos = nil
UILobbyTeam.ulLobbyTeamChatBubble = nil
UILobbyTeam.ulLobbyDrag = nil

local MAX_MEMBER_COUNT = 4

local function RemoveTeamMember(self, nPlayerId)
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_DESTORY_MEMBER_ACTOR, nPlayerId)
    local nPosIndex = self.tbCurrentHumanPos[nPlayerId]
    if not nPosIndex then
        logerror("UILobbyTeam:RemovePlayer, nPosIndex is nil,nPlayerId=", nPlayerId)
        return 
    end
    local pbPlayerTitle = self.tbMemberTitlePrefab[nPosIndex]
    if pbPlayerTitle then
        pbPlayerTitle:HideData()
    else
        logerror("UILobbyTeam:RemovePlayer, pbPlayerTitle is nil,nPlayerId, nPosIndex=",nPlayerId, nPosIndex)
    end
    self.tbCurrentHumanPos[nPlayerId] = nil
end

local function AddTeamMember(self, tbMemberData)
    if not tbMemberData or not tbMemberData.tbSummary then
        return
    end
    local nPlayerId = tbMemberData.nPlayerId
    local LobbyMain = LobbySystem:GetSub(LobbySubTypeDef.MAIN)
    local nPosIndex = LobbyMain:GetPlayerPos(nPlayerId)
    --logdebug("AddTeamMember,nPlayerId,nPosIndex=",nPlayerId,nPosIndex)
    if not nPosIndex or nPosIndex == 0 then
        return
    end
    local pbPlayerTitle = self.tbMemberTitlePrefab[nPosIndex]
    pbPlayerTitle:SetData(tbMemberData)
    self.tbCurrentHumanPos[nPlayerId] = nPosIndex
end

local function DismissTeam(self)
    local tbRemovePlayer = {}
    for k, v in pairs(self.tbCurrentHumanPos) do
        table.insert(tbRemovePlayer, k)
    end
    for k, v in ipairs(tbRemovePlayer) do
        RemoveTeamMember(self, v)
    end
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    self.tbCurrentHumanPos[GamePlayerSelfHelper:Get():GetPlayerId()] = LobbySystem:GetSub(LobbySubTypeDef.MAIN):GetPlayerPos(nSelfPlayerId)
end

local function HumanShow(self)
    local tbTeamMemberIds = TeamSystem:GetTeamMemberIds()
    for k, v in ipairs(tbTeamMemberIds) do
        local tbMemberData = TeamSystem:GetTeamMemberData(v)
        AddTeamMember(self, tbMemberData)
    end
end

local function OnTeamChanged(self, tbPackage)
    local nPlayerId = tbPackage.player_id
    if tbPackage.change_type == Proto.ChangeType.ADD_MEMBER then
        local tbMemberData = TeamSystem:GetTeamMemberData(nPlayerId)
        AddTeamMember(self, tbMemberData)
    elseif tbPackage.change_type == Proto.ChangeType.DISMISS then
        DismissTeam(self)
    elseif tbPackage.change_type == Proto.ChangeType.LEAVE_TEAM or tbPackage.change_type == Proto.ChangeType.KICK_OUT_TEAM then
        if nPlayerId == GamePlayerSelfHelper:Get():GetPlayerId() then
            DismissTeam(self)
        else
            RemoveTeamMember(self, nPlayerId)
        end
        --
    end
end

local function RefreshPlayerTitleInfo(self, nPlayerId)
    local LobbyMain = LobbySystem:GetSub(LobbySubTypeDef.MAIN)
    local nPosIndex = LobbyMain:GetPlayerPos(nPlayerId)
    if nPosIndex then
        local tbMemberData = TeamSystem:GetTeamMemberData(nPlayerId)
        if tbMemberData then
            self.tbMemberTitlePrefab[nPosIndex]:SetData(tbMemberData)
            self.tbCurrentHumanPos[nPlayerId] = nPosIndex
        end
    end
end

local function OnLeaderChanged(self, nNewLeader, nOldLeader)
    --logdebug("OnLeaderChanged,nNewLeader, nOldLeader=",nNewLeader, nOldLeader)
    RefreshPlayerTitleInfo(self, nOldLeader)
    RefreshPlayerTitleInfo(self, nNewLeader)
end


local function OnTeamMemberSummaryChanged(self, tbSummaryArray)
    for k, v in ipairs(tbSummaryArray) do
        RefreshPlayerTitleInfo(self, v.id)
    end
end

local function OnTeamMemberReadyChanged(self, nPlayerId, bIsReady)
    RefreshPlayerTitleInfo(self, nPlayerId)
end

function UILobbyTeam:OnLoad()
    self.tbMemberTitlePrefab = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    for i = 1, MAX_MEMBER_COUNT do
        local pbPlayerTitle = PrefabHelper:BindPrefab(pWidgetRef["pbPlayerTitle0"..i])
        self.tbMemberTitlePrefab[i] = pbPlayerTitle
    end
    self.ulLobbyTeamChatBubble = self.UILogicHelper:CreateUILogic("ULLobbyTeamChatBubble")
    self.ulLobbyDrag = self.UILogicHelper:CreateUILogic("ULLobbyDrag")
end

function UILobbyTeam:OnShow()
    self.tbCurrentHumanPos = {}
    HumanShow(self)
    self.ulLobbyDrag:SetEnable(true)
end

function UILobbyTeam:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_CHANGED, self, OnTeamChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_LEADER_CHANGED, self, OnLeaderChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_TEAM_MEMBER_READY_MATCH, self, OnTeamMemberReadyChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_MAIN_PLAYER_SUMMARY_CHANGE, self, OnTeamMemberSummaryChanged)
end

function UILobbyTeam:OnExit()
    self.tbCurrentHumanPos = nil
end



return UILobbyTeam