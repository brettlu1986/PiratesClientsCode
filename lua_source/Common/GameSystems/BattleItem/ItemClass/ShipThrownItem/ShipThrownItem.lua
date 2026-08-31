-----------------------------------------------------
--File Name    : ShipThrownItem.lua
--Author       : Song Fuhao
--Create Time  : 2020-02-20
--Description  : 船投掷物基类（原臼炮、陷阱）
--               由于投掷物可以堆叠，所以投掷物实例里不计
--               战斗状态相关变量，仅封装逻辑使用，这样调
--               用任意一个实例的接口，逻辑都可以正常执行
-----------------------------------------------------
local luaclass = require("luaclass")
local ShipWeaponItemBase = require("ShipWeaponItemBase")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleShipWeaponEventHelper = require("BattleShipWeaponEventHelper")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ShipFiringOperationDef = require("ShipFiringOperationDef")
local ShipWeaponFiringFailedDef = require("ShipWeaponFiringFailedDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local TeamWatchServerHelper = dynamic_require("TeamWatchServerHelper")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

--- @class ShipThrownItem : ShipWeaponItemBase
local ShipThrownItem = luaclass("ShipThrownItem", ShipWeaponItemBase)

local ONCE_DECREASE_ITEM_COUNT = 1

ShipThrownItem.bIsInRemovingFromPlayer = false

local function LOG(self, ...)
    local OwnerCharacter = self:GetOwnerCharacter()
    local szOwnerName = OwnerCharacter and OwnerCharacter.szName
    log("[BattleShipWeapon][ThrownItem]", szOwnerName, self:GetInstanceId(), ...)
end

local function IsBulletEnough(self)
    local nItemCount = BattleItemSystemHelper:GetUnequippedItemCount(self:GetOwnerCharacterInstanceId(),
                                                                     self:GetTemplateId(),
                                                                     not self:IsServerInstance())
    return nItemCount > 0
end

--- 获取下一个可用的投掷物TemplateId
local function GetNextThrownItemTemplateId(self)
    local nCurrentTemplateId = self:GetTemplateId()
    local nNextThrownItemTemplateId = nil
    local tbItems = BattleItemSystemHelper:GetUnequippedItemsByCategory(self:GetOwnerCharacterInstanceId(), BattleItemCategoryDef.SHIP_THROWN_ITEM, false)
    for _, Item in ipairs(tbItems) do
        if Item ~= self then
            local nTemplateId = Item:GetTemplateId()
            if nTemplateId == nCurrentTemplateId then
                return nTemplateId
            else
                if nNextThrownItemTemplateId then
                    nNextThrownItemTemplateId = math.min(nTemplateId, nNextThrownItemTemplateId)
                else
                    nNextThrownItemTemplateId = nTemplateId
                end
            end
        end
    end
    return nNextThrownItemTemplateId
end

function ShipThrownItem:SetOwnerCharacter(tbOwnerCharacter)
    ShipThrownItem.super.SetOwnerCharacter(self, tbOwnerCharacter)
    LOG(self, "SetOwnerCharacter", tbOwnerCharacter)
end

function ShipThrownItem:ActivateWeapon()
    ShipThrownItem.super.ActivateWeapon(self)
    if (self:IsServerInstance() or (not GlobalVariableSystem:IsStandalone())) then
        self:GetBPComponent():SetWeaponId(self:GetTemplateId())
    end
end

function ShipThrownItem:PreRemoveFromPlayer(bRemoveAll)
    self.bIsInRemovingFromPlayer = true
    if self:IsServerInstance() and (not bRemoveAll) then
        local tbCharacter = self:GetOwnerCharacter()
        local EquippedWeaponItem = BattleShipWeaponSystem:GetEquippedWeaponItem(tbCharacter, ShipWeaponSlotDef.THROW)
        if EquippedWeaponItem == self then
            BattleShipWeaponSystem:EquipThrownItem(tbCharacter, GetNextThrownItemTemplateId(self))
        end
    end
    self.bIsInRemovingFromPlayer = false
end

function ShipThrownItem:Equip()
    BattleShipWeaponEventHelper.FireOnShipWeaponEquippedEvent(self)
end

function ShipThrownItem:Unequip()
    BattleShipWeaponEventHelper.FireOnShipWeaponUnequippedEvent(self)
end

function ShipThrownItem:GetWeaponSlot()
    return ShipWeaponSlotDef.THROW
end

function ShipThrownItem:IsReadyToFire(nFiringOperation)
    local bResult, nFailedReason = ShipThrownItem.super.IsReadyToFire(self, nFiringOperation)
    if not bResult then
        return bResult, nFailedReason
    end
    if (nFiringOperation == ShipFiringOperationDef.START) or (nFiringOperation == ShipFiringOperationDef.END) then
        if not IsBulletEnough(self) then
            LOG(self, "StartFiring failed, reason : item is not enough.")
            return false, ShipWeaponFiringFailedDef.BULLET_EMPTY
        end
    end
    return true
end

function ShipThrownItem:EndFiring(...)
    LOG(self, "EndFiring")
    self:OnEndFiring(...)
    BattleShipWeaponEventHelper.FireOnShipWeaponFiredEvent(self, ONCE_DECREASE_ITEM_COUNT)
    BattleShipWeaponEventHelper.FireOnShipWeaponFiringSuccessEvent(self)
end

function ShipThrownItem:DecreaseBullet()
    LOG(self, "DecreaseItemCount")
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    BattleItemSystemServer:DecreaseItemCount(self:GetInstanceId(), ONCE_DECREASE_ITEM_COUNT)
    TeamWatchServerHelper.SendShipAmmoInfoToViewers(self:GetOwnerCharacter(), self, true, false, self:GetWeaponSlot())
end

function ShipThrownItem:IsInRemovingFromPlayer()
    return self.bIsInRemovingFromPlayer
end

return ShipThrownItem