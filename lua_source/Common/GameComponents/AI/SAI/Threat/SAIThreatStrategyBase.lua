local luaclass = require("luaclass")
local SAIThreatStrategyBase = luaclass("SAIThreatStrategyBase")
local Timer = require("Timer")
local SAISystemDef = require("SAISystemDef")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local SAIMisc = require("SAIMisc")
local AIVariableSystem = require("AIVariableSystem")

SAIThreatStrategyBase.tbOwner = nil
SAIThreatStrategyBase.nTickIntarval = 1
SAIThreatStrategyBase.nTimer = nil
SAIThreatStrategyBase.tbPerceptionSystem = nil
SAIThreatStrategyBase.tbGoalSystem = nil
SAIThreatStrategyBase.tbThreatObject = nil
SAIThreatStrategyBase.tbWeaponSystem = nil
SAIThreatStrategyBase.bActive = false

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIThreatStrategyBase:", ...)
end
-- luacheck: pop

local function ClearThreat(self)
    self.tbGoalSystem:ClearAttack()
    self.tbWeaponSystem:SetAimTarget(nil)
    self.tbThreatObject = nil
end

local function AttackThreat(self, tbGameObject)
    self.tbGoalSystem:DoAttack(tbGameObject)
    self.tbWeaponSystem:SetAimTarget(tbGameObject.pUEActor)
    self.tbThreatObject = tbGameObject
end

function SAIThreatStrategyBase:Init(Owner)
    self.tbOwner = Owner
end

function SAIThreatStrategyBase:GetGameObject()
    return self.tbOwner
end

function SAIThreatStrategyBase:Tick()
    if not AIVariableSystem:IsBattleStarted() then
        return
    end
    --rts()
    local nOldInstanceId = self.tbThreatObject and self.tbThreatObject:GetServerInstanceId() or 0
    if self.tbWeaponSystem:CanAttack() then
        local tbThreatObject = self:SelectTreat()
        if tbThreatObject ~= self.tbThreatObject then
            if tbThreatObject then
                AttackThreat(self, tbThreatObject)
            else
                ClearThreat(self)
            end
        end
    elseif self.tbThreatObject then
        ClearThreat(self)
    end
    --rte("decide threat cost")
    local nNewInstanceId = self.tbThreatObject and self.tbThreatObject:GetServerInstanceId() or 0
    if nNewInstanceId ~= nOldInstanceId then
        self:FireEvent("OnThreatChanged", nOldInstanceId, nNewInstanceId)
    end
end

function SAIThreatStrategyBase:GetDistanceSqured(AIEntityComponent)
    local nFromX, nFromY, nFromZ = self.tbOwner.SAIEntityComponent:GetLocation()
    local nToX, nToY, nToZ = AIEntityComponent:GetLocation()
    local nX2 = nFromX - nToX
    nX2 = nX2 * nX2
    local nY2 = nFromY - nToY
    nY2 = nY2 * nY2
    local nZ2 = nFromZ - nToZ
    nZ2 = nZ2 * nZ2
    return nX2 + nY2 + nZ2
end

function SAIThreatStrategyBase:IsMoreDangerous(tbGameObjectBase, tbGameObjectOther)
    return not tbGameObjectBase or
    self:GetDistanceSqured(tbGameObjectOther.SAIEntityComponent) < self:GetDistanceSqured(tbGameObjectBase.SAIEntityComponent)

end

function SAIThreatStrategyBase:IsThreat(OtherAIEntityComponent)
    if OtherAIEntityComponent:GetIsDead() then
        return false
    end
    if not OtherAIEntityComponent:VisibleToAI() then
        return false
    end
    local OwnerAIEntityComponent = self.tbOwner.SAIEntityComponent
    if OwnerAIEntityComponent.nTeamId == OtherAIEntityComponent.nTeamId then
        return false
    end
    return true
end

function SAIThreatStrategyBase:SelectTreat()
    local tbPerceptionSystem = self.tbPerceptionSystem
    local tbThreatObject = nil
    local tbSeenActors = tbPerceptionSystem:GetSeenActors()
    for i,v in ipairs(tbSeenActors) do
        local tbGameObject = GameObjectSystem:FindByInstanceId(v)
        if tbGameObject then
            if self:IsThreat(tbGameObject.SAIEntityComponent) and
            self:IsMoreDangerous(tbThreatObject, tbGameObject) then
                tbThreatObject = tbGameObject
            end
        end
    end
    local tbDamagedActors = tbPerceptionSystem:GetDamagedActors()
    for i,v in ipairs(tbDamagedActors) do
        local tbGameObject = GameObjectSystem:FindByInstanceId(v.DamageMakerId)
        if tbGameObject then
            if self:IsThreat(tbGameObject.SAIEntityComponent) and
            self:IsMoreDangerous(tbThreatObject, tbGameObject) then
                tbThreatObject = tbGameObject
            end
        end
    end

    local tbSoundEvent = tbPerceptionSystem:GetHeardSound()
    if tbSoundEvent then
        local tbGameObject = GameObjectSystem:FindByInstanceId(tbSoundEvent.SoundMakerId)
        if tbGameObject then
            if self:IsThreat(tbGameObject.SAIEntityComponent) and
            self:IsMoreDangerous(tbThreatObject, tbGameObject) then
                tbThreatObject = tbGameObject
            end
        end
    end

   return tbThreatObject
end

function SAIThreatStrategyBase:OnStart()

end

function SAIThreatStrategyBase:OnStop()

end

function SAIThreatStrategyBase:OnDead(tbGameObject)
    if self.tbThreatObject == tbGameObject then
        ClearThreat(self)
    end
end

function SAIThreatStrategyBase:SetInterval(nInterval)
    self.nTickIntarval = nInterval
    self:StartTimer()
end

function SAIThreatStrategyBase:StartTimer()
    self:StoptTimer()
    self.nTimer = Timer.NewTimerMethod(self, self.Tick, self.nTickIntarval, true)
    LOG("start threat", self.tbOwner.szName)
end

function SAIThreatStrategyBase:StoptTimer()
    if self.nTimer then
        self.nTimer:Clear()
        self.nTimer = nil
    end
end

function SAIThreatStrategyBase:Start(nInterval)
    local AIComponent = self.tbOwner.SAIComponent
    self.tbPerceptionSystem = AIComponent:GetSystem(SAISystemDef.Perception)
    self.tbGoalSystem = AIComponent:GetSystem(SAISystemDef.Goal)
    self.tbWeaponSystem = AIComponent:GetSystem(SAISystemDef.Weapon)
    self:SetInterval(nInterval)
    ClearThreat(self)
    self:OnStart()
    self.bActive = true
end

function SAIThreatStrategyBase:Stop()
    if self.bActive then
        ClearThreat(self)
        self:StoptTimer()
        self:OnStop()
        self.tbGoalSystem = nil
        self.tbPerceptionSystem = nil
        self.tbWeaponSystem = nil
        self.bActive = false
    end
end

function SAIThreatStrategyBase:FireEvent(szEventName, ...)
    SAIMisc:FireEvent(self.tbOwner, "OnThreatEvent_" .. szEventName, ...)
end

function SAIThreatStrategyBase:Uninit()

end



return SAIThreatStrategyBase