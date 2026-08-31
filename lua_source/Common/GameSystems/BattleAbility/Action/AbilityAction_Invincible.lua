-----------------------------------------------------
--File Name    : AbilityAction_Invincible.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-08
--Description  : 开启当前角色无敌
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_Invincible = luaclass("AbilityAction_Invincible", AbilityActionBase)

AbilityAction_Invincible.bDone = false

function AbilityAction_Invincible:OnDo(tbParams)
    self.bDone = true
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        tbCharacter.ShipBattlePropertyComponent.bInvincible = true
        tbCharacter.HumanBattlePropertyComponent.bInvincible = true
    end, tbParams)
end

function AbilityAction_Invincible:OnUndo(tbParams)
    if self.bDone then
        self.bDone = false
        self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
            tbCharacter.ShipBattlePropertyComponent.bInvincible = false
            tbCharacter.HumanBattlePropertyComponent.bInvincible = false
        end, tbParams)
    end
end

return AbilityAction_Invincible
