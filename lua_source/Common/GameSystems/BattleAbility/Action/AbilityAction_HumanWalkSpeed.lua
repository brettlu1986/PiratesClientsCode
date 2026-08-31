-----------------------------------------------------
--File Name    : AbilityAction_HumanWalkSpeed.lua
--Author       : Fang Jing
--Create Time  : 2018-10-19
--Description  : 人移动速度
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_HumanWalkSpeed = luaclass("AbilityAction_HumanWalkSpeed", AbilityActionBase)

AbilityAction_HumanWalkSpeed.nValue = 0

function AbilityAction_HumanWalkSpeed:OnCreate(Owner, tbInitParams)
    self.nValue = tbInitParams.Value
end

function AbilityAction_HumanWalkSpeed:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function(tbCharacter)
        local tbHumanMovementStateComponent = tbCharacter.HumanMovementStateComponent
        if tbHumanMovementStateComponent then
            tbHumanMovementStateComponent:ChangeSpeedBuffRatio(self.nValue)
        end
    end, tbParams)
end

function AbilityAction_HumanWalkSpeed:OnUndo(tbParams)
    self.AbilityHelper:ForeachTargetPawns(function(tbCharacter)
        local tbHumanMovementStateComponent = tbCharacter.HumanMovementStateComponent
        if tbHumanMovementStateComponent then
            tbHumanMovementStateComponent:ChangeSpeedBuffRatio(-self.nValue)
        end
    end, tbParams)
end

return AbilityAction_HumanWalkSpeed
