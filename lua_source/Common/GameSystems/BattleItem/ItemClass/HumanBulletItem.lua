-----------------------------------------------------
--File Name    : HumanBulletItem.lua
--Author       : zhiyuan
--Create Time  : 2018-09-11
--Description  : 人的弹药物品
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local HumanBulletItem = luaclass("HumanBulletItem", EquipmentItemBase)

function HumanBulletItem:OnCreate()
end

function HumanBulletItem:OnDestroy()
end

function HumanBulletItem:OnEquipOnServer()

end

function HumanBulletItem:OnUnequipOnServer()
end

function HumanBulletItem:OnEquipOnClient()
end

function HumanBulletItem:OnUnequipOnClient()
end

return HumanBulletItem