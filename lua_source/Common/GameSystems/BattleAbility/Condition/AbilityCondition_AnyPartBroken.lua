-----------------------------------------------------
--File Name    : AbilityCondition_AnyPartBroken.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : 炮损条件检测
-----------------------------------------------------
local AbilityCondition_AnyPartBroken = {}

local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityCondition_AnyPartBroken:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_AnyPartBroken:CheckCondition( Skill, tbParams )
    -- return Skill.OwnerPawn.SustainedDamageSpotComponent:IsAnySpotActive()
    return false
end

function AbilityCondition_AnyPartBroken:GetConditionID()
    return SkillCastFailedDef.DONT_HAVE_BROKEN_PART
end

return AbilityCondition_AnyPartBroken
