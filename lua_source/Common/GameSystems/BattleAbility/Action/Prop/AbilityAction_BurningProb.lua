-----------------------------------------------------
--File Name    : AbilityAction_BurningProb.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 修改点火率
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_BurningProb = luaclass("AbilityAction_BurningProb", AbilityActionPropBase)

local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_BurningProb:GetWrapperName()
    return require("PropName").tbBurningProbInfo
end

function AbilityAction_BurningProb:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_BurningProb:GetValue(tbCharacter)
    local tbInitParams = self.tbInitParams
    return {
        nValue = tbInitParams.Value,
        tbWeaponTypes = tbInitParams.WeaponTypes,
        tbWeaponIds = tbInitParams.WeaponIds,
    }
end

return AbilityAction_BurningProb
