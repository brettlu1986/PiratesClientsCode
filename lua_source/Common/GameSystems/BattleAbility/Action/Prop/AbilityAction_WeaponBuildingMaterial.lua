-----------------------------------------------------
--File Name    : AbilityAction_WeaponBuildingMaterial.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-10
--Description  : 舰船武器建造时节省一定比例的材料
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_WeaponBuildingMaterial = luaclass("AbilityAction_WeaponBuildingMaterial", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_WeaponBuildingMaterial:GetWrapperName()
    return PropName.nWeaponBuildingMaterialRatio
end

function AbilityAction_WeaponBuildingMaterial:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

return AbilityAction_WeaponBuildingMaterial
