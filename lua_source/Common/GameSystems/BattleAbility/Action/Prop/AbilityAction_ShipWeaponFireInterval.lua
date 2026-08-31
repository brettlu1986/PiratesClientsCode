-----------------------------------------------------
--File Name    : AbilityAction_ShipWeaponFireInterval.lua
--Author       : Song Fuhao
--Create Time  : 2018-11-28
--Description  : 调整开火间隔
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ShipWeaponFireInterval = luaclass("AbilityAction_ShipWeaponFireInterval", AbilityActionPropBase)

function AbilityAction_ShipWeaponFireInterval:GetWrapperName()
    return require("PropName").nFiringIntervalRatio
end

return AbilityAction_ShipWeaponFireInterval
