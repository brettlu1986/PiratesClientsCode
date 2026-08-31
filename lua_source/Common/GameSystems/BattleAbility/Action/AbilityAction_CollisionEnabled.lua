-----------------------------------------------------
--File Name    : AbilityAction_CollisionEnabled.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-28
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_CollisionEnabled = luaclass("AbilityAction_CollisionEnabled", AbilityActionBase)

function AbilityAction_CollisionEnabled:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if tbCharacter and tbCharacter.pUEActor then
            log("AbilityAction_CollisionEnabled false")
            tbCharacter.pUEActor:SetCollisionEnabledMulticast(false)
        end
    end, tbParams)
end

function AbilityAction_CollisionEnabled:OnUndo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        if tbCharacter and tbCharacter.pUEActor then
            log("AbilityAction_CollisionEnabled true")
            tbCharacter.pUEActor:SetCollisionEnabledMulticast(true)
        end
    end, tbParams)
end

return AbilityAction_CollisionEnabled
