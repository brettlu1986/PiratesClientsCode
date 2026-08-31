-----------------------------------------------------
--File Name    : AbilityAction_ApplyCure.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-25
--Description  : 加血
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyCure = luaclass("AbilityAction_ApplyCure", AbilityActionBase)
local PropUtil = require("PropUtil")

local BattleAbilityDefine = require("BattleAbilityDefine")
local ValueType = BattleAbilityDefine.ValueType

AbilityAction_ApplyCure.nValue = 0
AbilityAction_ApplyCure.nType = ValueType.FIXED
AbilityAction_ApplyCure.nMaxHpPercentage = nil

function AbilityAction_ApplyCure:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
    if self.nType then
        self.nType = tbInitParams.Type
    end
    self.nMaxHpPercentage = tbInitParams.MaxHpPercentage
end

function AbilityAction_ApplyCure:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local nMaxHp = PropUtil.GetMaxHpWithType(tbCharacter, self.nTargetType)
        local nMaxHpPercentage = self.nMaxHpPercentage or 1.0
        local nHpLimit = nMaxHp * nMaxHpPercentage
        local nCurrentHp = PropUtil.GetHpWithType(tbCharacter, self.nTargetType)
        local nMaxValue = nHpLimit - nCurrentHp

        local nFixedValue
        if self.nType == ValueType.FIXED then
            nFixedValue = self.nValue
        else
            nFixedValue = nMaxHp * self.nValue
        end
        if nFixedValue > nMaxValue then
            nFixedValue = math.max(nMaxValue, 0)
        end
        -- nFixedValue = math.ceil(nFixedValue)
        PropUtil.ApplyCureWithType(tbCharacter, self.nTargetType, self.tbInstigator, nFixedValue)
    end, tbParams)
end

return AbilityAction_ApplyCure
