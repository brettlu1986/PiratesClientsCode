-- 输赢结果结算

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattlePVPResultStep_S = luaclass("BattlePVPResultStep_S", BattlePlayerResultStepClass)


local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")

local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")
local PropertyDef = require("BattleDataStatisticsPropertyFieldDef")

BattlePVPResultStep_S.bHasSendedResult = false

BattlePVPResultStep_S.ListenEventsTarget = nil

function BattlePVPResultStep_S:Init()
    BattlePVPResultStep_S.super.Init(self)
end

function BattlePVPResultStep_S:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattlePVPResultStep_S.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVP_BATTLE_RESULT_AWARD)
    end
end

local function GetStatsByPlayerId(nPlayerId)
    local tbAllStats = BattleDataStatisticsSystem:GetAllPlayerStats()
    for _, tbStats in pairs(tbAllStats) do
        if tbStats:GetProperty(PropertyDef.PLAYERID) == nPlayerId then
            return tbStats
        end
    end
    return nil
end

function BattlePVPResultStep_S:Start()
    if(self.bSendResultToHub) then
        local tbResults = self.rResultStep.Results
        local tbPacket = {}
        local tbSendResults = {}
        tbPacket.player_results = tbSendResults
        local nCount = #tbResults
        local tbResult

        for i=1, nCount do
            tbResult = tbResults[i]
            local nPlayerId = tbResult.nPlayerId
            local tbFightResult = {}
            tbFightResult.player_id = nPlayerId
            tbFightResult.result = tbResult.nResult

            local tbStats = GetStatsByPlayerId(nPlayerId)
            if tbStats ~= nil then
                tbFightResult.ship_used = tbStats:GetProperty("ShipTemplateId")
                tbFightResult.damage = tbStats:GetProperty("CausedDamage_Total")
                tbFightResult.kills = tbStats:GetProperty("CausedCount_Sunk")
                tbFightResult.death = tbStats:GetProperty("Count_Sunk") > 0
            else
                logwarning("BattlePVPResultStep_S player stats not found. Missing statistic data")
            end
            table.insert(tbSendResults, tbFightResult)
        end
        HubSenderManager:Multicast(HubProto.d2s_ArenaGameResult, tbPacket)
    end

    BattlePVPResultStep_S.super.Start(self)
end

-- test code
--[[
function BattlePVPResultStep_S:CheckComplete(BattleTarget)
    local ret = BattlePVPResultStep_S.super.CheckComplete(self, BattleTarget)
    logdebug('BattlePVPResultStep_S:CheckComplete() ret : ', ret)
    if false == ret then
        local EventManager = require("EventManager")
        EventManager:OnFireEvent(EventDef.EV_SHOW_BATTLE_RESULT_AWARD)
    end
    return ret
end
]]
return BattlePVPResultStep_S
