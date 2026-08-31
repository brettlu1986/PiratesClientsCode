--复活
local luaclass = require("luaclass")
local BattleReviveSystem = luaclass("BattleReviveSystem")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local DGRepProto= require("DungeonRepProtoNames")
local BattleReviveModeTypeDef = require("BattleReviveModeTypeDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")

function BattleReviveSystem:Init()
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, self, self.OnRevive)
    EventManager:BindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_RESULT, self, self.OnReviveResult)
    return true 
end

function BattleReviveSystem:Uninit()
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_INFOANDSHOW, self, self.OnRevive)
    EventManager:UnBindEventMethod(CommonEventDef.EV_BATTLE_REVIVE_RESULT, self, self.OnReviveResult)
end

function BattleReviveSystem:OnReviveMode(nPlayerServerInstanceId, bBackCity)
  
end

-- ????? TODO Whether revive or not depends on if we have tbPlayerState ??? It may not create PlayerState in BattleGameModeSystem:InitPlayerState. 
function BattleReviveSystem:OnRevive(nReviveType, tbPlayer, nReviveWaitTime)
    local tbPlayerStateCom = tbPlayer.BattlePlayerStateComponent
    if tbPlayerStateCom == nil then
        -- logerror(" BattlePlayerStateComponent is NULL")
        return false
    end

    local tbPlayerState = tbPlayerStateCom:GetGamePlayerState()
    local EReviveType = DGRepProto.rReviveInfoAndShow_EReviveType
    if  tbPlayerState ~= nil then
        if nReviveType == BattleReviveModeTypeDef.BackCityAndNow then
            local tbReviveInfo = tbPlayer.tbPrepareInfo.tbReviveInfo
            self:SendToClient(tbPlayerState, EReviveType.BACKCITY_NOWREVIVE, true, 
                                  nReviveWaitTime, tbReviveInfo.bCanRevive, tbReviveInfo.nReviveCostType, 
                                  tbReviveInfo.nReviveCostNum)
        elseif nReviveType == BattleReviveModeTypeDef.WaitAllAndNow then
            local tbReviveInfo = tbPlayer.tbPrepareInfo.tbReviveInfo
            self:SendToClient(tbPlayerState, EReviveType.WAIT_NOW, true, 
                                    nReviveWaitTime, tbReviveInfo.bCanRevive, tbReviveInfo.nReviveCostType, 
                                    tbReviveInfo.nReviveCostNum)
        else
            self:SendToClient(tbPlayerState,EReviveType.RESET,true)
        end
        
    --else
         -- logerror(" PlayerState is NULL")
    end
end


function BattleReviveSystem:SendToClient(tbPlayerState, ReviveType, bIsDie, nWaitReviveTime, bIsCanRevive, nCostType, nCostNum)
    tbPlayerState.rReviveInfoAndShow.bIsDie = bIsDie
    tbPlayerState.rReviveInfoAndShow.nWaitReviveTime =  nWaitReviveTime
    tbPlayerState.rReviveInfoAndShow.ReviveType = ReviveType
    tbPlayerState.rReviveInfoAndShow.bIsCanRevive = bIsCanRevive
    tbPlayerState.rReviveInfoAndShow.nCostType = nCostType
    tbPlayerState.rReviveInfoAndShow.nCostNum = nCostNum
    tbPlayerState.rReviveInfoAndShow.RepNowToClient()
end

function BattleReviveSystem:OnReviveResult(player_id, result, nReviveType)
    
    local tbPlayer = GameObjectSystem:FindPlayerByPlayerId(player_id)

    if tbPlayer == nil then
        logerror(" BattlePlayerStateComponent is NULL")
        return false
    end

    local tbPlayerStateCom = tbPlayer.BattlePlayerStateComponent
    if tbPlayerStateCom == nil then
        logerror(" BattlePlayerStateComponent is NULL")
        return false
    end

    if result then
        tbPlayer:Reborn()
        EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_REVIVE_SUCCE, tbPlayer)
        -- 统计金币复活次数
        if nReviveType == BattleReviveModeTypeDef.BackCityAndNow then
            EventManager:OnFireEvent(CommonEventDef.EV_STATS_PAIDREVIVE, tbPlayer)
        end
    end
    
    local tbPlayerState = tbPlayerStateCom:GetGamePlayerState()

    local EReviveType = DGRepProto.rReviveInfoAndShow_EReviveType
    if  tbPlayerState ~= nil then
        if nReviveType == BattleReviveModeTypeDef.BackCityAndNow then
            self:SendToClient(tbPlayerState, EReviveType.BACKCITY_NOWREVIVE, not result)
        else
            self:SendToClient(tbPlayerState, EReviveType.RESET, not result)
        end
        
    else
         logerror(" PlayerState is NULL")
    end
end


return BattleReviveSystem

