-----------------------------------------------------
--File Name    : AbilityAction_ApplyFireBombDamage.lua
--Description  : 燃烧弹燃烧buff damage
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyFireBombDamage = luaclass("AbilityAction_ApplyFireBombDamage", AbilityActionBase)

local DamageTypeEx = require("DamageTypeEx")
local BattleAbilityDefine = require("BattleAbilityDefine")
local PropUtil = require("PropUtil")

local ValueType = BattleAbilityDefine.ValueType

AbilityAction_ApplyFireBombDamage.nValue = 0
AbilityAction_ApplyFireBombDamage.nType = ValueType.FIXED

local FIRE_BOMB = 27010002

function AbilityAction_ApplyFireBombDamage:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
    if self.nType then
        self.nType = tbInitParams.Type
    end
end

function AbilityAction_ApplyFireBombDamage:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local tbDamageExtraData = {}
        tbDamageExtraData.nWeaponTemplateId = FIRE_BOMB
        if self.nType == ValueType.FIXED then
            PropUtil.ApplyDamage(tbCharacter, self.tbInstigator, DamageTypeEx.HUMAN_FIREBOMB, self.nValue, tbDamageExtraData)
        else
            PropUtil.ApplyDamage(tbCharacter, self.tbInstigator, DamageTypeEx.HUMAN_FIREBOMB,
                PropUtil.GetMaxHp(tbCharacter) * self.nValue, tbDamageExtraData)
        end
    end, tbParams)
end

return AbilityAction_ApplyFireBombDamage
