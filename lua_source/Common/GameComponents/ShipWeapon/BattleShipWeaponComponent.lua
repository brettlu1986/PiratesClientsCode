-----------------------------------------------------
--File Name    : BattleShipWeaponComponent.lua
--Author       : Song Fuhao
--Create Time  : 2020-07-22
--Description  : 新版舰船武器数据Component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")

--- @class BattleShipWeaponComponent
local BattleShipWeaponComponent = luaclass("BattleShipWeaponComponent", GameComponentBase)

BattleShipWeaponComponent.ActiveWeaponItem = nil
BattleShipWeaponComponent.EquippedThrownItem = nil
BattleShipWeaponComponent.bIsInAim = false
BattleShipWeaponComponent.nActiveSlotCache = ShipWeaponSlotDef.UNKNOWN

--- 输出日志
--- @vararg string
local function LOG(self, ...)
    log("[BattleShipWeapon][Component]", self.Owner.szName, ...)
end

-- 会验证以下条件
-- * 武器实例是否有值
-- * 武器持有者是否为船状态
-- * 武器持有者当前UEActor是否有值
local function IsValidWeapon(WeaponItem)
    return WeaponItem and WeaponItem:GetOwnerShipUEActor()
end

-- 发送舰船武器信息给观战者
local function SendShipWeaponInfoToViewers(self, OldActiveWeaponItem, NewActiveWeaponItem)
    if GlobalVariableSystem:IsDedicatedClient() then
        return
    end
    local nOldSlot = OldActiveWeaponItem and OldActiveWeaponItem:GetWeaponSlot()
    local nNewSlot = NewActiveWeaponItem and NewActiveWeaponItem:GetWeaponSlot()
    TeamWatchServerHelper.SendShipAmmoInfoToViewers(self.Owner, NewActiveWeaponItem, false, nOldSlot ~= nNewSlot, nNewSlot)
end

function BattleShipWeaponComponent:OnActorCreated(...)
    BattleShipWeaponComponent.super.OnActorCreated(self, ...)
    if IsValidWeapon(self.ActiveWeaponItem) then
        self.ActiveWeaponItem:ActivateWeapon()
    end
end

function BattleShipWeaponComponent:OnActorDestroyed(...)
    if IsValidWeapon(self.ActiveWeaponItem) then
        self.ActiveWeaponItem:DeactivateWeapon(true)
    end
    BattleShipWeaponComponent.super.OnActorDestroyed(self, ...)
end

--- 获取装备的投掷物武器实例
--- @return ShipThrownItem
function BattleShipWeaponComponent:GetEquippedThrownItem()
    return self.EquippedThrownItem
end

--- 获取当前激活的武器实例
--- @return ShipWeaponItemBase
function BattleShipWeaponComponent:GetActiveWeaponItem()
    return self.ActiveWeaponItem
end

--- 获取当前是否处于开镜瞄准状态
--- @return boolean
function BattleShipWeaponComponent:GetIsInAim()
    return self.bIsInAim
end

--- 弹出激活槽位缓存，用于装备替换后的激活恢复，获取一次自动质控
--- @return number
function BattleShipWeaponComponent:PopActiveSlotChache()
    local nActiveSlotCache = self.nActiveSlotCache
    self.nActiveSlotCache = ShipWeaponSlotDef.UNKNOWN
    return nActiveSlotCache
end

--- 设置激活的武器实例
--- @param NewActiveWeaponItem ShipWeaponItemBase 新激活的武器实例，传空时激活默认武器
--- @return boolean
function BattleShipWeaponComponent:SetActiveWeaponItem(NewActiveWeaponItem, bCacheLastSlot)
    local OldActiveWeaponItem = self:GetActiveWeaponItem()
    if OldActiveWeaponItem == NewActiveWeaponItem then
        return false
    end
    LOG(self, "SetActiveWeaponItem OldInstanceId, NewInstanceId =", OldActiveWeaponItem and OldActiveWeaponItem:GetInstanceId(), NewActiveWeaponItem and NewActiveWeaponItem:GetInstanceId())
    if IsValidWeapon(OldActiveWeaponItem) then
        if bCacheLastSlot then
            self.nActiveSlotCache = OldActiveWeaponItem:GetWeaponSlot()
        end
        OldActiveWeaponItem:DeactivateWeapon()
    end
    self.ActiveWeaponItem = NewActiveWeaponItem
    if IsValidWeapon(NewActiveWeaponItem) then
        NewActiveWeaponItem:ActivateWeapon()
    end
    EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_ACTIVE_WEAPON_ITEM_CHANGED, self.Owner, NewActiveWeaponItem, OldActiveWeaponItem)

    SendShipWeaponInfoToViewers(self, OldActiveWeaponItem, NewActiveWeaponItem)
    return true
end

--- 设置装备的投掷物实例
--- @param NewEquippedThrownItem ShipThrownItem 新装备的武器实例
--- @return boolean
function BattleShipWeaponComponent:SetEquippedThrownItem(NewEquippedThrownItem)
    local OldEquippedThrownItem = self:GetEquippedThrownItem()
    if NewEquippedThrownItem == OldEquippedThrownItem then
        return false
    end
    LOG(self, "SetEquippedThrownItemInstanceId OldInstanceId, NewInstanceId =", OldEquippedThrownItem and OldEquippedThrownItem:GetInstanceId(), NewEquippedThrownItem and NewEquippedThrownItem:GetInstanceId())
    if OldEquippedThrownItem then
        OldEquippedThrownItem:Unequip()
    end
    self.EquippedThrownItem = NewEquippedThrownItem
    if NewEquippedThrownItem then
        NewEquippedThrownItem:Equip()
    end
    return true
end

--- 设置当前是开镜瞄准状态
--- @param bIsInAim boolean 新的开镜瞄准状态
--- @return boolean
function BattleShipWeaponComponent:SetIsInAim(bIsInAim)
    if bIsInAim == self.bIsInAim then
        return false
    end
    LOG(self, "SetIsInAim", bIsInAim)
    self.bIsInAim = bIsInAim
    EventManager:OnFireEvent(CommonEventDef.EV_ON_SHIP_AIM_STATE_CHANGED, self.Owner, bIsInAim)
    return true
end

return BattleShipWeaponComponent