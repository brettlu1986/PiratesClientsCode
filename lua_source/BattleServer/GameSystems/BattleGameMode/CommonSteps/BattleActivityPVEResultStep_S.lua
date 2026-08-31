-- 输赢结果结算

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattleActivityPVEResultStep_S = luaclass("BattleActivityPVEResultStep_S", BattlePlayerResultStepClass)


local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")
local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")

BattleActivityPVEResultStep_S.ListenEventsTarget = nil
BattleActivityPVEResultStep_S.bSendResultToHub = false

function BattleActivityPVEResultStep_S:Init()
    BattleActivityPVEResultStep_S.super.Init(self)
end

function BattleActivityPVEResultStep_S:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattleActivityPVEResultStep_S.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)
    end
end

function BattleActivityPVEResultStep_S:Start()
    if(self.bSendResultToHub) then 
        local tbResults = self.rResultStep.Results
        local tbPacket = {}
        local tbSendResults = {}
        tbPacket.player_results = tbSendResults
        if tbResults == nil then 
            logerror("BattleActivityPVEResultStep_S tbResults is nill")
            return
        end
        local nCount = #tbResults
        local tbResult

        for i=1, nCount do
            tbResult = tbResults[i]
            local nPlayerId = tbResult.nPlayerId
            if nPlayerId ~= nil then
                local tbFightResult = {}
                tbFightResult.player_id = nPlayerId
                tbFightResult.result = tbResult.nResult
                table.insert(tbSendResults, tbFightResult)
            end
        end
        HubSenderManager:Multicast(HubProto.d2s_ActivityDungeonGameResult, tbPacket)
    end

    BattleActivityPVEResultStep_S.super.Start(self)
end

return BattleActivityPVEResultStep_S
