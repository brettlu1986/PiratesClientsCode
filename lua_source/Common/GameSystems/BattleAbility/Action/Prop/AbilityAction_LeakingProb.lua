-----------------------------------------------------
--File Name    : AbilityAction_LeakingProb.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-11
--Description  : 修改漏水
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_LeakingProb = luaclass("AbilityAction_LeakingProb", AbilityActionPropBase)

local PropName = require("PropName")
local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_LeakingProb:GetWrapperName()
    return PropName.tbLeakingProbInfo
end

function AbilityAction_LeakingProb:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_LeakingProb:GetValue(tbCharacter)
    local tbInitParams = self.tbInitParams
    return {
        nValue = tbInitParams.Value,
        tbWeaponTypes = tbInitParams.WeaponTypes,
        tbWeaponIds = tbInitParams.WeaponIds,
    }
end

return AbilityAction_LeakingProb