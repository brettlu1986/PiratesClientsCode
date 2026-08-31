-- 只有单机副本才会走这里的逻辑

local luaclass = require("luaclass")
local BattlePlayerResultStepClass = require("BattlePlayerResultStep")
local BattlePVEResultStep_C = luaclass("BattlePVEResultStep_C", BattlePlayerResultStepClass)
local NetworkManager = dynamic_require("NetworkManager")

local Proto = require("ClientProtoNames")
local ListenEventsTargetClass = require("ListenEventsTarget")
local EventDef = require("CommonEventDef")
local EventManager = require("EventManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleResultDef = require("BattleResultDef")
local ClientEventDef = require("ClientEventDef")
-- local HandlerManagerHelper = require("HandlerManagerHelper")
local BattleDataStatisticsSystem = dynamic_require("BattleDataStatisticsSystem")

BattlePVEResultStep_C.bSendResultToHub = false
BattlePVEResultStep_C.ListenEventsTarget = nil

function BattlePVEResultStep_C:Init()
    BattlePVEResultStep_C.super.Init(self)
end
function BattlePVEResultStep_C:SetParams(rBattlePlayerResultStep, nTime, bSendResultToHub)
    BattlePVEResultStep_C.super.SetParams(self, rBattlePlayerResultStep, nTime, bSendResultToHub)
    if self.bSendResultToHub == true then
        self.ListenEventsTarget = self:CreateTarget(ListenEventsTargetClass)
        self.ListenEventsTarget:ListenEvent(EventDef.EV_SHOW_PVE_BATTLE_RESULT_AWARD)
    end
end

function BattlePVEResultStep_C:Start()
    -- HandlerManagerHelper:SwitchMode(Enum_HandlerMode.ShipCommonMode)

    local PLAYERSELF_INDEX = 1
    -- 发送c2s_FightResult
    local nResult = BattleResultDef.LOSE
    local nBalanceType = BattleResultDef.ReslutType.Kill
    local tbResults = self.rResultStep.Results
    local nToastId = nil
    if tbResults ~= nil then
        if(#tbResults >= PLAYERSELF_INDEX) then
            nResult = tbResults[PLAYERSELF_INDEX].nResult
            nBalanceType = tbResults[PLAYERSELF_INDEX].nBalanceType
            nToastId = tbResults[PLAYERSELF_INDEX].nToastId
        end
    else
        tbResults = {}
        local tbResult = {}
        tbResult.nPlayerId = GamePlayerSelfHelper:Get().nPlayerId
        tbResult.nResult = nResult
        tbResult.nBalanceType = nBalanceType
        table.insert( tbResults, tbResult )
        self.rResultStep.Results = tbResults
    end
    local c2s_LocalDungeonResult =
    {
        result = nResult,
        die_count = BattleDataStatisticsSystem:GetPlayerStatsPropertyByPlayerId(GamePlayerSelfHelper:Get().nPlayerId, "Count_Sunk")
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_LocalDungeonResult, c2s_LocalDungeonResult)

    if(self.bSendResultToHub == false) then
        -- BattleDataStatisticsSystem:SendFinishPlayerStatisticsToClient(GamePlayerSelfHelper:Get().nPlayerId)
        local tbPlayerAward = {}
        tbPlayerAward.nResultType = nResult
        tbPlayerAward.tbAwardList = {}
        EventManager:OnFireEvent(ClientEventDef.EV_BATTLE_RESULT, nResult, tbPlayerAward, nBalanceType, nToastId)
        if nBalanceType == BattleResultDef.ReslutType.Escape then
            self.bStopShip = false
        end
    end
    BattlePVEResultStep_C.super.Start(self)
    self.bStopShip = true
end

return BattlePVEResultStep_C
