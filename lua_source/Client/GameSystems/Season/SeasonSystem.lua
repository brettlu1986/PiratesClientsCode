local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local UIUtils = require("UIUtils")
local EventManager = require("EventManager")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local UITextDef = require("UITextDef")
local SelfEventHelper = require("SelfEventHelper")
local AwardSystem = require("AwardSystem")
local AwardSessionType = require("AwardSessionType")
local TimeUtil = require("TimeUtil")
local DelayTimer = require("DelayTimer")
local SeasonDataTable = require("SeasonDataTable")
local WndDataTable = require("WndDataTable")
local MatchmakingTeamModeDataTable = require("MatchmakingTeamModeDataTable")
local RankDataTable = require("RankDataTable")

local DEFAULT_RANK = 11

local Return_Code = {
    [Proto.ReturnCode.ALREADY_COLLECT_RANK_DAILY_CHEST] = UITextDef.SEASON_ALREADY_GET_DAILYAWARD,
    [Proto.ReturnCode.ALREADY_ACTIVE_BATTLE_PASS] = UITextDef.SEASON_ALREADY_ACTIVE_BATTLE_PASS,
    [Proto.ReturnCode.BATTLE_TIER_INVALID] = UITextDef.SEASON_BATTLE_TIER_INVALID,
    [Proto.ReturnCode.TICKET_IS_NOT_ENOUGH] = UITextDef.TICKET_IS_NOT_ENOUGH,
    [Proto.ReturnCode.BATTLE_PASS_NOT_ACTIVE] = UITextDef.SEASON_BATTLE_PASS_NOT_ACTIVE,

    [Proto.ReturnCode.CHALLENGE_NOT_EXIST] = UITextDef.CHALLENGE_NOT_EXIST,
    [Proto.ReturnCode.CHALLENGE_WEEKLY_NOT_COMPLETED] = UITextDef.CHALLENGE_WEEKLY_NOT_COMPLETED,
    [Proto.ReturnCode.CHALLENGE_WEEKLY_HAS_AWARDED] = UITextDef.CHALLENGE_WEEKLY_HAS_AWARDED,
    [Proto.ReturnCode.CHALLENGE_HAS_EXPIRED] = UITextDef.CHALLENGE_HAS_EXPIRED,
    [Proto.ReturnCode.CHALLENGE_SUB_NOT_EXIST] = UITextDef.CHALLENGE_SUB_NOT_EXIST,
    [Proto.ReturnCode.CHALLENGE_SUB_NOT_COMPLETED] = UITextDef.CHALLENGE_SUB_NOT_COMPLETED,
    [Proto.ReturnCode.FORBID_VIEW_STATS] = UITextDef.FORBID_VIEW_STATS,
    [Proto.ReturnCode.SEASON_NOT_JOINED] = UITextDef.SEASON_NOT_JOINED,
    [Proto.ReturnCode.OFF_SEASON_BATTLE_PASS] = UITextDef.OFF_SEASON_BATTLE_PASS,
    [Proto.ReturnCode.BATTLE_TIER_LEVEL_AWARD_RECEIVED] = UITextDef.BATTLE_TIER_LEVEL_AWARD_RECEIVED
}

local SeasonSystem = {}
SeasonSystem.bInLobby = nil
SeasonSystem.tbCacheRankUp = nil
SeasonSystem.tbCacheTierUp = nil
SeasonSystem.tbRefreshChestTimer = nil
SeasonSystem.nRequestSeasonId = nil
SeasonSystem.nOldTier = nil

local function ShowErrorCode(nReturnCode)
    local l10nErrorCode = Return_Code[nReturnCode]
    if l10nErrorCode ~= nil then
        UIUtils.ShowToast(l10nErrorCode)
    else
        log("SeasonSystem invalid return code:", nReturnCode)
    end
end

local function OnPlayerDataSync(self, tbPlayerData, bReconnect)
    -- if bReconnect then
    --     return
    -- end

    local Component = self:GetComponent()
    if Component == nil then
        log("SeasonSystem enter lobyy get component invalid component")
        return
    end

    local nStatus = Component:GetNewSeasonStatus()
    local tbPlayerSeasonStatus = Proto.PlayerSeasonStatus
    if nStatus == tbPlayerSeasonStatus.FIRST_TIME then
        log("seasonSystem first season")
        self:RequestGetSeason()
    elseif nStatus == tbPlayerSeasonStatus.RESET then
        log("seasonSystem rest season")
        self:RequestResetSeason()
    else
        self:RequestGetSeason()
    end
end

local function ClearRefreshChestTimer(self)
    if self.tbRefreshChestTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRefreshChestTimer)
        self.tbRefreshChestTimer = nil
    end
end

local function RefreshRankDailyChest(self)
    local Component = self:GetComponent()
    local nTime = Component:GetRankDailyTime()
    local nRemainTime = TimeUtil.CalRefreshRemainSeconds(nTime)
    log("SeasonSystem:RefreshRankDailyChest ", nRemainTime)
    if nRemainTime > 0 then
        local DoRefreshRankDailyChest = function()
            ClearRefreshChestTimer(self)
            EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK)
        end
        self.tbRefreshChestTimer = DelayTimer:DelayRun(function() DoRefreshRankDailyChest() end, nRemainTime)
    else
        if Component:GetBattlePass() ~= nil then
            EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK)
        end
    end
end

local function OnEnterLobby(self)
    self.bInLobby = true
    if self.tbCacheRankUp then
        UIManager:OpenWnd(UIDef.UI_SEASON_RANKUP, self.tbCacheRankUp)
        self.tbCacheRankUp = nil
    end
    RefreshRankDailyChest(self)
end

local function OnLeaveLobby(self)
    self.bInLobby = false
    self.tbCacheRankUp = nil
    local Component = self:GetComponent()
    if Component ~= nil then
        Component:ClearCurSeasonStats()
    else
        logwarning("season system leave lobby component is nil")
    end
    ClearRefreshChestTimer(self)
end

local function FinishSeasonAwardSession()
    local SeasonAwardSession = AwardSystem:GetAlivedSession(AwardSessionType.SeasonAwardSession)
    if SeasonAwardSession then
        AwardSystem:FinishSession(SeasonAwardSession)
    else
        log("OnAwardSeason not find season session")
    end
end

local function OnAwardSeason(self)
    if self.tbCacheTierUp then
        UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEUP, {nBattleTier = self.tbCacheTierUp.new_battle_tier})
        self.tbCacheTierUp = nil
    else
        FinishSeasonAwardSession()
    end
end

local function OnCloseUI(self, szWndName)
    if szWndName == UIDef.UI_SEASON_BATTLEUP then
        FinishSeasonAwardSession()
    end
end

local function GetSeasonOpenWndName(self)
    local Component = self:GetComponent(self)
    local nSeasonId = Component:GetSeasonId()
    local szBaseUI  = UIDef.UI_SEASON_GO
    local szUI = string.format("%s%d", szBaseUI, nSeasonId)
    if WndDataTable:GetTemplate(szUI) ~= nil then
        return szUI
    else
        return szBaseUI
    end
end

local function SendPacket(szProto, tbPacket)
    local Socket = NetworkManager:GetHubServerProxy()
    Socket:SendPacket(szProto, tbPacket)
end






function SeasonSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_READY, self, OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_AWARD_SEASON, self, OnAwardSeason)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)

    return true
end

function SeasonSystem:Uninit()
    ClearRefreshChestTimer(self)
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    self.bInLobby = nil
    self.tbCacheRankUp = nil
    self.nRequestSeasonId = nil
end

function SeasonSystem:GetComponent()
    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf ~= nil then
        return tbPlayerSelf.SeasonComponent
    end
end

function SeasonSystem:RequestToGetSeasonSummary(nPlayerId)
    local c2s_GetSeasonSummary = {
        player_id = nPlayerId
    }
    SendPacket(Proto.c2s_GetSeasonSummary, c2s_GetSeasonSummary)
end


function SeasonSystem:RequestResetSeason()
    SendPacket(Proto.c2s_ResetSeason)
end

function SeasonSystem:RequestGetSeason()
    SendPacket(Proto.c2s_GetSeason)
end

function SeasonSystem:RequestBuyBattlePass()
    local Component = self:GetComponent()
    local tbPass = Component:GetBattlePass()
    self.nOldTier = tbPass.battle_tier
    SendPacket(Proto.c2s_BuyBattlePass)
end

function SeasonSystem:RequestBuyBattleTier(nTier)
    local Component = self:GetComponent()
    local tbPass = Component:GetBattlePass()
    self.nOldTier = tbPass.battle_tier
    local c2s_BuyBattleTier = {
        battle_tier = nTier
    }
    SendPacket(Proto.c2s_BuyBattleTier, c2s_BuyBattleTier)
end

function SeasonSystem:RequestCollectRankDailyChest()
    SendPacket(Proto.c2s_CollectRankDailyChest)
end

function SeasonSystem:RequestGetSeasonStats(nPlayerId, nSeasonId)
    local Component = self:GetComponent()
    if nPlayerId == nil then
        local tbPlayerSelf = GamePlayerSelfHelper:Get()
        nPlayerId = tbPlayerSelf.nPlayerId
    end
    if nSeasonId == nil then
        nSeasonId = Component:GetSeasonId()
    end
    local c2s_GetSeasonStats = {
        season_id = nSeasonId,
        player_id = nPlayerId
    }
    SendPacket(Proto.c2s_GetSeasonStats, c2s_GetSeasonStats)
end

function SeasonSystem:RequestGetChallenge(nType)
    if nType == Proto.ChallengeType.WEEKLY then
        self:GetCurrentChallengeWeekId()
    end

    local c2s_GetChallenge = {
        type = nType
    }
    SendPacket(Proto.c2s_GetChallenge, c2s_GetChallenge)
end

function SeasonSystem:GetCurrentChallengeWeekId()
    SendPacket(Proto.c2s_CurrentChallengeWeekId)
end

function SeasonSystem:RequestChallengeSubAward(nType, nId)
    local c2s_ChallengeSubAward = {
        type = nType,
        sub_id = nId
    }
    SendPacket(Proto.c2s_ChallengeSubAward, c2s_ChallengeSubAward)
end

function SeasonSystem:RequestChallengeWeeklyAward()
    SendPacket(Proto.c2s_ChallengeWeeklyAward)
end

function SeasonSystem:RequestGetSeasonHitorySummaries()
    SendPacket(Proto.c2s_GetSeasonHistorySummaries)
end

function SeasonSystem:RequestGetSeasonHistoryDetails(nSeasonId)
    self.nRequestSeasonId = nSeasonId
    local c2s_GetSeasonHistoryDetails = {
        season_id = nSeasonId
    }
    SendPacket(Proto.c2s_GetSeasonHistoryDetails, c2s_GetSeasonHistoryDetails)
end

function SeasonSystem:RequestGetSeasonPointRanking()
    SendPacket(Proto.c2s_GetSeasonPointRanking)
end

function SeasonSystem:RequestReceiveBattleTierAward(nTier)
    local c2s_ReceiveBattleTierAward = {
        battle_tier_level = nTier
    }
    SendPacket(Proto.c2s_ReceiveBattleTierAward, c2s_ReceiveBattleTierAward)
end

function SeasonSystem:RequestReceiveAllBattleTierAward()
    SendPacket(Proto.c2s_ReceiveAllBattleTierAward)
end

function SeasonSystem:OnRecvGetSeason(tbPacket)
    log("SeasonSystem:OnRecvGetSeason")
    local Component = self:GetComponent()

    local nOldStatus = Component:GetNewSeasonStatus()
    if nOldStatus ~= Proto.PlayerSeasonStatus.OFF_SEASON then
        Component:SetNewSeasonStatus(Proto.PlayerSeasonStatus.RUNNING)
    end
    Component:SetSeasonSummary(tbPacket.season.summary)
    Component:SetSeasonBattlePass(tbPacket.season.battle_pass)
    self:OnRecvCollectRankDailyChest({return_code =  Proto.ReturnCode.OK, rank_daily_chest = tbPacket.season.summary.season_rank.rank_daily_chest})

    -- Component:SetSeasonChallenge(tbPacket.season.challenge)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_GET_SEASON_DATA)
    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_STATUS, nOldStatus)
    local tbPlayerSeasonStatus = Proto.PlayerSeasonStatus
    if (nOldStatus == tbPlayerSeasonStatus.FIRST_TIME or nOldStatus == tbPlayerSeasonStatus.RESET)
        and self.bInLobby then
        UIManager:OpenWnd(GetSeasonOpenWndName(self), {nStatus = nOldStatus})
    else
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK)
end

function SeasonSystem:OnRecvResetSeason(tbPacket)
    log("SeasonSystem:OnRecvResetSeason")
    local Component = self:GetComponent()

    local nOldStatus = Component:GetNewSeasonStatus()
    Component:SetNewSeasonStatus(Proto.PlayerSeasonStatus.RUNNING)
    Component:SetSeasonSummary(tbPacket.season.summary)
    Component:SetSeasonBattlePass(tbPacket.season.battle_pass)
    -- Component:SetSeasonChallenge(tbPacket.season.challenge)

    Component:SetLastSeasonRank(tbPacket.last_season_rank)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_GET_SEASON_DATA)

    if self.bInLobby then
        UIManager:OpenWnd(GetSeasonOpenWndName(self), {nStatus = nOldStatus})
    else
        EventManager:OnFireEvent(ClientEventDef.EV_ON_NEXT_POP)
    end
end

function SeasonSystem:OnRecvCollectRankDailyChest(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
    end
    local Component = self:GetComponent()
    Component:SetRankDailyTime(tbPacket.rank_daily_chest)
    RefreshRankDailyChest(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK)
end

function SeasonSystem:OnRecvNotifyRankChange(tbPacket)
    local Component = self:GetComponent()
    if Component == nil then
        logerror("recv OnRecvNotifyRankChange but no component")
        return
    end
    if Component:GetCurRank() == nil then
        -- GetSeason数据包还没有收到，就收到了change包，出现在顶号情况下
        return
    end
    local tbOldRank = Component:GetCurRankByMode(tbPacket.rank.mode)
    Component:SetRankMode(tbPacket.rank)
    Component:SetSeasonPoint(tbPacket.season_point)

    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_RANK, tbPacket.rank.mode)

    local tbOldRankTemp = RankDataTable:GetTemplate(tbOldRank.rank)
    local tbCurRankTemp = RankDataTable:GetTemplate(tbPacket.rank.rank)
    local nChangeRank = tbPacket.rank.rank - tbOldRank.rank
    if tbOldRankTemp ~= nil and tbCurRankTemp ~= nil then
        nChangeRank = tbCurRankTemp.nRankLevel - tbOldRankTemp.nRankLevel
    end
    local tbChange = tbPacket.rank
    tbChange.rank_change = nChangeRank
    tbChange.point_change = tbPacket.rank.rank_point - tbOldRank.rank_point
    tbChange.protect_change = tbPacket.rank.rank_protect - tbOldRank.rank_protect
    tbChange.old_rank = tbOldRank.rank
    tbChange.mode = tbPacket.rank.mode
    tbChange.rank_point = tbPacket.rank.rank_point
    if (tbChange.rank_change ~= 0) or (tbChange.protect_change ~= 0  and  tbPacket.rank.rank_point <= tbOldRank.rank_point) then
        if self.bInLobby then
            UIManager:OpenWnd(UIDef.UI_SEASON_RANKUP, tbChange)
        else
            --缓存，等进入lobby再显示界面
            self.tbCacheRankUp = tbChange
        end
    end
end

function SeasonSystem:OnRecvBuyBattleTier(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    local Component = self:GetComponent()
    Component:SetBattleTier(tbPacket.battle_tier)
    if self.nOldTier then
        for i = self.nOldTier + 1, tbPacket.battle_tier do
            Component:SetReceiveBattleTierAward(i)
        end
    else
        Component:SetReceiveBattleTierAward(tbPacket.battle_tier)
    end
    -- 先弹出道具奖励界面，点击确定后，再弹出升阶界面
    -- if UIManager:IsWndOpen(UIDef.UI_LOBBY_AWARD_ITEM) then
    --     self.tbCacheTierUp = tbPacket
    -- else
    --     UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEUP, {nBattleTier = tbPacket.battle_tier})
    -- end
    UIManager:CloseWnd(UIDef.UI_SEASON_BATTLE_TIER_BUY)
    if self.bInLobby then
        UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEPASS)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS)
end

function SeasonSystem:OnRecvNotifyBattleStar(tbPacket)
    local Component = self:GetComponent()
    if Component:GetBattlePass() == nil then
        -- GetSeason数据包还没有收到，就收到了change包，出现在顶号情况下
        return
    end
    Component:SetBattleStar(tbPacket.battle_star)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS)
end

function SeasonSystem:OnRecvBattleTierUp(tbPacket)
    local Component = self:GetComponent()
    if Component:GetBattlePass() == nil then
        -- GetSeason数据包还没有收到，就收到了change包，出现在顶号情况下
        log("断线重连后服务器推送的OnRecvBattleTierUp消息在客户端请求的消息c2s_GetSeasonData之前下来")
        return
    end
    Component:SetBattleStar(tbPacket.new_battle_star)
    Component:SetBattleTier(tbPacket.new_battle_tier)

    if not AwardSystem:GetAlivedSession(AwardSessionType.SeasonAwardSession) then
        UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEUP, {nBattleTier = tbPacket.new_battle_tier})
    else
        self.tbCacheTierUp = tbPacket
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS)
end

function SeasonSystem:OnRecvBuyBattlePass(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    local Component = self:GetComponent()
    Component:SetPassActive()
    if self.nOldTier then
        for i = 1, self.nOldTier do
            Component:SetReceiveBattleTierAward(i)
        end
    end
    UIManager:CloseWnd(UIDef.UI_SEASON_BATTLEPASS_ADVANCE)
    UIManager:OpenWnd(UIDef.UI_SEASON_BATTLEUP, {bIsBattlePass = true})
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_PASS)
end

function SeasonSystem:OnRecvGetSeasonStats(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        if tbPacket.return_code ~= Proto.ReturnCode.SEASON_NOT_JOINED then
            ShowErrorCode(tbPacket.return_code)
        end
        local BuildBlankSeasonStats = function()
            return {
                matches               = 0,
                wins                  = 0,
                top_ten               = 0,
                kill                  = 0,
                death                 = 0,
                total_duration        = 0,
                duration              = 0,
                total_distance        = 0,
                distance              = 0,
                most_damage           = 0,
                most_kills            = 0,
                rescues               = 0,
                heals                 = 0,
                critical              = 0,
                hits                  = 0,
                attacks               = 0,
                damage                = 0,
                battle_points         = 0,
                dimensional_survivals = 0,
                dimensional_damages   = 0,
                dimensional_kills     = 0,
                dimensional_assists   = 0,
                dimensional_items     = 0,
            }
        end

        tbPacket.stats = {}
        local tbModes = MatchmakingTeamModeDataTable:GetAllMode()
        for i, v in ipairs(tbModes) do
            table.insert(tbPacket.stats, {key = v.nId, value = BuildBlankSeasonStats()})
        end
    end

    local tbPlayerSelf = GamePlayerSelfHelper:Get()
    if tbPlayerSelf and tbPacket.player_id == tbPlayerSelf.nPlayerId then
        log("set self season stats")
        local Component = self:GetComponent()
        Component:SetSeasonStats(tbPacket.season_id, tbPacket.stats)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_STATS, tbPacket.stats, tbPacket.return_code == Proto.ReturnCode.OK)
end

function SeasonSystem:OnRecvGetChallenge(tbPacket)
    local Component = self:GetComponent()
    if Component then
        Component:SetSeasonChallenge(tbPacket)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE)
    end
end

function SeasonSystem:OnRecvChallengeSubAward(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    local Component = self:GetComponent()
    if Component then
        if Component:GetSeasonChallenge(tbPacket.type) == nil then
            -- GetSeason数据包还没有收到，就收到了change包，出现在顶号情况下
            log("断线重连后服务器推送的OnRecvChallengeSubAward消息在客户端请求的消息s2c_GetChallenge之前下来")
            return
        end

        Component:SetGetChallengeAward(tbPacket.type, tbPacket.sub_id)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE)
    end
end

function SeasonSystem:OnRecvChallengeWeeklyAward(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    local Component = self:GetComponent()
    if Component then
        if Component:GetSeasonChallenge(Proto.ChallengeType.WEEKLY) == nil then
            -- GetSeason数据包还没有收到，就收到了change包，出现在顶号情况下
            log("断线重连后服务器推送的OnRecvChallengeWeeklyAward消息在客户端请求的消息s2c_GetChallenge之前下来")
            return
        end

        Component:SetChallengeWeekAward(Proto.ChallengeType.WEEKLY)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE_WEEKLY_AWARD)
    end
end

function SeasonSystem:OnRecvCurrentChallengeWeekId(tbPacket)
    local Component = self:GetComponent()
    if Component then
        Component:SetCurWeek(tbPacket.week_id)
    end
end

function SeasonSystem:OnRecvNotifyChallengeAwardStatus(tbPacket)
    local Component = self:GetComponent()
    if Component then
        Component:SetChallengeAwardStatus(tbPacket.award_status)
        EventManager:OnFireEvent(ClientEventDef.EV_ON_REFRESH_SEASON_CHALLENGE_AWARD_STATUS)
    end
end

function SeasonSystem:OnRecvGetSeasonHistorySummaries(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        tbPacket.summaries = {}
    end
    -- 没有参加的赛季服务器不发，需要客户端自己补上
    -- if #tbPacket.summaries > 0 then
        local Component = self:GetComponent()
        local nCurSeasonId = Component:GetSeasonId()
        local IsExist = function(nSeasonId)
            for i, v in ipairs(tbPacket.summaries) do
                if v.season_id == nSeasonId then
                    return true
                end
            end
            return false
        end

        local tbContainer = SeasonDataTable:GetContainer()
        for k, v in pairs(tbContainer) do
            if k < nCurSeasonId and not IsExist(k) then
                table.insert( tbPacket.summaries,
                    {
                        season_id = k,
                        season_start_time = v.nStartTime,
                        no_jion = true,
                        season_highest_rank = DEFAULT_RANK,
                        season_highest_rank_mode = 1,
                        season_highest_rank_point = 0
                    })
            end
        end

    -- end

    -- local Component = self:GetComponent()
    Component:SetSeasonHistorySummaries(tbPacket.summaries)

    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_HISTRORY_SUMMARIES)
end

function SeasonSystem:OnRecvGetSeasonHistoryDetails(tbPacket)
    local nSeasonId = self.nRequestSeasonId
    self.nRequestSeasonId = nil
    local Component = self:GetComponent()

    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        Component:SetSeasonHistoryDetail(nSeasonId)
    else
        Component:SetSeasonHistoryDetail(nSeasonId, tbPacket.season_point, tbPacket.season_point_ranking, tbPacket.season_participants, tbPacket.details)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_HISTRORY_DETAILS, nSeasonId)
end

function SeasonSystem:OnRecvGetSeasonPointRanking(tbPacket)
    local Component = self:GetComponent()
    Component:SetSeasonPointRanking(tbPacket.season_point_ranking, tbPacket.season_participants)
    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_POINT_RANKING, tbPacket.season_point_ranking, tbPacket.season_participants)
end

function SeasonSystem:OnRecvReceiveBattleTierAward(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    local Component = self:GetComponent()
    Component:SetReceiveBattleTierAward(tbPacket.battle_tier_level)
    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_BATTLE_TIER_AWARD, tbPacket.battle_tier_level)
    OnAwardSeason(self)
end

function SeasonSystem:OnRecvReceiveAllBattleTierAward(tbPacket)
    if tbPacket.return_code ~= Proto.ReturnCode.OK then
        ShowErrorCode(tbPacket.return_code)
        return
    end
    local Component = self:GetComponent()
    Component:SetReceiveBattleTierAllAwards()
    EventManager:OnFireEvent(ClientEventDef.EV_SEASON_BATTLE_TIER_AWARD)
    OnAwardSeason(self)
end

function SeasonSystem:OnSeasonSummaryReceived(tbPacket)
    EventManager:OnFireEvent(ClientEventDef.EV_PLAYER_SEASON_SUMMARY_RECEIVED, tbPacket.player_id, tbPacket.season)
end

return SeasonSystem