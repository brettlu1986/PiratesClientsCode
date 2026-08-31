-- 输赢结果结算

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattleWorldbossResultStep_S = luaclass("BattleWorldbossResultStep_S", BattlePlayerResultStepClass)

local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")
local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local BattleStatsTypeDef = require("BattleStatsTypeDef")
local BattleResultDef = require("BattleResultDef")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")

BattleWorldbossResultStep_S.ListenEventsTarget = nil
BattleWorldbossResultStep_S.bSendResultToHub = false
local PLAYER_WIN = BattleResultDef.WIN
local PLAYER_LOSE = BattleResultDef.LOSE

function BattleWorldbossResultStep_S:Init()
    BattleWorldbossResultStep_S.super.Init(self)
end

function BattleWorldbossResultStep_S:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattleWorldbossResultStep_S.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)
    end
end

function BattleWorldbossResultStep_S:Start()
    if(self.bSendResultToHub) then 
        local tbResults = self.rResultStep.Results
        local tbPacket = {}
        local tbSendResults = {}
        tbPacket.player_results = tbSendResults
        local tbPlayerResult
        local nResultType = PLAYER_WIN
        if tbResults == nil then 
            nResultType = PLAYER_LOSE
        end

        local tbAllStats = BattleDataStatisticsSystem:GetAllPlayerStats()
        for _, tbStats in pairs(tbAllStats) do
            if tbStats.StatsType == BattleStatsTypeDef.Player then
                local nPlayerId = tbStats:GetProperty(PropertyDef.PLAYERID)
                assert(nPlayerId ~= nil)
                tbPlayerResult = {}
                tbPlayerResult.player_id = nPlayerId
                tbPlayerResult.damage = tbStats:GetProperty("CausedDamage_Total")
                tbPlayerResult.result = nResultType
                table.insert(tbSendResults, tbPlayerResult)
            end
        end
        HubSenderManager:Multicast(HubProto.d2s_WorldbossGameResult, tbPacket)
    end
    
    BattleWorldbossResultStep_S.super.Start(self)
end

return BattleWorldbossResultStep_S
