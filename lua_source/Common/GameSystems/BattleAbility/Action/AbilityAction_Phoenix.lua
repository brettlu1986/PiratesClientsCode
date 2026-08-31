-----------------------------------------------------
--File Name    : AbilityAction_Phoenix.lua
--Author       : Song Fuhao
--Create Time  : 2019-10-28
--Description  : 角色死亡时重生（不会触发死亡逻辑）
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_Phoenix = luaclass("AbilityAction_Phoenix", AbilityActionBase)

function AbilityAction_Phoenix:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        tbCharacter.ShipBattlePropertyComponent.bPhoenix = true
        tbCharacter.HumanBattlePropertyComponent.bPhoenix = true
    end, tbParams)
end

function AbilityAction_Phoenix:OnUndo(tbParams)
    self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
        tbCharacter.ShipBattlePropertyComponent.bPhoenix = false
        tbCharacter.HumanBattlePropertyComponent.bPhoenix = false
    end, tbParams)
end

return AbilityAction_Phoenix
