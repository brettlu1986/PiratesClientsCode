local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local SeasonPacketProcessor = luaclass("SeasonPacketProcessor", NetMessageProcessorBase)
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local SeasonSystem = require("SeasonSystem")
local LobbyPopWndHelper = require("LobbyPopWndHelper")

local function OnRecvGetSeason(self, tbPacket)
    SeasonSystem:OnRecvGetSeason(tbPacket)
end

local function OnRecvResetSeason(self, tbPacket)
    SeasonSystem:OnRecvResetSeason(tbPacket)
end

local function OnRecvCollectRankDailyChest(self, tbPacket)
    SeasonSystem:OnRecvCollectRankDailyChest(tbPacket)
end

local function OnRecvNotifyRankChange(self, tbPacket)
    SeasonSystem:OnRecvNotifyRankChange(tbPacket)
end

local function OnRecvBuyBattleTier(self, tbPacket)
    SeasonSystem:OnRecvBuyBattleTier(tbPacket)
end

local function OnRecvNotifyBattleStar(self, tbPacket)
    SeasonSystem:OnRecvNotifyBattleStar(tbPacket)
end

local function OnRecvBattleTierUp(self, tbPacket)
    SeasonSystem:OnRecvBattleTierUp(tbPacket)
end

local function OnRecvBuyBattlePass(self, tbPacket)
    SeasonSystem:OnRecvBuyBattlePass(tbPacket)
end

local function OnRecvGetSeasonStats(self, tbPacket)
    SeasonSystem:OnRecvGetSeasonStats(tbPacket)
end

local function OnRecvGetChallenge(self, tbPacket)
    SeasonSystem:OnRecvGetChallenge(tbPacket)
end

local function OnRecvChallengeSubAward(self, tbPacket)
    SeasonSystem:OnRecvChallengeSubAward(tbPacket)
end

local function OnRecvChallengeWeeklyAward(self, tbPacket)
    SeasonSystem:OnRecvChallengeWeeklyAward(tbPacket)
end

local function OnRecvCurrentChallengeWeekId(self, tbPacket)
    SeasonSystem:OnRecvCurrentChallengeWeekId(tbPacket)
end

local function OnRecvNotifyChallengeAwardStatus(self, tbPacket)
    SeasonSystem:OnRecvNotifyChallengeAwardStatus(tbPacket)
end

local function OnRecvGetSeasonHistorySummaries(self, tbPacket)
    SeasonSystem:OnRecvGetSeasonHistorySummaries(tbPacket)
end

local function OnRecvGetSeasonHistoryDetails(self, tbPacket)
    SeasonSystem:OnRecvGetSeasonHistoryDetails(tbPacket)
end

local function OnRecvGetSeasonPointRanking(self, tbPacket)
    SeasonSystem:OnRecvGetSeasonPointRanking(tbPacket)
end

local function OnRecvReceiveBattleTierAward(self, tbPacket)
    SeasonSystem:OnRecvReceiveBattleTierAward(tbPacket)
end

local function OnRecvReceiveAllBattleTierAward(self, tbPacket)
    SeasonSystem:OnRecvReceiveAllBattleTierAward(tbPacket)
end

local function OnSeasummaryReceived(self, tbPacket)
    SeasonSystem:OnSeasonSummaryReceived(tbPacket)
end

-- 注册处理包
function SeasonPacketProcessor:RegisterPackets()
    LobbyPopWndHelper:RegisterResponse(Proto.s2c_GetSeason, Proto.s2c_ResetSeason, self, OnRecvGetSeason, OnRecvResetSeason)
    -- LobbyPopWndHelper:RegisterSameResponse(Proto.s2c_GetSeason, self, OnRecvGetSeason)
    -- self:BindMethod(Proto.s2c_GetSeason, self, OnRecvGetSeason)
    -- self:BindMethod(Proto.s2c_ResetSeason, self, OnRecvResetSeason)
    self:BindMethod(Proto.s2c_CollectRankDailyChest, self, OnRecvCollectRankDailyChest)
    self:BindMethod(Proto.s2c_NotifyRankChange, self, OnRecvNotifyRankChange)
    self:BindMethod(Proto.s2c_BuyBattleTier, self, OnRecvBuyBattleTier)
    self:BindMethod(Proto.s2c_NotifyBattleStar, self, OnRecvNotifyBattleStar)
    self:BindMethod(Proto.s2c_NotifyBattleTierUp, self, OnRecvBattleTierUp)
    self:BindMethod(Proto.s2c_BuyBattlePass, self, OnRecvBuyBattlePass)
    self:BindMethod(Proto.s2c_GetSeasonStats, self, OnRecvGetSeasonStats)
    self:BindMethod(Proto.s2c_GetChallenge, self, OnRecvGetChallenge)
    self:BindMethod(Proto.s2c_ChallengeSubAward, self, OnRecvChallengeSubAward)
    self:BindMethod(Proto.s2c_ChallengeWeeklyAward, self, OnRecvChallengeWeeklyAward)
    self:BindMethod(Proto.s2c_CurrentChallengeWeekId, self, OnRecvCurrentChallengeWeekId)
    self:BindMethod(Proto.s2c_NotifyChallengeAwardStatus, self, OnRecvNotifyChallengeAwardStatus)
    self:BindMethod(Proto.s2c_GetSeasonHistorySummaries, self, OnRecvGetSeasonHistorySummaries)
    self:BindMethod(Proto.s2c_GetSeasonHistoryDetails, self, OnRecvGetSeasonHistoryDetails)
    self:BindMethod(Proto.s2c_GetSeasonPointRanking, self, OnRecvGetSeasonPointRanking)
    self:BindMethod(Proto.s2c_ReceiveBattleTierAward, self, OnRecvReceiveBattleTierAward)
    self:BindMethod(Proto.s2c_ReceiveAllBattleTierAward, self, OnRecvReceiveAllBattleTierAward)
    self:BindMethod(Proto.s2c_GetSeasonSummary, self, OnSeasummaryReceived)
end

function SeasonPacketProcessor:Init()
    SeasonPacketProcessor.super.Init(self)
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    -- init uninit在这里很low,但是目前没想到好办法
    LobbyPopWndHelper:Init(HubServerProxy)
    self:SetBinder(HubServerProxy)

    self:RegisterPackets()

    return true
end

-- 结束
function SeasonPacketProcessor:Uninit()
    SeasonPacketProcessor.super.Uninit(self)
    LobbyPopWndHelper:Uninit()
end

return SeasonPacketProcessor
