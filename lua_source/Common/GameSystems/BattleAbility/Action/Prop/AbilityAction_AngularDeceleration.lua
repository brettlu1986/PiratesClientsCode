-----------------------------------------------------
--File Name    : AbilityAction_AngularDeceleration.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-23
--Description  : 船只转向减速度属性修改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_AngularDeceleration = luaclass("AbilityAction_AngularDeceleration", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_AngularDeceleration:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_AngularDeceleration:GetWrapperName()
    return PropName.nAngularDecelerationAddition
end

return AbilityAction_AngularDeceleration
