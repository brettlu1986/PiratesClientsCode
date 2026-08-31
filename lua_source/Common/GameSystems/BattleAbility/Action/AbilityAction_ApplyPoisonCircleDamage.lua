-----------------------------------------------------
--File Name    : AbilityAction_ApplyPoisonCircleDamage.lua
--Author       : WuJizhou
--Create Time  : 2018-08-21
--Description  : 毒圈
-----------------------------------------------------
local luaclass = require("luaclass")
local AbilityActionBase = require("AbilityActionBase")
local AbilityAction_ApplyPoisonCircleDamage = luaclass("AbilityAction_ApplyPoisonCircleDamage", AbilityActionBase)

local DamageTypeEx = require("DamageTypeEx")
local PropUtil = require("PropUtil")
local BattleBlackboard = require("BattleBlackboard")
local GameObjectTypeDef = require("GameObjectTypeDef")

AbilityAction_ApplyPoisonCircleDamage.POISON_CIRCLE_CENTER = "PoisonCircleCenter"
AbilityAction_ApplyPoisonCircleDamage.POISON_CIRCLE_RADIUS = "PoisonCircleRadius"

AbilityAction_ApplyPoisonCircleDamage.tbDistance = nil
AbilityAction_ApplyPoisonCircleDamage.tbShipExDamage = nil
AbilityAction_ApplyPoisonCircleDamage.tbHumanExDamage = nil
AbilityAction_ApplyPoisonCircleDamage.tbShipBaseDamage = nil
AbilityAction_ApplyPoisonCircleDamage.tbHumanBaseDamage = nil

local VectorCenter = Vector{X = 0,Y = 0, Z= 0}

function AbilityAction_ApplyPoisonCircleDamage:OnCreate(Owner, tbInitParams)
    self.tbDistance = tbInitParams.Distance
    self.tbShipExDamage= tbInitParams.ShipEx
    self.tbHumanExDamage= tbInitParams.HumanEx
    self.tbShipBaseDamage= tbInitParams.ShipBase
    self.tbHumanBaseDamage = tbInitParams.HumanBase
end



function AbilityAction_ApplyPoisonCircleDamage:OnDo(tbParams)
    self.AbilityHelper:ForeachAliveTargetPawns(function (tbCharacter)
        if self.tbDistance == nil then
            logerror("the tbDistance is nil")
            return
        end

        local nRadiusCount = #self.tbDistance
        if nRadiusCount == 0  then
            return
        end

        if not tbCharacter.pUEActor then
            logerror("cannot find pUEActor, error info:")
            logerror("------ szName :", tbCharacter.szName)
            logerror("------ nServerInstanceId :", tbCharacter:GetServerInstanceId())
            logerror("------ nUEActorUniqueId :", tbCharacter:GetUEActorUniqueId())
            logerror("------ nObjectType :", tbCharacter:GetObjectType())
            logerror("------ bIsShip :", tbCharacter:IsShip())
        end

        local Location = tbCharacter.pUEActor:K2_GetActorLocation()

        local tbCenter = BattleBlackboard:GetTable(AbilityAction_ApplyPoisonCircleDamage.POISON_CIRCLE_CENTER)
        if tbCenter == nil then
            return
        end
        VectorCenter.X = tbCenter.X
        VectorCenter.Y = tbCenter.Y

        local pVector = KismetMathLibrary.Subtract_VectorVector(Location, VectorCenter)
        pVector.Z = 0
        local nCurRadius =  BattleBlackboard:GetNumber(AbilityAction_ApplyPoisonCircleDamage.POISON_CIRCLE_RADIUS)

        local nDistance = KismetMathLibrary.VSize(pVector) - nCurRadius
        nDistance = nDistance / 100 -- 单位转换
        nDistance = nDistance < 0 and 1 or nDistance
        if nDistance <= self.tbDistance[1] then
            return
        end
        local nCircleIdx = 1
        for nIdx, v in ipairs(self.tbDistance) do
            if nDistance < v then
                break
            end
            nCircleIdx = nIdx
        end

        local nMaxHp =  PropUtil.GetMaxHp(tbCharacter)

        local nDamageValue
        if tbCharacter:IsShip() then
            nDamageValue = self.tbShipBaseDamage[nCircleIdx] +  nMaxHp * self.tbShipExDamage[nCircleIdx]
        else
            nDamageValue =  self.tbHumanBaseDamage[nCircleIdx] + nMaxHp * self.tbHumanExDamage[nCircleIdx]
        end
        if tbCharacter:GetObjectType() == GameObjectTypeDef.Horse then
            if tbCharacter:IsInvincibleToPoisonCircle() then
                -- 为避免刷一大堆大堆log直接不apply damage
                return
            end
        end
        PropUtil.ApplyDamageWithType(tbCharacter, self.nTargetType, self.tbInstigator, DamageTypeEx.POISON_CIRCLE, nDamageValue,nil)
    end, tbParams)
end

return AbilityAction_ApplyPoisonCircleDamage
