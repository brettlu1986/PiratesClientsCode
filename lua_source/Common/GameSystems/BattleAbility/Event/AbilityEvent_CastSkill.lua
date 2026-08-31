-----------------------------------------------------
--File Name    : AbilityEvent_CastSkill.lua
--Author       : Song Fuhao
--Create Time  : 2018-02-26
--Description  : 使用技能时触发
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityEventBaseClass = require("AbilityEventBase")
local AbilityEvent_CastSkill = luaclass("AbilityEvent_CastSkill", AbilityEventBaseClass)

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local function OnPawnCastSkill(self, tbPawn, nSkillId)
    if tbPawn ~= self.OwnerPawn then
        return
    end
    if self.tbParams.SkillId and (tonumber(self.tbParams.SkillId) ~= nSkillId) then
        return
    end
    self:TriggerDo()
end

function AbilityEvent_CastSkill:OnActivate()
    EventManager:BindEventMethod(CommonEventDef.EV_PAWN_CAST_SKILL, self, OnPawnCastSkill)
end

function AbilityEvent_CastSkill:OnDeactivate()
    EventManager:UnBindEventMethod(CommonEventDef.EV_PAWN_CAST_SKILL, self, OnPawnCastSkill)
end

return AbilityEvent_CastSkill
