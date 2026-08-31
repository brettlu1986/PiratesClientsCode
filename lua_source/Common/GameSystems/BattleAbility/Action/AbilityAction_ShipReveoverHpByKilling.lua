-----------------------------------------------------
--File Name    : AbilityAction_ShipReveoverHpByKilling.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-25
--Description  : 添加Buff
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ShipReveoverHpByKilling = luaclass("AbilityAction_ShipReveoverHpByKilling", AbilityActionBase)

local PropName = require("PropName")

function AbilityAction_ShipReveoverHpByKilling:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local PropertyComponent = tbCharacter.ShipBattlePropertyComponent
        local nMaxHp = PropertyComponent:GetMaxHp()
        local nShipRecoveredHpByKilling = PropertyComponent:GetProp(PropName.nShipRecoveredHpByKilling) - 1
        PropertyComponent:ApplyCure(tbCharacter, nMaxHp * nShipRecoveredHpByKilling)
    end, tbParams)
end

return AbilityAction_ShipReveoverHpByKilling
