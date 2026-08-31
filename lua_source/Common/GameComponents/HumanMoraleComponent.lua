local luaclass = require("luaclass")
local BaseMoraleComponent = require("BaseMoraleComponent")
local HumanMoraleComponent = luaclass("HumanMoraleComponent", BaseMoraleComponent)
local PropName = require("PropName")
local HumanMoraleDataTable = require("HumanMoraleDataTable")
local HumanMoraleIni = require("HumanMoraleIni")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

HumanMoraleComponent.bDecreaseToShip = false

function HumanMoraleComponent:OnCreate(Owner, tbParams)
    local bRet =  HumanMoraleComponent.super.OnCreate(self, Owner, tbParams)
    if not bRet then
        return false
    end

    self.bDecreaseToShip = HumanMoraleIni.tbHumanMorale.bDecreaseToShip
    self.nPhase = 1

    return true
end

function HumanMoraleComponent:OnActorCreated(pUEActor)
    HumanMoraleComponent.super.OnActorCreated(self, pUEActor)

    if self.Owner:IsHuman() then
        self:SetEnableDecrease(true)
    end
end

function HumanMoraleComponent:OnActorDestroyed(pUEActor)
    if self.Owner:IsHuman() and not self.bDecreaseToShip then
        self:OnMoralePhaseChanged(0)
        self:SetEnableDecrease(false)
    end

    HumanMoraleComponent.super.OnActorDestroyed(self, pUEActor)
end

function HumanMoraleComponent:GetMoralePhaseBuffIds(nPhase)
    if nPhase == 0 then
        return nil
    end

    if self.Owner:IsHuman() then
        local tbTemplate = HumanMoraleDataTable:GetMoralePhase(nPhase)
        if tbTemplate == nil then
            return nil
        end
        return tbTemplate.tbBuffIds
    end
end

function HumanMoraleComponent:VerifyMoralePhaseChange(nNewValue)
    local nPhaseCount = HumanMoraleDataTable:GetPhaseCount()
    for i = 1, nPhaseCount do
        local tbMoraleTemplate = HumanMoraleDataTable:GetMoralePhase(i)
        if tbMoraleTemplate ~= nil and nNewValue <= tbMoraleTemplate.nMorale then
            if self.nPhase ~= i then
                self:OnMoralePhaseChanged(i)
            end
            break
        end
    end
end

function HumanMoraleComponent:GetPropertyComponent()
    return self.Owner.HumanBattlePropertyComponent
end

function HumanMoraleComponent:GetDecreaseValue()
    return self.Owner.HumanBattlePropertyComponent:GetProp(PropName.nHumanMoraleConsumedSpeed)
end

function HumanMoraleComponent:GetDecreaseInterval()
    if GlobalVariableSystem:IsServerLogic() then
        return HumanMoraleIni.tbHumanMorale.nDecreaseInterval
    else
        return 0
    end
end

function HumanMoraleComponent:GetPhaseIcon()
    if self.nPhase <= 0 then
        return
    end
    local tbTemplate = HumanMoraleDataTable:GetMoralePhase(self.nPhase)
    return tbTemplate and tbTemplate.tbBuffIcons
end

return HumanMoraleComponent
