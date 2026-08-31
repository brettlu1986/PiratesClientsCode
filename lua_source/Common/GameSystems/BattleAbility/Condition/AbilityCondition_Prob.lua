-----------------------------------------------------
--File Name    : AbilityCondition_Prob.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : 概率条件检测
-----------------------------------------------------
local AbilityCondition_Prob = {}
local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityCondition_Prob:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_Prob:CheckCondition( Skill, tbParams )
    return math.random() <= tbParams.Value
end

function AbilityCondition_Prob:GetConditionID()
    return SkillCastFailedDef.PROB_NOT_ENOUGH
end

return AbilityCondition_Prob
