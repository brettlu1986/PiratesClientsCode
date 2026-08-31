local luaclass = require("luaclass")
local JGMWorldbossSetting = require("JGMWorldbossSetting")
local JGMWorldbossSetting_S = luaclass("JGMWorldbossSetting_S", JGMWorldbossSetting)
local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local BattleStatsTypeDef = require("BattleStatsTypeDef")
local BattleResultDef = require("BattleResultDef")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")

-- 玩家全部退出发送伤害数据
function JGMWorldbossSetting_S:SendPlayerResult()
    local tbPacket = {}
    local tbSendResults = {}
    tbPacket.player_results = tbSendResults
    local tbPlayerResult

    local tbAllStats = BattleDataStatisticsSystem:GetAllPlayerStats()
    for _, tbStats in pairs(tbAllStats) do
        if tbStats.StatsType == BattleStatsTypeDef.Player then
            local nPlayerId = tbStats:GetProperty(PropertyDef.PLAYERID)
            assert(nPlayerId ~= nil)
            tbPlayerResult = {}
            tbPlayerResult.player_id = nPlayerId
            tbPlayerResult.damage = tbStats:GetProperty("CausedDamage_Total")
            tbPlayerResult.result = BattleResultDef.LOSE
            table.insert(tbSendResults, tbPlayerResult)
        end
    end
    HubSenderManager:Multicast(HubProto.d2s_WorldbossGameResult, tbPacket)end
return JGMWorldbossSetting_S