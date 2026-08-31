
local luaclass = require("luaclass")
local SAILogicBase = luaclass("SAILogicBase")
local SelfEventHelperClass  = require("SelfEventHelper")
local AITypeDataTable       = require("AITypeDataTable")
local ResourceManager       = require("ResourceManager")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")

SAILogicBase.pAIController = nil
SAILogicBase.pBehaviorTreeHuman = nil
SAILogicBase.pBehaviorTreeShip = nil
SAILogicBase.EventHelper = nil
SAILogicBase.pAIControllerEndPlayDelegate = nil
SAILogicBase.Owner = nil
SAILogicBase.tbConfig = nil
SAILogicBase.bStarted = false

local function LOG(...)
    log("CJ->SAILogicBase:", ...)
end


local function OnAIControllerDestroyed(self)
    if GlobalVariableSystem:IsServerLogic() then
        local tbOwner = self.Owner
        local pLocation = tbOwner:GetLocation()
        LOG("ai controller destroyd:pawn postion ",tbOwner.szName, pLocation.X, pLocation.Y, pLocation.Z)
        local AIComponent = tbOwner.SAIComponent
        AIComponent:StopAI()
        AIComponent:DestroyAI()
        -- self.EventHelper:UnregisterAll()
        -- ResourceManager:Unhold(self.pBehaviorTreeShip)
        -- ResourceManager:Unhold(self.pBehaviorTreeHuman)
        -- self.pAIController = nil
        -- self.pBehaviorTreeHuman = nil
        -- self.pBehaviorTreeShip = nil
        LOG("OnAIControllerDestroyed")
    end
end


function SAILogicBase:OnInit(Owner)
    self.Owner = Owner
    self.EventHelper = SelfEventHelperClass()
end


function SAILogicBase:Enable(tbConfig, ...)
    self.tbConfig = tbConfig
    self:CreateAI()
    local AIComponent = self.Owner.SAIComponent
    AIComponent:ConfigSubSystem(tbConfig)
    if self.Owner.pUEActor then
        self:Start()
    end
end

function SAILogicBase:OnCreatedAI()

end

function SAILogicBase:CreateAI()
    if not self.pAIController then
        local nAIResourceId = self:GetAIResourceId()
        local tbTypeData = AITypeDataTable:GetTemplate(nAIResourceId)
        if tbTypeData then
            local szControllerClass = tbTypeData.szControllerClass
            local pCClass = szControllerClass:load()
            assert(pCClass, "can not find controller class", szControllerClass)
            local pController = EngineExtActorShell.SpawnActorForScript(GWorld, pCClass, Transform(), nil)
            self.pAIController      = pController
            self.pBehaviorTreeHuman = ResourceManager:LoadSync(tbTypeData.szHumanBTClass, true)
            self.pBehaviorTreeShip  = ResourceManager:LoadSync(tbTypeData.szShipBTClass , true)
            local szBlackboardClass = tbTypeData.szBlackboardClass
            local pBBClass = szBlackboardClass:load()
            assert(pBBClass, "can not load blackboard tree class", szBlackboardClass)
            local bRet, pBBComponent = pController:UseBlackboard(pBBClass)
            assert(bRet and pBBComponent, "can not controller use blackboard.")
            self.pAIControllerEndPlayDelegate = self.EventHelper:RegisterCppDelegate(pController.OnEndPlay, self, OnAIControllerDestroyed)
            LOG("create ai finished:", nAIResourceId)
            self:OnCreatedAI()
        else
            logerror("can not find ai type table data", nAIResourceId)
        end
    else
        logerror("duplicate create ai.")
    end
end

function SAILogicBase:OnUninit()
    self.EventHelper:UnregisterAll()
    if self.pAIController then
        ResourceManager:Unhold(self.pBehaviorTreeShip)
        ResourceManager:Unhold(self.pBehaviorTreeHuman)
        EngineExtActorShell.DestroyActor(GWorld, self.pAIController)
        self.pAIController = nil
        self.pBehaviorTreeHuman = nil
        self.pBehaviorTreeShip = nil
        LOG("destroyed ai")
    end
end


function SAILogicBase:IsEnabled()
    return self.bStarted
end


function SAILogicBase:Possessed()

end

function SAILogicBase:UnPossessed()

end

function SAILogicBase:Start()
    self:OnBindEvent(self.EventHelper)
    local Owner = self.Owner
    local pAIController = self.pAIController
    local pUEActor = Owner.pUEActor
    local AIComponent = Owner.SAIComponent
    if pAIController and pUEActor then
        local pBehaviorTree = nil
        if Owner:IsShip() then
            pBehaviorTree = self.pBehaviorTreeShip
        elseif Owner:IsHuman() then
            pBehaviorTree = self.pBehaviorTreeHuman
            local pHumanMovementComponent = pUEActor:GetHumanMovementComponent()
            pHumanMovementComponent.bUseControllerDesiredRotation = true
            pHumanMovementComponent.RotationRate.Yaw = 720
            pUEActor.bUseControllerRotationYaw = false
            pUEActor.bUseControllerRotationPitch = false
        else
            logerror("the owner of ai is not human and not ship.")
        end
        self.pAIController:RunBehaviorTree(pBehaviorTree)
        pAIController:Possess(pUEActor)
        AIComponent:StartSubSystem()
        self:Possessed()
        self.bStarted = true
    end
end

function SAILogicBase:Stop()
    self:OnUnbindEvent(self.EventHelper)
    if self.bStarted then
        local AIComponent = self.Owner.SAIComponent
        AIComponent:StopSubSystem()
        self.pAIController:UnPossess()
        self:UnPossessed()
        self.bStarted = false
        LOG("stop logic ", self.Owner.szName)
    end
end

function SAILogicBase:OnBindEvent(SelfEventHelper)

end

function SAILogicBase:OnUnbindEvent(SelfEventHelper)

end

function SAILogicBase:GetAIResourceId()
    return self.tbConfig.AIResourceId
end

function SAILogicBase:GetAIController()
    return self.pAIController
end


function SAILogicBase:CanUseWeapon(nTemplateId)
    return false
end

function SAILogicBase:GetWeaponConfig(nTemplateId)

end

function SAILogicBase:GetDamageParam()

end

return SAILogicBase
