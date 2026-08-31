local luaclass                      = require("luaclass")
local HumanMovementStateBase        = dynamic_require("HumanMovementStateBase")
local HumanMovementStateParachuting = luaclass("HumanMovementStateParachuting", HumanMovementStateBase)
local ParachutingNewIni = require("ParachutingNewIni")
local HumanCommonIni = require("HumanCommonIni")

function HumanMovementStateParachuting:Active(tbParams)
    local GamePlayer = self.GamePlayer
    local pUEActor = GamePlayer.pUEActor
    local CharacterMovement = pUEActor.CharacterMovement
    pUEActor.bUseControllerRotationYaw = true
    log("[parachuting] HumanMovementStateParachuting:Active", GamePlayer.szName, GamePlayer.nPlayerId)
    pUEActor.CapsuleComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_Pawn, ECollisionResponse.ECR_Ignore)
    if pUEActor.PickComponent ~= nil then
        pUEActor.PickComponent:SetEnabled(false)
    end
    pUEActor.CharacterMovement:SetActive(true)
    local tbNoOpenParachutingData = ParachutingNewIni.tbParachuteNoOpen
    CharacterMovement:SetFallingTerminalVelocity(tbNoOpenParachutingData.nNoOperateFallSpeed)
    CharacterMovement:SetMaxWalkSpeed(tbNoOpenParachutingData.nNoOperateTranslationSpeed)
    local pVelocity = Vector{X=0, Y=0, Z=-math.abs(pUEActor:GetParachutingVelocity())}
    CharacterMovement.Velocity  = pVelocity
    CharacterMovement.bUseHumanFallingTerminalVelocity = true
    CharacterMovement.GravityScale = tbNoOpenParachutingData.nAcceleration
    CharacterMovement.MaxAcceleration = tbNoOpenParachutingData.nTranslationAcceleration
end

function HumanMovementStateParachuting:UnActive()
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor
    local pLocation = GamePlayer:GetLocation()
    log("[parachuting] HumanMovementStateParachuting:UnActive", GamePlayer.szName, GamePlayer.nPlayerId, pLocation.Z)
    if not ParachutingNewIni.tbParachuteOpen.bHad then
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
end

return HumanMovementStateParachuting