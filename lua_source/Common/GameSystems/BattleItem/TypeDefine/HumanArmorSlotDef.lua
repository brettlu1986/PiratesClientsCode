-----------------------------------------------------
--File Name    : HumanArmorSlotDef.lua
--Author       : WuJizhou
--Create Time  : 8/29/2018, 2:49:31 PM
--Description  : HumanArmorSlotDef
-----------------------------------------------------
local HumanArmorSlotDef = {}

local HumanArmorDef = require("HumanArmorDef")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

if GlobalVariableSystem.bUseNewBattleItem then
    HumanArmorSlotDef.ArmorSlots = {
        HumanArmorDef.ArmorCategory.All,
    }

else
    HumanArmorSlotDef.ArmorSlots = {
        HumanArmorDef.ArmorCategory.Head,
        HumanArmorDef.ArmorCategory.Body,
    }
end

function HumanArmorSlotDef:SlotCount()
    return #self.ArmorSlots
end


HumanArmorSlotDef.MaxCount = HumanArmorSlotDef:SlotCount()

return HumanArmorSlotDef