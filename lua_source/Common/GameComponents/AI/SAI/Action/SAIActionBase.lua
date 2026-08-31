-----------------------------------------------------
--File Name    : SAIActionBase.lua
--Author       : Chen Jing
--Create Time  : 2018-12-29
--Description  : 船和人共有的操作
-----------------------------------------------------
local luaclass = require("luaclass")
local SAIActionBase = luaclass("SAIActionBase")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef  = require("BattleItemCategoryDef")
local BattleLandSystem       = dynamic_require("BattleLandSystem")
local BattleItemDataTable    = require("BattleItemDataTable")
local CheckCanBuildItemHelper= require("CheckCanBuildItemHelper")
local HumanWeaponSlotDef     = require("HumanWeaponSlotDef")
local HumanArmorSlotDef      = require("HumanArmorSlotDef")
local GameObjectSystem       = dynamic_require("GameObjectSystem")
local SelfEventHelperClass   = require("SelfEventHelper")

SAIActionBase.Owner = nil
SAIActionBase.pBlackboard = nil
SAIActionBase.pAIController = nil
SAIActionBase.tbSelfEventHelper = nil

local function LOG(...)
--    log("CJ->SAIActionBase:", ...)
end


function SAIActionBase:Start(tbOwner, pAIController)
    self.pAIController = pAIController
    self.pBlackboard = pAIController.Blackboard
    self.Owner = tbOwner
    self.tbSelfEventHelper = SelfEventHelperClass()
    self:RegisterEvent(self.tbSelfEventHelper)
end

function SAIActionBase:Stop()
    self.tbSelfEventHelper:UnregisterAll()
    self.Owner = nil
    self.pBlackboard = nil
    self.pAIController = nil
end


function SAIActionBase:RegisterEvent(SelfEventHelper)
    local pAIActionComponent = self.pAIController.ActionComponent
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnPickItem, self, self.OnPickItem)
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnBuildItem, self, self.OnBuildItem)
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnConsumeItem, self, self.OnConsumeItem)
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnChangeDisplay, self, self.OnChangeDisplay)
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnRescue,  self, self.OnRescue)
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnSwitchWeapon,  self, self.OnSwitchWeapon)
end


function SAIActionBase:OnChangeDisplay(...)
    assert(self.Owner)
    local nUniqueId = self.Owner.nUniqueId
    BattleLandSystem:OnStartChangeDisplay(nUniqueId)
end


function SAIActionBase:OnPickItem(nItemInstanceId)
    local nOwnerInstanceId = self.Owner.nServerInstanceId
    local tbItem = BattleItemSystemServer:GetItem(nItemInstanceId)
    if tbItem and not tbItem:HasOwnerCharacter() then
        if tbItem:GetCategory() == BattleItemCategoryDef.SCENE_ITEM_PACKAGE then
            local tbSubItems = BattleItemSystemServer:GetItemsInSceneItemPackage(nItemInstanceId) or {}
            for _,v in pairs(tbSubItems) do
                if BattleItemSystemServer:CanAutoPickUp(nOwnerInstanceId, v) then
                    LOG("start pick up item[item]:", v.nInstanceId)
                    BattleItemSystemServer:PickUpSceneItem(nOwnerInstanceId, v.nInstanceId)
                end
            end
        else
            if BattleItemSystemServer:CanAutoPickUp(nOwnerInstanceId, tbItem) then
                LOG("start pick up item[item]:", nItemInstanceId)
                BattleItemSystemServer:PickUpSceneItem(nOwnerInstanceId, nItemInstanceId)
            end
        end
    end
end

function SAIActionBase:OnBuildItem(nItemTemplateId)
    local nOwnerInstanceId = self.Owner.nServerInstanceId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_WEAPON then
        for i=1,HumanWeaponSlotDef:SlotCount() do
            local tbWeapon = BattleItemSystemServer:GetEquippedItem(nOwnerInstanceId, BattleItemCategoryDef.HUMAN_WEAPON,
            nOwnerInstanceId, i)
            if tbWeapon and CheckCanBuildItemHelper.GetNextBuildHumanItemTemplateId(tbWeapon:GetTemplateId()) == nItemTemplateId then
                BattleItemSystemServer:BuildItem(nOwnerInstanceId, nItemTemplateId, i)
                return
            end
        end

    elseif tbItemTemplate.nCategory == BattleItemCategoryDef.HUMAN_ARMOR then
        for i=1,HumanArmorSlotDef:SlotCount() do
            local tbArmor = BattleItemSystemServer:GetEquippedItem(nOwnerInstanceId, BattleItemCategoryDef.HUMAN_ARMOR,
            nOwnerInstanceId, i)
            if tbArmor and CheckCanBuildItemHelper.GetNextBuildHumanItemTemplateId(tbArmor:GetTemplateId()) == nItemTemplateId then
                BattleItemSystemServer:BuildItem(nOwnerInstanceId, nItemTemplateId, i)
                return
            end
        end
    else
        BattleItemSystemServer:BuildItem(nOwnerInstanceId, nItemTemplateId)
    end


end

function SAIActionBase:OnConsumeItem(nInstanceId)
    local tbOwner = self.Owner
    if tbOwner.ConsumableItemComponentServer and nInstanceId > 0 then
        tbOwner.ConsumableItemComponentServer:ConsumeItemRequest(nInstanceId)
    end
end


function SAIActionBase:OnRescue(nServerInstanceId)
    local tbRescueObject = GameObjectSystem:FindByInstanceId(nServerInstanceId)
    if tbRescueObject then
        if tbRescueObject:GetCurrentPropertyComponent():GetIsDying() and not
        tbRescueObject.BattleDyingComponent:IsBeingRescued() then
            tbRescueObject.BattleDyingComponent:Rescue(self.Owner)
            LOG("start rescuing")
        else
            LOG("stop rescuing")
        end
    end
end

function SAIActionBase:OnSwitchWeapon(nSlot)

end


return SAIActionBase