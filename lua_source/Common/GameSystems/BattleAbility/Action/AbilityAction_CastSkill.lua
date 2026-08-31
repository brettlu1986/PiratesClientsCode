-----------------------------------------------------
--File Name    : AbilityAction_CastSkill.lua
--Author       : Song Fuhao
--Create Time  : 2017-10-26
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_CastSkill = luaclass("AbilityAction_CastSkill", AbilityActionBase)

AbilityAction_CastSkill.nValue = 0

function AbilityAction_CastSkill:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
end

function AbilityAction_CastSkill:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        tbCharacter.SkillComponentServer:RequestCastSkill(self.nValue)
    end, tbParams)
end

return AbilityAction_CastSkill
