-----------------------------------------------------
--File Name    : ActorLocationHelper.lua
--Author       : Ran Jie
--Create Time  : 2020-06-24
--Description  : ActorLocationHelper
-----------------------------------------------------
local ActorLocationHelper = {}

local SetActorLocationXYZ = EngineExtActorShell.SetActorLocationXYZ

function ActorLocationHelper:SetHumanLocationBasedOnFoot(pUEActor, pLocation)
    self:SetHumanLocationXYZBasedOnFoot(pUEActor, pLocation.X, pLocation.Y, pLocation.Z)
end

function ActorLocationHelper:SetHumanLocationXYZBasedOnFoot(pUEActor, X, Y, Z)
    local nHeightOffset = 0
    local pCapsuleComponent = pUEActor.CapsuleComponent
    if pCapsuleComponent then
        nHeightOffset = pCapsuleComponent:GetScaledCapsuleHalfHeight()
    end
    local nCorrectZ = Z + nHeightOffset
    SetActorLocationXYZ(pUEActor, X, Y, nCorrectZ)
end


return ActorLocationHelper