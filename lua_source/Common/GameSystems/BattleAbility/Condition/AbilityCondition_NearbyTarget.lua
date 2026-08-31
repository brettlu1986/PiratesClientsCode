-----------------------------------------------------
--File Name    : AbilityCondition_NearbyTarget.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-30
--Description  : 附近敌人检测
-----------------------------------------------------
local AbilityCondition_NearbyTarget = {}

local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityCondition_NearbyTarget:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_NearbyTarget:CheckCondition( Skill, tbParams )
    local tbPawns = Skill:GetSkillTargetPawn()
    return #tbPawns > 0
end

function AbilityCondition_NearbyTarget:GetConditionID()
    return SkillCastFailedDef.CAN_NOT_FOUND_TRAGET_IN_NEARBY
end

return AbilityCondition_NearbyTarget
