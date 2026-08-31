-----------------------------------------------------
--File Name    : AbilityAction_HiddenInGame.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-28
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_HiddenInGame = luaclass("AbilityAction_HiddenInGame", AbilityActionBase)

function AbilityAction_HiddenInGame:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if tbCharacter and tbCharacter.pUEActor then
            tbCharacter.pUEActor:SetActorHiddeninGameMulticast(true)
        end
    end, tbParams)
end

function AbilityAction_HiddenInGame:OnUndo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if tbCharacter and tbCharacter.pUEActor then
            tbCharacter.pUEActor:SetActorHiddeninGameMulticast(false)
        end
    end, tbParams)
end

return AbilityAction_HiddenInGame
