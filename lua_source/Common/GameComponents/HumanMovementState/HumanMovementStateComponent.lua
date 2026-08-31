local luaclass          = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local HumanMovementStateComponent= luaclass("HumanMovementStateComponent", GameComponentBase)
local HumanMovementStateType = require("HumanMovementStateType")
local PropName = require("PropName")
local HumanMovementSpeedDataTable = require("HumanMovementSpeedDataTable")
local GameObjectTypeDef = require("GameObjectTypeDef")
local CommonEventDef = require("CommonEventDef")
local SelfEventHelper = require("SelfEventHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local PropUtil = require("PropUtil")
local DamageTypeEx = require("DamageTypeEx")
local HumanFallingDamageIni = require("HumanFallingDamageIni")
local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local SelfAnimationHelper = require("SelfAnimationHelper")
local Timer = require("Timer")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
-- local Analytics = require("DungeonAnalyticsProtoNames")
local HumanJumpTypeDef = require("HumanJumpTypeDef")
local HumanMovementStateHelper = require("HumanMovementStateHelper")
local TeamWatchServerHelper = require("TeamWatchServerHelper")
local HumanMovementIni = require("HumanMovementIni")
local HumanWeaponHelper = require("HumanWeaponHelper")
local AnimDef = require("AnimDef")

local CHANGE_POSE_TIMER = "ChangePoseTimer"

-- local AIHelper = require("AIHelper")


local LuaDelegate = require("LuaDelegate")

-- local AnalyticsStateType = Analytics.HumanStateTime_StateType


local ENUM_Direction = {
    Forward = 1,
    LeftRight = 2,
    Back = 3,
}

HumanMovementStateComponent.OnDirectionChanged = nil
HumanMovementStateComponent.nDirection = ENUM_Direction.Forward
HumanMovementStateComponent.tbCurrentPoseData = nil
HumanMovementStateComponent.rRunState = 0
HumanMovementStateComponent.EventHelper = nil

HumanMovementStateComponent.bEnableMove = true
HumanMovementStateComponent.bStopRun = false

HumanMovementStateComponent.nSpeedRatio = 1
HumanMovementStateComponent.nBaseSpeed = 0
HumanMovementStateComponent.rSpeedBuffRatio = nil
HumanMovementStateComponent.nWeaponSpeedFactor = 1
HumanMovementStateComponent.bLastCrawlAim = false
HumanMovementStateComponent.bIsCrawlMoving = false
-- Falling
HumanMovementStateComponent.bStartFalling = false
HumanMovementStateComponent.nStartFallingZ = 0
HumanMovementStateComponent.bParachutingEnd = true
HumanMovementStateComponent.rHumanJumpBuffConfig = nil
HumanMovementStateComponent.rHumanJumpBuff = nil
HumanMovementStateComponent.tbBaseHumanFallConfig = nil

HumanMovementStateComponent.rJumpType    = nil
HumanMovementStateComponent.rJumpTypeNew = nil
HumanMovementStateComponent.nJumpType    = 0

HumanMovementStateComponent.bIsRescuing = false 

HumanMovementStateComponent.nSwimmingStamina = 0 
HumanMovementStateComponent.bIsCrouching = false 

HumanMovementStateComponent.bSelfReady = false 

HumanMovementStateComponent.OnRootMotionJump = nil
HumanMovementStateComponent.OnRootMotionJumpNew = nil

HumanMovementStateComponent.tbActiveParams = nil
HumanMovementStateComponent.tbUnActiveParams = nil
HumanMovementStateComponent.bOnActorCreated = false

local StateChangeAnimation = {
    [HumanMovementStateType.UpRight_State * 100 + HumanMovementStateType.Crawl_State] = AnimDef.UPRIGHT_TO_CRAWL,
    [HumanMovementStateType.Crawl_State * 100 + HumanMovementStateType.UpRight_State] = AnimDef.CRAWL_TO_UPRIGHT,
    [HumanMovementStateType.Crouch_State * 100 + HumanMovementStateType.Crawl_State] = AnimDef.CROUCH_TO_CRAWL,
    [HumanMovementStateType.Crawl_State * 100 + HumanMovementStateType.Crouch_State] = AnimDef.CRAWL_TO_CROUCH
}

local CrouchChangeAnimation = {
    [HumanMovementStateType.UpRight_State * 100 + HumanMovementStateType.Crouch_State] = AnimDef.UPRIGHT_TO_CROUCH,
    [HumanMovementStateType.Crouch_State * 100 + HumanMovementStateType.UpRight_State] = AnimDef.CROUCH_TO_UPRIGHT,
}

local AimStateChangeAnimation = {
    [HumanMovementStateType.UpRight_State * 100 + HumanMovementStateType.Crawl_State] = AnimDef.AIM_UPRIGHT_TO_CRAWL,
    [HumanMovementStateType.Crawl_State * 100 + HumanMovementStateType.UpRight_State] = AnimDef.AIM_CRAWL_TO_UPRIGHT,
    [HumanMovementStateType.Crouch_State * 100 + HumanMovementStateType.Crawl_State] = AnimDef.AIM_CROUCH_TO_CRAWL,
    [HumanMovementStateType.Crawl_State * 100 + HumanMovementStateType.Crouch_State] = AnimDef.AIM_CRAWL_TO_CROUCH
}

local AimCrouchChangeAnimation = {
    [HumanMovementStateType.UpRight_State * 100 + HumanMovementStateType.Crouch_State] = AnimDef.AIM_UPRIGHT_TO_CROUCH,
    [HumanMovementStateType.Crouch_State * 100 + HumanMovementStateType.UpRight_State] = AnimDef.AIM_CROUCH_TO_UPRIGHT,
}

local ME_PREFIX = "Me"

local function DirectionChanged(self, nDirection, nAngle)
    local pUEActor = self.Owner.pUEActor

    if not pUEActor then  
        return 
    end

    self.nDirection = nDirection
    if not self.tbCurrentPoseData then
        return
    end
    self:SetBaseSpeed(self.tbCurrentPoseData.nSpeed)
    local nSpeed = 1
    if nDirection == ENUM_Direction.Forward then
        if self.rRunState:Get() then
            nSpeed =  self.tbCurrentPoseData.nRun
        else
            nSpeed = 1
        end
    elseif nDirection == ENUM_Direction.LeftRight then
        nSpeed = self.tbCurrentPoseData.nLeftRight
    else
        nSpeed = self.tbCurrentPoseData.nBack
    end

    self:SetSpeedRatio(nSpeed)
end

function HumanMovementStateComponent:OnStopMove(bStop)
    if bStop and self.Owner.pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling then
        return
    end
    self.bEnableMove = not bStop
    if bStop then
        self:SetBaseSpeed(0)
        --self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
    elseif self.tbCurrentPoseData then
        -- self.nSpeed:SetOriginValue(self.tbCurrentPoseData.nSpeed)
        self:SetBaseSpeed(self.tbCurrentPoseData.nSpeed)
    end
end


local function SendToServerEnableHumanMove(bEnable)
    local c2d_EnableHumanMove =
    {
        enable = bEnable
    }
    NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_EnableHumanMove, c2d_EnableHumanMove)
end 
-- local function SendToServerChangeGridType(nRegionType)
--     local c2d_ChangeSwimmingType =
--     {
--         region_type = nRegionType
--     }
--     NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDC.c2d_ChangeSwimmingType, c2d_ChangeSwimmingType)
-- end 


local function OnEnableMove(self, bEnable)
    local GamePlayer = self.Owner
    if bEnable then
        if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf and not GlobalVariableSystem:IsServerLogic() then
            SendToServerEnableHumanMove(bEnable)
        end
        self:OnStopMove(not bEnable)
    end
end

local function IsOwnerAiming(self)
    local WeaponComponent = self.Owner.HumanWeaponComponent
    return WeaponComponent and WeaponComponent:IsAiming() 
end

local function IsSelfSniperWeapon(self)
    local GamePlayer = self.Owner
    local bSniperAim = HumanWeaponHelper.IsCurrentSniperAim(GamePlayer)
    if GamePlayer.ObjectType == GameObjectTypeDef.PlayerSelf and bSniperAim then  
        return true
    end
    return false
end

local function GetStateChangeAnimation(self, bStateChange, nOldState, nNewState)
    local bAiming = IsOwnerAiming(self)
    local bSelfSniperWeapon = IsSelfSniperWeapon(self)
    local nAnimIndx = nOldState * 100 + nNewState
    local szAnimation = nil
    if bStateChange then  
        szAnimation = bAiming and AimStateChangeAnimation[nAnimIndx] or StateChangeAnimation[nAnimIndx]
    else  
        szAnimation = bAiming and AimCrouchChangeAnimation[nAnimIndx] or CrouchChangeAnimation[nAnimIndx]
    end
    if bAiming and bSelfSniperWeapon and szAnimation then  
        return ME_PREFIX .. szAnimation
    else  
        return szAnimation
    end
end

local function PlayStateChangeAnimation(self, OldState, NewState)
    local szAnimKey = GetStateChangeAnimation(self, true, OldState, NewState)
    if not szAnimKey then  
        local bStandLowSpeed = self.Owner.pUEActor.Speed <= 0 
        if bStandLowSpeed  then 
            szAnimKey = GetStateChangeAnimation(self, false, OldState, NewState)
        end
    else
        self:OnStopMove(true)
    end 
    if szAnimKey then  
        self.bIsCrouching = true
        local AnimInstance = self.Owner.pUEActor.Mesh:GetAnimInstance()
        AnimInstance.IsChangeState = true
        local HumanWeaponComponent = self.Owner.HumanWeaponComponent
        local NeedStopAllMontage = not (HumanWeaponComponent:IsReloading() or HumanWeaponComponent:IsAttacking())
        local _Ret, nTimer = SelfAnimationHelper:PlayHumanAnimation(self.Owner, szAnimKey, 1.0, NeedStopAllMontage, self)
        -- self.EventHelper:RegisterCppDelegate(self.Owner.pUEActor.Mesh:GetAnimInstance().OnMontageEnded, self, OnStateMontageEnded)
        Timer.StartOwnerTimer(self, CHANGE_POSE_TIMER, function() 
            if self.bIsCrouching then  
                self.bIsCrouching = false 
                AnimInstance.IsChangeState = false
                -- self.Owner.pUEActor:SetUseDownBody(false)
            end 
            OnEnableMove(self, true)            
        end, nTimer)
    end    
    -- OnEnableMove(self, true)
end 

local function OnRepMovementState(self, _Property, nMovementState)
    local PlayerProperty = self.Owner.pUEActor.PlayerProperty
    if not PlayerProperty then
        return
    end
    
    if self.bIsDying and nMovementState ~= HumanMovementStateType.Dying_State then  
        if nMovementState ~= HumanMovementStateType.Swimming then 
            return 
        end
    end 

    self.StateHelper:OnRepMovementState(nMovementState)
    DirectionChanged(self, self.nDirection)
    PlayerProperty:SetMovementState(nMovementState)
end

local function OnHumanRunStatChanged(self, _Property, bHumanRunState)
    if self.Owner.pUEActor then 
        self.Owner.pUEActor.bRun = bHumanRunState
    end
    
    if bHumanRunState then  
        self.nDirection = ENUM_Direction.Forward
    end 
    DirectionChanged(self, self.nDirection)
end

local function OnHumanWeaponOnEquipid(self, nServerInstanceId)
    if self.Owner:GetServerInstanceId() ~= nServerInstanceId then
        return
    end

    local nWeaponSpeedFactor = self.Owner.HumanWeaponComponent:GetWeaponSpeedFactor()

    if self.nWeaponSpeedFactor == nWeaponSpeedFactor then
        return
    end
    -- logdebug("nWeaponSpeedFactor", nWeaponSpeedFactor)
    self.nWeaponSpeedFactor = nWeaponSpeedFactor
    self:OnSpeedChanged()
end

local function RefreshWeaponSpeedFactor(self)
    local HumanWeaponComponent = self.Owner.HumanWeaponComponent
    if HumanWeaponComponent:IsUnmovedWeaponState() and self:GetCurrentState() == HumanMovementStateType.Crawl_State then
        self.bStopRun = true
        self:SetBaseSpeed(0)
    elseif self.bStopRun then
        if self.tbCurrentPoseData then
            self:SetBaseSpeed(self.tbCurrentPoseData.nSpeed)
        end
        -- ChangeMovementState(self, self.nMovementState)
        -- self:RequestChangeMovement(self.nMovementState)
        self.bStopRun = false
    end
    OnHumanWeaponOnEquipid(self, self.Owner:GetServerInstanceId())
end 

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if self.Owner:GetServerInstanceId() ~= Owner:GetServerInstanceId() then
        return
    end
    RefreshWeaponSpeedFactor(self)
end

local function OnWeaponChanged(self, nNewWeapon, nLastWeapon, nInstanceId)
    if self.Owner:GetServerInstanceId() ~= nInstanceId then
        return
    end
    RefreshWeaponSpeedFactor(self)
end

local function OutPutUEMovmentChangedLog(self, pUEActor, MovementMode)
    if GlobalVariableSystem:IsServerLogic() then
        return
    end 
    if self.Owner.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end        
    if MovementMode == EMovementMode.MOVE_Falling then
        local CharacterMovement = pUEActor.CharacterMovement
        local pLocation = self.Owner:GetLocation()
        local pFloorResult = CharacterMovement:K2_FindFloor(pLocation)
        log("HumanMovementStateComponent is falling: ", self.Owner.nPlayerId, 
            pFloorResult.bBlockingHit, pFloorResult.bWalkableFloor)
        if isvalidhandle(pFloorResult.HitResult.Actor) then
            log("HumanMovementStateComponent is falling: Find Floor actor", self.Owner.nPlayerId,
                KismetSystemLibrary.GetDisplayName(pFloorResult.HitResult.Actor)) 
        end
    -- else
    --     log("HumanMovementStateComponent not falling", self.Owner.nPlayerId, enumtoint(MovementMode))
    end
end

local function OnUEMovementChanged(self, pUEActor, PrevMovementMode, PrevCustomMode)
    local CurrentMovementMode = pUEActor.CharacterMovement.MovementMode
    -- logdebug("CurrentMovementMode", enumtoint(CurrentMovementMode))
    if GlobalVariableSystem:IsServerLogic() then  
        TeamWatchServerHelper.NotifyViewersMovementModeChanged(self.Owner, PrevMovementMode, CurrentMovementMode)
    end

    -- 临时log
    OutPutUEMovmentChangedLog(self, pUEActor, CurrentMovementMode)

    if not GlobalVariableSystem:IsServerLogic() or self:GetVehicleState() ~= HumanVehicleStateDef.None then
        return 
    end 

    if self:IsInParachuting() then
        return
    end

    if CurrentMovementMode == EMovementMode.MOVE_Falling and self:GetCurrentState() ~= HumanMovementStateType.Vehicle then
        self.bStartFalling = true
        local _, _, Z = self.Owner:GetLocationXYZ()
        self.nStartFallingZ = Z
        -- destroyUserData(ActorLocation)
        log("FallingDamage StartZ", self.nStartFallingZ, self.Owner.szName, self.Owner.nPlayerId)
    elseif CurrentMovementMode == EMovementMode.MOVE_Swimming  then
        self.bStartFalling = false 
    else
        if self.bStartFalling then
            local _, _, Z = self.Owner:GetLocationXYZ()
            local nActorZ = Z
            -- destroyUserData(ActorLocation)
            local JumpZ = math.abs(nActorZ - self.nStartFallingZ)
            local tbHumanFallingDamage = HumanFallingDamageIni.tbHumanFallingDamage
            log("FallingDamage End Jump JumpZ", JumpZ, "nActorZ", nActorZ, tbHumanFallingDamage.nFallingHeight, self.Owner.szName, self.Owner.nPlayerId)
            if JumpZ > tbHumanFallingDamage.nFallingHeight then
                local nDamageFactor = tbHumanFallingDamage.nDamageFactor * self.Owner.HumanBattlePropertyComponent:GetProp(PropName.nResistFallDownCoefficient)
                local nDamage = (JumpZ - tbHumanFallingDamage.nFallingHeight) / nDamageFactor
                log("FallingDamage Damage ", self.Owner.szName, nDamage, tbHumanFallingDamage.nDamageFactor, self.Owner.nPlayerId, "nDamageFactor", nDamageFactor)
                PropUtil.ApplyDamage(self.Owner, nil, DamageTypeEx.FALLING, nDamage, nil)
            end
            self.bStartFalling = false
        end
    end
end

--  IsMoving
local function OnHumanMoveStateChanged(self, bIsMoving)
    --暂时不同步这个walking， 频率太高了， 目前观战基本不关注这个，等需要时候再加回来
    -- if GlobalVariableSystem:IsServerLogic() then  
    --     local WeaponComponent = self.Owner.HumanWeaponComponent 
    --     local bAimWeapon = WeaponComponent and WeaponComponent:IsHaveAimWeapon() 
    --     if bAimWeapon then 
    --         TeamWatchServerHelper.NotifyViewersIsWalkingNow(self.Owner, bIsMoving)
    --     end
    -- end

    if self:GetCurrentState() == HumanMovementStateType.Crawl_State then
        self.bIsCrawlMoving = bIsMoving
        if GlobalVariableSystem:IsClient() then
            local WeaponComponent = self.Owner.HumanWeaponComponent
            if not WeaponComponent then  
                return 
            end 
            if WeaponComponent:IsUnmovedWeaponState()  then
                return
            end
            if not WeaponComponent:IsHaveAimWeapon(self) then
                return
            end
            local bIsAim = WeaponComponent:IsAiming()
            if bIsMoving then
                if bIsAim then 
                    self.bLastCrawlAim = bIsAim
                    self.EventHelper:FireEvent(CommonEventDef.EV_MOVEMENT_CRAWL_CHANGE_AIM_STATE, false)
                end
            else
                if not bIsAim and self.bLastCrawlAim then
                    self.EventHelper:FireEvent(CommonEventDef.EV_MOVEMENT_CRAWL_CHANGE_AIM_STATE, true)
                    self.bLastCrawlAim = false
                end
            end
        end
    else
        self.bIsCrawlMoving = false
    end
end

local function OnRootMotionJump(self, _Property, tbHumanRootMotionJump)
    if self:IsInParachuting() then  
        return 
    end 
    self.OnRootMotionJump:Fire(tbHumanRootMotionJump)
end

local function OnRootMotionJumpNew(self, _Property, tbHumanRootMotionJump)
    if self:IsInParachuting() then  
        return 
    end 
    self.OnRootMotionJumpNew:Fire(tbHumanRootMotionJump)
end

-- local function OnPlayerSelfReady(self)
--     self.bSelfReady = true
-- end 

local function IsSwimmingVolume(nRegionType)
    if nRegionType ==EPiratesGridRegionType.Ocean or nRegionType ==EPiratesGridRegionType.Port or nRegionType ==EPiratesGridRegionType.Lake then 
        return true
    end 
    return false 
end 

local function OnGridTypeChanged(self, tbGameObject, nRegionType)  
    if self:IsInParachuting() then  
        return 
    end 
    if(tbGameObject == self.Owner) then
        self.nRegionType = nRegionType
        self:ChangeSwimmingType(nRegionType)
        if not IsSwimmingVolume(nRegionType) then 
            if self:GetCurrentState() == HumanMovementStateType.Swimming then  
                -- self:SetMovementState(HumanMovementStateType.UpRight_State)
                self:RequestChangeMovement(HumanMovementStateType.UpRight_State)
            end 
        end 
    end        
end

local function HumanFallConfigToStr(HumanFallConfig)
    local str = string.format("{\"AirDragCoefficient\":%f,\"LateralAcceleration\":%f,\"DefaultOriginSpeed\":%f,\"LandStunTime\":%f,\"LandStunSpeedPreservation\":%f,\"JumpLateralSpeedRatio\":%f,\"JumpZVelocity\":%f,\"CustomGravityScale\":%f}", 
    HumanFallConfig.AirDragCoefficient, HumanFallConfig.LateralAcceleration, HumanFallConfig.DefaultOriginSpeed, HumanFallConfig.LandStunTime, HumanFallConfig.LandStunSpeedPreservation, HumanFallConfig.JumpLateralSpeedRatio, HumanFallConfig.JumpZVelocity, HumanFallConfig.CustomGravityScale)
    return str
end

local function ApplyHumanJumpBuff(self)
    local JumpBuffConfig = self:GetHumanJumpBuffConfig()
    local CharacterMovement = self.Owner.pUEActor.CharacterMovement
    if not CharacterMovement then 
        log("[HumanJumpBuff] HumanMovementStateComponent:ApplyHumanJumpBuff cannot find CharacterMovement")
        return
    end

    local HumanFallConfig = HumanFallConfig()
    local tbFallParams = HumanMovementIni.tbDefaultFallParams
    local CurrentFallConfig = CharacterMovement:GetHumanFallConfig()
    
    HumanFallConfig.AirDragCoefficient = tbFallParams.nAirDragCoefficient * JumpBuffConfig.air_drag_change
    HumanFallConfig.LateralAcceleration = tbFallParams.nLateralAcceleration * JumpBuffConfig.accel_change
    HumanFallConfig.DefaultOriginSpeed = tbFallParams.nDefaultOriginSpeed * JumpBuffConfig.origin_speed_change
    HumanFallConfig.LandStunTime = CurrentFallConfig.LandStunTime
    HumanFallConfig.LandStunSpeedPreservation = CurrentFallConfig.LandStunSpeedPreservation
    HumanFallConfig.JumpLateralSpeedRatio = tbFallParams.nJumpLateralSpeedRatio * JumpBuffConfig.speed_change
    HumanFallConfig.JumpZVelocity = tbFallParams.nJumpZVelocity * JumpBuffConfig.z_velocity_change
    HumanFallConfig.CustomGravityScale = tbFallParams.nCustomGravityScale * JumpBuffConfig.gravity_change

    log("[HumanJumpBuff] HumanMovementStateComponent:ApplyHumanJumpBuff to player", self.Owner.nPlayerId, "HumanFallConfig = ",HumanFallConfigToStr(HumanFallConfig))

    CharacterMovement:SetHumanFallConfig(HumanFallConfig)
end

local function OnHumanJumpBuffConfigChanged(self, _Property, NewJumpBuffConfig)
    ApplyHumanJumpBuff(self)
end

function HumanMovementStateComponent:SetParachutingEnd(bParachutingEnd)
    self.bParachutingEnd = bParachutingEnd
    if GlobalVariableSystem:IsServerLogic() then  
        if bParachutingEnd then 
            local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
            local pLocation = self.Owner:GetLocation()
            local nRealRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)   
            OnGridTypeChanged(self, self.Owner, nRealRegionType)     
        end
    end
end

function HumanMovementStateComponent:ChangeSwimmingType(nRegionType)
    if self:IsInParachuting() then  
        return 
    end 
    local CharacterMovement = self.Owner.pUEActor.CharacterMovement
    if IsSwimmingVolume(nRegionType) then  
        if self:GetCurrentState() ~= HumanMovementStateType.Swimming then  
            CharacterMovement:SetHumanPreSwimState(true)
            self.EventHelper:FireEvent(CommonEventDef.EV_NOTIFY_BOT_CHANGED_TO_SWIM, self.Owner, true)
        end
    else  
        CharacterMovement:SetHumanPreSwimState(false)
        self.EventHelper:FireEvent(CommonEventDef.EV_NOTIFY_BOT_CHANGED_TO_SWIM, self.Owner, false)
    end 
end 

function HumanMovementStateComponent:CanChangeAimInMovement()
    if self.bIsCrawlMoving then
        --趴下移动,趴下疾跑 都不能开镜
        return false
    end
    return true
end


function HumanMovementStateComponent:IsInParachuting() 
    if not self.StateHelper then  
        return false 
    end 
    return self.StateHelper:IsInParachuting() 
end 

function HumanMovementStateComponent:CanChangeState(nNewState)
    if not self.StateHelper then  
        return false 
    end 
    return self.StateHelper:CanChangeState(nNewState)
end 

function HumanMovementStateComponent:SetMovementState(nNewState, bForce)
    if not bForce and not self:CanChangeState(nNewState) then 
        return 
    end

    local rState = self.rMovementState
    if(rState) then
        rState:Set(nNewState)
    end
end

function HumanMovementStateComponent:GetCurrentState()
    if not self.StateHelper then  
        return HumanMovementStateType.UpRight_State
    end 
    return self.StateHelper:GetCurrentState()
end

function HumanMovementStateComponent:GetLastState()
    if not self.StateHelper then  
        return HumanMovementStateType.UpRight_State
    end 
    return self.StateHelper:GetLastState()
end


function HumanMovementStateComponent:SetRun(bRun)
    local rState = self.rRunState
    if(rState) then
        rState:Set(bRun)
    end
end

function HumanMovementStateComponent:GetRun()
    return self.rRunState:Get()
end

function HumanMovementStateComponent:OnCreate(Owner, tbParams)
    HumanMovementStateComponent.super.OnCreate(self, Owner, tbParams)
    self.EventHelper = SelfEventHelper()
end

function HumanMovementStateComponent:GetVehicleState() 
    local VehicleComponent = self.Owner.GameVehicleComponent
    if not VehicleComponent then
        return HumanVehicleStateDef.None
    end
    return VehicleComponent:GetVehicleState()
end 

function HumanMovementStateComponent:GetVehicleInstanceId(bIgnoreVehicleState)
    local VehicleComponent = self.Owner.GameVehicleComponent
    if not VehicleComponent then
        return 0
    end
    return VehicleComponent:GetVehicleInstanceId(bIgnoreVehicleState)
end 

function HumanMovementStateComponent:IsInVehicle()
    local VehicleComponent = self.Owner.GameVehicleComponent
    if not VehicleComponent then
        return false
    end
    return VehicleComponent:IsInVehicle()
end 

function HumanMovementStateComponent:OnActorCreated(pUEActor)
    self.bOnActorCreated = true
    HumanMovementStateComponent.super.OnActorCreated(self, pUEActor)
    self.OnRootMotionJump = LuaDelegate()
    self.OnRootMotionJumpNew = LuaDelegate()

    local rComponent = self.Owner.CustomReplicationComponent
    self.rMovementState = rComponent:BindMethod(
        PropName.HumanMovementState,
        HumanMovementStateType.UpRight_State, self, OnRepMovementState, true)
    -- logdebug("aaaaaaaaaaaaaaaaaa")
    self.rJumpType = rComponent:BindMethod(PropName.rHumanRootMotionJump,
        nil, self, OnRootMotionJump, true)

    self.rJumpTypeNew = rComponent:BindMethod(PropName.rHumanRootMotionJumpNew,
    nil, self, OnRootMotionJumpNew, true)

    -- logdebug("eeeeeeeeeeee")
    self.rRunState = rComponent:BindMethod(
        PropName.HumanRunState,
        false, self, OnHumanRunStatChanged, true)
        
    self.rSpeedBuffRatio = rComponent:BindMethod(PropName.HumanSpeedBuffRadio,
        0, self, self.OnBuffSpeedChanged, true)


    self.rHumanJumpBuffConfig = rComponent:BindMethod(PropName.rHumanJumpBuffConfig,
        nil, self, OnHumanJumpBuffConfigChanged, true)
    self.StateHelper = HumanMovementStateHelper()
    self.StateHelper:Init(self)

    self.EventHelper:RegisterCppDelegate(pUEActor.DirectionChange, self, DirectionChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_CURRENT_WEAPON_CHANGED, self, OnWeaponChanged)

    if GlobalVariableSystem:IsServerLogic() then
        self.EventHelper:RegisterEvent(CommonEventDef.EV_GRID_TYPE_CHANGED, self, OnGridTypeChanged)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_EQUIPED_SERVER, self, OnHumanWeaponOnEquipid)
        self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_ON_UNEQUIPED_SERVER, self, OnHumanWeaponOnEquipid)
    end

    local CharacterMovement = pUEActor.CharacterMovement
    self.EventHelper:RegisterCppDelegate(CharacterMovement.OnHumanMoveStateChanged, self, OnHumanMoveStateChanged)
    self.EventHelper:RegisterCppDelegate(pUEActor.MovementModeChangedDelegate, self, OnUEMovementChanged)
    OnRepMovementState(self, nil, self.rMovementState:Get())

    if self.Owner.HumanBattlePropertyComponent:GetIsDying() then  
        self.StateHelper:OnDyingChanged(true)
    end 
    OnHumanRunStatChanged(self, nil, self.rRunState:Get())
    self:OnSpeedChanged()
    ApplyHumanJumpBuff(self)
    self.bOnActorCreated = false
end

function HumanMovementStateComponent:ClearAll()
    if self.OnRootMotionJump then 
        self.OnRootMotionJump:UnbindAll()
        self.OnRootMotionJump = nil 
    end 

    if self.OnRootMotionJumpNew then 
        self.OnRootMotionJumpNew:UnbindAll()
        self.OnRootMotionJumpNew = nil 
    end 

    Timer.StopOwnerAllTimer(self, true)
    if self.OnDirectionChanged then
        self.OnDirectionChanged:Unbind()
        self.OnDirectionChanged = nil
    end
    if self.OnActorMovementChanged then
        self.OnActorMovementChanged:Unbind()
        self.OnActorMovementChanged = nil
    end
    if self.StateHelper then
        self.StateHelper:UnInit()
    end
    self.EventHelper:UnregisterAll()
    self.rMovementState = nil
end

function HumanMovementStateComponent:OnActorDestroyed(pUEActor)
    self:ClearAll()

    SelfAnimationHelper:ClearOwnerCache(self)

    HumanMovementStateComponent.super.OnActorDestroyed(self, pUEActor)
end


function HumanMovementStateComponent:OnDestroy()
    HumanMovementStateComponent.super.OnDestroy(self)
    self:ClearAll()
end


function HumanMovementStateComponent:SetSpeedRatio(nSpeedRatio)
    -- self.nSpeed:ModifyOverlap(self.nSpeedRatio, nSpeedRatio)
    if nSpeedRatio == self.nSpeedRatio then
        return
    end
    self.nSpeedRatio = nSpeedRatio
    self:OnSpeedChanged()
end

function HumanMovementStateComponent:SetBaseSpeed(nBaseSpeed)
    if not self.bEnableMove and nBaseSpeed > 0 then
        return
    end
    -- if nBaseSpeed == self.nBaseSpeed then
    --     return
    -- end
    self.nBaseSpeed = nBaseSpeed
    self:OnSpeedChanged()
end

function HumanMovementStateComponent:OnBuffSpeedChanged(_Property, nNewSpeed)
    self:OnSpeedChanged()
end
function HumanMovementStateComponent:ChangeSpeedBuffRatio(nValue)
    local nSpeedBuffRatio =  self.rSpeedBuffRatio:Get() + nValue
    self.rSpeedBuffRatio:Set(nSpeedBuffRatio)
end

function HumanMovementStateComponent:OnSpeedChanged()
    local pUEActor = self.Owner.pUEActor
    if not pUEActor then  
        return 
    end 

    local CharacterMovement = pUEActor.CharacterMovement
    local nSpeed = self.nBaseSpeed * (1 + self.rSpeedBuffRatio:Get()) * self.nSpeedRatio * self.nWeaponSpeedFactor
    -- logdebug("HumanMovementStateComponent On Human Movement Speed Changed", nSpeed,
    --   "nBaseSpeed", self.nBaseSpeed, "nSpeedRatio", self.nSpeedRatio, "nWeaponSpeedFactor", self.nWeaponSpeedFactor, "buff", self.rSpeedBuffRatio:Get())
    CharacterMovement:SetMaxWalkSpeed(nSpeed)
    CharacterMovement.CheckMaxSpeed = nSpeed
    CharacterMovement.MaxSwimSpeed = nSpeed
        -- pUEActor.MaxWalkSpeed = self.tbCurrentPoseData.nSpeed
end

function HumanMovementStateComponent:OnDyingChanged(bIsDying)
    if self.StateHelper then 
        self.StateHelper:OnDyingChanged(bIsDying)
    end
end

function HumanMovementStateComponent:SetRescuingChanged(bIsRescuing)
    self.bIsRescuing = bIsRescuing
    -- if bIsRescuing then
    --     self:SetMovementState(HumanMovementStateType.Crouch_State)
    -- end
end 

function HumanMovementStateComponent:SetEnableMove(bEnable)
    OnEnableMove(self, bEnable)
end 

function HumanMovementStateComponent:OnMovementStateChangedNew(nNewState, nLastMovementState)
    self.tbCurrentPoseData = HumanMovementSpeedDataTable:GetTemplate(nNewState)
    log("ChangeMovementState OldState", nLastMovementState, "NewState", nNewState)
    self.EventHelper:FireEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self.Owner, nLastMovementState, nNewState)

    if not self.bOnActorCreated and self.Owner.pUEActor:WasRecentlyRendered(0.2) or GlobalVariableSystem:IsServerLogic() then 
        PlayStateChangeAnimation(self, nLastMovementState, nNewState)
    end

    if self.tbCurrentPoseData then
        self:SetBaseSpeed(self.tbCurrentPoseData.nSpeed)
    end

    self.Owner.pUEActor:SetMovementState(nNewState)
    -- local PlayerProperty = self.Owner.pUEActor.PlayerProperty
    -- if not PlayerProperty then
    --     return
    -- end
    -- PlayerProperty:SetMovementState(nNewState)
end

function HumanMovementStateComponent:RequestChangeMovement(nNewState, bForce)
    self:SetMovementState(nNewState, bForce)
end

function HumanMovementStateComponent:GetDestructibleObject()
    return self.StateHelper:GetDestructibleObject()
end 

function HumanMovementStateComponent:RequestSpeel(nJumpType, nDestructibleInstanceId, tbWallPosition, Yaw)
    if nJumpType ~= HumanJumpTypeDef.None and self:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then  
        return
    end 

    if nDestructibleInstanceId and nDestructibleInstanceId > 0 then  
        local tbDestructible = GameObjectSystem:FindByInstanceId(nDestructibleInstanceId)
        if tbDestructible then  
            tbDestructible:Break()
        end 
    end 

    local tbHumanRootMotionJump = self.rJumpType:Get()
    if not tbHumanRootMotionJump then  
        tbHumanRootMotionJump = {}
    end
    
    if tbHumanRootMotionJump.jump_type == nJumpType then  
        nJumpType = nJumpType * -1
    end 
    tbHumanRootMotionJump.jump_type = nJumpType
    tbHumanRootMotionJump.destructible_id = nDestructibleInstanceId
    tbHumanRootMotionJump.wall_position = tbWallPosition
    tbHumanRootMotionJump.yaw = Yaw

    self.rJumpType:Set(tbHumanRootMotionJump)
end

function HumanMovementStateComponent:RequestSpeelNew(nJumpType, nDestructibleInstanceId, tbSpeelPos, tbTargetPos, tbExpectStartPos, Yaw)
    --todo 距离校验检查
    if nJumpType ~= HumanJumpTypeDef.None and self:GetCurrentState() == HumanMovementStateType.Jumping_SpeelWall then  
        return
    end 

    if nDestructibleInstanceId and nDestructibleInstanceId > 0 then  
        local tbDestructible = GameObjectSystem:FindByInstanceId(nDestructibleInstanceId)
        if tbDestructible then  
            tbDestructible:Break()
        end 
    end 

    local tbHumanRootMotionJump = self.rJumpTypeNew:Get()
    if not tbHumanRootMotionJump then  
        tbHumanRootMotionJump = {}
    end
    
    if tbHumanRootMotionJump.jump_type == nJumpType then  
        nJumpType = nJumpType * -1
    end 

    local tbPacket = {}
    tbPacket.jump_type = nJumpType
    tbPacket.destructible_id = nDestructibleInstanceId
    tbPacket.speel_position = tbSpeelPos
    tbPacket.target_position = tbTargetPos
    tbPacket.expect_start_position = tbExpectStartPos
    tbPacket.yaw = Yaw

    self.rJumpTypeNew:Set(tbPacket)
end

function HumanMovementStateComponent:SetJumpBuffConfig(tbInJumpBuffConfig, bSet)
    local tbJumpBuffConfig = self:GetHumanJumpBuffConfig()

    log("[HumanJumpBuff] HumanMovementStateComponent:SetJumpBuffConfig, tbInJumpBuffConfig = ", t2s(tbInJumpBuffConfig))

    tbJumpBuffConfig.speed_change          = tbJumpBuffConfig.speed_change        * tbInJumpBuffConfig.nSpeedChange
    tbJumpBuffConfig.z_velocity_change     = tbJumpBuffConfig.z_velocity_change   * tbInJumpBuffConfig.nZVelocityChange
    tbJumpBuffConfig.gravity_change        = tbJumpBuffConfig.gravity_change      * tbInJumpBuffConfig.nGravityChange
    tbJumpBuffConfig.origin_speed_change   = tbJumpBuffConfig.origin_speed_change * tbInJumpBuffConfig.nOriginSpeedChange
    tbJumpBuffConfig.air_drag_change       = tbJumpBuffConfig.air_drag_change     * tbInJumpBuffConfig.nAirDragChange
    tbJumpBuffConfig.accel_change          = tbJumpBuffConfig.accel_change        * tbInJumpBuffConfig.nAccelChange

    log("[HumanJumpBuff] HumanMovementStateComponent:SetJumpBuffConfig, tbJumpBuffConfig = ", t2s(tbJumpBuffConfig))
        
    
    self.rHumanJumpBuffConfig:Set(tbJumpBuffConfig)
end

function HumanMovementStateComponent:GetHumanJumpBuffConfig()
    local tbJumpBuffConfig = self.rHumanJumpBuffConfig:Get()
    if not tbJumpBuffConfig or not tbJumpBuffConfig.speed_change then
        tbJumpBuffConfig = {}
        tbJumpBuffConfig.speed_change          = 1;
        tbJumpBuffConfig.z_velocity_change     = 1;
        tbJumpBuffConfig.gravity_change        = 1;
        tbJumpBuffConfig.origin_speed_change   = 1;
        tbJumpBuffConfig.air_drag_change       = 1;
        tbJumpBuffConfig.accel_change          = 1;
        self.rHumanJumpBuffConfig:Set(tbJumpBuffConfig)
    end

    return tbJumpBuffConfig
end

return HumanMovementStateComponent