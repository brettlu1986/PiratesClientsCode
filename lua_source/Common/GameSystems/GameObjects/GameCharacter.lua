-- 角色类
-- 换装相关的建议放到component里

local luaclass = require("luaclass")
local GameObjectClass = require("GameObject")
local GameCharacter = luaclass("GameCharacter", GameObjectClass)

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ShipDataTable = require("ShipDataTable")
local HumanDataTable = require("HumanDataTable")
local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local TemplateTypeDef = require("TemplateTypeDef")
local CollectionDataTable = require("CollectionDataTable")
local UEActorHelper = require("UEActorHelper")
local DamageTypeEx = require("DamageTypeEx")
local AIHelper = require("AIHelper")
local PropName = require("PropName")

GameCharacter.nTemplateType = TemplateTypeDef.SHIP
GameCharacter.bPaused = false

function GameCharacter:ParseCreateData(tbCreateData)
    if(not GameCharacter.super.ParseCreateData(self, tbCreateData)) then
        return false
    end

    self.nTemplateType = tbCreateData.nTemplateType
    return true
end

function GameCharacter.StaticGetActorClass(nTemplateType, nTemplateId)
    local tbTable = nil
    if nTemplateType == TemplateTypeDef.SHIP then
        tbTable = ShipDataTable:GetTemplate(nTemplateId)
        if(tbTable == nil) then
            logerror("GameCharacter_C:GetActorClassByTemplateId failed, can not find ship templateid: ", nTemplateId)
            return nil
        end
        return tbTable.tbResData.szPawnClassName
    elseif nTemplateType == TemplateTypeDef.HUMAN then
        tbTable = HumanDataTable:GetTemplate(nTemplateId)
        if(tbTable == nil) then
            logerror("GameCharacter_C:GetActorClassByTemplateId failed, can not find human templateid: ", nTemplateId)
            return nil
        end
        return tbTable.tbResData.szPawnClassName
    elseif nTemplateType == TemplateTypeDef.SHIPCOLLECTION or nTemplateType == TemplateTypeDef.HUMANCOLLECTION then
        tbTable = CollectionDataTable:GetTemplate(nTemplateId)
        if(tbTable == nil) then
            logerror("GameCharacter_C:GetActorClassByTemplateId failed, can not find collection templateid: ", nTemplateId)
            return nil
        end
        return tbTable.tbResData.szPawnClassName
    end

    logerror("GameCharacter_C:GetActorClassByTemplateId failed, invalid type, templateid: ", nTemplateId)
    return nil
end

function GameCharacter:GetActorClassByTemplateId(nTemplateId)
    return GameCharacter.StaticGetActorClass(self.nTemplateType, nTemplateId)
end

function GameCharacter:IsShip()
    return self.nTemplateType == TemplateTypeDef.SHIP
end

function GameCharacter:IsHuman()
    return self.nTemplateType == TemplateTypeDef.HUMAN
end

function GameCharacter:GetTemplateType()
    return self.nTemplateType
end

function GameCharacter:ConvertToComponentParams(nLifeCycleType)
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

    local nActorType
    if self.nTemplateType == TemplateTypeDef.SHIP then
        nActorType = Def.tbActorType.Ship
    elseif self.nTemplateType == TemplateTypeDef.HUMAN then
        nActorType = Def.tbActorType.Human
    elseif self.nTemplateType == TemplateTypeDef.SHIPCOLLECTION then
        nActorType = Def.tbActorType.ShipCollection
    elseif self.nTemplateType == TemplateTypeDef.HUMANCOLLECTION then
        nActorType = Def.tbActorType.HumanCollection
    else
        nActorType = Def.tbActorType.None
    end

    return nEnvironmentType, nActorType, nLifeCycleType
end

function GameCharacter:OnCreateComponents()
    local bRet = GameCharacter.super.OnCreateComponents(self)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithGameObject))
    return bRet
end

function GameCharacter:OnActorPreCreated(pUEActor)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
    GameCharacter.super.OnActorPreCreated(self, pUEActor)
end

function GameCharacter:OnActorCreated(pUEActor)
    GameCharacter.super.OnActorCreated(self, pUEActor)
end

function GameCharacter:UnbindUEActor()
    GameCharacter.super.UnbindUEActor(self)
    GameComponentCreateHelper:Destroy(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
end

function GameCharacter:GetDebugInfo()
    local tbRet = GameCharacter.super.GetDebugInfo(self)
    tbRet.nTemplateType = self.nTemplateType
    return tbRet
end

function GameCharacter:GetCurrentPropertyComponent()
    if self:IsShip() then
        return self.ShipBattlePropertyComponent
    else
        return self.HumanBattlePropertyComponent
    end
end

function GameCharacter:IsDead()
    local bShipDead = self.ShipBattlePropertyComponent:GetIsDead()
    local bHumanDead = self.HumanBattlePropertyComponent:GetIsDead()
    if self:IsHuman() and bShipDead then
        log("[GameCharacter:IsDead] CharacerInfo:", self.szName, "IsAIControlled:", AIHelper.IsAIControlled(self))
        error("[GameCharacter:IsDead] dead state error. Character is human now.")
    elseif self:IsShip() and bHumanDead then
        log("[GameCharacter:IsDead] CharacerInfo:", self.szName, "IsAIControlled:", AIHelper.IsAIControlled(self))
        error("[GameCharacter:IsDead] dead state error. Character is ship now.")
    end
    return bShipDead or bHumanDead
    --return self:GetCurrentPropertyComponent():GetIsDead()
end

function GameCharacter:IsDying()
    return self:GetCurrentPropertyComponent():GetIsDying()
end

-- 是否活着（没有死亡且不处于重伤状态）
function GameCharacter:IsAlive()
    return not (self:IsDead() or self:IsDying())
end

function GameCharacter:KillSelf(nDamageType)
    nDamageType = nDamageType or DamageTypeEx.KILL_SELF
    local PropertyComponent = self:GetCurrentPropertyComponent()
    local nMaxHp = PropertyComponent:GetMaxHp()
    PropertyComponent:ApplyDamage(self, nDamageType, nMaxHp)
end

-- 交互或者其他时机，需要暂停船只移动及武器开关时调用
function GameCharacter:SetPaused(bPaused)
    self.bPaused = bPaused
end

function GameCharacter:IsPaused()
    return self.bPaused
end

function GameCharacter:GetShipTemplateId()
    return self.ShipBattlePropertyComponent:GetProp(PropName.nShipTemplateId)
end

function GameCharacter:GetHumanTemplateId()
    return self.HumanBattlePropertyComponent:GetProp(PropName.nHumanTemplateId)
end

function GameCharacter:StopMove(bImmediately)
    UEActorHelper.StopMove(self.pUEActor, bImmediately)
end

return GameCharacter
