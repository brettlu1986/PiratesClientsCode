local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BaseMoraleComponent = luaclass("BaseMoraleComponent", GameComponentBaseClass)

local SelfTimerHelper = require("SelfTimerHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelperClass  = require("SelfEventHelper")
local EventManager = require("EventManager")

BaseMoraleComponent.nDecreaseTimerHandler = nil
BaseMoraleComponent.EventHelper  = nil
BaseMoraleComponent.TimerHelper  = nil
BaseMoraleComponent.nPhase = 0

local function OnDyingStateChanged(self, tbGameObject, bIsDying)
    if tbGameObject ~= self.Owner then
        return
    end
    if not bIsDying then
        return 
    end

    local tbPropertyComponent = self:GetPropertyComponent()
    if tbPropertyComponent ~= nil then
        local nCurEp = tbPropertyComponent:GetEp()
        if nCurEp > 0 then
            tbPropertyComponent:ConsumeEp(nCurEp)
        end
    end
end

local function ClearTimer(self)
    if self.nDecreaseTimerHandler then
        self.TimerHelper:ClearTimer(self.nDecreaseTimerHandler)
        self.nDecreaseTimerHandler = nil
    end
end

local function OnPawnDead(self, tbGameObject)
    if tbGameObject ~= self.Owner then
        return
    end

    local tbPropertyComponent = self:GetPropertyComponent()
    if tbPropertyComponent ~= nil then
        local nCurEp = tbPropertyComponent:GetEp()
        if nCurEp > 0 then
            tbPropertyComponent:ConsumeEp(nCurEp)
        end
    end    
    ClearTimer(self)
end

function BaseMoraleComponent:OnCreate(Owner, tbParams)
    BaseMoraleComponent.super.OnCreate(self, Owner, tbParams)

    self.TimerHelper = SelfTimerHelper()
    local tbPropertyComponent = self:GetPropertyComponent()
    if tbPropertyComponent ~= nil then
        tbPropertyComponent.OnEpChanged:Bind(self.OnEpChanged, self)
    end
    self.EventHelper = SelfEventHelperClass()
    if GlobalVariableSystem:IsServerLogic() then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DYING_CHANGED,  self, OnDyingStateChanged)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    end
    return true
end

function BaseMoraleComponent:OnDestroy()
    self.EventHelper:UnregisterAll()
    self.EventHelper = nil
    ClearTimer(self)
    self.TimerHelper = nil
    BaseMoraleComponent.super.OnCreate(self)
end

function BaseMoraleComponent:OnActorCreated(pUEActor)
    BaseMoraleComponent.super.OnActorCreated(self, pUEActor)
end

function BaseMoraleComponent:OnActorDestroyed(pUEActor)
    BaseMoraleComponent.super.OnActorDestroyed(self, pUEActor)
end

local function RemoveProperies(self, tbBuffIds)
    local tbOwner = self.Owner
    if tbOwner and tbBuffIds and tbOwner.BuffComponentServer then
        for _,v in ipairs(tbBuffIds) do
            log("BaseMoraleComponent remove buffer ", v)
            tbOwner.BuffComponentServer:RemoveBuffById(v)
        end
    end
end

local function AddProperies(self, tbBuffIds)
    local tbOwner = self.Owner
    if tbOwner and tbBuffIds and tbOwner.BuffComponentServer then
        for _, v in ipairs(tbBuffIds) do
            log("BaseMoraleComponent add buffer ", v)
            tbOwner.BuffComponentServer:AddBuffWithInstigator(tbOwner, v)
        end
    end
end

function BaseMoraleComponent:GetMoralePhaseBuffIds(nPhase)
    return nil
end

function BaseMoraleComponent:OnMoralePhaseChanged(nNewPhase)
    if GlobalVariableSystem:IsServerLogic() then
        local tbOldBuffIds = self:GetMoralePhaseBuffIds(self.nPhase)
        local tbNewBuffIds = self:GetMoralePhaseBuffIds(nNewPhase)
        RemoveProperies(self, tbOldBuffIds)
        AddProperies(self, tbNewBuffIds)
    end
    self.nPhase = nNewPhase
    EventManager:OnFireEvent(CommonEventDef.EV_MORALE_PHASE_CHANGED)
end

function BaseMoraleComponent:VerifyMoralePhaseChange(nNewValue)
end

function BaseMoraleComponent:OnEpChanged(nNewValue)
    if self.Owner:IsDead() then
        return
    end
    self:SetEnableDecrease(nNewValue > 0)
    self:VerifyMoralePhaseChange(nNewValue)
end

function BaseMoraleComponent:GetPropertyComponent()
    return nil
end

function BaseMoraleComponent:GetDecreaseValue()
    return 1
end

function BaseMoraleComponent:OnTickMoraleDecrease()
    local tbPropertyComponent = self:GetPropertyComponent()
    if tbPropertyComponent ~= nil and tbPropertyComponent:GetEp() > 0 then
        tbPropertyComponent:ConsumeEp(self:GetDecreaseValue())
    end
end

function BaseMoraleComponent:GetDecreaseInterval()
    return 0
end

function BaseMoraleComponent:SetEnableDecrease(bEnable)
    local nInterval = self:GetDecreaseInterval()
    if nInterval > 0 then
        if bEnable then
            if self.nDecreaseTimerHandler == nil then
                self.nDecreaseTimerHandler = self.TimerHelper:NewTimerMethod(self,self.OnTickMoraleDecrease, nInterval, true)
            end
        else
            ClearTimer(self)
        end
    end
end

return BaseMoraleComponent
