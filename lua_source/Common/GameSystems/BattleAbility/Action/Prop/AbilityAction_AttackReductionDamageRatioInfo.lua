-----------------------------------------------------
--File Name    : AbilityAction_AttackReductionDamageRatioInfo.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-18
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_AttackReductionDamageRatioInfo = luaclass("AbilityAction_AttackReductionDamageRatioInfo", AbilityActionPropBase)

local PropertyWrapperType = require("PropertyWrapperType")

function AbilityAction_AttackReductionDamageRatioInfo:GetWrapperName()
    return require("PropName").tbAttackReductionDamageRatioInfo
end

function AbilityAction_AttackReductionDamageRatioInfo:GetOverlapType()
    return PropertyWrapperType.TYPE_OVERRIDE
end

function AbilityAction_AttackReductionDamageRatioInfo:GetValue(tbCharacter)
    local tbInitParams = self.tbInitParams
    return {
        nValue = tbInitParams.Value,
        tbWeaponTypes = tbInitParams.WeaponTypes,
        tbWeaponIds = tbInitParams.WeaponIds,
    }
end

return AbilityAction_AttackReductionDamageRatioInfo
