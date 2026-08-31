-----------------------------------------------------
--File Name    : AbilityAction_AngularAcceleration.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-23
--Description  : 船只转向加速度属性修改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_AngularAcceleration = luaclass("AbilityAction_AngularAcceleration", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_AngularAcceleration:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_AngularAcceleration:GetWrapperName()
    return PropName.nAngularAccelerationAddition
end

return AbilityAction_AngularAcceleration
