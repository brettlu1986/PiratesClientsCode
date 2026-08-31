-----------------------------------------------------
--File Name    : AbilityAction_ApplyDamage.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-25
--Description  : 扣血
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyDamage = luaclass("AbilityAction_ApplyDamage", AbilityActionBase)

local DamageTypeEx = require("DamageTypeEx")
local BattleAbilityDefine = require("BattleAbilityDefine")
local PropUtil = require("PropUtil")

local ValueType = BattleAbilityDefine.ValueType

AbilityAction_ApplyDamage.nValue = 0
AbilityAction_ApplyDamage.nType = ValueType.FIXED
AbilityAction_ApplyDamage.nDamageType = DamageTypeEx.UNKNOWN

function AbilityAction_ApplyDamage:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
    if tbInitParams.Type then
        self.nType = tbInitParams.Type
    end
    if tbInitParams.DamageType then
        self.nDamageType = DamageTypeEx[tbInitParams.DamageType]
    end
    
    if self.nDamageType == DamageTypeEx.UNKNOWN then
        error("AbilityAction_ApplyDamage:OnCreate damage type is unknown", tbInitParams.DamageType)
    end
end

function AbilityAction_ApplyDamage:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if self.nType == ValueType.FIXED then
            PropUtil.ApplyDamage(tbCharacter, self.tbInstigator, self.nDamageType, self.nValue)
        else
            PropUtil.ApplyDamage(tbCharacter, self.tbInstigator, self.nDamageType,
                PropUtil.GetMaxHp(tbCharacter) * self.nValue)
        end
    end, tbParams)
end

return AbilityAction_ApplyDamage
