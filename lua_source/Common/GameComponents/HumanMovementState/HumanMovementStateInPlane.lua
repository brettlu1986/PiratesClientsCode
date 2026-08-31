local luaclass              = require("luaclass")
local HumanMovementStateBase             = dynamic_require("HumanMovementStateBase")
local HumanMovementStateInPlane    = luaclass("HumanMovementStateInPlane", HumanMovementStateBase)

function HumanMovementStateInPlane:Active(tbParams)
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = self.pOwnerActor
    Owner:SetParachutingEnd(false)
    Owner.bEnableMove = true
    pUEActor.bUseControllerRotationYaw = false
    Owner.nWeaponSpeedFactor = 1
    pUEActor.CharacterMovement:SetComponentTickEnabled(false)
    pUEActor.CharacterMovement:SetMovementMode(EMovementMode.MOVE_Flying, 0)
    pUEActor.CharacterMovement:SetActive(false)
    pUEActor.CharacterMovement:InitHumanSwimState()
    log("[parachuting] HumanMovementStateInPlane:Active", GamePlayer.szName, GamePlayer.nPlayerId)
end

function HumanMovementStateInPlane:UnActive()
    log("[parachuting] HumanMovementStateInPlane:UnActive", self.GamePlayer.szName, self.GamePlayer.nPlayerId)
end

return HumanMovementStateInPlane