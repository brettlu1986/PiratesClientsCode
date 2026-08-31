local luaclass = require("luaclass")
local GameObjectClass = dynamic_require("GameObject")
local GameVehicle = luaclass("GameVehicle", GameObjectClass)
local VehicleDataTable = require("VehicleDataTable")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local GameComponentCreateHelper = require("GameComponentCreateHelper")
local DamageTypeEx = require("DamageTypeEx")

function GameVehicle:OnCreate()
    return GameVehicle.super.OnCreate(self)
end
function GameVehicle:OnCreateComponents()
    local bRet = GameVehicle.super.OnCreateComponents(self)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithGameObject))
    return bRet
end

function GameVehicle:OnActorPreCreated(pUEActor)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
        GameVehicle.super.OnActorPreCreated(self, pUEActor)
end

function GameVehicle:OnActorCreated(pUEActor)
    GameVehicle.super.OnActorCreated(self, pUEActor)
    if GlobalVariableSystem:IsServerLogic() then
        local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
        AIVehicleManager:SetVehicleLocation(self.nServerInstanceId, pUEActor:K2_GetActorLocation())
        log("add vehicle to ai:", self.nServerInstanceId)
    end
end

function GameVehicle:UnbindUEActor()
    if GlobalVariableSystem:IsServerLogic() then
        local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
        AIVehicleManager:RemoveVehicle(self.nServerInstanceId)
        log("remove vehicle from ai:", self.nServerInstanceId)
    end
    GameVehicle.super.UnbindUEActor(self)
    GameComponentCreateHelper:Destroy(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
end

function GameVehicle.StaticCollectResources(nTemplateId)
    local tbVehicleData = VehicleDataTable:GetTemplate(nTemplateId)

    if not tbVehicleData or not tbVehicleData.tbResData then
        return nil
    end
    return tbVehicleData.tbResData.szPawnClassName
end


function GameVehicle:GetActorClassByTemplateId(nTemplateId)
    return GameVehicle.StaticCollectResources(nTemplateId)
end


function GameVehicle:GetCurrentPropertyComponent()
    return self.VehiclePropertyComponent
end

function GameVehicle:ConvertToComponentParams(nLifeCycleType)
    local Def = GameComponentTypeDefine

    local nEnvironmentType
    if(GlobalVariableSystem.bIsInDungeon) then
        if(GlobalVariableSystem:IsServerLogic()) then
            nEnvironmentType = Def.tbEnvironmentType.BattleServer
        else
            nEnvironmentType = Def.tbEnvironmentType.BattleClient
        end
    else
        nEnvironmentType = Def.tbEnvironmentType.Lobby
    end

    local nActorType = Def.tbActorType.Vehicle
    return nEnvironmentType, nActorType, nLifeCycleType
end

function GameVehicle:GetDebugInfo()
    local tbRet = GameVehicle.super.GetDebugInfo(self)
    tbRet.nTemplateType = self.nTemplateType
    return tbRet
end

function GameVehicle:GetCurrentPropertyComponent()
    return self.VehiclePropertyComponent
end

function GameVehicle:IsDead()
    local PropertyComponent = self:GetCurrentPropertyComponent()
    if not PropertyComponent then
        return true
    end
    return PropertyComponent:GetIsDead()
end

function GameVehicle:IsDying()
    return self:GetCurrentPropertyComponent():GetIsDying()
end

-- 是否活着（没有死亡且不处于重伤状态）
function GameVehicle:IsAlive()
    return not (self:IsDead() or self:IsDying())
end

function GameVehicle:KillSelf()
    local PropertyComponent = self:GetCurrentPropertyComponent()
    local nMaxHp = PropertyComponent:GetMaxHp()
    PropertyComponent:ApplyDamage(self, DamageTypeEx.KILL_SELF, nMaxHp)
end

-- 交互或者其他时机，需要暂停船只移动及武器开关时调用
function GameVehicle:SetPaused(bPaused)
    self.bPaused = bPaused
end

function GameVehicle:IsPaused()
    return self.bPaused
end


function GameVehicle:StopMove(bImmediately)
    self.VehicleMovementComponent:StopMove(false)
end

function GameVehicle:IsShip()
    return false
end

function GameVehicle:IsHuman()
    return false
end

function GameVehicle:IsInvincibleToPoisonCircle()
    return self.VehiclePropertyComponent.bInvincibleToPoisonCircle
end

function GameVehicle:OnDead()
    if GlobalVariableSystem:IsServerLogic() then
        local AIVehicleManager = CommonShell.GetCommon(GWorld):GetAIVehicleManager()
        AIVehicleManager:RemoveVehicle(self.nServerInstanceId)
        log("remove vehicle from ai:", self.nServerInstanceId)
    end
end

return GameVehicle