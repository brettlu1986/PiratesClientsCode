-- 输赢结果结算

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattlePVEResultStep_S = luaclass("BattlePVEResultStep_S", BattlePlayerResultStepClass)


local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")
local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

BattlePVEResultStep_S.ListenEventsTarget = nil
BattlePVEResultStep_S.bSendResultToHub = false

function BattlePVEResultStep_S:Init()
    BattlePVEResultStep_S.super.Init(self)
end

function BattlePVEResultStep_S:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattlePVEResultStep_S.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)
    end
end

function BattlePVEResultStep_S:Start()
    if(self.bSendResultToHub) then 
        local tbResults = self.rResultStep.Results
        local tbPacket = {}
        local tbSendResults = {}
        tbPacket.results = tbSendResults
        local nCount = #tbResults
        local tbResult

        for i=1, nCount do
            tbResult = tbResults[i]
            local nPlayerId = tbResult.nPlayerId
            local tbFightResult = {}
            tbFightResult.player_id = nPlayerId
            tbFightResult.result = tbResult.nResult
            local GamePlayer = GameObjectSystem:FindPlayerByPlayerId(nPlayerId)
            if GamePlayer == nil then
                logwarning("BattlePVEResultStep_S die count not set since player not found. PlayerId: ", nPlayerId)
            else
                tbFightResult.die_count = BattleDataStatisticsSystem:GetPlayerStatsPropertyByPlayerId(nPlayerId, "Count_Sunk")
                
            end
            table.insert(tbSendResults, tbFightResult)
        end
        HubSenderManager:Multicast(HubProto.d2s_FightResult, tbPacket)
    end

    BattlePVEResultStep_S.super.Start(self)
end

-- test code
--[[
function BattlePVEResultStep_S:CheckComplete(BattleTarget)
    local ret = BattlePVEResultStep_S.super.CheckComplete(self, BattleTarget)
    logdebug('BattlePVEResultStep_S:CheckComplete() ret : ', ret)
    if false == ret then
        local EventManager = require("EventManager")
        EventManager:OnFireEvent(EventDef.EV_SHOW_BATTLE_RESULT_AWARD)
    end
    return ret
end
]]
return BattlePVEResultStep_S
