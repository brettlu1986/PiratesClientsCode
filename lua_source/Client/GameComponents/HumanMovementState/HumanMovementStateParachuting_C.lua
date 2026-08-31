local luaclass = require("luaclass")
local HumanMovementStateParachuting = require("HumanMovementStateParachuting")
local HumanMovementStateParachuting_C = luaclass("HumanMovementStateParachuting_C", HumanMovementStateParachuting)
local ParachutingNewIni = require("ParachutingNewIni")

function HumanMovementStateParachuting_C:UnActive(tbParams)
    HumanMovementStateParachuting_C.super.UnActive(self, tbParams)

    if self.bSelf and not ParachutingNewIni.tbParachuteOpen.bHad then
        local CharacterMovement = self.pOwnerActor.CharacterMovement
        local pLocation = self.GamePlayer:GetLocation()
        local pFloorResult = CharacterMovement:K2_FindFloor(pLocation)
        log("[parachuting] HumanMovementStateParachuting:UnActive Find Floor", self.GamePlayer.nPlayerId, 
            pFloorResult.bBlockingHit, pFloorResult.bWalkableFloor)
        if isvalidhandle(pFloorResult.HitResult.Actor) then
            log("[parachuting] HumanMovementStateParachuting:UnActive Find Floor actor", self.GamePlayer.nPlayerId,
                KismetSystemLibrary.GetDisplayName(pFloorResult.HitResult.Actor)) 
        end
    end
end

return HumanMovementStateParachuting_C