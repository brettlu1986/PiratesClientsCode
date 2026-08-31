local luaclass                      = require("luaclass")
local HumanMovementStateBase        = dynamic_require("HumanMovementStateBase")
local HumanMovementStateGliding     = luaclass("HumanMovementStateGliding", HumanMovementStateBase)
local ParachutingNewIni = require("ParachutingNewIni")
local HumanCommonIni = require("HumanCommonIni")

function HumanMovementStateGliding:Active(tbParams)
    local GamePlayer = self.GamePlayer
    local pUEActor = GamePlayer.pUEActor
    local CharacterMovement = pUEActor.CharacterMovement
    log("[parachuting] HumanMovementStateGliding:Active", GamePlayer.szName, GamePlayer.nPlayerId)
    
    local tbOpenParachutingData = ParachutingNewIni.tbParachuteOpen
    -- CharacterMovement:SetFallingTerminalVelocity(tbOpenParachutingData.nNoOperateFallSpeed)
    -- CharacterMovement:SetMaxWalkSpeed(tbOpenParachutingData.nNoOperateTranslationSpeed)
    local pVelocity = Vector{X=0, Y=0, Z=-math.abs(pUEActor:GetParachutingVelocity())}
    CharacterMovement.Velocity  = pVelocity
    CharacterMovement.bUseHumanFallingTerminalVelocity = true
    CharacterMovement.GravityScale = tbOpenParachutingData.nAcceleration
    CharacterMovement.MaxAcceleration = tbOpenParachutingData.nTranslationAcceleration
end

function HumanMovementStateGliding:UnActive()
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor
    local pLocation = GamePlayer:GetLocation()
    log("[parachuting] HumanMovementStateGliding:UnActive", GamePlayer.szName, GamePlayer.nPlayerId, pLocation.Z)
    local CharacterMovement = pUEActor.CharacterMovement
    pUEActor.bUseControllerRotationYaw = true
    pUEActor.CapsuleComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Block)
    if pUEActor.PickComponent ~= nil then
        pUEActor.PickComponent:SetEnabled(true)
    end
    CharacterMovement:SetFallingTerminalVelocity(0)
    CharacterMovement.bUseHumanFallingTerminalVelocity = false
    local HumanFallConfig = CharacterMovement:GetHumanFallConfig()
    CharacterMovement.GravityScale = HumanFallConfig.CustomGravityScale
    CharacterMovement.MaxAcceleration = HumanCommonIni.tbHumanCommonData.nMaxAcceleration
    Owner:SetBaseSpeed(0)    
    Owner:SetParachutingEnd(true)
end

return HumanMovementStateGliding