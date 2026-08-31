-- 输赢结果结算

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattleGuildbossResultStep_S = luaclass("BattleGuildbossResultStep_S", BattlePlayerResultStepClass)


local HubSenderManager = require("HubSenderManager_S")
local HubProto = require("DungeonProtoNames")
local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")
local BattleResultDef = require("BattleResultDef")

local PLAYER_LOSE = BattleResultDef.LOSE
BattleGuildbossResultStep_S.ListenEventsTarget = nil
BattleGuildbossResultStep_S.bSendResultToHub = false

function BattleGuildbossResultStep_S:Init()
    BattleGuildbossResultStep_S.super.Init(self)
end

function BattleGuildbossResultStep_S:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattleGuildbossResultStep_S.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)
    end
end

function BattleGuildbossResultStep_S:Start()
    if(self.bSendResultToHub) then 
        local tbResults = self.rResultStep.Results
        local tbPacket = {}
        local tbPlayerIds = {}
        tbPacket.player_id = tbPlayerIds
        if tbResults == nil then 
            logerror("BattleGuildbossResultStep_S tbResults is nill")
            return
        end
        local nCount = #tbResults
        local tbResult
        local nResult = PLAYER_LOSE
        for i=1, nCount do
            tbResult = tbResults[i]
            local nPlayerId = tbResult.nPlayerId
            if nPlayerId ~= nil then
                nResult = tbResult.nResult
                table.insert(tbPlayerIds, nPlayerId)
            end
        end
        tbPacket.result = nResult
        HubSenderManager:Multicast(HubProto.d2s_GuildbossGameResult, tbPacket)
    end

    BattleGuildbossResultStep_S.super.Start(self)
end

return BattleGuildbossResultStep_S
