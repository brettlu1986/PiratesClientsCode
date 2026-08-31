-- Dummy
-- 一些通用的场景小物件

local luaclass = require("luaclass")
local GameObjectClass = dynamic_require("GameObject")
local GameDummy = luaclass("GameDummy", GameObjectClass)

local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DummyResDataTable = require("DummyResDataTable")


function GameDummy:ParseCreateData(tbCreateData)
    if(not GameDummy.super.ParseCreateData(self, tbCreateData)) then
        return false
    end

    return true
end

function GameDummy:ConvertToComponentParams(nLifeCycleType)
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

    local nActorType = Def.tbActorType.All
    return nEnvironmentType, nActorType, nLifeCycleType
end

function GameDummy:OnCreateComponents()
    local bRet = GameDummy.super.OnCreateComponents(self)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithGameObject))
    return bRet
end

function GameDummy:OnActorPreCreated(pUEActor)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
    GameDummy.super.OnActorPreCreated(self, pUEActor)
end

function GameDummy:UnbindUEActor()
    GameDummy.super.UnbindUEActor(self)
    GameComponentCreateHelper:Destroy(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
end

function GameDummy:GetActorClassByTemplateId(nTemplateId)
    local tbTemplate = DummyResDataTable:GetTemplate(nTemplateId)
    if(tbTemplate == nil) then
        logerror("GameDummy:GetActorClassByTemplateId failed", nTemplateId)
        return nil
    end
    return tbTemplate.szBPClass
end

function GameDummy:GetDebugInfo()
    local tbRet = GameDummy.super.GetDebugInfo(self)
    return tbRet
end

function GameDummy.StaticCollectResources(tbCreateData, tbCustomData)
    local tbTemplate = DummyResDataTable:GetTemplate(tbCreateData.nTemplateId)
    if(tbTemplate == nil) then
        return nil
    end
    return tbTemplate.szBPClass
end

return GameDummy
