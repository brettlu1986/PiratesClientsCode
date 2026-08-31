local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyCureTo = luaclass("AbilityAction_ApplyCureTo", AbilityActionBase)
local PropUtil = require("PropUtil")

local BattleAbilityDefine = require("BattleAbilityDefine")
local ValueType = BattleAbilityDefine.ValueType

AbilityAction_ApplyCureTo.nValue = 0
AbilityAction_ApplyCureTo.nType = ValueType.FIXED
AbilityAction_ApplyCureTo.nMaxHpPercentage = nil

function AbilityAction_ApplyCureTo:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
    if self.nType then
        self.nType = tbInitParams.Type
    end
    self.nMaxHpPercentage = tbInitParams.MaxHpPercentage
end

function AbilityAction_ApplyCureTo:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local nMaxHp = PropUtil.GetMaxHpWithType(tbCharacter, self.nTargetType)
        local nMaxHpPercentage = self.nMaxHpPercentage or 1.0
        local nHpLimit = nMaxHp * nMaxHpPercentage
        local nCurrentHp = PropUtil.GetHpWithType(tbCharacter, self.nTargetType)
        local nMaxValue = nHpLimit - nCurrentHp

        local nFixedValue
        if self.nType == ValueType.FIXED then
            nFixedValue = self.nValue - nCurrentHp
        else
            nFixedValue = nMaxHp * self.nValue - nCurrentHp
        end
        nFixedValue = math.max(nFixedValue, 0)
        if nFixedValue > nMaxValue then
            nFixedValue = math.max(nMaxValue, 0)
        end
        -- nFixedValue = math.ceil(nFixedValue)
        PropUtil.ApplyCureWithType(tbCharacter, self.nTargetType, self.tbInstigator, nFixedValue)
    end, tbParams)
end

return AbilityAction_ApplyCureTo
