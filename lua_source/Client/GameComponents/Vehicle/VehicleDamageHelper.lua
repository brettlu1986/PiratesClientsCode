local VehicleDamageHelper = {}
local EffectHelper = require("EffectHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local HumanBodyDef = require("HumanBodyDef")
local GameObjectTypeDef = require("GameObjectTypeDef")

local HIT_EFFECT_ID = 37

local VEHICLE_PROPERTY_NAME = {
        ["Head"] = "Head",
        ["Body"] = "Body",
        ["ForwardRight"] = "R_Foream",
        ["ForwardLeft"] = "L_Forearm",
        ["BackLeft"] = "L_Calf",
        ["BackRight"] = "R_Calf",
}

function VehicleDamageHelper.CheckPlayHitEffect()
    if not GlobalVariableSystem:GetDungeonDamageEnabled() then
        return false
    end

    return true
end

function VehicleDamageHelper.PlayHitEffect(tbVehicle, pHitResult, szDamageType)
    if not VehicleDamageHelper.CheckPlayHitEffect() then
        return
    end

    if not (tbVehicle and tbVehicle.pUEActor) then
        return
    end

    if tbVehicle.ObjectType ~= GameObjectTypeDef.Horse then
        return
    end

    local pUEActor = tbVehicle.pUEActor
    local pActorLocation = pUEActor:K2_GetActorLocation()

    if pHitResult then
        local pImpactPoint = pHitResult.ImpactPoint
        pActorLocation.X = pImpactPoint.X
        pActorLocation.Y = pImpactPoint.Y
        pActorLocation.Z = pImpactPoint.Z
    elseif szDamageType then
        local pDamageLoc = pUEActor[szDamageType] and pUEActor[szDamageType]:K2_GetComponentLocation()
        if pDamageLoc then
            pActorLocation.X = pDamageLoc.X
            pActorLocation.Y = pDamageLoc.Y
            pActorLocation.Z = pDamageLoc.Z
        end
    end

    EffectHelper:PlayEffectAttached(tbVehicle, HIT_EFFECT_ID, pActorLocation)
end

function VehicleDamageHelper.CalculateDamageType(tbTaker, tbCauser, nRegionType)
    if not (tbTaker and tbTaker.pUEActor and tbCauser and tbCauser.pUEActor) then
        return nil
    end

    local szDamageType = VEHICLE_PROPERTY_NAME.Body

    if nRegionType and nRegionType == HumanBodyDef.HUMAN_HEAD then
        szDamageType = VEHICLE_PROPERTY_NAME.Head
    elseif nRegionType and nRegionType == HumanBodyDef.HUMAN_BODY then
        szDamageType = VEHICLE_PROPERTY_NAME.Body
    elseif nRegionType and nRegionType == HumanBodyDef.HUMAN_ALLFOURS then
        local nDirAngle = ExtendBlueprintFunctions.GetDirectionFromActor(tbTaker.pUEActor, tbCauser.pUEActor)
    
        if nDirAngle >= 0 and nDirAngle < 90 then
            szDamageType = VEHICLE_PROPERTY_NAME.ForwardRight
        elseif nDirAngle >= 90 and nDirAngle < 180 then
            szDamageType = VEHICLE_PROPERTY_NAME.BackRight
        elseif nDirAngle >= -90 and nDirAngle < 0 then
            szDamageType = VEHICLE_PROPERTY_NAME.ForwardLeft
        elseif nDirAngle >= 270 then
            szDamageType = VEHICLE_PROPERTY_NAME.ForwardRight
        end
    end
    return szDamageType
end

return VehicleDamageHelper