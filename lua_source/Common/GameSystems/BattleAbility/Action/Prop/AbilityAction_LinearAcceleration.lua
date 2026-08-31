-----------------------------------------------------
--File Name    : AbilityAction_LinearAcceleration.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-26
--Description  : 船只加速度属性修改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_LinearAcceleration = luaclass("AbilityAction_LinearAcceleration", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_LinearAcceleration:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_LinearAcceleration:GetWrapperName()
    return PropName.nLinearAccelerationAddition
end

return AbilityAction_LinearAcceleration
