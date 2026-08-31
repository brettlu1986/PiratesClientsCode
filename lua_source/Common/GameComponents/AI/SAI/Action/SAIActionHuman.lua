local luaclass = require("luaclass")
local SAIActionBase = require("SAIActionBase")
local SAIActionHuman = luaclass("SAIActionHuman", SAIActionBase)
local HumanWeaponSlotDef     = require("HumanWeaponSlotDef")
local BattleHumanWeaponSystem = dynamic_require("BattleHumanWeaponSystemNew")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleItemCategoryDef  = require("BattleItemCategoryDef")
local HumanMovementStateType = require("HumanMovementStateType")

local function LOG(...)
    log("CJ->SAIActionHuman:", ...)
end

local function CanChangeMovementState(self)
    local tbOwner = self.Owner
    local HumanMovementStateComponent = tbOwner.HumanMovementStateComponent
    if tbOwner and tbOwner:IsHuman() and HumanMovementStateComponent then
        return true
    end
    return false
end

function SAIActionHuman:RegisterEvent(SelfEventHelper)
    SAIActionHuman.super.RegisterEvent(self, SelfEventHelper)
    local pAIActionComponent = self.pAIController.ActionComponent
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnRun, self, self.OnRun)
    SelfEventHelper:RegisterCppDelegate(pAIActionComponent.OnJump,self, self.OnJump)
end

function SAIActionHuman:OnRun(bRun)
    assert(self.Owner and self.Owner.pUEActor)
    local Owner = self.Owner
    if not CanChangeMovementState(self) then
        return
    end
    Owner.HumanMovementStateComponent:SetRun(bRun)
end

function SAIActionHuman:OnJump()
    local Owner = self.Owner
    local HumanMovementStateComponent = Owner.HumanMovementStateComponent
    if not CanChangeMovementState(self) or not HumanMovementStateComponent.bEnableMove then
        return
    end
    local nMovementState = HumanMovementStateComponent.rMovementState
    if nMovementState == HumanMovementStateType.Crouch_State or
    nMovementState == HumanMovementStateType.Crawl_State then
        HumanMovementStateComponent:SetMovementState(HumanMovementStateType.UpRight_State)
        return
    end
    Owner.pUEActor:Jump()
end

function SAIActionHuman:OnSwitchWeapon(nSlot)
    LOG("switch weapon ", nSlot)
    assert(self.Owner and self.Owner.pUEActor)
    local tbOwner = self.Owner
    local WeaponComponent = tbOwner.HumanWeaponComponent
    if nSlot > 0 and nSlot <= HumanWeaponSlotDef:SlotCount() then
        local tbWeapon = BattleItemSystemServer:GetEquippedItem(tbOwner:GetServerInstanceId(), BattleItemCategoryDef.HUMAN_WEAPON,
        tbOwner:GetServerInstanceId(), nSlot)
        if WeaponComponent and tbWeapon then
            WeaponComponent:SetCurrentWeapon(tbWeapon:GetInstanceId())
        end
    else
        local tbThrowItems = BattleItemSystemServer:GetUnequippedItemsByCategory(tbOwner:GetServerInstanceId(),
        BattleItemCategoryDef.HUMAN_THROWN_ITEM)
        -- luacheck: push ignore
        for _,v in ipairs(tbThrowItems) do
            BattleHumanWeaponSystem:OnHoldThrownWeapon(tbOwner, v:GetInstanceId())
            break
        end
        -- luacheck: pop
    end

end

return SAIActionHuman