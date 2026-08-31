-----------------------------------------------------
--File Name    : AbilityAction_HumanMinHpRatio.lua
--Author       : Song Fuhao
--Create Time  : 2019-06-12
--Description  : 配置人最小Hp比例
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_HumanMinHpRatio = luaclass("AbilityAction_HumanMinHpRatio", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")
local PropUtil = require("PropUtil")

function AbilityAction_HumanMinHpRatio:GetWrapperName()
    return PropName.nHumanMinHpRatio
end

function AbilityAction_HumanMinHpRatio:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_HumanMinHpRatio:GetTargetType()
    return PropUtil.TARGET_TYPE.HUMAN
end

return AbilityAction_HumanMinHpRatio
