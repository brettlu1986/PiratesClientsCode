local luaclass = require("luaclass")
local GameObjectClass = dynamic_require("GameObject")
local GameDestructibleObject = luaclass("GameDestructibleObject", GameObjectClass)
local DestructibleObjectNewDataTable = require("DestructibleObjectNewDataTable")
local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DamageTypeEx = require("DamageTypeEx")

local CLASSRES = {
    "Class'/Game/Game/OtherObject/DestructibleObject/BP_WindowBase.BP_WindowBase_C'",
    "Class'/Game/Game/OtherObject/DestructibleObject/BP_DoorBase.BP_DoorBase_C'"
}

local TempVector1 = Vector()
local TempVector2 = Vector()

local function SetVector(TempVector, X, Y, Z)
    TempVector.X = X
    TempVector.Y = Y
    TempVector.Z = Z
end

function GameDestructibleObject:OnCreate()
    return GameDestructibleObject.super.OnCreate(self)
end 

function GameDestructibleObject.StaticCollectResources(nTemplateId)
    local tbDestructibleObjectData = DestructibleObjectNewDataTable:GetTemplate(nTemplateId)
    if tbDestructibleObjectData == nil then
        return nil 
    end 
    if tbDestructibleObjectData.szRes then
        return tbDestructibleObjectData.szRes
    else
        return CLASSRES[tbDestructibleObjectData.nType]
    end
end


function GameDestructibleObject:GetActorClassByTemplateId(nTemplateId)
    return GameDestructibleObject.StaticCollectResources(nTemplateId)
end

function GameDestructibleObject:OnActorCreated(pUEActor)
    GameDestructibleObject.super.OnActorCreated(self, pUEActor)
    
    local tbDestructibleObjectData = DestructibleObjectNewDataTable:GetTemplate(self.nTemplateId)
    if tbDestructibleObjectData == nil then
        return
    end
    local szPawnMeshName = tbDestructibleObjectData.szMesh
    if szPawnMeshName then
        self.pUEActor:SetMesh(szPawnMeshName)
    end
    if tbDestructibleObjectData.tbCollisionLocation and tbDestructibleObjectData.tbCollisionScale then
        local tbLocation = tbDestructibleObjectData.tbCollisionLocation
        local tbScale = tbDestructibleObjectData.tbCollisionScale
        SetVector(TempVector1, tbLocation[1], tbLocation[2], tbLocation[3])
        SetVector(TempVector2, tbScale[1], tbScale[2], tbScale[3])
        self.pUEActor:SetCollisionTransform(TempVector1, TempVector2)
    end
    if tbDestructibleObjectData.tbInPos and tbDestructibleObjectData.tbOutPos then
        local tbInPos = tbDestructibleObjectData.tbInPos
        local tbOutPos = tbDestructibleObjectData.tbOutPos
        SetVector(TempVector1, tbInPos[1], tbInPos[2], tbInPos[3])
        SetVector(TempVector2, tbOutPos[1], tbOutPos[2], tbOutPos[3])
        self.pUEActor:SetInOutPos(TempVector1, TempVector2)
    end
end

function GameDestructibleObject:IsDead()
    -- log("GameDestructibleObject:IsDead", self.DestructibleObjectPropertyComponent:GetIsDead())
    return self.DestructibleObjectPropertyComponent:GetIsDead()    
end

function GameDestructibleObject:GetCurrentPropertyComponent()
    return self.DestructibleObjectPropertyComponent
end

function GameDestructibleObject:ConvertToComponentParams(nLifeCycleType)
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

    local nActorType = Def.tbActorType.DestructibleObject
    return nEnvironmentType, nActorType, nLifeCycleType
end

function GameDestructibleObject:OnCreateComponents()
    local bRet = GameDestructibleObject.super.OnCreateComponents(self)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithGameObject))
    return bRet
end

function GameDestructibleObject:OnActorPreCreated(pUEActor)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
    GameDestructibleObject.super.OnActorPreCreated(self, pUEActor)
end

function GameDestructibleObject:UnbindUEActor()
    GameDestructibleObject.super.UnbindUEActor(self)
    GameComponentCreateHelper:Destroy(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
end

function GameDestructibleObject:Break()
    local PropertyComponent = self.DestructibleObjectPropertyComponent
    local nMaxHp = PropertyComponent:GetDefaultMaxHp()
    PropertyComponent:ApplyDamage(self, DamageTypeEx.KILL_SELF, nMaxHp)
end

return GameDestructibleObject