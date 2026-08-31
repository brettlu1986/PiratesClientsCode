-----------------------------------------------------
--File Name    : ShipWeaponAttachmentItem.lua
--Author       : chenjing6
--Create Time  : 2018-08-03
--Description  : 武器配件插槽物件
-----------------------------------------------------

local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local ShipWeaponAttachmentItem = luaclass("ShipWeaponAttachmentItem", EquipmentItemBase)
local PropName = require("PropName")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

ShipWeaponAttachmentItem.tbCacheOverlapIds = nil
ShipWeaponAttachmentItem.bActive = false

local tbPropertyNames = {
    "nTelescopeScale",              --瞄准镜倍率
    "nCoreDetect",                  --核心区探测
    "nShipBulletDeviationRatio",    --不开镜时炮弹散布比例
    "nShipBulletAimDeviationRatio", --开镜时炮弹散布比例
    "nReloadSpeedRatio",            --加快装填速度
    "nFiringRotationRangeRatio",    --增加射界
    "nFireSoundReduction",          --消音比
    "nFiringIntervalRatio",         --武器开火间隔
    "nBulletTriggerRangeRatio",     --子弹触发范围
    "nBulletSpeedRatio",            --子弹速度
    "nPerfectFiringRangeBegin",     --最佳射击起始距离差值
    "nPerfectFiringRangeEnd",       --最佳设计距离结束差值
    "nWeaponDamageIntervalRatio",   --近战武器伤害间隔
    "nPowderKegFiringAngleRatio",   --爆桶发射夹角
}

local function LOG(self, ...)
    local OwnerCharacter = self:GetOwnerCharacter()
    local szOwnerName = OwnerCharacter and OwnerCharacter.szName
    log("[ShipWeaponAttachment]", szOwnerName, self:GetInstanceId(), ...)
end

--------------------------------------------------server--------------------------------------------
function ShipWeaponAttachmentItem:Active()
    if not self:IsServerInstance() then
        return
    end
    if self.tbCacheOverlapIds then
        return
    end
    self.tbCacheOverlapIds = { }
    local ShipBattlePropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    for _,v in ipairs(tbPropertyNames) do
        local nPropertyValue = self.tbTemplate[v]
        if nPropertyValue then
            local nOverlapId = ShipBattlePropertyComponent:PropOverlap_Add(PropName[v], nPropertyValue)
            LOG(self, "add ship part property", nOverlapId, v, " :", nPropertyValue)
            table.insert(self.tbCacheOverlapIds, { Name = v, Id = nOverlapId })
        end
    end
end

function ShipWeaponAttachmentItem:Deactive()
    if not self:IsServerInstance() then
        return
    end
    if not self.tbCacheOverlapIds then
        return
    end
    local ShipBattlePropertyComponent = self:GetOwnerCharacter().ShipBattlePropertyComponent
    for _,v in ipairs(self.tbCacheOverlapIds) do
        LOG(self, "remove ship part property", v.Id, v.Name)
        ShipBattlePropertyComponent:RemovePropOverlap(PropName[v.Name], v.Id)
    end
    self.tbCacheOverlapIds = nil
end

local function OnEquip(self, bIsClient)
    local tbOwnerGameObject = self:GetOwnerCharacter()
    if self:IsServerInstance() and tbOwnerGameObject then
        local tbStorageLocation = self:GetStorageLocation()
        local nActiveWeaponSlot = BattleShipWeaponSystem:GetActiveWeaponSlot(tbOwnerGameObject)
        local nWeaponSlotIndex = BattleItemSystemHelper:GetEquippedSlotIndex(tbStorageLocation.nOwnerInstanceId, bIsClient)
        if nWeaponSlotIndex and nWeaponSlotIndex > 0 and nWeaponSlotIndex == nActiveWeaponSlot then
            LOG(self, "Active on equip")
            self:Active()
        end
    end
end

local function OnUnequip(self, bIsClient)
    local tbOwnerGameObject = self:GetOwnerCharacter()
    if self:IsServerInstance() and tbOwnerGameObject then
        LOG(self, "Deactive on unequip")
        self:Deactive()
    end
end


function ShipWeaponAttachmentItem:CompatibleWithCurrentWeapons(bIsClient)
    local nServerInstanceId = self.tbOwnerCharacter.nServerInstanceId
    for i=ShipWeaponSlotDef.COMMON_START, ShipWeaponSlotDef.COMMON_END do
        local tbWeapon = BattleItemSystemHelper:GetEquippedItem(nServerInstanceId, BattleItemCategoryDef.SHIP_WEAPON,
        nServerInstanceId, i, bIsClient)
        if tbWeapon then
            if BattleItemSystemHelper:CheckItemSlotCompatibility(nServerInstanceId, tbWeapon.nInstanceId ,
            self.tbTemplate.nSubCategory, self, bIsClient) then
                return true
            end
        end
    end
    return false
end


function ShipWeaponAttachmentItem:OnEquipOnServer()
    OnEquip(self, false)
    EventManager:OnFireEvent(CommonEventDef.EV_SHIP_WEAPON_ATTACHMENT_ON_EQUIPED_SERVER, self:GetOwnerCharacterInstanceId(), self)
end


function ShipWeaponAttachmentItem:OnUnequipOnServer()
    OnUnequip(self, false)
    EventManager:OnFireEvent(CommonEventDef.EV_SHIP_WEAPON_ATTACHMENT_ON_UNEQUIPED_SERVER, self:GetOwnerCharacterInstanceId(), self)
end

--------------------------------------------------client--------------------------------------------
function ShipWeaponAttachmentItem:OnEquipOnClient()
    OnEquip(self, true)
end


function ShipWeaponAttachmentItem:OnUnequipOnClient()
    OnUnequip(self, true)
end

return ShipWeaponAttachmentItem