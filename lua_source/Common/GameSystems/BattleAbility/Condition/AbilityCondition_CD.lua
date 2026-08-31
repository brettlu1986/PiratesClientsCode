-----------------------------------------------------
--File Name    : AbilityCondition_CD.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : CD条件检测
-----------------------------------------------------
local AbilityCondition_CD = {}
local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityCondition_CD:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_CD:CheckCondition( Skill, tbParams )
    return not Skill:IsInCD()
end

function AbilityCondition_CD:GetConditionID()
    return SkillCastFailedDef.SKILL_IN_CD
end

return AbilityCondition_CD
