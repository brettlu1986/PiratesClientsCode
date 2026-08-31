-----------------------------------------------------
--File Name    : AbilityAction_InvincibleToPoisonCircle.lua
--Author       : Song Fuhao
--Create Time  : 2020-06-30
--Description  : 开启当前角色毒圈无敌
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_InvincibleToPoisonCircle = luaclass("AbilityAction_InvincibleToPoisonCircle", AbilityActionBase)

AbilityAction_InvincibleToPoisonCircle.bDone = false

function AbilityAction_InvincibleToPoisonCircle:OnDo(tbParams)
    self.bDone = true
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        tbCharacter.ShipBattlePropertyComponent.bInvincibleToPoisonCircle = true
        tbCharacter.HumanBattlePropertyComponent.bInvincibleToPoisonCircle = true
    end, tbParams)
end

function AbilityAction_InvincibleToPoisonCircle:OnUndo(tbParams)
    if self.bDone then
        self.bDone = false
        self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
            tbCharacter.ShipBattlePropertyComponent.bInvincibleToPoisonCircle = false
            tbCharacter.HumanBattlePropertyComponent.bInvincibleToPoisonCircle = false
        end, tbParams)
    end
end

return AbilityAction_InvincibleToPoisonCircle
