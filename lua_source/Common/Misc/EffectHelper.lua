local EffectResDataTable = require("EffectResDataTable")

local EffectHelper = {}

local pDefualtLocation = Vector()
local pDefualtRotation = Rotator()
local pDefualtScale = Vector{X=1,Y=1,Z=1}

function EffectHelper:GetEffectClassById(nEffectId)
    local tbEffectTemplate = EffectResDataTable:GetTemplate(nEffectId)
    if tbEffectTemplate == nil then
        return nil
    end
    return tbEffectTemplate.szEffectClass
end

function EffectHelper:PlayEffectAttached(tbObject, nEffectId, inReleationLocation)
    local pEffect = nil
    if nEffectId > 0 and tbObject.pUEActor then
        local tbEffect = EffectResDataTable:GetTemplate(nEffectId)
        if tbEffect then
            local attachComnponent = tbObject.pUEActor[tbEffect.szSocket]
            if attachComnponent then
                local ReleationLocation = inReleationLocation == nil and  attachComnponent:K2_GetComponentLocation() or inReleationLocation
                pEffect = ExtendBlueprintFunctions.SpawnEmitterAttachedEx(tbEffect.szEffectClass:load(),
                tbObject.pUEActor.RootComponent, "" , ReleationLocation, Rotator(), Vector{X = 1, Y = 1, Z = 1},
                    EAttachLocation.KeepWorldPosition, true, 1, EPSCPoolMethod.None, false)
            else
                local ReleationLocation = inReleationLocation == nil and  tbObject.pUEActor:K2_GetActorLocation() or inReleationLocation
                pEffect = ExtendBlueprintFunctions.SpawnEmitterAttachedEx(tbEffect.szEffectClass:load(),
                tbObject.pUEActor.RootComponent, "" , ReleationLocation, Rotator(), Vector{X = 1, Y = 1, Z = 1},
                    EAttachLocation.KeepWorldPosition, true, 1, EPSCPoolMethod.None, false)
            end
        end
    end
    return pEffect
end

function EffectHelper:PlayEffectAtLocation(nEffectId, pInLocation, pInRotation, pInScale, bAutoDestroy)
    if nEffectId > 0 then
        local tbEffect = EffectResDataTable:GetTemplate(nEffectId)
        if tbEffect then
            local pLocation = (pInLocation == nil) and pDefualtLocation or pInLocation
            local pRotation = (pInRotation == nil) and pDefualtRotation or pInRotation
            local pScale = (pInScale == nil) and pDefualtScale or pInScale
            GameplayStatics.SpawnEmitterAtLocation(GWorld, tbEffect.szEffectClass:load(), pLocation, pRotation, pScale, bAutoDestroy, 1, EPSCPoolMethod.None)
        end
    end
end

function EffectHelper:DestoryEffect(tbObject, pEffect)
    if isvalidhandle(pEffect) then
        ExtendBlueprintFunctions.DeactivateEmitter(pEffect)
    end
end


return EffectHelper
