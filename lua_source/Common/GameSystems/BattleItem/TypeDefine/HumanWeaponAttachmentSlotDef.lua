-----------------------------------------------------
--File Name    : HumanWeaponAttachmentSlotDef.lua
--Author       : WuJizhou
--Create Time  : 9/4/2018, 3:49:49 PM
--Description  : HumanWeaponAttachmentSlotDef
-----------------------------------------------------
local HumanWeaponAttachmentDef = require("HumanWeaponAttachmentDef")

local HumanWeaponAttachmentSlotDef = {}

HumanWeaponAttachmentSlotDef.Slots = {
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Muzzle, 
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.HandGuard, 
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Sight,
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Stock,
    HumanWeaponAttachmentDef.WeaponAttachmentCategory.Magazine
}

function HumanWeaponAttachmentSlotDef:SlotCount()
    return #self.Slots
end

function HumanWeaponAttachmentSlotDef:GetSlotIndex(nAttachmentCategory)
    for i, v in ipairs(self.Slots) do
        if nAttachmentCategory == v then
            return i
        end
    end
    return -1
end


return HumanWeaponAttachmentSlotDef