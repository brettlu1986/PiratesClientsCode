-----------------------------------------------------
--File Name    : AbilityAction_MakeDiamondVisibleOnMap.lua
--Author       : ZhangWei
--Create Time  : 2020-6-16
--Description  : 在雷达地图上显示最近的宝石
-----------------------------------------------------
local PropName      = require("PropName")
local PropUtil      = require("PropUtil")

local luaclass = require("luaclass")
local PropertyWrapperType = require("PropertyWrapperType")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_MakeDiamondVisibleOnMap = luaclass("AbilityAction_MakeDiamondVisibleOnMap", AbilityActionPropBase)


function AbilityAction_MakeDiamondVisibleOnMap:GetWrapperName()
    return PropName.bCanSeeDiamondOnMap
end

function AbilityAction_MakeDiamondVisibleOnMap:GetTargetType()
    return PropUtil.TARGET_TYPE.HUMAN
end

function AbilityAction_MakeDiamondVisibleOnMap:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_MakeDiamondVisibleOnMap:GetValue(tbCharacter)
    return true
end

function AbilityAction_MakeDiamondVisibleOnMap:OnDo(tbParams)
    AbilityAction_MakeDiamondVisibleOnMap.super.OnDo(self, tbParams)
end


return AbilityAction_MakeDiamondVisibleOnMap
