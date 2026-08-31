-----------------------------------------------------
--File Name    : HumanWeaponSlotDef.lua
--Author       : WuJizhou
--Create Time  : 9/4/2018, 3:49:49 PM
--Description  : HumanWeaponSlotDef
-----------------------------------------------------
local HumanWeaponDef        = require("HumanWeaponDef")
local GlobalVariableSystem  = dynamic_require("GlobalVariableSystem")

local HumanWeaponSlotDef = {}

if GlobalVariableSystem.bUseNewBattleItem then
    HumanWeaponSlotDef.Slots =
    {
        HumanWeaponDef.WeaponSlotCategory.All,
        HumanWeaponDef.WeaponSlotCategory.All
    }
else
    HumanWeaponSlotDef.Slots =
    {
        HumanWeaponDef.WeaponSlotCategory.Ranged,
        HumanWeaponDef.WeaponSlotCategory.Ranged,
        HumanWeaponDef.WeaponSlotCategory.Melee
    }
end

function HumanWeaponSlotDef:SlotCount()
    return #self.Slots
end


return HumanWeaponSlotDef