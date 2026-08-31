local luaclass = require("luaclass")
local AISupplySystem = luaclass("AISupplySystem")
local SelfEventHelperClass      = require("SelfEventHelper")
local CommonEventDef            = require("CommonEventDef")
local GlobalVariableSystem      = dynamic_require("GlobalVariableSystem")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local PropUtil = require("PropUtil")
local ConsumableItemDef         = require("ConsumableItemDef")
local BattleItemDataTable       = require("BattleItemDataTable")

AISupplySystem.SelfEventHelper = nil
AISupplySystem.Owner = nil
AISupplySystem.pAIController  = nil
AISupplySystem.nHPConsumeItem = 0
AISupplySystem.nEPConsumeItem = 0
AISupplySystem.nHpConsumeStartPercent = 0
AISupplySystem.nEpConsumeStartPercent = 0

local szHPConsumeItemKey  = "HPConsumeItem"
local szEPConsumeItemKey  = "EPConsumeItem"
local szIsConsumingKey    = "IsConsumeItem"

local nDefaultHpConsumeStartPercent = 0.7
local nDefaultEpConsumeStartPercent = 1.0

local function LOG(...)
    --log("CJ->AISupplySystem:", ...)
end

local function CheckHpLimit(self, tbItem)
    local tbCharacter = self.Owner
    local nHpPercent= PropUtil.GetHpPercent(tbCharacter)
    if nHpPercent <= 0 or nHpPercent >= self.nHpConsumeStartPercent then
        return false
    end
    local tbTemplate = tbItem:GetTemplate()
    local nPercentageCap = tbTemplate.nHpLimit
    if nPercentageCap and nHpPercent * 100 >= nPercentageCap then
        return false
    end
    return true
end

local function CheckEpLimit(self)
    local tbCharacter = self.Owner
    local nMaxEP = PropUtil.GetMaxEp(tbCharacter)
    local nCurEP = PropUtil.GetEp(tbCharacter)
    return  nCurEP < nMaxEP * self.nEpConsumeStartPercent
end

local function OnItemChanged(self)
    if GlobalVariableSystem:IsServerLogic() then
        local tbOwner = self.Owner
        local pBlackboard = self.pAIController.Blackboard
        local bIsBuilding = pBlackboard:GetValueAsBool(szIsConsumingKey)
        if bIsBuilding then
            return
        end
        if tbOwner:IsDying() or tbOwner:IsDead() then
            return
        end


        local nCharacterInstanceId = self.Owner.nServerInstanceId
        local tbItems = BattleItemSystemServer:GetUnequippedItemsByCategory(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_CONSUMABLE)
        local nHPItem = 0
        local nEPItem = 0
        for i,v in ipairs(tbItems) do
            local tbConsumableTemplate = v:GetTemplate()
            if tbConsumableTemplate.nRecoveringType == ConsumableItemDef.RecoveringType.HP then
                if CheckHpLimit(self, v) and nHPItem <= 0 then
                    nHPItem = v.nInstanceId
                end
            elseif tbConsumableTemplate.nRecoveringType == ConsumableItemDef.RecoveringType.EP then
                if CheckEpLimit(self) and nEPItem <= 0 then
                    nEPItem = v.nInstanceId
                end
            end
        end
        self:SetHPConsumeItem(nHPItem)
        self:SetEPConsumeItem(nEPItem)
    end
end



local function OnItemRemove(self, nItemInstanceId, nItemTemplateId, nCharacterInstanceId, nRoomType, nOwnerInstanceId, nSlotIndex)
    if nCharacterInstanceId == self.Owner.nServerInstanceId and GlobalVariableSystem:IsServerLogic() then
        local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
        if tbTemplate and tbTemplate.nCategory == BattleItemCategoryDef.HUMAN_CONSUMABLE then
            OnItemChanged(self)
        end
    end
end

local function OnItemAdd(self, tbItem)
    if tbItem.tbOwnerCharacter == self.Owner and GlobalVariableSystem:IsServerLogic() and
    tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_CONSUMABLE then
        OnItemChanged(self)
    end
end

local function OnItemStack(self, tbItem)
    if tbItem.tbOwnerCharacter == self.Owner and GlobalVariableSystem:IsServerLogic() and
    tbItem:GetCategory() == BattleItemCategoryDef.HUMAN_CONSUMABLE then
        OnItemChanged(self)
    end
end

local function OnConsumeOK(self, tbPlayer, nItemTemplateId)
    if tbPlayer == self.Owner and GlobalVariableSystem:IsServerLogic() then
        local pBlackboard = self.pAIController.Blackboard
        pBlackboard:SetValueAsBool(szIsConsumingKey, false)
        OnItemChanged(self)
        LOG("consume ok")
    end
end

local function OnHpChanged(self, nHp, nMaxHp, nHpPercent)
    if nHpPercent < self.nHpConsumeStartPercent and self.nHPConsumeItem <= 0 then
        OnItemChanged(self)
    elseif nHpPercent >= self.nHpConsumeStartPercent then
        local pBlackboard = self.pAIController.Blackboard
        pBlackboard:SetValueAsBool(szIsConsumingKey, false)
        pBlackboard:SetValueAsInt(szHPConsumeItemKey, 0)
    end
end

function AISupplySystem:Init(pAIController, tbOwner, tbConfig)
    self.Owner = tbOwner
    self.pAIController = pAIController
    local SelfEventHelper = SelfEventHelperClass()
    local PropertyComponent = tbOwner:GetCurrentPropertyComponent()
    self.SelfEventHelper = SelfEventHelper
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_ADD_SERVER,                self, OnItemAdd)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_REMOVE_SERVER,             self, OnItemRemove)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_BATTLE_ITEM_CHANGE_STACKCOUNT_SERVER,  self, OnItemStack)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_CONSUMABLE_ITEM_CONSUME_SUCCESS,       self, OnConsumeOK)
    SelfEventHelper:RegisterLuaDelegate(PropertyComponent.OnHpChanged, OnHpChanged,        self)
    local pBlackboard = pAIController.Blackboard
    pBlackboard:SetValueAsBool(szIsConsumingKey, false)
    pBlackboard:SetValueAsInt(szHPConsumeItemKey, 0)
    pBlackboard:SetValueAsInt(szEPConsumeItemKey, 0)
    self.nHpConsumeStartPercent = tbConfig.nHpConsumeStartPercent or nDefaultHpConsumeStartPercent
    self.nEpConsumeStartPercent = tbConfig.nEpConsumeStartPercent or nDefaultEpConsumeStartPercent
end

function AISupplySystem:SetParams(tbConfig)

end

function AISupplySystem:SetHPConsumeItem(nInstanceId)
    self.nHPConsumeItem = nInstanceId
    LOG("SetHPConsumeItem ", nInstanceId)
    if self.pAIController then
        local pBlackboard = self.pAIController.Blackboard
        pBlackboard:SetValueAsInt(szHPConsumeItemKey, nInstanceId)
    end
end

function AISupplySystem:SetEPConsumeItem(nInstanceId)
    self.nEPConsumeItem = nInstanceId
    LOG("SetEPConsumeItem ", nInstanceId)
    if self.pAIController then
        local pBlackboard = self.pAIController.Blackboard
        pBlackboard:SetValueAsInt(szEPConsumeItemKey, nInstanceId)
    end
end

function AISupplySystem:Uninit()
    self:SetHPConsumeItem(0)
    self:SetEPConsumeItem(0)
    self.SelfEventHelper:UnregisterAll()
    self.SelfEventHelper = nil
end

return AISupplySystem