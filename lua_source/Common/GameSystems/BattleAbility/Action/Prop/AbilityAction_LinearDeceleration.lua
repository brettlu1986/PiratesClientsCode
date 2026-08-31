-----------------------------------------------------
--File Name    : AbilityAction_LinearDeceleration.lua
--Author       : Song Fuhao
--Create Time  : 2017-12-29
--Description  : 船只减速度属性修改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_LinearDeceleration = luaclass("AbilityAction_LinearDeceleration", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_LinearDeceleration:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_LinearDeceleration:GetWrapperName()
    return PropName.nLinearDecelerationAddition
end

return AbilityAction_LinearDeceleration
