-- 输赢结果结算

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattleGroundResultStep_S = luaclass("BattleGroundResultStep_S", BattlePlayerResultStepClass)


local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")
local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")

BattleGroundResultStep_S.ListenEventsTarget = nil
BattleGroundResultStep_S.bSendResultToHub = false

function BattleGroundResultStep_S:Init()
    BattleGroundResultStep_S.super.Init(self)
end

function BattleGroundResultStep_S:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattleGroundResultStep_S.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)
    end
end

function BattleGroundResultStep_S:Start()
    if(self.bSendResultToHub) then 
        local tbResults = self.rResultStep.Results
        local tbPacket = {}
        local tbSendResults = {}
        tbPacket.player_results = tbSendResults
        if tbResults == nil then 
            logerror("BattleGroundResultStep_S tbResults is nill")
            return
        end
        local nCount = #tbResults
        local tbResult

        for i=1, nCount do
            tbResult = tbResults[i]
            local nPlayerId = tbResult.nPlayerId
            -- Note nPlayerId may be nil. Since team member may be robot who has no nPlayerId.
            if nPlayerId ~= nil then
                local tbFightResult = {}
                tbFightResult.player_id = nPlayerId
                tbFightResult.result = tbResult.nResult
               
                table.insert(tbSendResults, tbFightResult)
            end
        end
        HubSenderManager:Multicast(HubProto.d2s_BattlegroundGameResult, tbPacket)
    end

    BattleGroundResultStep_S.super.Start(self)
end

-- test code
--[[
function BattleGroundResultStep_S:CheckComplete(BattleTarget)
    local ret = BattleGroundResultStep_S.super.CheckComplete(self, BattleTarget)
    logdebug('BattleGroundResultStep_S:CheckComplete() ret : ', ret)
    if false == ret then
        local EventManager = require("EventManager")
        EventManager:OnFireEvent(EventDef.EV_SHOW_BATTLE_RESULT_AWARD)
    end
    return ret
end
]]
return BattleGroundResultStep_S
