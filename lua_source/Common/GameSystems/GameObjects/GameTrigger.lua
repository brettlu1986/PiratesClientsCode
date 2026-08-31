-- Trigger

local luaclass = require("luaclass")
local GameObjectClass = dynamic_require("GameObject")
local GameTrigger = luaclass("GameTrigger", GameObjectClass)

local GameComponentCreateHelper = require("GameComponentCreateHelper")
local GameComponentTypeDefine = require("GameComponentTypeDefine")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TriggerResDataTable = require("TriggerResDataTable")
local BattleTemplateActorSystem = dynamic_require("BattleTemplateActorSystem")
local SceneItemActorDef = require("SceneItemActorDef")

GameTrigger.SHAPE_TYPE_CIRCLE = 0
GameTrigger.SHAPE_TYPE_BOX = 1

GameTrigger.nType = nil
GameTrigger.nResId = nil
GameTrigger.nTriggerId = nil
GameTrigger.nShapeType = nil
GameTrigger.nRadius = nil
GameTrigger.nGroupIndex = nil
GameTrigger.nSubGroupIndex = nil
GameTrigger.nBoxX = nil
GameTrigger.nBoxY = nil
GameTrigger.nBoxZ = nil
GameTrigger.nTemplateActorInstanceId = nil

function GameTrigger:ParseCreateData(tbCreateData)
    if(not GameTrigger.super.ParseCreateData(self, tbCreateData)) then
        return false
    end

    local tbTriggerData = TriggerResDataTable:GetTemplate(tbCreateData.nResId)
    local nShapeType = tbCreateData.nShapeType
    self.nTriggerId = tbCreateData.nTriggerId
    self.nType = tbTriggerData and tbTriggerData.nType or 0
    self.nResId = tbCreateData.nResId
    self.nShapeType = nShapeType
    self.nGroupIndex = tbCreateData.nGroupIndex
    self.nSubGroupIndex = tbCreateData.nSubGroupIndex

    if(nShapeType == self.SHAPE_TYPE_CIRCLE) then
        self.nRadius = tbCreateData.nRadius
    elseif(nShapeType == self.SHAPE_TYPE_BOX) then
        self.nBoxX = tbCreateData.nBoxX
        self.nBoxY = tbCreateData.nBoxY
        self.nBoxZ = tbCreateData.nBoxZ
    end

    if(GlobalVariableSystem.bEnableTemplateActor and GlobalVariableSystem:IsServerLogic()) then
        -- 掉落物逻辑
        local tbCustomData = tbCreateData.tbCustomData
        if(tbCustomData) then
            local tbSceneItemInfo = tbCustomData.scene_item_info
            if(tbSceneItemInfo and tbSceneItemInfo.type ~= SceneItemActorDef.AIR_DROP_BOX) then
                -- 空投走server
                local fnAdd = nil
                if(tbSceneItemInfo.type == SceneItemActorDef.SIGHT_FREE_ITEM) then
                    fnAdd = BattleTemplateActorSystem.AddGlobal
                else
                    fnAdd = BattleTemplateActorSystem.Add
                end
                local bRet = fnAdd(BattleTemplateActorSystem,
                    tbSceneItemInfo.instance_id,
                    tbSceneItemInfo.template_id,
                    tbCreateData.nLocationX,
                    tbCreateData.nLocationY,
                    tbCreateData.nLocationZ,
                    tbCreateData.nRotationYaw,
                    tbSceneItemInfo.type)
                if(bRet) then
                    self.bCreateUEActor = false
                    self.bCreateComponents = false
                    self.nTemplateActorInstanceId = tbSceneItemInfo.instance_id
                end
            end
        end
    end
    return true
end

function GameTrigger:OnDestroy()
    if(self.nTemplateActorInstanceId ~= nil) then
        BattleTemplateActorSystem:Remove(self.nTemplateActorInstanceId)
    end

    GameTrigger.super.OnDestroy(self)
end

function GameTrigger:ConvertToComponentParams(nLifeCycleType)
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

function GameTrigger:OnCreateComponents()
    local bRet = GameTrigger.super.OnCreateComponents(self)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithGameObject))
    return bRet
end

function GameTrigger:InitShapeInfo(pUEActor)
    local nShapeType = self.nShapeType
    if(nShapeType == self.SHAPE_TYPE_CIRCLE) then
        -- 圆
        if(self.nRadius == nil) then
            logerror(" GameTrigger:InitShapeInfo failed, invalid radius", self.nTriggerId, self.nResId)
            return
        end
        pUEActor:SetCollisionRadius(self.nRadius)
    elseif(nShapeType == self.SHAPE_TYPE_BOX) then
        if(self.nBoxX == nil or self.nBoxY == nil or self.nBoxZ == nil) then
            logerror(" GameTrigger:InitShapeInfo failed, invalid box extention",
                self.nTriggerId, self.nResId)
            return
        end
        pUEActor:SetCollisionExtension(Vector{X=self.nBoxX, Y=self.nBoxY, Z=self.nBoxZ})
    end
end

function GameTrigger:OnActorPreCreated(pUEActor)
    GameComponentCreateHelper:Create(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
    GameTrigger.super.OnActorPreCreated(self, pUEActor)
end

function GameTrigger:OnActorCreated(pUEActor)
    GameTrigger.super.OnActorCreated(self, pUEActor)

    if(self.nTriggerId) then
        pUEActor:SetTriggerId(self.nTriggerId)
    end
    self:InitShapeInfo(pUEActor)
end

function GameTrigger:UnbindUEActor()
    GameTrigger.super.UnbindUEActor(self)
    GameComponentCreateHelper:Destroy(self,
        self:ConvertToComponentParams(GameComponentTypeDefine.tbLifeCycleType.WithUEActor))
end

function GameTrigger:GetActorClassByTemplateId(_nTemplateId)
    local tbTriggerData = TriggerResDataTable:GetTemplate(self.nResId)
    if tbTriggerData == nil then
        logerror("GameTrigger:GetActorClassByTemplateId failed, can not find trigger templateid: ", self.nResId)
        return nil
    end
    return tbTriggerData.szPawnClassName
end

function GameTrigger:GetDebugInfo()
    local tbRet = GameTrigger.super.GetDebugInfo(self)
    tbRet.nResId = self.nResId
    tbRet.nTriggerId = self.nTriggerId
    tbRet.nRadius = self.nRadius
    return tbRet
end

-- function GameTrigger:PlayDestroyedEffect()
--     local nResId = self.nResId
--     local tbTemplate = nil
--     tbTemplate = TriggerResDataTable:GetTemplate(nResId)
--     if (tbTemplate.nDestroyEffectId ~= -1) then
--         local szEffectRes = EffectHelper:GetEffectClassById(tbTemplate.nDestroyEffectId)
--         local pClass = szEffectRes:load()
--         if(pClass == nil) then
--             logerror("GameTrigger_C:PlayDestroyedEffect spawn effect failed", nResId)
--             return false
--         end
--         self.pUEActor:SpawnDestroyedEffect_M(pClass, tbTemplate.DestroyEffectScaleType)
--     end
-- end

function GameTrigger.StaticCollectResources(tbCreateData, tbCustomData)
    local nResId = tbCreateData.nResId
    local tbTriggerData = TriggerResDataTable:GetTemplate(nResId)
    if tbTriggerData == nil then
        logerror("GameTrigger.StaticCollectResources failed, can not find trigger templateid: ", nResId)
        return nil
    end
    return tbTriggerData.szPawnClassName
end

return GameTrigger
