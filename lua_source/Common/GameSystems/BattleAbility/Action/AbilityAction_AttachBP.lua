-----------------------------------------------------
--File Name    : AbilityAction_AttachBP.lua
--Author       : Song Fuhao
--Create Time  : 2017-11-29
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_AttachBP = luaclass("AbilityAction_AttachBP", AbilityActionBase)

local UEActorHelper = require("UEActorHelper")
local ATTACHMENT_RULE = EAttachmentRule.KeepRelative

AbilityAction_AttachBP.szClassPath = nil
AbilityAction_AttachBP.tbAttachedActors = {}

function AbilityAction_AttachBP:OnCreate(Owner, tbInitParams)
    if tbInitParams.ClassPath then
        self.szClassPath = tbInitParams.ClassPath
    else
        logerror("AbilityAction_AttachBP OnCreate failed, ClassPath is nil")
    end
end

function AbilityAction_AttachBP:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local _, pActor = UEActorHelper:CreateActor(self.szClassPath)
        if pActor then
            pActor:K2_AttachToActor(self.OwnerPawn.pUEActor, "", ATTACHMENT_RULE, ATTACHMENT_RULE, ATTACHMENT_RULE, false)
            pActor:OnAttached(tbCharacter.pUEActor, nil)
            table.insert(self.tbAttachedActors, pActor)
        end
    end, tbParams)
end

function AbilityAction_AttachBP:OnUndo(tbParams)
    self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
        for i,v in ipairs(self.tbAttachedActors) do
            v:OnDetached()
        end
    end, tbParams)
end

return AbilityAction_AttachBP
