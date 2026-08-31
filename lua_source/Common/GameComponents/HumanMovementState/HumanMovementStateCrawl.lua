local luaclass = require("luaclass")
local HumanMovementStateBase = dynamic_require("HumanMovementStateBase")
local HumanMovementStateCrawl = luaclass("HumanMovementStateCrawl", HumanMovementStateBase)

HumanMovementStateCrawl.DealyEnableInputTimer = nil

function HumanMovementStateCrawl:UnInit()

end

function HumanMovementStateCrawl:Active()
    self.pOwnerActor.bCanFalling = false 
    -- pUEActor.bIsCrouched = true
    -- pUEActor.CharacterMovement.bWantsToCrouch = true
    -- 由于站到趴胶囊体改变太大会变成falling 将MaxStepHeight这个值改大会避免这个问题
    -- pUEActor.CharacterMovement.MaxStepHeight = 60
    self:BlendCameraWithTime()
    local pUEActor = self.pOwnerActor
    pUEActor.CrawlCapsule:SetCollisionEnabled(ECollisionEnabled.QueryAndPhysics)
    self.nCapsuleRadius = self.pOwnerActor.CapsuleComponent:GetUnscaledCapsuleRadius()
    -- pUEActor.CapsuleComponent:SetCapsuleRadius(20)
    self:ChangeCapsule()
    self.MaxStepHeight = pUEActor.CharacterMovement.MaxStepHeight
    self.WalkableFloorAngle = pUEActor.CharacterMovement.WalkableFloorAngle
    self.CrawlMoveAlongFloorAngle = pUEActor.CharacterMovement.CrawlMoveAlongFloorAngle
    pUEActor.CharacterMovement.MaxStepHeight = 30
    pUEActor.CharacterMovement.WalkableFloorAngle  = 30
    pUEActor.CharacterMovement:SetCrawlMoveAlongFloorAngle(30)
end

function HumanMovementStateCrawl:UnActive()
    local pUEActor = self.pOwnerActor
    pUEActor.CrawlCapsule:SetCollisionEnabled(ECollisionEnabled.NoCollision)
    -- pUEActor.CapsuleComponent:SetCapsuleRadius(self.nCapsuleRadius)
    pUEActor.CharacterMovement.MaxStepHeight = self.MaxStepHeight
    pUEActor.CharacterMovement.WalkableFloorAngle  = self.WalkableFloorAngle    
    pUEActor.CharacterMovement:SetCrawlMoveAlongFloorAngle(self.CrawlMoveAlongFloorAngle)

    self.pOwnerActor.bCanFalling = true
    -- pUEActor.bIsCrouched = false
    -- pUEActor.CharacterMovement.MaxStepHeight = 45
   
end

return HumanMovementStateCrawl