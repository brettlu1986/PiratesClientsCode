-----------------------------------------------------
--File Name    : ShipBulletItem.lua
--Author       : zhiyuan
--Create Time  : 2018-09-11
--Description  : 船的弹药物品
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local ShipBulletItem = luaclass("ShipBulletItem", EquipmentItemBase)

function ShipBulletItem:OnCreate()
end

function ShipBulletItem:OnDestroy()
end

function ShipBulletItem:OnEquipOnServer()

end

function ShipBulletItem:OnUnequipOnServer()
end

function ShipBulletItem:OnEquipOnClient()
end

function ShipBulletItem:OnUnequipOnClient()
end

return ShipBulletItem