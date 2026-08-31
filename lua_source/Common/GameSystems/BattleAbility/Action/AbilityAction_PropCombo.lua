-----------------------------------------------------
--File Name    : AbilityAction_PropCombo.lua
--Author       : Song Fuhao
--Create Time  : 2019-05-16
--Description  : 利用PropCombo
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_PropCombo = luaclass("AbilityAction_PropCombo", AbilityActionBase)

AbilityAction_PropCombo.nComboId = -1
AbilityAction_PropCombo.tbPropComboOverlapMap = nil

function AbilityAction_PropCombo:OnCreate(Owner, tbInitParams)
    self.nComboId = tbInitParams.Id
end

function AbilityAction_PropCombo:OnDo(tbParams)
    self.tbPropComboOverlapMap = {}
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        self.tbPropComboOverlapMap[tbCharacter] = tbCharacter.PropertyComboComponent:ApplyPropertyComboOverlap(self.nComboId)
    end, tbParams)
end

function AbilityAction_PropCombo:OnUndo(tbParams)
    for tbCharacter, nPropComboOverlapId in pairs(self.tbPropComboOverlapMap) do
        tbCharacter.PropertyComboComponent:RemovePropertyComboOverlap(nPropComboOverlapId)
    end
    self.tbPropComboOverlapMap = nil
end

return AbilityAction_PropCombo
