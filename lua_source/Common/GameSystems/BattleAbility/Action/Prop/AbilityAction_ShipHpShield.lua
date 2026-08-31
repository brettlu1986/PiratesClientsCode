-----------------------------------------------------
--File Name    : AbilityAction_ShipHpShield.lua
--Author       : Song Fuhao
--Create Time  : 2018-10-17
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionPropBase = require("AbilityActionPropBase")
local AbilityAction_ShipHpShield = luaclass("AbilityAction_ShipHpShield", AbilityActionPropBase)

local BattleAbilityDefine = require("BattleAbilityDefine")
local tbValueType = BattleAbilityDefine.ValueType

function AbilityAction_ShipHpShield:GetWrapperName()
    return require("PropName").nShipHpShield
end

function AbilityAction_ShipHpShield:GetValue(tbCharacter)
    local nValueType = self.tbInitParams.Type
    local nValue = self.tbInitParams.Value
    if nValueType == tbValueType.FIXED then
        return nValue
    elseif nValueType == tbValueType.PERCENT then
        local nMaxHp = tbCharacter.ShipBattlePropertyComponent:GetMaxHp()
        return nValue * nMaxHp
    end
end

return AbilityAction_ShipHpShield
