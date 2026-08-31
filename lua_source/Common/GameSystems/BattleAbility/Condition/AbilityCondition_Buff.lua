-----------------------------------------------------
--File Name    : AbilityCondition_Buff.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : buff条件检测
-----------------------------------------------------
local AbilityCondition_Buff = {}

local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityCondition_Buff:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_Buff:CheckCondition( Skill, tbParams )
    return Skill.OwnerPawn.BuffComponentServer:IsExistBuffById(tbParams.Value)
end

function AbilityCondition_Buff:GetConditionID()
    return SkillCastFailedDef.BUFF_CONDITION_NOT_ENOUGH
end

return AbilityCondition_Buff
