local luaclass              = require("luaclass")
local HumanMovementStateBase             = dynamic_require("HumanMovementStateBase")
local HumanMovementJumpSpeelWall    = luaclass("HumanMovementJumpSpeelWall", HumanMovementStateBase)
local SelfAnimationHelper = require("SelfAnimationHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanJumpTypeDef = require("HumanJumpTypeDef")
local SelfEventHelper = require("SelfEventHelper")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local HumanMovementStateType = require("HumanMovementStateType")
local Timer = require("Timer")
local HumanWeaponMisc = require("HumanWeaponMisc")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local AIHelper = require("AIHelper")
local PropName = require("PropName")
local AnimDef = require("AnimDef")
local HumanWeaponType = HumanWeaponMisc.Type

local WallLocation = Vector()
local WallRotation = Rotator()

HumanMovementJumpSpeelWall.bInJumping = false
HumanMovementJumpSpeelWall.tbJumpRootMotion = nil
HumanMovementJumpSpeelWall.tbJumpRootMotionNew = nil

local JumpMontage = {
    [HumanJumpTypeDef.JumpLow] = AnimDef.JUMP_LOW,
    [HumanJumpTypeDef.JumpMid] = AnimDef.JUMP_MID,
    [HumanJumpTypeDef.JumpHeight] = AnimDef.JUMP_HEIGHT,
    [HumanJumpTypeDef.JumpMiddleStand] = AnimDef.JUMP_MID_STAND,
    [HumanJumpTypeDef.JumpHeightStand] = AnimDef.JUMP_HEIGHT_STAND,
}

local JumpMontageNew = {
    [HumanJumpTypeDef.JumpLow] = AnimDef.JUMP_LOW_NEW,
    [HumanJumpTypeDef.JumpMid] = AnimDef.JUMP_MID_NEW,
    [HumanJumpTypeDef.JumpHeight] = AnimDef.JUMP_HEIGHT_NEW,
    [HumanJumpTypeDef.JumpMiddleStand] = AnimDef.JUMP_MID_STAND_NEW,
    [HumanJumpTypeDef.JumpHeightStand] = AnimDef.JUMP_HEIGHT_STAND_NEW,
}

local SPEEL_ALL_TIMER= "SpeelAllTimer"
local SPEEL_TIMER= "SpeelTimer"


local function RootMotionJump(nType)
    local c2d_RootMotionJump =
    {
        jump_type = nType
    }
    if GlobalVariableSystem.bUseNewSpeel then
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_RootMotionJumpNew, c2d_RootMotionJump)
    else
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_RootMotionJump, c2d_RootMotionJump)
    end
end

local function ClearSpeel(self)
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor

    pUEActor.bCanFalling = true
    -- Owner:OnStopMove(false)
    pUEActor.CapsuleComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_WorldStatic, ECollisionResponse.ECR_Block)

    local CharacterMovement = pUEActor.CharacterMovement

    CharacterMovement:SetMovementMode(EMovementMode.MOVE_Walking, 0)

    if self.bInJumping then
        if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsClient() then
            RootMotionJump(HumanJumpTypeDef.None)
        end

        if GlobalVariableSystem.bUseNewSpeel then
            self:SetTargetLocation()
        end
    end
    self.bInJumping = false
end

local function OnMontageEnded(self)
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor
    pUEActor:StopAnimMontage(nil)

    local bAIJumpWall = false
    if GlobalVariableSystem:IsServerLogic() then
        bAIJumpWall = AIHelper.IsAIControlled(GamePlayer)
    end

    if not bAIJumpWall and GlobalVariableSystem:IsDedicatedServer() then
        ClearSpeel(self)
        return
    end

    local nJumpType = self.tbJumpRootMotion.jump_type
    if nJumpType ~= HumanJumpTypeDef.None then
        ClearSpeel(self)
        self.Owner:RequestChangeMovement(HumanMovementStateType.UpRight_State)
    end
    
    log("On Speel End")
end

local function OnNewMontageEnded(self)
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor
    pUEActor:StopAnimMontage(nil)

    --重置碰撞以及切到站立
    ClearSpeel(self)
    self.Owner:RequestChangeMovement(HumanMovementStateType.UpRight_State)
end

local function OnSpeelEnd(self)
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor


    pUEActor.CapsuleComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_WorldStatic, ECollisionResponse.ECR_Block)

    if GlobalVariableSystem:IsClient() then 
        local CharacterMovement = pUEActor.CharacterMovement
        CharacterMovement:SetMovementMode(EMovementMode.MOVE_Falling, 0)
    end
end

function HumanMovementJumpSpeelWall:DoJumpSpeel(nJumpType)
    if nJumpType < 0 then
        nJumpType = nJumpType * -1
    end

    if nJumpType == HumanJumpTypeDef.None then
        return
    end
    self.bInJumping = true
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor


    -- Owner:OnStopMove(true)

    local CharacterMovement = pUEActor.CharacterMovement
    CharacterMovement.MaxFlySpeed = 0

    pUEActor.CapsuleComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_WorldStatic, ECollisionResponse.ECR_Ignore)
    CharacterMovement:SetMovementMode(EMovementMode.MOVE_Flying, 0)

    pUEActor.bCanFalling = false

    local bIsClient = GlobalVariableSystem:IsClient()
    pUEActor:StopAnimMontage(nil)
    local bAIJumpWall = false
    if GlobalVariableSystem:IsServerLogic() then
        bAIJumpWall = AIHelper.IsAIControlled(GamePlayer)
    end

    local fClimbRate = GamePlayer.HumanBattlePropertyComponent:GetProp(PropName.nClimbCoefficient)
    log("HumanMovementJumpSpeelWall GamePlayer ClimbRate:", fClimbRate)

    if(bIsClient or bAIJumpWall ) then

        local _Ret, _nAllTime, pMontage = SelfAnimationHelper:PlayHumanAnimation(GamePlayer, JumpMontage[nJumpType], fClimbRate)
        if not pMontage then
            logerror("Error Anim Key", JumpMontage[nJumpType])
            return
        end
        if bIsClient then  
            CharacterMovement:DiscardPendingMove()
        end

        local nSpeelTime, nMontageTime= ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.ON_SPEEL_END)
        nSpeelTime = nSpeelTime / fClimbRate
        nMontageTime = nMontageTime / fClimbRate

        Timer.StartOwnerTimer(self, SPEEL_TIMER, OnSpeelEnd, nSpeelTime)
        Timer.StartOwnerTimer(self, SPEEL_ALL_TIMER, OnMontageEnded, nMontageTime)
        -- logdebug("nSpeelTime", nSpeelTime, "nMontageTime", nMontageTime)
        -- local bRet, WallLocation, WallRotation = pUEActor:GetWallLocation(nJumpType)
        -- if bRet then 

        local tbJumpRootMotion = self.tbJumpRootMotion
        WallLocation.X = tbJumpRootMotion.wall_position.X
        WallLocation.Y = tbJumpRootMotion.wall_position.Y
        WallLocation.Z = tbJumpRootMotion.wall_position.Z
        -- logdebug("WallLocation.X", WallLocation.X, "WallLocation.Y", WallLocation.Y)
        WallRotation.Yaw = tbJumpRootMotion.yaw

        self:SetSpellLocation()
        -- end
    else  
        local szAnimation = SelfAnimationHelper:GetHumanAnimation(GamePlayer, JumpMontage[nJumpType])
        local pMontage = szAnimation:load()
        -- local nAllTime = ExtendBlueprintFunctions.GetMontageLength(pMontage)
        local nSpeelTime, nMontageTime= ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.ON_SPEEL_END)

        nSpeelTime = nSpeelTime / fClimbRate
        nMontageTime = nMontageTime / fClimbRate

        Timer.StartOwnerTimer(self, SPEEL_TIMER, OnSpeelEnd, nSpeelTime + 0.1)
        Timer.StartOwnerTimer(self, SPEEL_ALL_TIMER, OnMontageEnded, nMontageTime)        
    end

end

function HumanMovementJumpSpeelWall:SetSpellLocation()
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor
    pUEActor:K2_SetActorLocation(WallLocation, false, false)
end 

function HumanMovementJumpSpeelWall:SetTargetLocation()
    local Owner      = self.Owner
    local GamePlayer = Owner.Owner

    --强制设置最终位置
    local target_position = self.tbJumpRootMotionNew.target_position
    if target_position then
        GamePlayer:SetLocation(target_position.X, target_position.Y, target_position.Z)
    end
end

function HumanMovementJumpSpeelWall:DoJumpSpeelNew()
    local nJumpType = self.tbJumpRootMotionNew.jump_type
    if nJumpType < 0 then
        nJumpType = nJumpType * -1
    end

    if nJumpType == HumanJumpTypeDef.None then
        return
    end

    self.bInJumping = true
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    local pUEActor = GamePlayer.pUEActor

    local CharacterMovement = pUEActor.CharacterMovement
    CharacterMovement.MaxFlySpeed = 0

    pUEActor.CapsuleComponent:SetCollisionResponseToChannel(ECollisionChannel.ECC_WorldStatic, ECollisionResponse.ECR_Ignore)
    CharacterMovement:SetMovementMode(EMovementMode.MOVE_Flying, 0)

    pUEActor.bCanFalling = false
    pUEActor:StopAnimMontage(nil)

    local fClimbRate = GamePlayer.HumanBattlePropertyComponent:GetProp(PropName.nClimbCoefficient)
    log("HumanMovementJumpSpeelWall GamePlayer ClimbRate:", fClimbRate)
--[[
    pUEActor:DrawDebugSpeelInfo(Rotator{Pitch = 0, Yaw = self.tbJumpRootMotionNew.yaw, Roll = 0}, 
    Vector{X = self.tbJumpRootMotionNew.speel_position.X, Y = self.tbJumpRootMotionNew.speel_position.Y, Z = self.tbJumpRootMotionNew.speel_position.Z},
    Vector{X = self.tbJumpRootMotionNew.target_position.X, Y = self.tbJumpRootMotionNew.target_position.Y, Z = self.tbJumpRootMotionNew.target_position.Z},
    Vector{X = self.tbJumpRootMotionNew.expect_start_position.X, Y = self.tbJumpRootMotionNew.expect_start_position.Y, Z = self.tbJumpRootMotionNew.expect_start_position.Z})
]]

    local szAnimKey = JumpMontageNew[nJumpType]
    local _Ret, _nAllTime, pMontage = SelfAnimationHelper:PlayHumanAnimation(GamePlayer, szAnimKey, fClimbRate)
    if not pMontage then
        logerror("Error Anim Key", szAnimKey)
        return
    end

    local bIsClient = GlobalVariableSystem:IsClient()
    if bIsClient then  
        CharacterMovement:DiscardPendingMove()
    end

    local _szMontage, tbTemplate = SelfAnimationHelper:GetHumanAnimation(GamePlayer, szAnimKey)

    local nScaledTime = tbTemplate.fEndRootMotionTime / fClimbRate
    Timer.StartOwnerTimer(self, SPEEL_ALL_TIMER, OnNewMontageEnded, nScaledTime)
    
    local tbTargetPos      = self.tbJumpRootMotionNew.target_position
    local tbExpectStartPos = self.tbJumpRootMotionNew.expect_start_position

    local nYaw = self.tbJumpRootMotionNew.yaw

    local pTargetPos = KismetMathLibrary.MakeTransform(
                            Vector{X=tbTargetPos.X, Y=tbTargetPos.Y, Z=tbTargetPos.Z}, 
                            Rotator{Roll=0,Pitch=0,Yaw=nYaw}, 
                            Vector{X=1, Y=1, Z=1})

    local pExpectStartPos = KismetMathLibrary.MakeTransform(
                            Vector{X=tbExpectStartPos.X, Y=tbExpectStartPos.Y, Z=tbExpectStartPos.Z}, 
                            Rotator{Roll=0,Pitch=0,Yaw=nYaw}, 
                            Vector{X=1, Y=1, Z=1})

    pUEActor.CharacterMovement:PlayRootMotionWithDeltaCorrection(
                            tbTemplate.tbRootMotionVectors, 
                            pExpectStartPos,
                            tbTemplate.fRootMotionStartCorrectTime,
                            Vector2D{X = tbTemplate.tbRootMotionCorrectSectionTimeRange[1], Y = tbTemplate.tbRootMotionCorrectSectionTimeRange[2]}, 
                            pTargetPos, 
                            fClimbRate,
                            false
                            )
--[[
    pUEActor.CharacterMovement:PlayRootMotion(
        tbTemplate.tbRootMotionVectors, 
        0.0,
        Vector{X=tbExpectStartPos.X, Y=tbExpectStartPos.Y, Z=tbExpectStartPos.Z}
    )
]]
end

function HumanMovementJumpSpeelWall:Active(tbParams)
    if not self.EventHelper then
        self.EventHelper = SelfEventHelper()
    end
    local Owner   = self.Owner
    local GamePlayer = Owner.Owner
    -- self.nCapsuleRadius = self.pOwnerActor.CapsuleComponent:GetUnscaledCapsuleRadius()
    -- self.pOwnerActor.CapsuleComponent:SetCapsuleRadius(20, false)
    -- self:ChangeCapsule()
    if not GlobalVariableSystem.bUseNewSpeel then
        local CharacterMovement = GamePlayer.pUEActor.CharacterMovement
        CharacterMovement.bEnableClientAdjustPosition = false
        CharacterMovement.bCorrectiveRootMotion = true
        CharacterMovement.bIgnoreClientMovementErrorChecksAndCorrection = true
        -- CharacterMovement.bIgnoreFallingInRootmotion = true
    end

    local HumanWeaponComponent = GamePlayer.HumanWeaponComponent
    if not GlobalVariableSystem:IsServerLogic() then
        local State = HumanWeaponComponent:GetCurrentState()
        if State == HumanWeaponStateDef.UNHOLDING then
            local StateHelper = HumanWeaponComponent.StateHelper
            StateHelper:ChangeState(HumanWeaponStateDef.UNHOLDED, true)
        end
        if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf and HumanWeaponComponent:IsReloading() then
            HumanWeaponComponent:CancelReload()
        end
    end
end

function HumanMovementJumpSpeelWall:UnActive()
    -- self.pOwnerActor.CapsuleComponent:SetCapsuleRadius(self.nCapsuleRadius, false)
    Timer.StopOwnerAllTimer(self, true)
    ClearSpeel(self)

    local Owner   = self.Owner
    local GamePlayer = Owner.Owner

    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    if not GlobalVariableSystem.bUseNewSpeel then
        local CharacterMovement = GamePlayer.pUEActor.CharacterMovement
        CharacterMovement.bEnableClientAdjustPosition = true
        CharacterMovement.bCorrectiveRootMotion = false
        CharacterMovement.bIgnoreClientMovementErrorChecksAndCorrection = false
        -- CharacterMovement.bIgnoreFallingInRootmotion = false
    end

    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf then
        if not GlobalVariableSystem:IsServerLogic() then
            local HumanWeaponComponent = GamePlayer.HumanWeaponComponent
            local tbWeapon = HumanWeaponComponent:GetCurrentWeapon()
            if tbWeapon and tbWeapon:IsType(HumanWeaponType.GUN) and tbWeapon:GetCurrentAmmo() == 0 then
                HumanWeaponComponent:Reload()
            end
        end
    end
end

local function OnRootMotionJump(self, tbJumpRootMotion)
    self.tbJumpRootMotion = tbJumpRootMotion
    if tbJumpRootMotion.jump_type == HumanJumpTypeDef.None and self.Owner:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then
        self.Owner:RequestChangeMovement(HumanMovementStateType.UpRight_State)
        return
    end
    if self.bInJumping then 
        return 
    end
    if tbJumpRootMotion.jump_type > 0 then
        self.Owner:RequestChangeMovement(HumanMovementStateType.Jumping_SpeelWall)
    end

    self:DoJumpSpeel(tbJumpRootMotion.jump_type)
end

local function OnRootMotionJumpNew(self, tbJumpRootMotion)
    if tbJumpRootMotion.jump_type == HumanJumpTypeDef.None and self.Owner:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then
        self.Owner:RequestChangeMovement(HumanMovementStateType.UpRight_State)
        return
    end

    if self.bInJumping then 
        return 
    end

    self.tbJumpRootMotionNew = tbJumpRootMotion

    if tbJumpRootMotion.jump_type > 0 then
        self.Owner:RequestChangeMovement(HumanMovementStateType.Jumping_SpeelWall)
    end

    self:DoJumpSpeelNew()
end

function HumanMovementJumpSpeelWall:UnInit(tbOwner)
    Timer.StopOwnerAllTimer(self, true)

    if self.EventHelper then
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil
    end

    HumanMovementJumpSpeelWall.super.UnInit(self, tbOwner)
end

function HumanMovementJumpSpeelWall:Init(tbOwner)
    HumanMovementJumpSpeelWall.super.Init(self, tbOwner)

    self.Owner.OnRootMotionJump:Bind(OnRootMotionJump, self)
    self.Owner.OnRootMotionJumpNew:Bind(OnRootMotionJumpNew, self)
end

function HumanMovementJumpSpeelWall:GetYaw()
    if GlobalVariableSystem.bUseNewSpeel then
        return self.tbJumpRootMotionNew.yaw
    else
        return self.tbJumpRootMotion.yaw
    end
end

return HumanMovementJumpSpeelWall