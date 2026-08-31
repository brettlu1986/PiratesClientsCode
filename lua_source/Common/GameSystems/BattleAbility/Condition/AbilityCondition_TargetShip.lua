-----------------------------------------------------
--File Name    : AbilityCondition_TargetShip.lua
--Author       : Song Fuhao
--Create Time  : 2017-09-30
--Description  : 目标检测
-----------------------------------------------------
local AbilityCondition_TargetShip = {}

local SkillCastFailedDef = require("SkillCastFailedDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

function AbilityCondition_TargetShip:CheckConditionWithTargetType(Skill, tbParams, nTargetType)
    -- TODO 按照 type 改实现
    return self:CheckCondition(Skill, tbParams)
end

function AbilityCondition_TargetShip:CheckCondition( Skill, tbParams )
    local OwnerShip = Skill.OwnerPawn
    local tbTargetShip = nil
    if GlobalVariableSystem:IsClient() and OwnerShip.ObjectType == GameObjectTypeDef.PlayerSelf then
        tbTargetShip = OwnerShip.SkillComponentClient.tbTargetPawn
    else
        tbTargetShip = OwnerShip.SkillComponentServer.tbTargetPawn
    end
    if tbTargetShip == nil then
        return false
    end
    if tbParams.Range then
        local nDistance = OwnerShip.pUEActor:GetSquaredDistanceTo(tbTargetShip.pUEActor)
        return nDistance <= tbParams.Range * tbParams.Range
    end
    return true
end

function AbilityCondition_TargetShip:GetConditionID()
    return SkillCastFailedDef.CAN_NOT_FOUND_TRAGET_SHIP
end

return AbilityCondition_TargetShip
