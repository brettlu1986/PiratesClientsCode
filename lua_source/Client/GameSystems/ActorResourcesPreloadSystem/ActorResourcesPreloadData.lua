local luaclass = require("luaclass")
local ActorResourcesPreloadData = luaclass("ActorResourcesPreloadData")

local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local TemplateTypeDef = require("TemplateTypeDef")
local ReplicateHelper = require("ReplicateHelper")
local UEActorHelper = require("UEActorHelper")
local PropName = require("PropName")
local ProgressBarHelper = require("ProgressBarHelper")
local NPCDataTable = require("NPCDataTable")

local LoadMultiAssetsAsyncCallbackFire = EngineExtShell.LoadMultiAssetsAsyncCallbackFire
local GetValueFromRepComponent = ReplicateHelper.GetValueFromRepComponent

ActorResourcesPreloadData.nServerInstanceId = nil
ActorResourcesPreloadData.pActorChannel = nil
ActorResourcesPreloadData.tbInitProtoData = nil
--ActorResourcesPreloadData.nActorNetGuid = nil
ActorResourcesPreloadData.pActor = nil
ActorResourcesPreloadData.nObjectType = nil
ActorResourcesPreloadData.tbLoadedObjects = nil
ActorResourcesPreloadData.bLoadFinished = nil
ActorResourcesPreloadData.fnLoadedCallback = nil
ActorResourcesPreloadData.pDelegate = nil
ActorResourcesPreloadData.nDelegateHandle = nil
ActorResourcesPreloadData.bAllFinished = nil

local CollectResources
local DoCustomActions
local AreAllCustomActionsFinished
local SetAllPreloadActionsFinished
local VerifyAllPreloadActionFinished
local UnbindLoadDelegate

local function CollectHumanWeaponResource(self, pRepComponent, nPropId, tbOutPaths)
    local nTemplateId = GetValueFromRepComponent(pRepComponent, nPropId)
    if(nTemplateId ~= 0) then
        table.insert(tbOutPaths, HumanWeaponHelper.GetWeaponResClassPath(nTemplateId))
    end
end

local function CollectHumanProgressBarResource(self, pRepComponent, nPropId, tbOutPaths)
    local tbProgressBar = GetValueFromRepComponent(pRepComponent, nPropId)
    if(tbProgressBar ~= 0) then
        ProgressBarHelper.GetHumanProgressBarResClassPath(pRepComponent, self.tbInitProtoData.template_id, tbOutPaths)
    end
end
local function CollectHumanResources(self, pRepComponent, tbOutPaths)
    CollectHumanWeaponResource(self, pRepComponent, PropName.nHumanWeaponPrimaryTemplateId, tbOutPaths)
    CollectHumanWeaponResource(self, pRepComponent, PropName.nHumanWeaponSecondaryTemplateId, tbOutPaths)
    CollectHumanWeaponResource(self, pRepComponent, PropName.nHumanWeaponMeleeTemplateId, tbOutPaths)
    CollectHumanWeaponResource(self, pRepComponent, PropName.nHumanWeaponThrowTemplateId, tbOutPaths)
    CollectHumanProgressBarResource(self, pRepComponent, PropName.ProgressBar, tbOutPaths)
end

CollectResources = function(self, tbOutPaths)
    -- 各系统可以根据自身需求分析出想要加载的资源，然后放到tbOutPaths中，后面会自动加载tbOutPaths
    local pRepComponent = self.pActor.CustomReplication
    local nObjectType = self.nObjectType
    local tbInitProtoData = self.tbInitProtoData
    local nTemplateType = tbInitProtoData.template_type

    -- luacheck: push ignore
    if(nObjectType == GameObjectTypeDef.PlayerSelf) then
    -- luacheck: pop
    elseif(nObjectType == GameObjectTypeDef.PlayerOther) then
        if(nTemplateType == TemplateTypeDef.HUMAN) then
            CollectHumanResources(self, pRepComponent, tbOutPaths)
        end
    elseif(nObjectType == GameObjectTypeDef.Npc) then
        local tbTemplate = NPCDataTable:GetTemplate(tbInitProtoData.template_id)
        if(tbTemplate ~= nil and tbTemplate.nType == TemplateTypeDef.HUMAN) then
            CollectHumanResources(self, pRepComponent, tbOutPaths)
        end
    end
end

DoCustomActions = function(self)
    -- TODO: 如果有其他事情可以放到这里，然后把IsAllCustomDataFinished实现下
end

AreAllCustomActionsFinished = function(self)
    -- TODO: 如果有custom需求需要改写此函数
    return true
end

SetAllPreloadActionsFinished = function(self)
    self.bAllFinished = true
    local pActorChannel = self.pActorChannel
    if(isvalidhandle(pActorChannel)) then
        pActorChannel:SetActorResourcesLoaded(self.tbLoadedObjects)
        if(GlobalVariableSystem.bEnableActorBeginPlayManuallyInNetClient) then
            pActorChannel:UseComponentDataSerializer(UEActorHelper.tbBattleComponentTags, GlobalVariableSystem.bUseSeparateBeginPlayInNetClient)
        end
    end
end

VerifyAllPreloadActionFinished = function(self)
    if(not self.bLoadFinished) then
        return
    end

    if(not AreAllCustomActionsFinished(self)) then
        return
    end

    SetAllPreloadActionsFinished(self)
end

UnbindLoadDelegate = function(self)
    if(isvalidhandle(self.pDelegate)) then
        unbindDelegate(self.pDelegate, self.nDelegateHandle)
    end
    self.pDelegate = nil
    self.nDelegateHandle = nil
    self.fnLoadedCallback = nil
end

function ActorResourcesPreloadData:OnCreate(pActorChannel,
    pActor, nServerInstanceId, tbInitProtoData, nActorNetGuid, bLoadAsync)

    self.nServerInstanceId = nServerInstanceId
    self.pActorChannel = pActorChannel
    self.tbInitProtoData = tbInitProtoData
    --self.nActorNetGuid = nActorNetGuid
    self.pActor = pActor

    local tbPaths = {}
    local tbGamePlayerSelf = GamePlayerSelfHelper:Get()
    assert(tbGamePlayerSelf)

    local nType = tbInitProtoData.script_type
    if(nType == GameObjectTypeDef.PlayerSelf
        and tbGamePlayerSelf.nPlayerId ~= tbInitProtoData.player_id) then
        nType = GameObjectTypeDef.PlayerOther
    end
    self.nObjectType = nType

    CollectResources(self, tbPaths)
    DoCustomActions(self)

    local fnLoadedCallback = function(tbLoadedObjects)
        if(self.pActor == nil) then
            return
        end
        UnbindLoadDelegate(self)
        self.tbLoadedObjects = tbLoadedObjects
        self.bLoadFinished = true
        VerifyAllPreloadActionFinished(self)
    end
    self.fnLoadedCallback = fnLoadedCallback

    if(#tbPaths > 0) then
        if(bLoadAsync) then
            self.pDelegate, self.nDelegateHandle = createDelegate(LoadMultiAssetsAsyncCallbackFire, fnLoadedCallback, "Preload actor resources")
            EngineExtShell.Get(GWorld):LoadMultiAssetsAsync(tbPaths, self.pDelegate)
        else
            local tbLoadedObjects = {}
            for _, v in ipairs(tbPaths) do
                table.insert(tbLoadedObjects, v:load())
            end
            fnLoadedCallback(tbLoadedObjects)
        end
    else
        fnLoadedCallback(nil)
    end
end

function ActorResourcesPreloadData:OnDestroy()
    self.pActor = nil
    UnbindLoadDelegate(self)
end

return ActorResourcesPreloadData