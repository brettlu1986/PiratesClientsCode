

local luaclass = require("luaclass")
local CameraLogicBase = require("CameraLogicBase")
local CLMovement = luaclass("CLMovement", CameraLogicBase)

local CommonEventDef = require("CommonEventDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanMovementStateType = require("HumanMovementStateType")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local ClientEventDef = require("ClientEventDef")
local HumanCameraDataTable = require("HumanCameraDataTable")
local GameCameraModeDef = require("GameCameraModeDef")
local ParachutionSystem = require("ParachutionSystem_C")
local VehicleCameraDataTable = require("VehicleCameraDataTable")
local DelayTimer = require("DelayTimer")
local CameraIni = require("CameraIni")
local HumanVehicleStateDef = require("HumanVehicleStateDef")

CLMovement.tbTimerObject = nil

local ArmRotYaw = 0
local ArmRotPitch = 0
local DEFAULT_VEHICLE_CAMERA = 1
local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local HumanState = GameCameraModeGroupDef.HumanState

local ZERO_ROTATOR = Rotator{Pitch = 0, Yaw = 0, Roll = 0}

local function LOG(...)
    log("[ParachuteCamera]:", ...)
end

local function ClearTimer(self)
    if self.tbTimerObject then
        DelayTimer:ClearTimer(self.tbTimerObject)
        self.tbTimerObject = nil
    end
end

local function LockInputInTime(self, nTime)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    GameCameraManager.LockMoveInput = true
    GameCameraManager.ForbiddenFreeView = true
    ClearTimer(self)
    self.tbTimerObject = DelayTimer:DelayRun(function()
        GameCameraManager.LockMoveInput = false
        GameCameraManager.ForbiddenFreeView = false
    end, nTime)
end

local function OnActiveCrawlCamera(self, tbCharacter, bSetControlRot)
    if tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsClient() then

        local nTemplateId = tbCharacter:GetHumanTemplateId()
        local tbUprightCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)
        local tbCrawlCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crawl_State)

        local nCapsuleRadius = tbCharacter.pUEActor.CapsuleComponent:GetUnscaledCapsuleRadius()
        local nCapsuleHalfHeight = tbCrawlCapsuleData.nCapsuleHalfHeight
        if nCapsuleHalfHeight < nCapsuleRadius then
            nCapsuleHalfHeight = nCapsuleRadius
        end

        local nLocOffset = tbUprightCapsuleData.nCapsuleHalfHeight - nCapsuleHalfHeight
        local nMoveX, nMoveY = self.Owner:GetCameraMoveScale()
        local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
        GameCameraManager:UnInitCameraActorParam()
        GameCameraManager:InitFollowTarget(tbCharacter.pUEActor, ECameraFollowType.NotAttachFollowLocation, false, nil, Vector{ X = 0, Y = 0, Z = nLocOffset }, "")

        if self.Owner:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
            GameCameraManager:SetHandleMoveParam(nMoveX, nMoveY, EHandleInputType.UseArm)
        else
            GameCameraManager:SetHandleMoveParam(nMoveX, nMoveY, EHandleInputType.UseControllerArm)
        end
    end
end

local function OnDeactiveCrawlCamera(self, tbCharacter)
    if tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsClient() then
        local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
        local CameraActor = GameCameraManager:GetPlayerCameraActor()
        GameCameraManager:ForceToResetFreeViewRotation()
        GameCameraManager:InitFollowTarget(tbCharacter.pUEActor, ECameraFollowType.Attach, false, nil, Vector{X = 0,Y = 0,Z = 0}, "")

        local Arm = self.Owner.InnerHelper:GetArm()
        local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
        local ControlRotation = pPlayerController:GetControlRotation()
        local ActorRotation = tbCharacter.pUEActor:K2_GetActorRotation()
        pPlayerController:SetControlRotation(Rotator{Pitch = ControlRotation.Pitch, Yaw = ActorRotation.Yaw, Roll = ControlRotation.Roll })
        Arm:K2_SetRelativeRotation(Rotator{Pitch = ControlRotation.Pitch, Yaw = 0, Roll = 0})

        local nTemplateId = tbCharacter:GetHumanTemplateId()
        local tbUprightCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)

        local nCapsuleRadius = tbCharacter.pUEActor.CapsuleComponent:GetUnscaledCapsuleRadius()
        local nCapsuleHalfHeight = tbUprightCapsuleData.nCapsuleHalfHeight
        if nCapsuleHalfHeight < nCapsuleRadius then
            nCapsuleHalfHeight = nCapsuleRadius
        end

        local tbCrawlCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crawl_State)
        local nLocOffset = nCapsuleHalfHeight - tbCrawlCapsuleData.nCapsuleHalfHeight

        CameraActor:K2_SetActorRelativeLocation(Vector{X = 0,Y = 0,Z = nLocOffset})
        CameraActor:K2_SetActorRelativeRotation(Rotator{Pitch = 0, Yaw = 0, Roll = 0})

        local nMoveX, nMoveY = self.Owner:GetCameraMoveScale()
        if self.Owner:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
            GameCameraManager:SetHandleMoveParam(nMoveX, nMoveY, EHandleInputType.UseArm)
        else
            GameCameraManager:SetHandleMoveParam(nMoveX, nMoveY, EHandleInputType.UseControllerArmPitch)
        end

    end
end

local function ChangeCapsuleFromLastState(self, tbCharacter, nOldState)
    local bCrawl = nOldState == HumanMovementStateType.Crawl_State

    local nTemplateId = tbCharacter:GetHumanTemplateId()
    local tbUprightCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)
    local tbCrawlCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crawl_State)
    local tbCrouchCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crouch_State)

    local OffsetZ= 0
    if bCrawl then
        OffsetZ = tbUprightCapsuleData.nCapsuleHalfHeight - tbCrawlCapsuleData.nCapsuleHalfHeight
    else
        OffsetZ = tbUprightCapsuleData.nCapsuleHalfHeight - tbCrouchCapsuleData.nCapsuleHalfHeight
    end

    local pUEActor = tbCharacter.pUEActor
    local pLocation = pUEActor:K2_GetActorLocation()
    pUEActor:K2_SetActorLocation(Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z + OffsetZ}, true, true)

    if bCrawl then
        self.EventHelper:FireEvent(CommonEventDef.EV_DEACTIVE_CRAWL_CAMERA, tbCharacter)
    end

    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    local CameraActor = GameCameraManager:GetPlayerCameraActor()
    CameraActor:K2_DetachFromActor(EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative)
    pLocation = CameraActor:K2_GetActorLocation()
    CameraActor:K2_SetActorLocation(Vector{X=pLocation.X, Y=pLocation.Y, Z=pLocation.Z - OffsetZ}, true, true)
    CameraActor:K2_AttachToActor(tbCharacter.pUEActor, nil, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)

    local OffsetVector = Vector{X=0, Y=0, Z= tbUprightCapsuleData.nCapsuleHalfHeight * -1}
    pUEActor.BaseTranslationOffset = OffsetVector
    pUEActor.Mesh:K2_SetRelativeLocation(OffsetVector)

    ExtendBlueprintFunctions.ChangePlayerMeshTranslationOffset(pUEActor.CharacterMovement, OffsetZ * -1)
end

local function OnLastMovementStateDeactive(self, tbCharacter, nOldState, nCurrentState)
    local tbStateType = HumanMovementStateType
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    if not GameCameraManager then
        return
    end
    if nOldState == tbStateType.Jumping_SpeelWall then
        local Arm =  self.Owner.InnerHelper:GetArm()
        local nMoveX = GameCameraManager.CurMoveX
        local nMoveY = GameCameraManager.CurMoveY
        nMoveX = ArmRotYaw + nMoveX
        if nMoveX ~= 0 or nMoveY ~= 0 then
            tbCharacter.pUEActor:K2_AddActorLocalRotation(Rotator{Pitch = 0, Yaw = nMoveX, Roll = 0})
            tbCharacter.pUEActor:AddControllerYawInput(nMoveX)
            tbCharacter.pUEActor:AddControllerPitchInput(nMoveY)
            local nNewPitch = ArmRotPitch - nMoveY
            nNewPitch = KismetMathLibrary.ClampAngle(nNewPitch, GameCameraManager.ViewPitchMin, GameCameraManager.ViewPitchMax)
            Arm:K2_SetRelativeRotation(Rotator{Pitch = nNewPitch, Yaw = 0, Roll = 0})
        end
        tbCharacter.pUEActor:SetJumpAnimOver(true)
        GameCameraManager:OnCacheCameraMove(false)
        local nMoveXScale, nMoveYScale = self.Owner:GetCameraMoveScale()
        if self.Owner:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
            self.Owner.InnerHelper:UpdateFreeViewCacheRotation(GameCameraManager:GetCameraRotation())
            GameCameraManager:SetHandleMoveParam(nMoveXScale, nMoveYScale, EHandleInputType.UseArm)
        else
            GameCameraManager:SetHandleMoveParam(nMoveXScale, nMoveYScale, EHandleInputType.UseControllerArmPitch)
        end


    elseif nOldState == tbStateType.Crawl_State then
        --尝试解决  趴下站起来 视角被旋转的问题
        local UpdateComponent = tbCharacter.pUEActor.CharacterMovement.UpdatedComponent
        local Rot = UpdateComponent:K2_GetComponentRotation()
        Rot.Pitch = 0
        Rot.Roll = 0
        UpdateComponent:K2_SetRelativeRotation(Rot)
    elseif nOldState == tbStateType.Swimming then
        self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, tbGroupDef.HumanSwimming)
    end
end

local function IsJoyStickTouchStarted()
    local pUEActor = PlayerSelfHelper:GetUEActor()
    if pUEActor and pUEActor.PlayerInputComponent then  
        return pUEActor.PlayerInputComponent:IsInMove()
    end
    return false
end

local function OnCurrentMovementStateActive(self, tbCharacter, nOldState, nCurrentState)
    local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
    if not GameCameraManager then
        return
    end
    local tbStateType = HumanMovementStateType
    local pUEActor = tbCharacter.pUEActor
    if nCurrentState == tbStateType.Parachutine_State then
        self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, tbGroupDef.NewParachuteOpenParachute)
    elseif nCurrentState == tbStateType.InPlane_State then
        if nOldState == tbStateType.Crawl_State or nOldState == tbStateType.Crouch_State then
            ChangeCapsuleFromLastState(self, tbCharacter, nOldState)
        end

        local pParentActor, nTransporterId = ParachutionSystem:GetAttachedLineShip()
        if pParentActor ~= nil and nTransporterId ~= nil then
            LOG("NewParachuteShipping")
            self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, tbGroupDef.NewParachuteShipping, {pTarget = pParentActor, nTransporterId = nTransporterId})
        end

        --进跳伞因为人的MovementComponent Tick关掉了，所以服务器相机位置还在集合岛，会导致集合岛npc船跟名字片删不掉
        --当前帧调用ForceSendClientCamera不行，因为引擎取的相机位置是Cache的，还是集合岛的，得延迟设才行
        ClearTimer(self)
        self.tbTimerObject = DelayTimer:DelayRun(function()
            GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
            if GameCameraManager then 
                GameCameraManager:ForceSendClientCamera()
            end
        end, 1)
    elseif nCurrentState == tbStateType.Gliding_State then
        local bJoyStickTouched = IsJoyStickTouchStarted()
        LOG("Parachute Glide State")
        GameCameraManager.bJoystickTouchCheck = CameraIni.bGlideSpecalReset
        GameCameraManager.AutoRotInterp = CameraIni.nGlideFollowInterp
        GameCameraManager.AutoTriggerTime = CameraIni.nGlideTriggerTime
        GameCameraManager.AutoRotPich = CameraIni.nGlidePitch
        GameCameraManager.AutoConditionStartSpeed = 0
        GameCameraManager.CurrentAutoEffectSpeed = 0
        GameCameraManager.AutoEffectMinYaw = 0
        GameCameraManager:EnableAutoRot(CameraIni.bGlideReset)
        GameCameraManager:CheckJoytickEventForAutoRot(true)

        if CameraIni.bGlideSpecalReset then
            if bJoyStickTouched then  
                GameCameraManager:NotifyAutoRot()
            else  
                GameCameraManager.bJoyStickEnableAutoRot = false
            end
        else  
            GameCameraManager:NotifyAutoRot()
        end
       
        local nMoveXScale, nMoveYScale = self.Owner:GetCameraMoveScale()
        GameCameraManager:SetHandleMoveParam(nMoveXScale, nMoveYScale, EHandleInputType.UseArm)

    elseif nCurrentState == tbStateType.Falling_State then
        --不要 focus阶段了， 需要直接attach到飞出去的人身后
        if pUEActor == nil then
            pUEActor = PlayerSelfHelper:GetUEActor()
        end
        if pUEActor then
            self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, tbGroupDef.NewParachuteLaunchFocus, {pTarget = pUEActor})
        end
    elseif nCurrentState == tbStateType.Jumping_SpeelWall then
        local pArm = self.Owner.InnerHelper:GetArm()
        --根据墙的转向，在开始攀爬的时候只转人不转镜头
        local WallRotYaw = tbCharacter.HumanMovementStateComponent.StateHelper:GetRootMotionJumpWallYaw()
        if WallRotYaw ~= -1 then
            local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
            local nCurrentYaw = pPlayerController:GetControlRotation().Yaw
            local nAddYaw = WallRotYaw - nCurrentYaw
            pUEActor:AddControllerYawInput(nAddYaw)
            pArm:K2_SetRelativeRotation(Rotator{Pitch = pArm.RelativeRotation.Pitch, Yaw = pArm.RelativeRotation.Yaw - nAddYaw, Roll = 0})
        end
        
        --记录攀爬过程中 可能会划屏的操作
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        GameCameraManager:ResetBaseSocketOffset(tbInitParams.SocketOffset)

        GameCameraManager:OnCacheCameraMove(true)
        local nMoveXScale, nMoveYScale = self.Owner:GetCameraMoveScale()
        GameCameraManager:SetHandleMoveParam(nMoveXScale, nMoveYScale, EHandleInputType.UseArm)

        ArmRotYaw = pArm.RelativeRotation.Yaw
        if self.Owner.nCurrentGroupId == tbGroupDef.HumanFreeView then
            ArmRotPitch = GameCameraManager.CacheCameraRotator.Pitch
        else
            ArmRotPitch = pArm.RelativeRotation.Pitch
        end

        pArm:EnableCameraLocationLagWithTimeAndSpeed(true, CameraIni.nSpeelDuration, CameraIni.nSpeelLagSpeed)

    elseif nCurrentState == tbStateType.Swimming then
        self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, tbGroupDef.HumanSwimming)
    elseif nCurrentState == tbStateType.Crawl_State or nCurrentState == tbStateType.Crouch_State then 
        if tbCharacter.pUEActor then 
            if not tbCharacter.pUEActor:IsJumpAnimOver() then  
                tbCharacter.pUEActor:SetJumpAnimOver(true)
            end
        end
    end
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState)
    if tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf and GlobalVariableSystem:IsClient() then
        if tbCharacter:IsHuman() then
            self.Owner.InnerHelper:SafeSpawnCameraActor()
            OnLastMovementStateDeactive(self, tbCharacter, nOldState, nNewState)
            OnCurrentMovementStateActive(self, tbCharacter, nOldState, nNewState)
        end
    end
end

local function OnActiveCameraGroup(self, nGroupId, tbParams)
    local pUEActor = PlayerSelfHelper:GetUEActor()
    if nGroupId == tbGroupDef.HumanSwimming then
        self.Owner:DeactiveMode(tbModeDef.ModeOffsetMove)
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, true)
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Swim)
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        local pArm = self.Owner.InnerHelper:GetArm()
        self.Owner:ActiveCameraLogic(tbGroupDef.HumanSwimming, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pUEActor,
                pFollowType = ECameraFollowType.NotAttachFollowLocXYRotYaw,
                bSetControlRot = true
            }
        })
        
        pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)
        if tbParams and tbParams.bImmediatly then
            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = true })
        else
            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = false, nBlendTime = 0.2 })
        end
        LockInputInTime(self, 0.3)
    elseif nGroupId == tbGroupDef.VehicleView then
        --VCamera active::
        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        local pArm = self.Owner.InnerHelper:GetArm()
        local CameraActor = GCMgr:GetPlayerCameraActor()

        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, false)
        GCMgr:SetCacheArmRotator(false, ZERO_ROTATOR)
        GCMgr:UnInitCameraActorParam()

        local PreArmRelativeRot = pArm.RelativeRotation
        local PreCameraActorRot = CameraActor:K2_GetActorRotation()
        local TargetCameraActorRot = Rotator{Pitch = 0, Yaw = tbParams.pTarget:K2_GetActorRotation().Yaw, Roll = 0}
        local OffsetRot = Rotator{Pitch = -PreCameraActorRot.Pitch, Yaw = TargetCameraActorRot.Yaw - PreCameraActorRot.Yaw, Roll = -PreCameraActorRot.Roll}
        pArm:K2_SetRelativeRotation(Rotator{Pitch = PreArmRelativeRot.Pitch - OffsetRot.Pitch, Yaw = PreArmRelativeRot.Yaw - OffsetRot.Yaw,
            Roll = PreArmRelativeRot.Roll - OffsetRot.Roll})
        GCMgr:InitFollowTarget(tbParams.pTarget, ECameraFollowType.NotAttackFollowLocRotYaw, true, nil, Vector{ X = 0, Y = 0, Z = 0 }, "")

        local tbInitParams = VehicleCameraDataTable:GetVehicleInitCameraParam(DEFAULT_VEHICLE_CAMERA)
        self.Owner:ActiveCameraLogic(tbGroupDef.VehicleView, { bKeepNoChange = true} , { bKeepNoChange = true} )
        pArm:K2_SetRelativeLocation(tbInitParams.ArmLocation)
        pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)
        pArm.TargetArmLength = tbInitParams.nArmLength
        pArm.SocketOffset = tbInitParams.SocketOffset

        local pCamera = CameraActor:GetCamera()
        pCamera:K2_SetRelativeRotation(tbInitParams.CameraRotation)
        pCamera:K2_SetRelativeLocation(Vector{X=0, Y=0, Z=0})
        GCMgr.ViewPitchMax = tbInitParams.nPitchViewMax
        GCMgr.ViewPitchMin = tbInitParams.nPitchViewMin

        GCMgr:EnableCameraMoveBackOrigin(true)
        GCMgr.EnableGyro = false
        pArm.FixOffset = -70
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = tbParams.pTarget, bImmediatly = false, nBlendTime = CameraIni.nOnHorseTime })
        LockInputInTime(self, CameraIni.nOnHorseTime + 0.2)
    end
end

local function OnDeactiveCameraGroup(self, nGroupId, tbParams)
    if nGroupId == tbGroupDef.VehicleView then
        --VCamera deactive
        self.tbTimerObject = DelayTimer:DelayRun(function()
            local pUEActor = PlayerSelfHelper:GetUEActor()
            if pUEActor == nil then
                return
            end
            self.Owner:DeactiveMode(tbModeDef.ModeArmLen)
            local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
            local GCMgr = self.Owner.InnerHelper:GetCameraManager()
            GCMgr:EnableCameraMoveBackOrigin(false)
            GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
            local pArm = self.Owner.InnerHelper:GetArm()
            local CameraActor = GCMgr:GetPlayerCameraActor()

            self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, false)
            GCMgr:UnInitCameraActorParam()
            
            local PlayerSelf = PlayerSelfHelper:Get()
            local ArmWorldRot = pArm:K2_GetComponentRotation()
            local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
            local MovementComponent = PlayerSelfHelper:Get().HumanMovementStateComponent
            local nCurrentMovementState = MovementComponent:GetCurrentState()
            if nCurrentMovementState == HumanMovementStateType.Dying_State then  
                tbInitParams.SocketOffset = HumanCameraDataTable:GetDyingSocketOffset()
                local nTemplateId = PlayerSelf:GetHumanTemplateId()
                local DyingCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Dying_State)
                local StandCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)
                local nCapsuleRadius = DyingCapsuleData.nCapsuleRadius
                local nCapsuleHalfHeight = DyingCapsuleData.nCapsuleHalfHeight
                if nCapsuleHalfHeight < nCapsuleRadius then  
                    nCapsuleHalfHeight = nCapsuleRadius
                end
                local OffsetZ = nCapsuleHalfHeight - StandCapsuleData.nCapsuleHalfHeight
                CameraActor:K2_SetActorLocationAndRotation(Vector{X=0, Y=0, Z= -OffsetZ},Rotator{Pitch = 0, Yaw = 0, Roll = 0}, false, false)
            else 
                CameraActor:K2_SetActorLocationAndRotation(Vector{X=0, Y=0, Z=0},Rotator{Pitch = 0, Yaw = 0, Roll = 0}, false, false)
            end
            CameraActor:K2_AttachToActor(pUEActor, "", EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
            pArm:K2_SetRelativeRotation(Rotator{Pitch = ArmWorldRot.Pitch, Yaw = 0, Roll = 0})
            pPlayerController:SetControlRotation(Rotator{Pitch = ArmWorldRot.Pitch, Yaw = ArmWorldRot.Yaw, Roll = 0})

            self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, { bKeepNoChange = true} , { bKeepNoChange = true} )
            pArm:K2_SetRelativeLocation(tbInitParams.ArmLocation)
            pArm:UpdatePreArmLocationZ(tbInitParams.ArmLocation.Z)
            pArm.SocketOffset = tbInitParams.SocketOffset
            pArm.TargetArmLength = tbInitParams.nArmLength

            local pCamera = CameraActor:GetCamera()
            pCamera:K2_SetRelativeRotation(tbInitParams.CameraRotation)
            pCamera:K2_SetRelativeLocation(Vector{X=0, Y=0, Z=0})
            GCMgr.ViewPitchMax = tbInitParams.nPitchViewMax
            GCMgr.ViewPitchMin = tbInitParams.nPitchViewMin

            pArm.FixOffset = -14
            self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = false, nBlendTime = CameraIni.nDownHorseTime })
            LockInputInTime(self, CameraIni.nDownHorseTime + 0.2)
            self.EventHelper:FireEvent(ClientEventDef.EV_SETTING_HUMAN_GYRO)

        end, 0.1)
        
    elseif nGroupId == tbGroupDef.HumanSwimming then
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_FREE_VIEW, true)

        local GCMgr = self.Owner.InnerHelper:GetCameraManager()
        local pUEActor = PlayerSelfHelper:GetUEActor()
        self.Owner:DeactiveMode(tbModeDef.ModeArmLen)
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)

        local tbTargetParams = { pFollowTarget = pUEActor, pFollowType = ECameraFollowType.Attach, bSetControlRot = true }
        self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, { tbConfigInitParams = tbInitParams, tbTargetParams = tbTargetParams })
        self.Owner:ActiveCameraMode(tbModeDef.ModeChangeTarget, { pTarget = pUEActor, bImmediatly = false, nBlendTime = 0.3 })
        LockInputInTime(self, 0.3)
    end
end

local function OnVehicleStateChange(self, Player, nState, nVehicleId)
    if Player.ObjectType == GameObjectTypeDef.PlayerSelf then
        if nState == HumanVehicleStateDef.PreDetachFromVehicle then
            local CameraManager = self.Owner.InnerHelper:GetCameraManager()
            CameraManager.LockMoveInput = true
            CameraManager.ForbiddenFreeView = true
        end
    end
end

local function ComboAttackCameraBegin(self)
    if GlobalVariableSystem.bNewMeleeCamera then
        local pArm = self.Owner.InnerHelper:GetArm()
        local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
        GameCameraManager:OnCacheCameraMove(true)
        local nMoveXScale, nMoveYScale = self.Owner:GetCameraMoveScale()
        GameCameraManager:SetHandleMoveParam(nMoveXScale, nMoveYScale, EHandleInputType.UseArm)

        ArmRotYaw = pArm.RelativeRotation.Yaw
        ArmRotPitch = pArm.RelativeRotation.Pitch
    end
end

local function ComboAttackCameraOver(self)
    if GlobalVariableSystem.bNewMeleeCamera then
        local GameCameraManager = self.Owner.InnerHelper:GetCameraManager()
        local Arm =  self.Owner.InnerHelper:GetArm()
        local nMoveX = GameCameraManager.CurMoveX
        local nMoveY = GameCameraManager.CurMoveY
        nMoveX = ArmRotYaw + nMoveX
        if nMoveX ~= 0 or nMoveY ~= 0 then
            local pUEActor = PlayerSelfHelper:GetUEActor()
            pUEActor:K2_AddActorLocalRotation(Rotator{Pitch = 0, Yaw = nMoveX, Roll = 0})
            pUEActor:AddControllerYawInput(nMoveX)
            pUEActor:AddControllerPitchInput(nMoveY)
            local nNewPitch = ArmRotPitch - nMoveY
            nNewPitch = KismetMathLibrary.ClampAngle(nNewPitch, GameCameraManager.ViewPitchMin, GameCameraManager.ViewPitchMax)
            Arm:K2_SetRelativeRotation(Rotator{Pitch = nNewPitch, Yaw = 0, Roll = 0})
        end
        
        GameCameraManager:OnCacheCameraMove(false)
        local nMoveXScale, nMoveYScale = self.Owner:GetCameraMoveScale()
        GameCameraManager:SetHandleMoveParam(nMoveXScale, nMoveYScale, EHandleInputType.UseControllerArmPitch)
    end
end

function CLMovement:OnCreate()
end

function CLMovement:OnDestroy()
    ClearTimer(self)
end

function CLMovement:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, self, OnActiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, self, OnDeactiveCameraGroup)

    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_ACTIVE_CRAWL_CAMERA, self, OnActiveCrawlCamera)
    EventHelper:RegisterEvent(CommonEventDef.EV_DEACTIVE_CRAWL_CAMERA, self, OnDeactiveCrawlCamera)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChange)

    EventHelper:RegisterEvent(ClientEventDef.EV_MELEE_COMBO_ATTACK_BGEIN, self, ComboAttackCameraBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_MELEE_COMBO_ATTACK_OVER, self, ComboAttackCameraOver)
end

function CLMovement:OnUnbindEvent(EventHelper)
end

return CLMovement
