-----------------------------------------------------
--File Name    : AbilityCondition_MaxCastCount.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : CD条件检测
-----------------------------------------------------
local AbilityCondition_MaxCastCount = {}
local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityCondition_MaxCastCount:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_MaxCastCount:CheckCondition( Skill, nMaxCastCount )
    return Skill.nCastCount < nMaxCastCount
end

function AbilityCondition_MaxCastCount:GetConditionID()
    return SkillCastFailedDef.CAST_COUNT_NOT_ENOUGH
end

return AbilityCondition_MaxCastCount
