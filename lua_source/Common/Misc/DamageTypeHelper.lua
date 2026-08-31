-----------------------------------------------------
--File Name    : DamageTypeHelper.lua
--Author       : WuJizhou
--Create Time  : 10/29/2018, 4:50:48 PM
--Description  : DamageTypeHelper
-----------------------------------------------------
local DamageTypeHelper = {}
local HumanWeaponDef = require("HumanWeaponDef")
local DamageTypeEx = require("DamageTypeEx")
local WeaponDamageType = HumanWeaponDef.WeaponDamageType
-- 如果nWeaponCategory不合法，返回nil
function DamageTypeHelper.GetHumanWeaponDamageType(nWeaponCategory)
    local WeaponCategory = HumanWeaponDef.WeaponCategory
    local nDamageType = nil
    if nWeaponCategory == WeaponCategory.Pistol then
        nDamageType = DamageTypeEx.HUMAN_PISTOL
    elseif nWeaponCategory == WeaponCategory.Flintlock then
        nDamageType = DamageTypeEx.HUMAN_FLINTLOCK
    elseif nWeaponCategory == WeaponCategory.Matchlock then
        nDamageType = DamageTypeEx.HUMAN_MATCHLOCK
    elseif nWeaponCategory == WeaponCategory.Crossbow then
        nDamageType = DamageTypeEx.HUMAN_CROSSBOW
    elseif nWeaponCategory == WeaponCategory.Bow then
        nDamageType = DamageTypeEx.HUMAN_BOW
    elseif nWeaponCategory == WeaponCategory.Melee then
        nDamageType = DamageTypeEx.HUMAN_MELEE
    elseif nWeaponCategory == WeaponCategory.TwoHand then
        nDamageType = DamageTypeEx.HUMAN_MELEE        
    elseif nWeaponCategory == WeaponCategory.ThrowWeapon then
        nDamageType = DamageTypeEx.HUMAN_FLYINGKNIFE          
    elseif nWeaponCategory == WeaponCategory.Wand then
        nDamageType = DamageTypeEx.HUMAN_MAGIC                       
    else
        logerror("DamageTypeHelper.GetHumanWeaponDamageType, weapon category illegal, value : ", nWeaponCategory)
    end
    return nDamageType
end

function DamageTypeHelper.GetHumanWeaponCalcDamageType(nWeaponCategory)
    local WeaponCategory = HumanWeaponDef.WeaponCategory
    local nDamageType = nil

    if nWeaponCategory == WeaponCategory.Melee 
     or nWeaponCategory == WeaponCategory.TwoHand then
        nDamageType = WeaponDamageType.Melee
    elseif nWeaponCategory == WeaponCategory.Wand then
        nDamageType = WeaponDamageType.Magic        
    else
        nDamageType = WeaponDamageType.Bullet 
    end
    return nDamageType    
end

return DamageTypeHelper