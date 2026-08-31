local luaclass = require("luaclass")
local SAIWeaponStrategyBase = luaclass("SAIWeaponStrategyBase")
local SelfEventHelperClass  = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local BattleItemCategoryDef     = require("BattleItemCategoryDef")
local ShipWeaponSlotDef         = require("ShipWeaponSlotDef")
local BattleItemSystemServer    = require("BattleItemSystemServer")
local HumanWeaponSlotDef        = require("HumanWeaponSlotDef")
local SAIMisc = require("SAIMisc")

local HUMAN_THROWITEM_SLOT = HumanWeaponSlotDef:SlotCount() + 1

SAIWeaponStrategyBase.tbOwner = nil
SAIWeaponStrategyBase.tbSelfEventHelper = nil
SAIWeaponStrategyBase.tbAIWeapon = nil

local function LOG(...)
    log("CJ->SAIWeaponStrategyBase:", ...)
end

local function OnWeaponEquipped_Human(self, nOwnerCharacterInstanceId, nWeaponInstanceId)
    local tbOwner = self.tbOwner
    if nOwnerCharacterInstanceId == tbOwner.nServerInstanceId then
        local tbWeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
        local nSlotIndex = tbWeaponItem:GetStorageLocation().nSlotIndex
        local WeaponComponent = tbOwner.HumanWeaponComponent
        if WeaponComponent and tbWeaponItem and SAIMisc:CanUseWeapon(tbOwner, tbWeaponItem:GetTemplateId()) then
            self:AddWeapon(nSlotIndex, tbWeaponItem)
        end
    end
end

local function OnWeaponUnEquipped_Human(self, nOwnerCharacterInstanceId, tbWeaponItem)
    if nOwnerCharacterInstanceId == self.tbOwner.nServerInstanceId then
        local nSlotIndex  = tbWeaponItem:GetStorageLocation().nSlotIndex
        self:RemoveWeapon(nSlotIndex)
    end
end

local function OnWeaponEquipped_Ship(self, OwnerCharacter, nWeaponSlot, tbWeaponItem)
    if (OwnerCharacter and OwnerCharacter.nServerInstanceId == self.tbOwner.nServerInstanceId) and (tbWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON) then
        local tbOwner = self.tbOwner
        if tbWeaponItem and SAIMisc:CanUseWeapon(tbOwner, tbWeaponItem:GetTemplateId()) then
            self:AddWeapon(nWeaponSlot, tbWeaponItem)
        end
    end
end

local function OnWeaponUnEquipped_Ship(self, OwnerCharacter, nWeaponSlot, tbWeaponItem)
    if (OwnerCharacter and OwnerCharacter.nServerInstanceId == self.tbOwner.nServerInstanceId) and (tbWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_WEAPON) then
        self:RemoveWeapon(nWeaponSlot)
    end
end

function SAIWeaponStrategyBase:Init(Owner)
    self.tbOwner = Owner
    self.tbSelfEventHelper = SelfEventHelperClass()
end

function SAIWeaponStrategyBase:AddWeapon(nWeaponSlot, tbWeaponItem)

end

function SAIWeaponStrategyBase:RemoveWeapon(nWeaponSlot)

end

function SAIWeaponStrategyBase:ChangeWeapon(nWeaponSlot)
    self.tbAIWeapon:ChangeWeapon(nWeaponSlot)
end

function SAIWeaponStrategyBase:OnStart()

end

function SAIWeaponStrategyBase:OnStop()

end

function SAIWeaponStrategyBase:Start(tbAIWeapon)
    self.tbAIWeapon = tbAIWeapon
    local tbOwner = self.tbOwner
    local SelfEventHelper = self.tbSelfEventHelper
    if tbOwner:IsHuman() then
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_POST, self, OnWeaponEquipped_Human)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER   , self, OnWeaponUnEquipped_Human)
        for i=1,HumanWeaponSlotDef:SlotCount() do
            local tbWeaponItem = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
            tbOwner:GetServerInstanceId(), i)
            if tbWeaponItem and SAIMisc:CanUseWeapon(tbOwner, tbWeaponItem:GetTemplateId()) then
               self:AddWeapon(i, tbWeaponItem)
            end
        end
        local tbThrowItems = BattleItemSystemServer:GetUnequippedItemsByCategory(tbOwner:GetServerInstanceId(),
        BattleItemCategoryDef.HUMAN_THROWN_ITEM)
        for _,v in ipairs(tbThrowItems) do
            if SAIMisc:CanUseWeapon(tbOwner, v:GetTemplateId()) then
                self:AddWeapon(HUMAN_THROWITEM_SLOT, v)
                return
            end
        end

    else
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_EQUIPPED_SERVER , self, OnWeaponEquipped_Ship)
        SelfEventHelper:RegisterEvent(CommonEventDef.EV_ON_SHIP_WEAPON_UNEQUIPPED_SERVER   , self, OnWeaponUnEquipped_Ship)
        for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
            local tbWeaponItem = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.SHIP_WEAPON,
            tbOwner:GetServerInstanceId(), i)
            if tbWeaponItem and SAIMisc:CanUseWeapon(tbOwner, tbWeaponItem:GetTemplateId()) then
                self:AddWeapon(i, tbWeaponItem)
            end
        end
    end

    self:OnStart()
end

function SAIWeaponStrategyBase:Stop()
    self.tbAIWeapon = nil
    self.tbSelfEventHelper:UnregisterAll()
    self:OnStop()
    LOG("stop")
end


function SAIWeaponStrategyBase:Uninit()
    self.tbSelfEventHelper:UnregisterAll()
end

return SAIWeaponStrategyBase