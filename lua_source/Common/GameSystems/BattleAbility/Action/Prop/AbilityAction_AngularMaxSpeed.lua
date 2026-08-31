-----------------------------------------------------
--File Name    : AbilityAction_AngularMaxSpeed.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-23
--Description  : 船只转向最大速度属性修改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_AngularMaxSpeed = luaclass("AbilityAction_AngularMaxSpeed", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_AngularMaxSpeed:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_AngularMaxSpeed:GetWrapperName()
    return PropName.nAngularMaxSpeedAddition
end


return AbilityAction_AngularMaxSpeed
