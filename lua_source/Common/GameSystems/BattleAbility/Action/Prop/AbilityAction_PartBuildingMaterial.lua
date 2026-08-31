-----------------------------------------------------
--File Name    : AbilityAction_PartBuildingMaterial.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-10
--Description  : 舰船零件建造时节省一定比例的材料
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_PartBuildingMaterial = luaclass("AbilityAction_PartBuildingMaterial", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_PartBuildingMaterial:GetWrapperName()
    return PropName.nPartBuildingMaterialRatio
end

function AbilityAction_PartBuildingMaterial:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

return AbilityAction_PartBuildingMaterial
