-----------------------------------------------------
--File Name    : AbilityAction_ShipMinHpRatio.lua
--Author       : Song Fuhao
--Create Time  : 2019-06-12
--Description  : 配置船最小Hp比例
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ShipMinHpRatio = luaclass("AbilityAction_ShipMinHpRatio", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")
local PropUtil = require("PropUtil")

function AbilityAction_ShipMinHpRatio:GetWrapperName()
    return PropName.nShipMinHpRatio
end

function AbilityAction_ShipMinHpRatio:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_ShipMinHpRatio:GetTargetType()
    return PropUtil.TARGET_TYPE.SHIP
end

return AbilityAction_ShipMinHpRatio
