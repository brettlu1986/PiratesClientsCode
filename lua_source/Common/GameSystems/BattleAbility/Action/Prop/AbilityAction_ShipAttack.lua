-----------------------------------------------------
--File Name    : AbilityAction_ShipAttack.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-17
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ShipAttack = luaclass("AbilityAction_ShipAttack", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_ShipAttack:GetWrapperName()
    return PropName.nShipAttack
end

function AbilityAction_ShipAttack:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

return AbilityAction_ShipAttack
