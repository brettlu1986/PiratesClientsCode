-----------------------------------------------------
--File Name    : BattleGroundSystem.lua
--Description  : 战场
-----------------------------------------------------
local NetworkManager       = dynamic_require("NetworkManager")
local Proto                = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIManager            = require("UIManager")
local UITextDef            = require("UITextDef")
local EventManager         = require("EventManager")
local BattleGroundDataTable= require("BattleGroundDataTable")
local UIDef                = require("UIDef")
local ClientEventDef       = require("ClientEventDef")
local L10N                 = require("L10N")
local UIUtils              = require("UIUtils")
-- local UIDialogHelper       = require("UIDialogHelper")
local UISetUtils           = require("UISetUtils")

local BattleGroundSystem = {}

local MATCH_TITLE = UISetUtils.GetL10NTextByKey("BATTLEGROUNDSYSTEM_MATCH_TITLE")
local L10N_AnswerText =
{
    [Proto.s2c_BattlegroundMatchmakingAnswer_Answer.DECLINED]      = UITextDef.BATTLEGROUND_ANSWER_DECLINED,
    [Proto.s2c_BattlegroundMatchmakingAnswer_Answer.DISCONNECTED]  = UITextDef.BATTLEGROUND_ANSWER_DISCONNECTED
}
local L10N_CancelReasonText =
{
    [Proto.s2c_BattlegroundMatchmakingCancelled_CancelReason.PLAYER_CANCEL]     = UITextDef.BATTLEGROUND_MATCH_CANCEL,
    [Proto.s2c_BattlegroundMatchmakingCancelled_CancelReason.PLAYER_DISCONNECT] = UITextDef.BATTLEGROUND_MATCH_DISCONNECT,
}
local L10N_FailedReasonText =
{
    [Proto.ReturnCode.BATTLEGROUND_INVALID_ID]              = UITextDef.BATTLEGROUND_FAILED_INVALID,
    [Proto.ReturnCode.BATTLEGROUND_NOT_OPEN]                = UITextDef.BATTLEGROUND_FAILED_NOTOPEN,
    [Proto.ReturnCode.BATTLEGROUND_INTERNAL_ERROR]          = UITextDef.BATTLEGROUND_FAILED_INTERNALERROR,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_STATE]            = UITextDef.BATTLEGROUND_FAILED_PLAYERSTATE,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_LEVEL]            = UITextDef.BATTLEGROUND_FAILED_PLAYERLEVEL,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_SCENE]            = UITextDef.BATTLEGROUND_FAILED_PLAYERSCENE,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_SHIP_GRADE]       = UITextDef.BATTLEGROUND_FAILED_SHIPGRADE,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_SHIP_CATEGORY]    = UITextDef.BATTLEGROUND_FAILED_SHIPCATEGORY,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_FORBIDDEN_BUFF]   = UITextDef.BATTLEGROUND_FAILED_FORBIDDENBUFF,
    [Proto.ReturnCode.BATTLEGROUND_PLAYER_DURABILITY]       = UITextDef.BATTLEGROUND_FAILED_PLAYDURABILITY,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_LEADER]             = UITextDef.BATTLEGROUND_FAILED_TEAMLEADER,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_SIZE]               = UITextDef.BATTLEGROUND_FAILED_TEAMSIZE,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_SHIP_CATEGORY]      = UITextDef.BATTLEGROUND_FAILED_TEAMSHIPCATEGORY,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_MEMBER_ONLINE]      = UITextDef.BATTLEGROUND_FAILED_MEMBERONLINE,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_MEMBER_STATE]       = UITextDef.BATTLEGROUND_FAILED_MEMBERSTATE,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_MEMBER_LEVEL]       = UITextDef.BATTLEGROUND_FAILED_MEMBERLEVEL,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_MEMBER_SCENE]       = UITextDef.BATTLEGROUND_FAILED_MEMBERSCENE,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_MEMBER_SHIP_GRADE]  = UITextDef.BATTLEGROUND_FAILED_MEMBERSHIPGRADE,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_FORBIDDEN_BUFF]     = UITextDef.BATTLEGROUND_FAILED_MEMBERFORBIDDENBUFF,
    [Proto.ReturnCode.BATTLEGROUND_TEAM_MEMBER_DURABILITY]  = UITextDef.BATTLEGROUND_FAILED_MEMBERDURABILITY,
}

function BattleGroundSystem:Init()
    return true
end

function BattleGroundSystem:Uninit()

end

function BattleGroundSystem:GetComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf == nil then
        logerror("BattleGroundSystem get playerself failed")
        return
    end
    local BattleGroundComponent = PlayerSelf.BattleGroundComponent
    if BattleGroundComponent == nil then
        logerror("BattleGroundSystem get BattleGroundComponent failed")
        return
    end

    return BattleGroundComponent
end

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    return Socket:SendPacket(szProto, tbPacket)
end

function BattleGroundSystem:RequestMatchMaking(nId)
    SendPacket(Proto.c2s_BattlegroundRequestMatchmaking, {battleground_id = nId})
end

function BattleGroundSystem:RequestAnswerMatchMaking(bAgree)
    SendPacket(Proto.c2s_BattlegroundAnswerMatchmaking, {accepted = bAgree})
end

function BattleGroundSystem:RequestCancelMatchmaking()
    SendPacket(Proto.c2s_BattlegroundCancelMatchmaking)
end

function BattleGroundSystem:RequestLeaderBoard(bIsCurWeek, nIndex, nCount)
    local c2s_BattlegroundLeaderboard = {
        leaderboard = bIsCurWeek and Proto.LeaderBoard.CURRENT or Proto.LeaderBoard.LAST_WEEK,
        start_from_rank = nIndex,
        max_result = nCount
    }
    SendPacket(Proto.c2s_BattlegroundLeaderboard, c2s_BattlegroundLeaderboard)
end

function BattleGroundSystem:RequestLeaderBoardRank(bIsCurWeek)
    local c2s_BattlegroundLeaderboardRank = {
        leaderboard = bIsCurWeek and Proto.LeaderBoard.CURRENT or Proto.LeaderBoard.LAST_WEEK
    }
    SendPacket(Proto.c2s_BattlegroundLeaderboardRank, c2s_BattlegroundLeaderboardRank)
end

local function OpenMatchingWnd(self, nId)
    local tbTemplate = BattleGroundDataTable:GetTemplate(nId)
    local szTitle    = L10N:Format(MATCH_TITLE, L10N:ToString(tbTemplate.l10nName))

    local SelfObj    = GamePlayerSelfHelper:Get()
    local TeamComponent = SelfObj.TeamComponent

    if TeamComponent:IsInTeam() then
        -- logerror("TeamComponent:IsInTeam open battleground")
        --如果处于组队状态，打开组队匹配窗口
        local wnd = UIManager:OpenWnd(UIDef.UI_PVP_MATCH,{szTitle = szTitle})

        wnd.CancelMatchmaking:Bind(self.RequestCancelMatchmaking, self)
        wnd.AnswerMatchMaking:Bind(self.RequestAnswerMatchMaking, self)
    else
        logwarning("ShowCountDownDialog")
        -- UIDialogHelper:ShowCountDownDialog(szTitle, UITextDef.MATCH_BEGIN, self.RequestCancelMatchmaking, self)

        -- --打开排位赛匹配窗口 ////////////////
        -- local wnd = UIManager:OpenWnd(UIDef.UI_PVP_SINGLE_MATCH, {szTitle = szTitle})
        -- wnd.CancelMatchmaking:Bind(self.RequestCancelMatchmaking, self)
    end
end

function BattleGroundSystem:RecevieAskMatchmaking(tbPacket)
    if not UIManager:IsWndVisible( UIDef.UI_PVP_MATCH ) then
        OpenMatchingWnd(self, tbPacket.battleground_id)
    end
end

local function OnShowToast(l10nErrorMsg)
    UIUtils.ShowToast(l10nErrorMsg , 1)
end

function BattleGroundSystem:ReceiveMatchMakingAnswer(tbPacket)
    local bAnswer = true
    if tbPacket.answer ~= Proto.s2c_BattlegroundMatchmakingAnswer_Answer.ACCEPTED then
        local l10nErrorMsg = L10N_AnswerText[tbPacket.answer]
        OnShowToast(l10nErrorMsg)
        bAnswer = false
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ANSWER_MATCH_MAKING, tbPacket.player_id, bAnswer)
end

function BattleGroundSystem:ReceiveMatchMakingFailed(tbPacket)
    local l10nErrorMsg = L10N_FailedReasonText[tbPacket.return_code]
    OnShowToast(l10nErrorMsg)
end

function BattleGroundSystem:ReceiveMatchMakingBegin(tbPacket)
    if(not UIManager:IsWndVisible( UIDef.UI_PVP_MATCH ))then
        OpenMatchingWnd(self, tbPacket.battleground_id)
    end
end

function BattleGroundSystem:ReceiveMatchMakingCancelled(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_MATCH_MAKING_CANCELLED)

    local l10nErrorMsg = L10N_CancelReasonText[tbPacket.reason]
    OnShowToast(l10nErrorMsg)
end

function BattleGroundSystem:ReceiveMatchMakingSuccessful(tbPacket)
    self:GetComponent():SetMatchPlayerInfo(tbPacket.players)
    local tbParam = {nDungeonId = tbPacket.dungeon_id, bOpenWithAnim = true}
    UIManager:OpenWnd(UIDef.UI_LOADING, tbParam)
    EventManager:OnFireEvent(ClientEventDef.EV_MATCH_MAKING_SUCCESS)
end

function BattleGroundSystem:ReceiveDailyFirstWinSync(tbPacket)
    self:GetComponent():SetDailyFirstWinTime(tbPacket.last_daily_first_win)
end

function BattleGroundSystem:ReceiveLeaderboard(tbPacket)
    local bIsCurWeek = tbPacket.leaderboard == Proto.LeaderBoard.CURRENT
    self:GetComponent():AddRankList(tbPacket.entries, tbPacket.no_more_entry, bIsCurWeek)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLEGROUND_LEADER_BOARD_LIST_UPDATE, bIsCurWeek)
end

function BattleGroundSystem:ReceiveLeaderboardRank(tbPacket)
    local bIsCurWeek = tbPacket.leaderboard == Proto.LeaderBoard.CURRENT
    local tbComponent = self:GetComponent()
    tbComponent:SetRank(tbPacket.rank, bIsCurWeek)
    EventManager:OnFireEvent(ClientEventDef.EV_BATTLEGROUND_LEADER_BOARD_RANK_UPDATE, bIsCurWeek)
end

function BattleGroundSystem:ReceiveContribution(tbPacket)
    local tbComponent = self:GetComponent()
    local nContribution = tbComponent:GetContribution(true)
    if tbPacket.battleground_point_current > nContribution then
        UIUtils.ShowGetBattleGroundPointToast(tbPacket.battleground_point_current - nContribution)
    end
    tbComponent:SetContribution(tbPacket.battleground_point_current, true)
end

function BattleGroundSystem:ReceiveLastContribution(tbPacket)
    self:GetComponent():SetContribution(tbPacket.battleground_point_last, false)
end

return BattleGroundSystem
