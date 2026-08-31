local luaclass = require("luaclass")
local SAIPerceptionBase = require("SAIPerceptionBase")
local SAIPerceptionSight = luaclass("SAIPerceptionSight", SAIPerceptionBase)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

SAIPerceptionSight.tbSeenServerInstanceIds = nil
SAIPerceptionSight.bBothShipAndHuman = false

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIPerceptionSight:", ...)
end
-- luacheck: pop

local function OnActorInSight(self, nUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if tbGameObject and GameObjectTypeDef.PlayerSelf == tbGameObject:GetObjectType() then
        if not self.bBothShipAndHuman and tbGameObject:IsHuman() ~= self.tbOwner:IsHuman() then
            return
        end
        local nServerInstanceId = tbGameObject:GetServerInstanceId()
        for i,v in ipairs(self.tbSeenServerInstanceIds) do
            if v == nServerInstanceId then
                return
            end
        end
        table.insert(self.tbSeenServerInstanceIds, nServerInstanceId)
        self:FireEvent("OnActorInSight", nServerInstanceId)
        --LOG("in sight actor:", tbGameObject.szName)
    end
end

local function OnRemoveGameObjectFromSight(self, nServerInstanceId)
    for i,v in ipairs(self.tbSeenServerInstanceIds) do
        if v == nServerInstanceId then
            table.remove(self.tbSeenServerInstanceIds, i)
            self:FireEvent("OnActorLoseSight", nServerInstanceId)
            return
        end
    end
end

local function OnActorLoseSight(self, nUniqueId)
    local tbGameObject = GameObjectSystem:FindByUniqueId(nUniqueId)
    if tbGameObject then
        --LOG("lose sight actor:", tbGameObject.szName)
        OnRemoveGameObjectFromSight(self, tbGameObject:GetServerInstanceId())
    end
end

local function OnDead(self, tbGameObject)
    if GlobalVariableSystem:IsServerLogic() then
        OnRemoveGameObjectFromSight(self, tbGameObject:GetServerInstanceId())
    end
end

function SAIPerceptionSight:OnStarted()
    self.tbSeenServerInstanceIds = {}
    local tbConfig = self.tbConfig
    local pAIController = self.pAIController
    local tbSightConfig = self.tbOwner:IsShip() and tbConfig.Ship or tbConfig.Human
    self.bBothShipAndHuman = tbConfig.bBothShipAndHuman
    pAIController:ConfigSight(tbSightConfig.InSightRange, tbSightConfig.LoseSightRange, tbSightConfig.FOV * 0.5)
    LOG("config sight:", tbSightConfig.InSightRange, tbSightConfig.LoseSightRange, tbSightConfig.FOV* 0.5)
end

function SAIPerceptionSight:OnStop()
    self.tbSeenServerInstanceIds = {}
end

function SAIPerceptionSight:BindEvent(SelfEventHelper)
    SAIPerceptionSight.super.BindEvent(self, SelfEventHelper)
    local pAIController = self.pAIController
    SelfEventHelper:RegisterCppDelegate(pAIController.NotifyActorInSight, self, OnActorInSight)
    SelfEventHelper:RegisterCppDelegate(pAIController.NotifyActorLoseSight, self, OnActorLoseSight)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self, OnDead)
end

function SAIPerceptionSight:GetSeenActors()
    return self.tbSeenServerInstanceIds
end


function SAIPerceptionSight:UnbindEvent(SelfEventHelper)
    SAIPerceptionSight.super.UnbindEvent(self, SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

return SAIPerceptionSight