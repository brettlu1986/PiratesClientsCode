local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local TeamPacketProcessor = luaclass("TeamPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
--local Proto1 = require("ClientProtoNames")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local TeamSystem = require("TeamSystem")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TeamRefuseReasonDataTable = require("TeamRefuseReasonDataTable")
local L10N = require("L10N")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local MatchmakingSystem = require("MatchmakingSystem")

local ERROR_CODE_L10NTEXT =
{
    [Proto.ReturnCode.PLAYER_ALREADY_IN_TEAM] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_PLAYER_ALREADY_IN_TEAM"),  --玩家已经加入了队伍
    [Proto.ReturnCode.INVITEE_ALREADY_IN_TEAM] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_INVITE_ALREADY_IN_TEAM"),  --被邀请人已经加入了队伍
    [Proto.ReturnCode.PLAYER_NOT_IN_TEAM] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_PLAYER_NOT_IN_TEAM"),  --玩家所在队伍已解散
    [Proto.ReturnCode.PLAYER_NOT_IN_INVITE_LIST] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_PLAYER_NOT_IN_INVITE_LIST"),  --玩家不在邀请列表
    [Proto.ReturnCode.NOT_TEAM_LEADER] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_NOT_TEAM_LEADER"),  --不是队长
    [Proto.ReturnCode.NOT_IN_APPLY_LIST] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_NOT_IN_APPLY_LIST"),  --玩家不在申请列表
    [Proto.ReturnCode.INVITATION_OUT_DATE] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_INVITATION_OUT_DATE"),  --邀请已经过期
    [Proto.ReturnCode.APPLICATION_OUT_DATE] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_APPLICATION_OUT_DATE"),  --申请已经过期
    [Proto.ReturnCode.TEAM_DISMISSED] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_DISMISSED"),  --队伍已解散
    [Proto.ReturnCode.NOT_TEAM_MEMBER] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_NOT_TEAM_MEMBER"),  --不是队伍成员
    [Proto.ReturnCode.TEAM_FULL] = UISetUtils.GetL10NTextByKey("TEAM_ERROR_FULL"),  --队伍满员
    [Proto.ReturnCode.OTHER_SIDE_MATCHING] = UISetUtils.GetL10NTextByKey("TEAM_OTHER_SIDE_MATCHMAKING"),  --对方匹配中
    [Proto.ReturnCode.OTHER_SIDE_BATTLING] = UISetUtils.GetL10NTextByKey("TEAM_OTHER_SIDE_BATTLING"),  --对方战斗中
    [Proto.ReturnCode.RECRUIT_NOT_ALLOW_CHANGE] = UISetUtils.GetL10NTextByKey("RECRUIT_NOT_ALLOW_CHANGE"),  --招募人数不允许修改
    [Proto.ReturnCode.OTHER_SIDE_OFFLINE] = UISetUtils.GetL10NTextByKey("LOBBY_TEAM_OTHER_SIDE_OFFLINE"),  --对方离线
}

local IGNORE_TIME_SPAN = 300  --秒

local function ShowMessageToast(nErrorCode, l10nMessage)
    if GlobalVariableSystem:IsInDungeon() then
        return
    end
    local l10nText = l10nMessage
    if nErrorCode then
        l10nText = ERROR_CODE_L10NTEXT[nErrorCode]
    end
    if l10nText then
        UIUtils.ShowToast(l10nText)
    end
end

function TeamPacketProcessor:OnSyncTeam(tbPacket)
    TeamSystem:SyncTeam(tbPacket)

    local bDungeon = GlobalVariableSystem:IsInDungeon()
    if not bDungeon then
        LobbySystem:GetSub(LobbySubTypeDef.MAIN):RefreshTeammate()
        EventManager:OnFireEvent(ClientEventDef.EV_TEAM_SYNC, TeamSystem:GetTeamMemberIds())
    end
end

--聊天邀请结果
function TeamPacketProcessor:OnChatInviteJoinTeam(tbPacket)
    local l10nMessage = ""
    if tbPacket.return_code == Proto.ReturnCode.OK then
        l10nMessage = UISetUtils.GetL10NTextByKey("TEAM_INVITE_SEND_OK")
    else
        l10nMessage = ERROR_CODE_L10NTEXT[tbPacket.return_code]
    end
    ShowMessageToast(nil, l10nMessage)
end

--聊天邀请cd合法性结果
function TeamPacketProcessor:OnRecruitReply(tbPacket)
    local l10nMessage = ""
    if tbPacket.return_code == Proto.ReturnCode.OK then
        l10nMessage = UISetUtils.GetL10NTextByKey("TEAM_INVITE_SEND_OK")
    elseif tbPacket.return_code == Proto.ReturnCode.RECRUIT_IN_COOLDOWN then
        local nRemainTime = tbPacket.remaining_cooldown_seconds
        l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("CHAT_TIME_REMINE"), nRemainTime)
    end
    ShowMessageToast(nil, l10nMessage)
end

--邀请结果
function TeamPacketProcessor:OnInviteJoinTeam(tbPacket)
    local l10nMessage = ""
    if tbPacket.return_code == Proto.ReturnCode.OK then
        l10nMessage = UISetUtils.GetL10NTextByKey("TEAM_INVITE_SEND_OK")
        local nPlayerId = tbPacket.player_id
        TeamSystem:WaittingInviteReply(nPlayerId)
        EventManager:OnFireEvent(ClientEventDef.EV_TEAM_INVITE_APPLY_WAITING, nPlayerId)
    else
        l10nMessage = ERROR_CODE_L10NTEXT[tbPacket.return_code]
    end
    ShowMessageToast(nil, l10nMessage)
end

--申请结果
function TeamPacketProcessor:OnApplyJoinTeam(tbPacket)
    local l10nMessage = ""
    if tbPacket.return_code == Proto.ReturnCode.OK then
        l10nMessage = UISetUtils.GetL10NTextByKey("TEAM_APPLY_SEND_OK")
        local nPlayerId = tbPacket.player_id
        TeamSystem:WaittingApplyReply(nPlayerId)
        EventManager:OnFireEvent(ClientEventDef.EV_TEAM_INVITE_APPLY_WAITING, nPlayerId)
    else
        l10nMessage = ERROR_CODE_L10NTEXT[tbPacket.return_code]
    end
    ShowMessageToast(nil, l10nMessage)
end

--应答结果
function TeamPacketProcessor:OnReplyJoinTeam(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowMessageToast(tbPacket.return_code)
    end
end

--通知玩家有邀请和申请
function TeamPacketProcessor:OnInviteApplyNotify(tbPacket)
    --EventManager:OnFireEvent(ClientEventDef.EV_INVITE_APPLY_NOTIFY, tbPacket)
    local nIgnoreTime = nil
    if tbPacket.type == Proto.InviteApplyType.INVITE_JOIN_TEAM then
        nIgnoreTime = TeamSystem:GetPlayerInviteIgnoreTime(tbPacket.player_summary.id)
    elseif tbPacket.type == Proto.InviteApplyType.APPLY_JOIN_TEAM then
        nIgnoreTime = TeamSystem:GetPlayerApplyIgnoreTime(tbPacket.player_summary.id)
    end
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if not bIsInDungeon then
        if not nIgnoreTime or (GlobalVariableSystem:GetLocalTime() - nIgnoreTime) >= IGNORE_TIME_SPAN then
            if UIManager:IsWndVisible(UIDef.UI_LOBBY_TEAM_INVITE) then
                EventManager:OnFireEvent(ClientEventDef.EV_TEAM_INVITE_APPLY, tbPacket)
            else
                UIManager:OpenWnd(UIDef.UI_LOBBY_TEAM_INVITE, tbPacket)
            end
        end
    end
end


--通知玩家邀请和申请结果
function TeamPacketProcessor:OnInviteApplyReplyNotify(tbPacket)
    if not tbPacket.accepted then
        local tbReasonTempalte = TeamRefuseReasonDataTable:GetTemplate(tbPacket.reason)
        if tbReasonTempalte then
            local l10nMessage = ""
            if tbPacket.reason == 0 then
                --未答复
                l10nMessage = tbReasonTempalte.l10nReasonText
            else
                l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("TEAM_INVITE_REFUSED"), tbPacket.name, tbReasonTempalte.l10nReasonText)
            end
            ShowMessageToast(nil, l10nMessage)
        end
        local nPlayerId = tbPacket.player_id
        if tbPacket.type == Proto.InviteApplyType.INVITE_JOIN_TEAM then
            TeamSystem:ResetInvitePlayer(nPlayerId)
        elseif tbPacket.type == Proto.InviteApplyType.APPLY_JOIN_TEAM then
            TeamSystem:ResetApplyPlayer(nPlayerId)
        end
        EventManager:OnFireEvent(ClientEventDef.EV_TEAM_INVITE_APPLY_WAITING_REPLY, nPlayerId)
    end
    --EventManager:OnFireEvent(ClientEventDef.EV_INVITE_APPLY_REPLY_NOTIFY, tbPacket)
end

--所有队员收到的队伍人数改变
function TeamPacketProcessor:OnNotifyTeamChanged(tbPacket)
    local l10nMessage = nil
    local bClearTeamData = false
    local nSelfPlayerId = GamePlayerSelfHelper:Get():GetPlayerId()
    if tbPacket.change_type == Proto.ChangeType.ADD_MEMBER then
        if tbPacket.player_id == nSelfPlayerId then
            l10nMessage = UISetUtils.GetL10NTextByKey("TEAM_JOIN_OK")
        else
            l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("TEAM_NEW_MEMBER_JOIN"), tbPacket.name)
        end
        
    elseif tbPacket.change_type == Proto.ChangeType.LEAVE_TEAM then
        if tbPacket.player_id == nSelfPlayerId then
            bClearTeamData = true
        else
            l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("TEAM_MEMBER_LEAVED"), tbPacket.name)
        end
    elseif tbPacket.change_type == Proto.ChangeType.KICK_OUT_TEAM then
        if tbPacket.player_id == nSelfPlayerId then
            l10nMessage = UISetUtils.GetL10NTextByKey("TEAM_YOU_ARE_KICKED_OUT")
            bClearTeamData = true
        else
            l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("TEAM_MEMBER_BE_KICKED_OUT"), tbPacket.name)
        end
    elseif tbPacket.change_type == Proto.ChangeType.DISMISS then
        bClearTeamData = true
    end
    if bClearTeamData then
        TeamSystem:ClearTeamMembers()
        if not GlobalVariableSystem:IsInDungeon() then
            LobbySystem:GetSub(LobbySubTypeDef.MAIN):DismissTeam()
        end
        EventManager:OnFireEvent(ClientEventDef.EV_TEAM_CLEAR_MEMBERS)
        UIManager:CloseWnd(UIDef.UI_LOBBY_TEAM_INVITE)
    end
    ShowMessageToast(nil, l10nMessage)
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_CHANGED, tbPacket)
end

--队长改变通知
function TeamPacketProcessor:OnLeaderChangedNotify(tbPacket)
    local nOldLeader = TeamSystem:GetTeamLeader()
    TeamSystem:UpdateTeamLeader(tbPacket.player_id)
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_LEADER_CHANGED, tbPacket.player_id, nOldLeader)
end


function TeamPacketProcessor:OnReadyToMatchNotify(tbPacket)
    TeamSystem:UpdateTeamMemberReady(tbPacket.player_id, tbPacket.is_ready)
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_MEMBER_READY_MATCH, tbPacket.player_id, tbPacket.is_ready)
end

function TeamPacketProcessor:OnReadyToMatch(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowMessageToast(tbPacket.return_code)
    end
end

function TeamPacketProcessor:OnSwitchMatchConditionNotify(tbPacket)
    local nMatchmakingMode = tbPacket.team_mode
    local nDungeonId = tbPacket.dungeon_id
    local bAutoMatchmaking = tbPacket.auto_team_formation
    
    if nMatchmakingMode == 0 then
        nMatchmakingMode = 4
        bAutoMatchmaking = true
        logerror("TeamPacketProcessor:OnSwitchMatchConditionNotify, receive error value from server,nMatchmakingMode is 0")
    end
    if nDungeonId == 0 then
        nDungeonId = 100011
        bAutoMatchmaking = true
        logerror("TeamPacketProcessor:OnSwitchMatchConditionNotify, receive error value from server,nDungeonId is 0")
    end
    MatchmakingSystem:SetAutoMatchmaking(bAutoMatchmaking)
    MatchmakingSystem:SetSelectDungeon(nDungeonId)
    MatchmakingSystem:SetMatchmakingMode(nMatchmakingMode)
    EventManager:OnFireEvent(ClientEventDef.EV_TEAM_MATCH_CONDITION_CHANGED, nMatchmakingMode, bAutoMatchmaking, nDungeonId)
end

-- 注册处理包
function TeamPacketProcessor:RegisterPackets()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_SyncTeam, self, self.OnSyncTeam)
    self:BindMethod(Proto.s2c_InviteJoinTeam, self, self.OnInviteJoinTeam)
    self:BindMethod(Proto.s2c_ApplyJoinTeam, self, self.OnApplyJoinTeam)
    self:BindMethod(Proto.s2c_ReplyJoinTeam, self, self.OnReplyJoinTeam)
    self:BindMethod(Proto.s2c_NotifyInviteApply, self, self.OnInviteApplyNotify)
    self:BindMethod(Proto.s2c_NotifyReplyInviteApply, self, self.OnInviteApplyReplyNotify)
    self:BindMethod(Proto.s2c_NotifyTeamChanged, self, self.OnNotifyTeamChanged)
    self:BindMethod(Proto.s2c_NotifyLeaderChanged, self, self.OnLeaderChangedNotify)
    self:BindMethod(Proto.s2c_NotifyReadyToMatch, self, self.OnReadyToMatchNotify)
    self:BindMethod(Proto.s2c_ReadyToMatch, self, self.OnReadyToMatch)
    self:BindMethod(Proto.s2c_NotifySwitchMatchCondition, self, self.OnSwitchMatchConditionNotify)
    self:BindMethod(Proto.s2c_ReplyRecruitTeammate, self, self.OnChatInviteJoinTeam)
    self:BindMethod(Proto.s2c_RecruitTeammate, self, self.OnRecruitReply)
end

-- 初始化
function TeamPacketProcessor:Init()
    TeamPacketProcessor.super.Init(self)
    self:RegisterPackets()
    return true
end

-- 结束
function TeamPacketProcessor:Uninit()
    TeamPacketProcessor.super.Uninit(self)
end

return TeamPacketProcessor
