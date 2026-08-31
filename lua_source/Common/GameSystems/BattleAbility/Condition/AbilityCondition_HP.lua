-----------------------------------------------------
--File Name    : AbilityCondition_HP.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : 血量条件检测
-----------------------------------------------------
local AbilityCondition_HP = {}

local SkillCastFailedDef = require("SkillCastFailedDef")
local MathUtil = require("MathUtil")
local PropUtil = require("PropUtil")

function AbilityCondition_HP:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    local nType = tbParams.Type
    local nValue = tbParams.Value
    local nMethod = tbParams.Method and tbParams.Method or MathUtil.ComparisonMethod.GREATER_THAN_OR_EQUAL_TO
    if nType == 1 then  -- 固定值
        return PropUtil.CheckHpValueWithType(Skill.OwnerPawn, nTargetType, nValue, nMethod)
    else                -- 百分比
        return PropUtil.CheckHpPercentWithType(Skill.OwnerPawn, nTargetType, nValue, nMethod)
    end
end

function AbilityCondition_HP:CheckCondition(Skill, tbParams)
    return self:CheckConditionWithType(Skill, tbParams)
end

function AbilityCondition_HP:GetConditionID()
    return SkillCastFailedDef.HP_NOT_ENOUGH
end

return AbilityCondition_HP
