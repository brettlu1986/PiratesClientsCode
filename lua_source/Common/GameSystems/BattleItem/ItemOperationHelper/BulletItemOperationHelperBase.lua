-----------------------------------------------------
--File Name    : BulletItemOperationHelperBase.lua
--Author       : zhiyuan
--Create Time  : 2018-09-11
--Description  : 弹药的物品操作helper基类
-----------------------------------------------------
local luaclass = require("luaclass")
local ItemCategoryOperationHelperBase = require("ItemCategoryOperationHelperBase")
local BulletItemOperationHelperBase = luaclass("BulletItemOperationHelperBase", ItemCategoryOperationHelperBase)

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemAutoPickUpHelper = require("BattleItemAutoPickUpHelper")

BulletItemOperationHelperBase.nMaxSlot = 1

local GamePlayerSelfHelper = nil

local function GetPlayerSelfOnClient()
    if GamePlayerSelfHelper == nil then
        GamePlayerSelfHelper = require("GamePlayerSelfHelper")
    end
    return GamePlayerSelfHelper
end

-- 获得可安装的槽位id，不可安装就是-1
local function GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nWeaponInstanceId, nItemTemplateId, bNeedEmptySlot, bIsClient)
    local nSlotIndex = 1
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, bIsClient)
    if self:GetBulletItemTemplateId(WeaponItem) ~= nItemTemplateId then
        log("Bullet type not valid!", self:GetBulletItemTemplateId(WeaponItem), nItemTemplateId)
        return -1
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = BattleItemSystemHelper:GetEquippedItem(nCharacterInstanceId,tbTemplate.nCategory, nWeaponInstanceId, nSlotIndex, bIsClient)
    if EquippedItem == nil then
        return nSlotIndex
    end
    if EquippedItem:GetStackCount() >= self:GetBulletMax(WeaponItem) then
        log("Bullet count is max!", nItemTemplateId, EquippedItem:GetStackCount(), self:GetBulletMax(WeaponItem), nCharacterInstanceId, nWeaponInstanceId)
        return -1
    end
    return nSlotIndex
end

local function HasWeaponMatch(self, nCharacterInstanceId, nItemTemplateId, bIsClient)
    local tbAllWeaponItems = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, self:GetOwnerCategory(), nCharacterInstanceId, bIsClient)
    for _, v in pairs(tbAllWeaponItems) do
        if self:GetBulletItemTemplateId(v) == nItemTemplateId then
            return true
        end
    end
    return false
end

local function GetAutoPickUpCount(nCharacterInstanceId, Item, bIsClient)
    local nItemTemplateId = Item:GetTemplateId()
    local nAutoPickupMax = BattleItemAutoPickUpHelper.GetAutoPickUpSettingValue(bIsClient, nItemTemplateId)
    local nItemCount = BattleItemSystemHelper:GetUnequippedItemCount(nCharacterInstanceId, nItemTemplateId, bIsClient)
    return math.max(0, nAutoPickupMax - nItemCount)
end

-- 获得Owner物品的大类型
-- need override
function BulletItemOperationHelperBase:GetOwnerCategory()
    return -1
end

-- 获取可装填的弹药类型
-- need override
function BulletItemOperationHelperBase:GetBulletItemTemplateId(WeaponItem)
    return -1
end

-- 获取可装填的弹药数量上限
-- need override
function BulletItemOperationHelperBase:GetBulletMax(WeaponItem)
    return -1
end

-- 是否可以手动拾取
function BulletItemOperationHelperBase:CanManuallyPickUpOnClient(Item)
    return true
end

-- 是否可以自动拾取
function BulletItemOperationHelperBase:CanAutoPickUpOnClient(Item)
    local bAutoPickUp = false
    local bIsBetter = false
    local nAvailableCount = nil
    local nItemTemplateId = Item:GetTemplateId()
    local nCharacterInstanceId = GetPlayerSelfOnClient():GetServerInstanceId()
    bIsBetter = HasWeaponMatch(self, nCharacterInstanceId, nItemTemplateId, true)

    if bIsBetter then
        local nAutoPickUpCount = GetAutoPickUpCount(nCharacterInstanceId, Item, true)
        bIsBetter = nAutoPickUpCount > 0
        if bIsBetter then
            nAvailableCount = BattleItemSystemHelper:GetAvailableAddCount(nCharacterInstanceId, Item:GetTemplateId(), nAutoPickUpCount, true)
            if nAvailableCount > 0 then
                bAutoPickUp = true
            end
        end
    end
    return bIsBetter, bAutoPickUp, nAvailableCount
end

-- 检查物品和槽位是否兼容
function BulletItemOperationHelperBase:CheckItemSlotCompatibility(nCharacterInstanceId, nWeaponInstanceId, nSlotIndex, Item, bIsClient)
    local WeaponItem = BattleItemSystemHelper:GetItem(nWeaponInstanceId, bIsClient)

    if self:GetBulletItemTemplateId(WeaponItem) == Item:GetTemplateId()
        and self:GetBulletMax(WeaponItem) >= Item:GetStackCount() then
        return true
    end
    return false
end

-- 获得在装备槽位上剩余还可以安装的叠加数量
function BulletItemOperationHelperBase:GetRemainStackCountOnEquipmentSlot(nCharacterInstanceId, nWeaponInstanceId, nSlotIndex, nItemTemplateId)
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local WeaponItem = BattleItemSystemServer:GetItem(nWeaponInstanceId)
    if self:GetBulletItemTemplateId(WeaponItem) ~= nItemTemplateId then
        return 0
    end
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local EquippedItem = BattleItemSystemServer:GetEquippedItem(nCharacterInstanceId, tbTemplate.nCategory, nWeaponInstanceId, nSlotIndex)
    if EquippedItem == nil then
        return self:GetBulletMax(WeaponItem)
    end
    return self:GetBulletMax(WeaponItem) - EquippedItem:GetStackCount()
end

-- 获得装配的位置(客户端方法)
function BulletItemOperationHelperBase:GetAvailableEquipmentSlotForItemOnClient(nItemTemplateId, bNeedEmptySlot)
    return -1,-1
end

-- 获得装配的位置id(客户端方法)
function BulletItemOperationHelperBase:GetAvailableEquipmentSlotForItemWithOwnerOnClient(nWeaponInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nCharacterInstanceId = GetPlayerSelfOnClient():GetServerInstanceId()
    return GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nWeaponInstanceId, nItemTemplateId, bNeedEmptySlot, true)
end

-- 是否可以自动拾取（服务端方法，给机器人AI使用）
function BulletItemOperationHelperBase:CanAutoPickUpOnServer(nCharacterInstanceId, Item)
    local nItemTemplateId = Item:GetTemplateId()
    local bIsBetter = HasWeaponMatch(self, nCharacterInstanceId, nItemTemplateId, false)
    if bIsBetter then
        local nAutoPickUpCount =  GetAutoPickUpCount(nCharacterInstanceId, Item, false)
        if nAutoPickUpCount > 0 then
            local nAvailableCount = BattleItemSystemHelper:GetAvailableAddCount(nCharacterInstanceId, Item:GetTemplateId(), nAutoPickUpCount, false)
            if nAvailableCount > 0 then
                return true
            end
        else
            return false
        end
    end
    return false
end

-- 不能不指定给那个武器安装弹药，所以返回-1，-1（服务端方法）
function BulletItemOperationHelperBase:GetAvailableEquipmentSlotForItemOnServer(nCharacterInstanceId, nItemTemplateId, bNeedEmptySlot)
    local nOwnerCategory = self:GetOwnerCategory()
    local BattleItemSystemServer = BattleItemSystemHelper:GetBattleItemSystemServer()
    local tbEquippedWeapons = BattleItemSystemServer:GetEquippedItems(nCharacterInstanceId, nOwnerCategory, nCharacterInstanceId)
    for _, v in pairs(tbEquippedWeapons) do
        local nOwnerInstanceId = v:GetInstanceId()
        local nSlot = self:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nOwnerInstanceId, nItemTemplateId, bNeedEmptySlot)
        if nSlot > 0 then
            return nOwnerInstanceId, nSlot
        end
    end

    return -1,-1
end

-- 获得可安装的槽位id，不可安装就是-1
function BulletItemOperationHelperBase:GetAvailableEquipmentSlotForItemWithOwnerOnServer(nCharacterInstanceId, nWeaponInstanceId, nItemTemplateId, bNeedEmptySlot)
    return GetAvailableEquipmentSlotForItemWithOwner(self, nCharacterInstanceId, nWeaponInstanceId, nItemTemplateId, bNeedEmptySlot, false)
end

return BulletItemOperationHelperBase