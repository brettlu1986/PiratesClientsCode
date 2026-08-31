local luaclass = require("luaclass")
local BattleCollectionSystem = luaclass("BattleCollectionSystem")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local SelfTimerHelper = require("SelfTimerHelper")
local D2CHelper = require("D2CHelper")
--local ProgressBarTable = require("ProgressBarTable")
local DGCollectionTable = require("DungeonCollectionTable")
local GameNpcType = require("GameNpcType")


BattleCollectionSystem.tbDelayTimerList = {}
BattleCollectionSystem.TimerHelper = nil

function BattleCollectionSystem:Init()
    self.TimerHelper = SelfTimerHelper()
    return true
end

function BattleCollectionSystem:Uninit()
    self.TimerHelper:ClearAllTimer()
    self.TimerHelper = nil
    self.tbDelayTimerList = nil
end

function BattleCollectionSystem:OnCollectionStart(nNpcServerInstanceId, nPlayerServerInstanceId)
    if self:IsObjectCollectioning(nNpcServerInstanceId) then
        return false
    end
    local tbPlayer = GameObjectSystem:FindByInstanceId(nPlayerServerInstanceId)
    local tbNpc = GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
    if tbPlayer ~= nil and tbNpc ~= nil and tbNpc:GetNpcType() == GameNpcType.BattleCollection then
        tbPlayer.pUEActor.ShipMovementComponent:StopMovementImmediately()
        D2CHelper:PlayerSwitchCommonHandlerMode(tbPlayer)

        local CollectionTable =  DGCollectionTable:GetTemplate(tbNpc.nTemplateId)
        if CollectionTable ~= nil then
            EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_COLLECTION_START, CollectionTable.nProgressID, nPlayerServerInstanceId)
            -- local tbProgressBarTable = ProgressBarTable:GetTemplate(CollectionTable.nProgressID)

            -- if tbProgressBarTable ~= nil then
            --     local CollectTimeEct = function()
            --         self:OnCollectionEnd(nNpcServerInstanceId)
            --     end
            --     local tbDelayTimer =  self.TimerHelper:NewTimerMethod(self, CollectTimeEct, tbProgressBarTable.nTime)
            --     local tbData = {}
            --     tbData.nNpcServerInstanceId = nNpcServerInstanceId
            --     tbData.nPlayerServerInstanceId = nPlayerServerInstanceId
            --     tbData.DelayTimer = tbDelayTimer
            --     table.insert(self.tbDelayTimerList, tbData)
            -- else
            --     logerror("Can't Find ProessBar ID")
            --     return false
            -- end
            return false
        else
            logerror("Can't Find DungeonCollectionTable ID" , tbNpc.nTemplateId)
            return false
        end
    elseif tbNpc == nil then
        logerror("Can't Find Gameobject NpcId : ,playerID：", nNpcServerInstanceId ,nPlayerServerInstanceId)
        return false
    end

    return true
end

function BattleCollectionSystem:OnCollectionEnd(nNpcServerInstanceId)

    local tbNpc = GameObjectSystem:FindByInstanceId(nNpcServerInstanceId)
    if tbNpc ~= nil then
        local Index = nil
        for nId, Object in pairs(self.tbDelayTimerList) do
            if Object.nNpcServerInstanceId == nNpcServerInstanceId then
                if Object.DelayTimer ~= nil then
                     self.TimerHelper:ClearTimer(Object.DelayTimer)
                    Index = nId
                    EventManager:OnFireEvent(CommonEventDef.EV_BATTLE_COLLECTION_END, nNpcServerInstanceId, Object.nPlayerServerInstanceId)
                    GameObjectSystem:DestroyNpcInGameModeByInstanceId(nNpcServerInstanceId)
                end
            end
        end
        if Index ~= nil then
            self.tbDelayTimerList[Index] = nil
        end
    end

end
--采集物是否在被采集
function BattleCollectionSystem:IsObjectCollectioning(nNpcServerInstanceId)
    for nId, Object in pairs(self.tbDelayTimerList) do
        if Object.nNpcServerInstanceId == nNpcServerInstanceId then
            return true
        end
    end
    return false
end

--采集中断
function BattleCollectionSystem:OnCollectionBreak(nNpcServerInstanceId)
    local Index = nil
    for nId, Object in pairs(self.tbDelayTimerList) do
        if Object.nNpcServerInstanceId == nNpcServerInstanceId then
             self.TimerHelper:ClearTimer(Object.DelayTimer)
            Index = nId
            local tbplayer = GameObjectSystem:FindByInstanceId(Object.nPlayerServerInstanceId)
            if tbplayer then
                NetworkManager:GetRPCNetworkProxy():SendToClient(tbplayer:GetUEControllerUniqueId(), ProtoDC.d2c_CollectionBreak)
            end
        end
    end

    if Index ~= nil then
        self.tbDelayTimerList[Index] = nil
    end
end

return BattleCollectionSystem()