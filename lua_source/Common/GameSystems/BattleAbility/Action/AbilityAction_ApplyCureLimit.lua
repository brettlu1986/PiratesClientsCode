local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyCureLimit = luaclass("AbilityAction_ApplyCureLimit", AbilityActionBase)
local PropUtil = require("PropUtil")

local BattleAbilityDefine = require("BattleAbilityDefine")
local ValueType = BattleAbilityDefine.ValueType

AbilityAction_ApplyCureLimit.nValue = 0
AbilityAction_ApplyCureLimit.nType = ValueType.FIXED
AbilityAction_ApplyCureLimit.nMaxHpLimit = nil
AbilityAction_ApplyCureLimit.nCurCureHp = nil

function AbilityAction_ApplyCureLimit:OnCreate(Owner, tbInitParams)
    logerror("AbilityAction_ApplyCureLimit")
    self.nValue = tbInitParams.Value
    if self.nType then
        self.nType = tbInitParams.Type
    end
    self.nMaxHpLimit = tbInitParams.nMaxHpLimit
    self.nCurCureHp = 0
end

function AbilityAction_ApplyCureLimit:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if self.nCurCureHp < self.nMaxHpLimit then
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
            if self.nCurCureHp + nFixedValue > self.nMaxHpLimit then
                nFixedValue = self.nMaxHpLimit - self.nCurCureHp
            end
            self.nCurCureHp = self.nCurCureHp + nFixedValue
            PropUtil.ApplyCureWithType(tbCharacter, self.nTargetType, self.tbInstigator, nFixedValue)
        end
    end, tbParams)
end

return AbilityAction_ApplyCureLimit
