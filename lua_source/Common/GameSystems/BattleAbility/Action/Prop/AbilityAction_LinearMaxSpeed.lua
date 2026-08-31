-----------------------------------------------------
--File Name    : AbilityAction_LinearMaxSpeed.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-23
--Description  : 船只最大速度属性修改
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_LinearMaxSpeed = luaclass("AbilityAction_LinearMaxSpeed", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")
local PropUtil = require("PropUtil")

function AbilityAction_LinearMaxSpeed:GetOverlapType()
    return PropertyWrapperType.TYPE_MULTIPLY
end

function AbilityAction_LinearMaxSpeed:GetWrapperName()
    return PropName.nLinearMaxSpeedAddition
end

function AbilityAction_LinearMaxSpeed:GetTargetType()
    return PropUtil.TARGET_TYPE.SHIP
end

return AbilityAction_LinearMaxSpeed
