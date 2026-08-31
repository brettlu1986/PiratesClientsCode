-----------------------------------------------------
--File Name    : TeamSystem.lua
--Author       : Ran Jie
--Create Time  : 2019-03-12
--Description  : 副本外组队系统
-----------------------------------------------------
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfEventHelper = require("SelfEventHelper")
local Proto = require("ClientProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ClientEventDef = require("ClientEventDef")
local ItemSystem = require("ItemSystem")
local DelayTimer = require("DelayTimer")
local TeamIni = require("TeamIni")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local PlayerInfoSystem = require("PlayerInfoSystem")
local L10N = require("L10N")

local TeamSystem = {}

local TEAM_MEMBER_COUNT_LIMIT = 4
local DEFAULT_MATCH_MODE = 4                    --默认是双人模式
local FROM_FRIEND = Proto.InviteFrom.FRIEND
local WAIT_TIME_OUT = TeamIni.nValidTimeForApplyJoinTeam + 1
local L10N_WAIT_TIME_OUT = UISetUtils.GetL10NTextByKey("TEAM_NOT_REPLY")

TeamSystem.tbIgnorePlayerInvite = nil
TeamSystem.tbIgnorePlayerApply = nil
TeamSystem.nTeamMode = DEFAULT_MATCH_MODE
TeamSystem.bAutoMatch = true --默认勾选自动匹配队友
TeamSystem.tbWaitInvitePlayer = nil
TeamSystem.tbWaitApplyPlayer = nil

local function GetComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local TeamComponent = PlayerSelf.TeamComponent
    if TeamComponent == nil then
        error("TeamComponent failed!TeamComponent == nil!")
    end
    return TeamComponent
end

local function ShowMessageToast(l10nMessage)
    if GlobalVariableSystem:IsInDungeon() then
        return
    end
    if l10nMessage then
        UIUtils.ShowToast(l10nMessage)
    end
end

local function OnSelfFashionChanged()
    local tbFashionItems = ItemSystem:GetEquippedFashionItems()
    local tbFashionIds = {}
    if tbFashionItems then
        for _, tbFashionItem in ipairs(tbFashionItems) do
            table.insert(tbFashionIds, tbFashionItem:GetTemplateId())
        end
    end
    GetComponent():UpdateTeamMemberFashion(GamePlayerSelfHelper:Get():GetPlayerId(), tbFashionIds)
end

local function UpdateMemberSummary(self, tbSummary)
    local TeamComponent = GetComponent()
    local tbOldMemberData = TeamComponent:GetTeamMemberData(tbSummary.id)
    if tbOldMemberData then
        local tbOldSummary = tbOldMemberData.tbSummary
        if tbOldSummary and tbOldSummary.status == Proto.PlayerStatus.OFFLINE and tbSummary.status ~= Proto.PlayerStatus.OFFLINE then
            local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("TEAM_MEMBER_ON_LINE"), tbSummary.name)
            ShowMessageToast(l10nMessage)
        end
        log("TeamSystem:UpdateMemberSummary",tbSummary.name)
        TeamComponent:UpdateTeamMemberSummary(tbSummary)
        return true
    end
    return false
end

local function OnRecvPlayerSummaries(self, tbSummariesArray)
    local tbTeamMemberSummaries = {}
    log("TeamSystem:OnRecvPlayerSummaries",#tbSummariesArray,GamePlayerSelfHelper:Get():GetName())
    for k, v in ipairs(tbSummariesArray) do
        if UpdateMemberSummary(self, v) then
            table.insert(tbTeamMemberSummaries, v)
        end
    end
    if #tbTeamMemberSummaries > 0 then
        self.EventHelper:FireEvent(ClientEventDef.EV_TEAM_MEMBER_SUMMARY_CHANGED, tbTeamMemberSummaries)
    end
end

local function OnPlayerSummaryChanged(self, tbSummary)
    local tbTeamMemberSummaries = {}
    if UpdateMemberSummary(self, tbSummary) then
        table.insert(tbTeamMemberSummaries, tbSummary)
        self.EventHelper:FireEvent(ClientEventDef.EV_TEAM_MEMBER_SUMMARY_CHANGED, tbTeamMemberSummaries)
    end
end

local function RequestTeamMemberSummaries(self, tbPlayerIdList)
    local tbCachedPlayerIds, tbNoCachedPlayerIds = PlayerInfoSystem:HasPlayerSummaries(tbPlayerIdList)
    PlayerInfoSystem:RequestPlayerSummariesFromServer(tbNoCachedPlayerIds)

    local tbSummaries = PlayerInfoSystem:GetPlayerSummariesFromLocal(tbCachedPlayerIds)
    local tbSummariesArray = {}
    for k, v in pairs(tbSummaries) do
        table.insert(tbSummariesArray, v)
    end
    OnRecvPlayerSummaries(self, tbSummariesArray)
end

local function OnPlayerDataSync(self, tbPacket, bReconnected)
    if bReconnected then
        GetComponent():ClearTeamMembers()
    end
end
--
function TeamSystem:Init()
    self.tbIgnorePlayerInvite = {}
    self.tbIgnorePlayerApply = {}
    self.tbWaitApplyPlayer = {}
    self.tbWaitInvitePlayer = {}
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_EQUIP_LOBBY_FASHION, self, OnSelfFashionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_UNEQUIP_LOBBY_FASHION, self, OnSelfFashionChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SUMMARIES_RECEIVED, self, OnRecvPlayerSummaries)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYER_SUMMARY_CHANGE_NOTIFIED, self, OnPlayerSummaryChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    return true
end

function TeamSystem:Uninit()
    self.EventHelper:UnregisterAll()
    self.nTeamMode = DEFAULT_MATCH_MODE
    self.bAutoMatch = true
end

function TeamSystem:SyncTeam(tbPacket)
    local TeamComponent = GetComponent()
    TeamComponent:ClearTeamMembers()
    TeamComponent:UpdateTeamInfo(tbPacket.team_id, tbPacket.leader_id)
    local tbPlayerIdList = {}
    for k, v in ipairs(tbPacket.team_members) do
        TeamComponent:UpdateTeamMember(v)
        table.insert(tbPlayerIdList, v.player_id)
        self:ResetInvitePlayer(v.player_id)
        self:ResetApplyPlayer(v.player_id)
    end
    RequestTeamMemberSummaries(self, tbPlayerIdList)
end

function TeamSystem:UpdateTeamLeader(nLeaderId)
    GetComponent():UpdateTeamLeader(nLeaderId)
end

function TeamSystem:ClearTeamMembers()
    GetComponent():ClearTeamMembers()
end

function TeamSystem:UpdateTeamMemberFashion(nPlayerId, tbFashionIds)
    GetComponent():UpdateTeamMemberFashion(nPlayerId, tbFashionIds)
end

function TeamSystem:UpdateTeamMemberReady(nPlayerId, bIsReady)
    GetComponent():UpdateTeamMemberReady(nPlayerId, bIsReady)
end

function TeamSystem:GetTeamMemberIds()
    return GetComponent():GetTeamMemberIds()
end

function TeamSystem:GetTeamMemberCount()
    return #GetComponent():GetTeamMemberIds()
end

function TeamSystem:IsTeamLeader(nPlayerId)
    return GetComponent():IsTeamLeader(nPlayerId)
end

function TeamSystem:GetTeamLeader()
    return GetComponent():GetTeamLeader()
end

function TeamSystem:GetTeamMemberData(nPlayerId)
    return GetComponent():GetTeamMemberData(nPlayerId)
end

function TeamSystem:IsInTeam()
    return #GetComponent():GetTeamMemberIds() > 0
end

function TeamSystem:GetTeamMemberCountLimit()
    return TEAM_MEMBER_COUNT_LIMIT
end

function TeamSystem:IsWaitingInvitedPlayer(nPlayerId)
    return self.tbWaitInvitePlayer[nPlayerId]
end

function TeamSystem:IsWaitingAppliedPlayer(nPlayerId)
    return self.tbWaitApplyPlayer[nPlayerId]
end

--招募队友
function TeamSystem:RecruitTeammate()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_RecruitTeammate)
end

--回应招募队友
function TeamSystem:ReplyRecruitTeammate(nPlayerId)
    local c2s_ReplyRecruitTeammate =
    {
        player_id = nPlayerId,
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ReplyRecruitTeammate, c2s_ReplyRecruitTeammate)
end

--邀请玩家入队
function TeamSystem:RequestInvitePlayer(nPlayerId, InviteFrom)
    InviteFrom = (InviteFrom == nil) and FROM_FRIEND or InviteFrom
    local c2s_InviteJoinTeam =
    {
        player_id = nPlayerId,
        from = InviteFrom
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_InviteJoinTeam, c2s_InviteJoinTeam)
end

--申请加入队伍
function TeamSystem:RequestApplyJoin(nPlayerId)
    local c2s_ApplyJoinTeam =
    {
        player_id = nPlayerId,
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ApplyJoinTeam, c2s_ApplyJoinTeam)
end

--应答邀请、申请
function TeamSystem:ReplyJoinTeam(nReplyType, nPlayerId, nTeamId, bAccepted, nReason, bRecruit)
    local c2s_ReplyJoinTeam =
    {
        type = nReplyType,
        player_id = nPlayerId,
        team_id = nTeamId,
        accepted = bAccepted,
        reason = nReason,
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ReplyJoinTeam, c2s_ReplyJoinTeam)
end

--离队
function TeamSystem:LeaveTeam()
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_LeaveTeam)
end

--踢出队伍
function TeamSystem:KickOutTeamMember(nPlayerId)
    local c2s_KickOutTeamMember =
    {
        player_id = nPlayerId,
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_KickOutTeamMember, c2s_KickOutTeamMember)
end

--转让队长
function TeamSystem:TransferTeamLeader(nPlayerId)
    local c2s_TransferTeamLeader =
    {
        player_id = nPlayerId,
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_TransferTeamLeader, c2s_TransferTeamLeader)
end

--准备/取消准备
function TeamSystem:ReadyToMatch(bIsReady)
    local c2s_ReadyToMatch =
    {
        is_ready = bIsReady,
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_ReadyToMatch, c2s_ReadyToMatch)
end

--队长切换mode或自动匹配
function TeamSystem:ChangeMatchCondition(nTeamMode, bAutoMatchMaking, nDungeonId)
    log("TeamSystem:SetDungeonCondition,nTeamMode, bAutoMatch=",nTeamMode, bAutoMatchMaking, nDungeonId)
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    if self:IsInTeam() then
        if self:IsTeamLeader(nSelfPlayerId) then
            local c2s_SwitchMatchCondition =
            {
                team_mode = nTeamMode,
                auto_team_formation = bAutoMatchMaking,
                dungeon_id = nDungeonId,
            }
            NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_SwitchMatchCondition, c2s_SwitchMatchCondition)
        end
    end
end

function TeamSystem:AddToInviteIgnore(nPlayerId, bIgnore)
    if bIgnore then
        self.tbIgnorePlayerInvite[nPlayerId] = GlobalVariableSystem:GetLocalTime()
    else
        self.tbIgnorePlayerInvite[nPlayerId] = nil
    end
end

function TeamSystem:GetPlayerInviteIgnoreTime(nPlayerId)
    return self.tbIgnorePlayerInvite[nPlayerId]
end

function TeamSystem:AddToApplyIgore(nPlayerId, bIgnore)
    if bIgnore then
        self.tbIgnorePlayerApply[nPlayerId] = GlobalVariableSystem:GetLocalTime()
    else
        self.tbIgnorePlayerApply[nPlayerId] = nil
    end
end

function TeamSystem:GetPlayerApplyIgnoreTime(nPlayerId)
    return self.tbIgnorePlayerApply[nPlayerId]
end

function TeamSystem:WaittingInviteReply(nPlayerId)
    if nPlayerId then
        if self.tbWaitInvitePlayer[nPlayerId] then
            DelayTimer:ClearTimer(self.tbWaitInvitePlayer[nPlayerId])
            self.tbWaitInvitePlayer[nPlayerId] = nil
        end
        self.tbWaitInvitePlayer[nPlayerId] = DelayTimer:DelayRun(function()
            self.tbWaitInvitePlayer[nPlayerId] = nil
            log("TeamSystem:WaittingInviteReply time out")
            UIUtils.ShowToast(L10N_WAIT_TIME_OUT)
            self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_TEAM_INVITE_APPLY_WAIT_TIME_OUT, nPlayerId)
        end, WAIT_TIME_OUT)
    end
end

function TeamSystem:WaittingApplyReply(nPlayerId)
    if nPlayerId then
        if self.tbWaitApplyPlayer[nPlayerId] then
            DelayTimer:ClearTimer(self.tbWaitApplyPlayer[nPlayerId])
            self.tbWaitApplyPlayer[nPlayerId] = nil
        end
        self.tbWaitApplyPlayer[nPlayerId] = DelayTimer:DelayRun(function()
            self.tbWaitApplyPlayer[nPlayerId] = nil
            log("TeamSystem:tbWaitApplyPlayer time out")
            UIUtils.ShowToast(L10N_WAIT_TIME_OUT)
            self.EventHelper:FireEvent(ClientEventDef.EV_LOBBY_TEAM_INVITE_APPLY_WAIT_TIME_OUT, nPlayerId)
        end, WAIT_TIME_OUT)
    end
end

function TeamSystem:ResetInvitePlayer(nPlayerId)
    if nPlayerId then
        if self.tbWaitInvitePlayer[nPlayerId] then
            DelayTimer:ClearTimer(self.tbWaitInvitePlayer[nPlayerId])
            self.tbWaitInvitePlayer[nPlayerId] = nil
        end
    else
        self.tbWaitInvitePlayer = {}
    end
end

function TeamSystem:ResetApplyPlayer(nPlayerId)
    if nPlayerId then
        if self.tbWaitApplyPlayer[nPlayerId] then
            DelayTimer:ClearTimer(self.tbWaitApplyPlayer[nPlayerId])
            self.tbWaitApplyPlayer[nPlayerId] = nil
        end
    else
        self.tbWaitApplyPlayer = {}
    end
end


return TeamSystem