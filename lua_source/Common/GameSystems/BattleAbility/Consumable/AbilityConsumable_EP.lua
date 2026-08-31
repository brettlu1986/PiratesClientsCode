-----------------------------------------------------
--File Name    : AbilityConsumable_EP.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : 充能消耗
-----------------------------------------------------
local AbilityConsumable_EP = {}

local SkillCastFailedDef = require("SkillCastFailedDef")

function AbilityConsumable_EP:HandleConsume( Skill, tbParams )
    -- local StatusComponent = Skill.OwnerPawn.BattleStatusComponent
    -- StatusComponent:ConsumeEp(tbParams.Value)
end

function AbilityConsumable_EP:CheckCondition( Skill, tbParams )
    -- local StatusComponent = Skill.OwnerPawn.BattleStatusComponent
    -- return StatusComponent:GetEp() >= tbParams.Value
    return false
end

function AbilityConsumable_EP:GetConditionID()
    return SkillCastFailedDef.CHARGE_NOT_ENOUGH
end

return AbilityConsumable_EP
