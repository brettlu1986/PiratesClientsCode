local luaclass              = require("luaclass")
local HumanMovementStateBase             = dynamic_require("HumanMovementStateBase")
local HumanMovementStateFalling    = luaclass("HumanMovementStateFalling", HumanMovementStateBase)

function HumanMovementStateFalling:Active(tbParams)
    local pUEActor = self.pOwnerActor
    local CharacterMovement = pUEActor.CharacterMovement
    log("[parachuting] HumanMovementStateFalling:Active", self.GamePlayer.szName, self.GamePlayer.nPlayerId)
    pUEActor.bUseControllerRotationYaw = true
    -- if not GlobalVariableSystem:IsClient() then 
        pUEActor:SetActiveChildComponent(false)
    -- end
    CharacterMovement:SetMaxWalkSpeed(0)
    -- CharacterMovement.MaxWalkSpeed = 0
    CharacterMovement.GravityScale = 0
    pUEActor.CharacterMovement:SetComponentTickEnabled(true)
    pUEActor:SetReplicateMovement(false)
end

function HumanMovementStateFalling:UnActive()
    log("[parachuting] HumanMovementStateFalling:UnActive", self.GamePlayer.szName, self.GamePlayer.nPlayerId)
    -- if not GlobalVariableSystem:IsClient() then 
    self.pOwnerActor:SetActiveChildComponent(true)
    -- end
    self.pOwnerActor:SetReplicateMovement(true)
end

return HumanMovementStateFalling