local luaclass = require("luaclass")
local HumanMovementStateGliding = require("HumanMovementStateGliding")
local HumanMovementStateGliding_C = luaclass("HumanMovementStateGliding_C", HumanMovementStateGliding)

function HumanMovementStateGliding_C:UnActive(tbParams)
    HumanMovementStateGliding_C.super.UnActive(self, tbParams)

    if self.bSelf then
        local CharacterMovement = self.pOwnerActor.CharacterMovement
        local pLocation = self.GamePlayer:GetLocation()
        local pFloorResult = CharacterMovement:K2_FindFloor(pLocation)
        log("[parachuting] HumanMovementStateGliding_C:UnActive Find Floor", self.GamePlayer.nPlayerId, 
            pFloorResult.bBlockingHit, pFloorResult.bWalkableFloor)
        if isvalidhandle(pFloorResult.HitResult.Actor) then
            log("[parachuting] HumanMovementStateGliding_C:UnActive Find Floor actor", self.GamePlayer.nPlayerId,
                KismetSystemLibrary.GetDisplayName(pFloorResult.HitResult.Actor)) 
        end
    end
end

return HumanMovementStateGliding_C