-----------------------------------------------------
--File Name    : AbilityAction_AddEp.lua
--Author       : 
--Create Time  : 2018-10-14
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_AddEp = luaclass("AbilityAction_ApplyCure", AbilityActionBase)

local PropUtil = require("PropUtil")
local BattleAbilityDefine = require("BattleAbilityDefine")
local ValueType = BattleAbilityDefine.ValueType

AbilityAction_AddEp.nValue = 0
AbilityAction_AddEp.nType = ValueType.FIXED

function AbilityAction_AddEp:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
    if self.nType then
        self.nType = tbInitParams.Type
    end
end

function AbilityAction_AddEp:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local nFixedValue
        if self.nType == ValueType.FIXED then
            nFixedValue = self.nValue
        else
            local nMaxEp = PropUtil.GetMaxEpWithType(tbCharacter, self.nTargetType)
            nFixedValue = nMaxEp * self.nValue
        end
        nFixedValue = math.ceil(nFixedValue)
        PropUtil.GainEpWithType(tbCharacter, self.nTargetType, nFixedValue)
    end, tbParams)
end

return AbilityAction_AddEp
