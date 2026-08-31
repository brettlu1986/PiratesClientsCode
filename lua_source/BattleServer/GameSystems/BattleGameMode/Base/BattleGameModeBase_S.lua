-- 纯服务器
local luaclass = require("luaclass")
local BattleGameModeBaseClass = require("BattleGameModeBase")
local BattleGameModeBase_S = luaclass("BattleGameModeBase_S", BattleGameModeBaseClass)

local BattleKickPlayerReasonDef = require("BattleKickPlayerReasonDef")
local HubSenderManager = require("HubSenderManager_S")
local Proto = require("DungeonProtoNames")
local ProtoDC = require("DungeonCommonProtoNames")

local tbQuitReasonMap = {
    [ProtoDC.c2d_QuitDungeon_QuitReason.QUIT_BUTTON]          = Proto.d2s_QuitDungeon_QuitReason.QUIT_BUTTON,
    [ProtoDC.c2d_QuitDungeon_QuitReason.BACK_TO_PORT]         = Proto.d2s_QuitDungeon_QuitReason.BACK_TO_PORT,
}




-- local function SendDungeonAnalyticsDataToHub(self)
--     local tbDatas = {}
--     local tbAllPlayerStats = BattleDataStatisticsSystem:GetAllPlayerStats()
--     for i,v in pairs(tbAllPlayerStats) do
--         local tbPlayerData = {}
--         tbPlayerData.player_id             = v:GetProperty("PlayerId");
--         tbPlayerData.ship_id               = v:GetProperty("ShipTemplateId");
--         tbPlayerData.caused_cannon_damage  = v:GetProperty("CausedDamage_MainCannon");      -- 造成的炮弹总伤害
--         tbPlayerData.caused_torpedo_damage = v:GetProperty("CausedDamage_Torpedo");         -- 造成的鱼雷总伤害
--         tbPlayerData.cannon_total_count    = v:GetProperty("LaunchCount_MainCannon");       -- 发射炮弹的总数量
--         tbPlayerData.torpedo_total_count   = v:GetProperty("LaunchCount_Torpedo");          -- 发射鱼雷的总数量
--         tbPlayerData.cannon_miss_count     = v:GetProperty("MissCount_MainCannon");         -- 跳弹数量
--         tbPlayerData.cannon_graze_count    = v:GetProperty("GrazeCount_MainCannon");        -- 刮擦数量
--         tbPlayerData.cannon_smash_count    = v:GetProperty("SmashCount_MainCannon");        -- 击穿数量
--         tbPlayerData.cannon_penetrate_count= v:GetProperty("PenetrateCount_MainCannon");    -- 过穿数量
--         tbPlayerData.cannon_core_count     = v:GetProperty("HitTargetCoreCount_Cannon");    -- 核心数量
--         tbPlayerData.caused_fire_count     = v:GetProperty("CausedCount_Fire");             -- 造成点火次数
--         tbPlayerData.caused_leak_count     = v:GetProperty("CausedCount_Leak");             -- 造成进水次数
--         tbPlayerData.crash_mountain_count  = v:GetProperty("Count_CrashMountain");          -- 触礁次数
--         tbPlayerData.got_buff              = v:GetProperty("Got_Buff");                     -- 获得buff次数
--         table.insert(tbDatas, tbPlayerData)
--     end
--     local tbPacket = {}
--     tbPacket.datas = tbDatas
--     HubSenderManager:Multicast(Proto.d2s_DungeonAnalyticsData, tbPacket)
-- end

-- local function SendBattleStatsDataToHub(self)
--    local tbDatas = {}
--     local tbAllPlayerStats = BattleDataStatisticsSystem:GetAllPlayerStats()
--     for _,v in pairs(tbAllPlayerStats) do
--         local tbPlayerData = v:GetHubBattleStatsData()
--         table.insert(tbDatas, tbPlayerData)
--     end
--     local tbPacket = {}
--     tbPacket.datas = tbDatas
--     HubSenderManager:Multicast(Proto.d2s_BattleStatsData, tbPacket)
-- end

local function SendPlayerEnterMessage(tbGamePlayer)
    local tbPacket = {}
    local nPlayerId = tbGamePlayer.nPlayerId
    local szPlayerSessionId = tbGamePlayer.szPlayerSessionId
    tbPacket.player_id = nPlayerId
    tbPacket.player_session_id = szPlayerSessionId
    HubSenderManager:Send(Proto.d2s_PlayerEnter, tbPacket, nPlayerId)
end

function BattleGameModeBase_S:OnPlayerReLogin(tbGamePlayer)
    BattleGameModeBase_S.super.OnPlayerReLogin(self, tbGamePlayer)
    SendPlayerEnterMessage(tbGamePlayer)
end

function BattleGameModeBase_S:OnPlayerLogin(tbGamePlayer)
    BattleGameModeBase_S.super.OnPlayerLogin(self, tbGamePlayer)
    SendPlayerEnterMessage(tbGamePlayer)
end

function BattleGameModeBase_S:OnPlayerLogout(tbGamePlayer)
--[[
    local tbPacket = {}
    local nPlayerId = tbGamePlayer.nPlayerId
    local nToken = tbGamePlayer.nToken
    local szPlayerSessionId = tbGamePlayer.szPlayerSessionId
    tbPacket.player_id = nPlayerId
    tbPacket.player_session_id = szPlayerSessionId
    tbPacket.dead_count = 0
    tbPacket.paid_revive_count = 0
    tbPacket.non_paid_revive_count = 0
    tbPacket.token = nToken
    HubSenderManager:Send(Proto.d2s_PlayerExit, tbPacket, nPlayerId)
]]
    BattleGameModeBase_S.super.OnPlayerLogout(self, tbGamePlayer)
end

function BattleGameModeBase_S:OnAllStepFinished()
    local tbPacket = {}
    HubSenderManager:Multicast(Proto.d2s_MatchEnd, tbPacket)

    BattleGameModeBase_S.super.OnAllStepFinished(self)
end

function BattleGameModeBase_S:OnAllPlayerLogout()
    BattleGameModeBase_S.super.OnAllPlayerLogout(self)

    -- 发送统计数据给Hub
    -- SendBattleStatsDataToHub(self)
    -- SendDungeonAnalyticsDataToHub(self)
    local tbPacket = {}
    HubSenderManager:Multicast(Proto.d2s_DungeonRelease, tbPacket)

    log("Hub Send:DungeonRelease")
end

-- 玩家中途退出
function BattleGameModeBase_S:QuitDungeon(tbPlayer, nQuitReason)
    BattleGameModeBase_S.super.QuitDungeon(self, tbPlayer, nQuitReason)

    local nPlayerId = tbPlayer.nPlayerId
    local nToken = tbPlayer.nToken
    local szPlayerSessionId = tbPlayer.szPlayerSessionId
    local tbPacket =
    {
        player_id = nPlayerId,
        reason = tbQuitReasonMap[nQuitReason],
        token = nToken,
        player_session_id = szPlayerSessionId
    }

    HubSenderManager:Send(Proto.d2s_QuitDungeon, tbPacket, nPlayerId)
    log("Hub Send:QuitDungeon")
end

function BattleGameModeBase_S:OnKickPlayer(tbPlayer)
    BattleGameModeBase_S.super.OnKickPlayer(self, tbPlayer)

    local nPlayerId = tbPlayer.nPlayerId
    local szPlayerSessionId = tbPlayer.szPlayerSessionId
    local tbPacket =
    {
        player_id = nPlayerId,
        reason = BattleKickPlayerReasonDef.Normal,
        player_session_id = szPlayerSessionId
    }

    HubSenderManager:Send(Proto.d2s_PlayerKicked, tbPacket, nPlayerId)
    log("Hub Send:PlayerKicked")
end

-- 玩家在结果界面提前退出
function BattleGameModeBase_S:LeaveDungeon(tbPlayer)
    BattleGameModeBase_S.super.LeaveDungeon(self, tbPlayer)
    local nPlayerId = tbPlayer.nPlayerId
    local nToken = tbPlayer.nToken
    local szPlayerSessionId = tbPlayer.szPlayerSessionId
    local tbPacket =
    {
        player_id = nPlayerId,
        token = nToken,
        player_session_id = szPlayerSessionId
    }
    HubSenderManager:Send(Proto.d2s_LeaveDungeon, tbPacket, nPlayerId)
end

return BattleGameModeBase_S
