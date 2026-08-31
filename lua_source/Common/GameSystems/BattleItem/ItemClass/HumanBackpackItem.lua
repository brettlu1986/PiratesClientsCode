-----------------------------------------------------
--File Name    : HumanBackpackItem.lua
--Author       : zhiyuan
--Create Time  : 2018-09-13
--Description  : 人的背包物品
-----------------------------------------------------
local luaclass = require("luaclass")
local EquipmentItemBase = require("EquipmentItemBase")
local HumanBackpackItem = luaclass("HumanBackpackItem", EquipmentItemBase)

local function RefreshAvatarRes(tbPlayer, nItem, bEquiped)

end


function HumanBackpackItem:OnCreate()
end

function HumanBackpackItem:OnDestroy()
end

-- 背包不可以卸下
function HumanBackpackItem:CanUnequip()
    return false
end

function HumanBackpackItem:OnEquipOnServer()
    RefreshAvatarRes(self:GetOwnerCharacter(), self, true)
end

function HumanBackpackItem:OnUnequipOnServer()
    RefreshAvatarRes(self:GetOwnerCharacter(), self, false)
end

function HumanBackpackItem:OnEquipOnClient()
end

function HumanBackpackItem:OnUnequipOnClient()
end

return HumanBackpackItem