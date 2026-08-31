
local luaclass = require("luaclass")
local SAISystemBase = require("SAISystemBase")
local SAIGoalSystem = luaclass("SAIGoalSystem", SAISystemBase)
local SAIBlackboradKey = require("SAIBlackboradKey")

SAIGoalSystem.pAIController = nil
SAIGoalSystem.pBlackboard = nil

-- luacheck: push ignore
local function LOG(...)
    log("CJ->SAIGoalSystem:", ...)
end
-- luacheck: pop



function SAIGoalSystem:OnStart()
    self.pAIController = self.tbOwner.SAIComponent:GetAIController()
    self.pBlackboard = self.pAIController.Blackboard
end


function SAIGoalSystem:OnStop()
    if self.pBlackboard then
        self:ClearAttack()
        self:FinishBuild()
        self:ClearSearchItem()
        self:ClearAlert()
    end
    self.pAIController = nil
    self.pBlackboard = nil
end

function SAIGoalSystem:OnUninit()

end


function SAIGoalSystem:DoAttack(tbGameObject)
    LOG("do attack ", tbGameObject.szName)
    if not tbGameObject:IsDead() then
        self.pBlackboard:SetValueAsObject(SAIBlackboradKey.szAttackTarget, tbGameObject.pUEActor)
    end
end

function SAIGoalSystem:ClearSearchItem()
    if not self.pBlackboard then
        return
    end
    self.pBlackboard:ClearValue(SAIBlackboradKey.szPickItem)
end

function SAIGoalSystem:SetGoalLocation(X, Y, Z)
    self.pBlackboard:SetValueAsVector(SAIBlackboradKey.szGoalLocation, Vector{X =X, Y = Y, Z = Z})
end

function SAIGoalSystem:ClearGoalLocation()
    if not self.pBlackboard then
        return
    end
    self.pBlackboard:ClearValue(SAIBlackboradKey.szGoalLocation)
end

function SAIGoalSystem:BuildItem(nTemplateId)
    self.pBlackboard:SetValueAsInt(SAIBlackboradKey.szBuildItem, nTemplateId)
end

function SAIGoalSystem:IsBuilding()
    return self.pBlackboard:GetValueAsBool(SAIBlackboradKey.szBuildingItem)
end

function SAIGoalSystem:FinishBuild()
    if not self.pBlackboard then
        return
    end
    self.pBlackboard:SetValueAsInt(SAIBlackboradKey.szBuildItem, 0)
    self.pBlackboard:ClearValue(SAIBlackboradKey.szBuildingItem)
end

function SAIGoalSystem:SetAlertTarget(tbGameObject)
    LOG("alert target ", tbGameObject.szName)
    if not tbGameObject:IsDead() then
        self.pBlackboard:SetValueAsObject(SAIBlackboradKey.szAlertTarget, tbGameObject.pUEActor)
    end
end

function SAIGoalSystem:ClearAlert()
    LOG("clear alert")
    if not self.pBlackboard then
        return
    end
    self.pBlackboard:ClearValue(SAIBlackboradKey.szAlertTarget)
end

function SAIGoalSystem:ClearAttack()
    LOG("clear attack")
    if not self.pBlackboard then
        return
    end
    self.pBlackboard:ClearValue(SAIBlackboradKey.szAttackTarget)
end

return SAIGoalSystem
