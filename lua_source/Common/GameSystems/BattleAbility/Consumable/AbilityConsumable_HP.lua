-----------------------------------------------------
--File Name    : AbilityConsumable_HP.lua
--Author       : Song Fuhao
--Create Time  : 2017-04-26
--Description  : 消耗血量
-----------------------------------------------------
local AbilityConsumable_HP = {}

-- local MathUtil = require("MathUtil")
-- local DamageType = require("DamageType")
local SkillCastFailedDef = require("SkillCastFailedDef")
-- local BattleAbilityDefine = require("BattleAbilityDefine")

function AbilityConsumable_HP:HandleConsume( Skill, tbParams )
    -- local nType = tbParams.Type
    -- local nValue = tbParams.Value
    -- local BattleStatusComponent = Skill.OwnerPawn.BattleStatusComponent
    -- if nType == BattleAbilityDefine.ValueType.FIXED then    -- 固定值
    --     BattleStatusComponent:ApplyDamage(Skill.OwnerPawn, DamageType.SKILL, nValue)
    -- else                                                    -- 百分比
    --     local nMaxHP = BattleStatusComponent:GetMaxHp()
    --     BattleStatusComponent:ApplyDamage(Skill.OwnerPawn, DamageType.SKILL, nValue * nMaxHP)
    -- end
end

function AbilityConsumable_HP:CheckCondition( Skill, tbParams )
    -- local nType = tbParams.Type
    -- local nValue = tbParams.Value

    -- local BattleShipPropertyComponent = Skill.OwnerPawn.BattleShipPropertyComponent
    -- if nType == BattleAbilityDefine.ValueType.FIXED then  -- 固定值
    --     return BattleShipPropertyComponent:CheckHPValue(nValue, MathUtil.ComparisonMethod.GREATER_THAN)
    -- else                -- 百分比
    --     return BattleShipPropertyComponent:CheckHPPercent(nValue, MathUtil.ComparisonMethod.GREATER_THAN)
    -- end
    return false
end

function AbilityConsumable_HP:GetConditionID()
    return SkillCastFailedDef.HP_NOT_ENOUGH
end

return AbilityConsumable_HP
