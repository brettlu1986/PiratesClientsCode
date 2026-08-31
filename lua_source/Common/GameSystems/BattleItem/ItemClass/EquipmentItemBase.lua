-----------------------------------------------------
--File Name    : EquipmentItemBase.lua
--Author       : zhiyuan
--Create Time  : 2018-09-07
--Description  : 可装备的物品基类
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemBase = require("BattleItemBase")
local EquipmentItemBase = luaclass("EquipmentItemBase", BattleItemBase)

EquipmentItemBase.bPendingUnequip = false

-----------------------------------------给外部的接口，不要override-------------------------------------------
function EquipmentItemBase:OnUnequip(bIsClient)
    if self:IsPendingUnequip() then
        return
    end
    if bIsClient then
        self:OnUnequipOnClient()
    else
        self:OnUnequipOnServer()
    end
    self.bPendingUnequip = true
end

function EquipmentItemBase:OnEquip(bIsClient)
    if bIsClient then
        self:OnEquipOnClient()
    else
        self:OnEquipOnServer()
    end
    self.bPendingUnequip = false
end

function EquipmentItemBase:IsPendingUnequip()
    return self.bPendingUnequip
end

--------------------------------------------根据需求override------------------------------------------
-- 是否可以卸下，默认都可以卸下，不可卸下的需要override这个方法
function EquipmentItemBase:CanUnequip()
    return true
end

-----------------------------------------需要子类override的方法----------------------------------------
-- need override
function EquipmentItemBase:OnEquipOnServer()
end

-- need override
function EquipmentItemBase:OnEquipOnClient()
end

-- need override
function EquipmentItemBase:OnUnequipOnServer()
end

-- need override
function EquipmentItemBase:OnUnequipOnClient()
end

return EquipmentItemBase