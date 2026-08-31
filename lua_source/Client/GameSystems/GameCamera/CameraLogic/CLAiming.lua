

local luaclass = require("luaclass")
local CameraLogicBase = require("CameraLogicBase")
local CLAiming = luaclass("CLAiming", CameraLogicBase)

-- local DelayTimer = require("DelayTimer")
local GameCameraModeDef = require("GameCameraModeDef")
local ClientEventDef = require("ClientEventDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanMovementStateType = require("HumanMovementStateType")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local HumanCameraDataTable = require("HumanCameraDataTable")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local ShipCameraDataTable = require("ShipCameraDataTable")
local CommonEventDef = require("CommonEventDef")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local HumanWeaponHelper = require("HumanWeaponHelper")
local CameraIni = require("CameraIni")
local HumanWeaponDef = require("HumanWeaponDef")

local tbGroupDef = GameCameraModeGroupDef
local tbModeDef = GameCameraModeDef
local HumanState = GameCameraModeGroupDef.HumanState

local ZERO_ROTATOR = Rotator{Pitch = 0, Yaw = 0, Roll = 0}
local CAMERA_AIM_START = Vector{X= 0, Y = -4, Z = 4}
local HUMAN_AIM_IN_RES = "SoundCue'/Game/SoundCues/FFA/Weapon/SC_AllWeapon_Aim_1.SC_AllWeapon_Aim_1'"
local HUMAN_AIM_OUT_RES = "SoundCue'/Game/SoundCues/FFA/Weapon/SC_AllWeapon_Aim_3.SC_AllWeapon_Aim_3'"
local nOffsetYValue = -5 --block时候向左偏移一点
local nOffsetXValue = 5 --block时候向前偏移一点
local nAimBlendTime = 0.4

local INHIBIT_PITCH_MIN = -89
local INHIBIT_PITCH_MAX = 89

CLAiming.bInhibitActive = false

--狙击枪开镜
--1.针对动作的抖动，目前对狙击枪客户端自己在 站蹲趴切换，以及移动的混合空间用了单独的，以保证动作最小的抖动
--2.开镜针对客户端自己，隐藏了长的准镜，具体做法是在枪的AB当中把准镜的骨头移动到了脚底下
--3.替换短的高清的瞄准镜，具体做法并不是attach到枪上，而是根枪一样，attach到了人的右手上，偏移用的枪里的SightTransform，这么做的原因是因为针对大地图的float浮点误差计算，是换算到
--人的相对transform的，如果attach到枪上，parent就是枪了，这样打开浮点优化获取的 RenderMatrix就不对了，就看不到瞄准镜了，目前先这么做，枪没有动画
--所以还能接受
local function HideSightForAim(tbCurWeapon, bHide)
    if tbCurWeapon and isvalidhandle(tbCurWeapon.pWeaponActor) and tbCurWeapon.pWeaponActor.SetHideSight then
        local pWeaponActor = tbCurWeapon.pWeaponActor
        pWeaponActor:SetHideSight(bHide)
        local szHoldSocket = tbCurWeapon:GetHoldSocketName()
        local tbOwner = tbCurWeapon:GetOwner()
        if tbOwner and tbOwner.pUEActor and tbOwner.pUEActor.Mesh then 
            pWeaponActor:ChangeSightMeshNew(bHide, szHoldSocket, tbOwner.pUEActor.Mesh)
        end
    end
end

local function GetCurShipTemplateId()
    local PlayerSelf = PlayerSelfHelper:Get()
    return  PlayerSelf:GetShipTemplateId()
end

local function GetCurShipAimLoc(self)
    local nShipTemplateId = GetCurShipTemplateId(self)
    local tbInitParams = ShipCameraDataTable:GetShipInitCameraParam(nShipTemplateId)

    local PlayerSelf = PlayerSelfHelper:Get()
    local BattleShipWeaponComponent = PlayerSelf.BattleShipWeaponComponent
    if BattleShipWeaponComponent then 
        local tbActiveWeapon = BattleShipWeaponComponent:GetActiveWeaponItem()
        if tbActiveWeapon then  
            local nSlot = tbActiveWeapon:GetWeaponSlot()
            if nSlot == ShipWeaponSlotDef.HEAD then
                return tbInitParams.HeadAimArmLoc
            elseif nSlot == ShipWeaponSlotDef.SIDE then
                return tbInitParams.SideAimArmLoc
            elseif nSlot == ShipWeaponSlotDef.DECK then
                return tbInitParams.SternAimArmLoc
            else  
                return tbInitParams.AimArmLoc
            end
        end
    end
    return tbInitParams.AimArmLoc
end

local function ResetPitchViewByState(self)
    local CameraManager = self.Owner.InnerHelper:GetCameraManager()
    local tbPlayer = PlayerSelfHelper:Get()
    local MovementComponent = tbPlayer.HumanMovementStateComponent
    local nCurrentMovementState = MovementComponent:GetCurrentState()
    if nCurrentMovementState == HumanMovementStateType.UpRight_State or
         nCurrentMovementState == HumanMovementStateType.Crouch_State or 
         nCurrentMovementState == HumanMovementStateType.Crawl_State then  
        local nStatePitchMax, nStatePitchMin = HumanCameraDataTable:GetMovementCameraPitchLimit(nCurrentMovementState)
        CameraManager:ResetPitchView(nStatePitchMax, nStatePitchMin)
    end
end

local function OnActiveCameraGroup(self, nGroupId, tbParams)
    local pUEActor = PlayerSelfHelper:GetUEActor()
    if nGroupId == tbGroupDef.HumanAiming then
        GameplayStatics.PlaySoundAtLocation(GWorld, HUMAN_AIM_IN_RES:load(), pUEActor:K2_GetActorLocation(), ZERO_ROTATOR, 1, 1, 0, nil, nil, nil)

        local tbPlayer = PlayerSelfHelper:Get()
        local MovementComponent = tbPlayer.HumanMovementStateComponent
        local nCurrentMovementState = MovementComponent:GetCurrentState()
        if nCurrentMovementState == HumanMovementStateType.Crawl_State then
            pUEActor.CharacterMovement:SetCrawlState(false)
            local UpdateComponent = pUEActor.CharacterMovement.UpdatedComponent
            local Rot = UpdateComponent:K2_GetComponentRotation()
            Rot.Pitch = 0
            Rot.Roll = 0
            UpdateComponent:K2_SetRelativeRotation(Rot)
        end

        local pArm = self.Owner.InnerHelper:GetArm()
        pArm.bDoCollisionTest = false
        self.Owner:DeactiveMode(tbModeDef.ModeOffsetMove)

        pArm.bEnableCameraRotationLag = false
        local tbCurrentWeapon = tbPlayer.HumanWeaponComponent:GetCurrentWeapon()
        local pWeaponActor = tbCurrentWeapon.pWeaponActor
        local CameraManager = self.Owner.InnerHelper:GetCameraManager()
        if self.bInhibitActive then
            tbParams.CameraOffset = Vector{X = nOffsetXValue, Y = nOffsetYValue, Z = 0 }
            self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
            HideSightForAim(tbCurrentWeapon, false)
            CameraManager.ViewPitchMin = INHIBIT_PITCH_MIN
            CameraManager.ViewPitchMax = INHIBIT_PITCH_MAX
        else  
            local pSightTransform = pWeaponActor:GetSightTransform()
            self.Owner:ActiveCameraMode(tbModeDef.ModeCameraTrack, {
                pTargetMesh = pUEActor.Mesh, 
                szTargetSocket = CameraIni.szAimSocket, 
                pRefMesh = pWeaponActor.Mesh, 
                pSightRelativeTransform = pSightTransform,
                nTrackSpeed = CameraIni.nTrackSpeed, 
                nDelayBeginTime = CameraIni.nDelayBeginTime, 
                nDelayTraceOnceTime = CameraIni.nDelayTraceOnceTime, 
                nOffsetForward = tbParams.nOffsetToAim
            })
            HideSightForAim(tbCurrentWeapon, true)
            --这个offset 是为了控制 每次开镜 镜头是从武器左侧移进来的感觉
            tbParams.CameraOffset = CAMERA_AIM_START
        end
        
        self.Owner:ActiveCameraLogic(tbGroupDef.HumanAiming, nil, tbParams)
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = tbParams.nAimRate, nBlendTime = nAimBlendTime })

        if self.bInhibitActive then
            local nMoveX, nMoveY = self.Owner:GetCameraMoveScale()
            CameraManager:SetHandleMoveParam(nMoveX, nMoveY * 10, EHandleInputType.UseController)
        end
    elseif nGroupId == tbGroupDef.ShipAiming then
        local pArm = self.Owner.InnerHelper:GetArm()
        pArm:K2_SetRelativeLocation(GetCurShipAimLoc(self))
        self.Owner:ActiveCameraLogic(tbGroupDef.ShipAiming, { bKeepNoChange = true}, tbParams)
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = tbParams.nAimRate, nBlendTime = nAimBlendTime })
    end
end

local function OnDeactiveCameraGroup(self, nGroupId, tbParams)
    if nGroupId == tbGroupDef.HumanAiming then
        self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
        local tbPlayer = PlayerSelfHelper:Get()
        local tbCurrentWeapon = tbPlayer.HumanWeaponComponent:GetCurrentWeapon()
        HideSightForAim(tbCurrentWeapon, false)
        
        local pUEActor = PlayerSelfHelper:GetUEActor()
        GameplayStatics.PlaySoundAtLocation(GWorld, HUMAN_AIM_OUT_RES:load(), pUEActor:K2_GetActorLocation(), ZERO_ROTATOR, 1, 1, 0, nil, nil, nil)
        --设置站立时候 人的base offset 方便蹲下 站立的时候镜头移动
        local tbInitParams = HumanCameraDataTable:GetHumanCameraParam(HumanState.Normal)
        --恢复成当前人的状态对应的的 相机offset
        local MovementComponent = tbPlayer.HumanMovementStateComponent
        local nCurrentMovementState = MovementComponent:GetCurrentState()

        local GCMgr =  self.Owner.InnerHelper:GetCameraManager()
        local CameraActor = GCMgr:GetPlayerCameraActor()
        GCMgr:ResetBaseSocketOffset(tbInitParams.SocketOffset)
        tbInitParams.nPitchViewMax = GCMgr.ViewPitchMax
        tbInitParams.nPitchViewMin = GCMgr.ViewPitchMin

        local nActorPitch = pUEActor:GetAimPitchValue()
        tbInitParams.ArmRotation = Rotator{ Pitch = nActorPitch, Yaw = 0, Roll = 0 }

        if nCurrentMovementState == HumanMovementStateType.Crouch_State then
            tbInitParams.SocketOffset = HumanCameraDataTable:GetCrouchSocketOffset()
        elseif nCurrentMovementState == HumanMovementStateType.Crawl_State then
            tbInitParams.SocketOffset = HumanCameraDataTable:GetCrawlSocketOffset()
        elseif nCurrentMovementState == HumanMovementStateType.Dying_State then 
            tbInitParams.SocketOffset = HumanCameraDataTable:GetDyingSocketOffset()
        end
        --人切瞄准的时候不要设置 control rotation 否则在切换过程中 人的pitch会收到影响
        self.Owner:ActiveCameraLogic(tbGroupDef.HumanNormal, nil, {
            tbConfigInitParams = tbInitParams,
            tbTargetParams = {
                pFollowTarget = pUEActor,
                pFollowType = ECameraFollowType.Attach,
                bSetControlRot = false
            }
        })

        local OffsetZ = 0
        local nTemplateId = tbPlayer:GetHumanTemplateId()
        local CrawlCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crawl_State)
        local CrouchCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crouch_State)
        local StandCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.UpRight_State)
        local DyingCapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Dying_State)

        local nCapsuleRadius = 0
        local nCapsuleHalfHeight = 0
        if nCurrentMovementState == HumanMovementStateType.Crouch_State then
            nCapsuleRadius = CrouchCapsuleData.nCapsuleRadius
            nCapsuleHalfHeight = CrouchCapsuleData.nCapsuleHalfHeight
        elseif nCurrentMovementState == HumanMovementStateType.Crawl_State then
            nCapsuleRadius = CrawlCapsuleData.nCapsuleRadius
            nCapsuleHalfHeight = CrawlCapsuleData.nCapsuleHalfHeight
        elseif nCurrentMovementState == HumanMovementStateType.Dying_State then 
            nCapsuleRadius = DyingCapsuleData.nCapsuleRadius
            nCapsuleHalfHeight = DyingCapsuleData.nCapsuleHalfHeight
        end
        if nCapsuleHalfHeight < nCapsuleRadius then  
            nCapsuleHalfHeight = nCapsuleRadius
        end
        if nCapsuleHalfHeight ~= 0 then 
            OffsetZ = nCapsuleHalfHeight - StandCapsuleData.nCapsuleHalfHeight
        end  
        if OffsetZ ~= 0 then
            CameraActor:K2_DetachFromActor(EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative, EDetachmentRule.KeepRelative)
            local pLocation = CameraActor:K2_GetActorLocation()
            CameraActor:K2_SetActorLocation(Vector{X= pLocation.X, Y= pLocation.Y, Z= pLocation.Z - OffsetZ}, true, true)
            CameraActor:K2_AttachToActor(pUEActor, nil, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, false)
        end

        if nCurrentMovementState == HumanMovementStateType.Crawl_State then
            self.EventHelper:FireEvent(CommonEventDef.EV_ACTIVE_CRAWL_CAMERA, tbPlayer, false)
            pUEActor.CharacterMovement:SetCrawlState(true)
        end

        local pArm = self.Owner.InnerHelper:GetArm()
        pArm.bEnableCameraRotationLag = false
        pArm.bDoCollisionTest = true

        local nCurMovementState = tbPlayer.HumanMovementStateComponent:GetCurrentState()
        if nCurMovementState == HumanMovementStateType.Crawl_State then
            local nMoveX, nMoveY = self.Owner:GetCameraMoveScale()
            GCMgr:SetHandleMoveParam(nMoveX, nMoveY, EHandleInputType.UseControllerArm)
        end
        ResetPitchViewByState(self)
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = 0, nBlendTime = tbParams.bWithAnim and nAimBlendTime or 0 })
    elseif nGroupId == tbGroupDef.ShipAiming then
        local pArm = self.Owner.InnerHelper:GetArm()
        local nShipTemplateId = GetCurShipTemplateId(self)
        local tbInitParams = ShipCameraDataTable:GetShipInitCameraParam(nShipTemplateId)
        if tbInitParams.ArmLocation then 
            pArm:K2_SetRelativeLocation(tbInitParams.ArmLocation)
        end
        self.Owner:ActiveCameraLogic(tbGroupDef.ShipNormal, { bKeepNoChange = true}, { bKeepNoChange = true} )
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = 0, nBlendTime = tbParams.bWithAnim and nAimBlendTime or 0  })
    end
end

local function ActiveInhibitAttack(self, bActive)
    if self.bInhibitActive ~= bActive then  
        local PlayerSelf = PlayerSelfHelper:Get()
        local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
        local bAiming = HumanWeaponComponent:IsAiming()
        local GCMgr =  self.Owner.InnerHelper:GetCameraManager()
        local CameraActor = GCMgr:GetPlayerCameraActor()
        if bAiming then
            local tbCurWeapon = HumanWeaponComponent:GetCurrentWeapon()
            if tbCurWeapon ~= nil then 
                if bActive then  
                    GCMgr.ViewPitchMin = INHIBIT_PITCH_MIN
                    GCMgr.ViewPitchMax = INHIBIT_PITCH_MAX
                    local nMoveX, nMoveY = self.Owner:GetCameraMoveScale()
                    GCMgr:SetHandleMoveParam(nMoveX, nMoveY * 10, EHandleInputType.UseController)
                    self.Owner:DeactiveMode(tbModeDef.ModeCameraTrack)
                    HideSightForAim(tbCurWeapon, false)
                    CameraActor:K2_SetActorRelativeLocation(Vector{X =  nOffsetXValue, Y = nOffsetYValue,Z = 0 }) 
                else
                    --这个offset 是为了控制 每次开镜 镜头是从武器左侧移进来的感觉
                    CameraActor:K2_SetActorRelativeLocation(CAMERA_AIM_START)
                    local pSightTransform = tbCurWeapon.pWeaponActor:GetSightTransform()

                    self.Owner:ActiveCameraMode(tbModeDef.ModeCameraTrack, {
                        pTargetMesh = PlayerSelf.pUEActor.Mesh, 
                        szTargetSocket = CameraIni.szAimSocket, 
                        pRefMesh = tbCurWeapon.pWeaponActor.Mesh, 
                        pSightRelativeTransform = pSightTransform,
                        nTrackSpeed = CameraIni.nTrackSpeed, 
                        nDelayBeginTime = CameraIni.nDelayBeginTime,
                        nDelayTraceOnceTime = CameraIni.nDelayTraceOnceTime, 
                        nOffsetForward = tbCurWeapon:GetProperty().nOffsetToAim
                    })
                    HideSightForAim(tbCurWeapon, true)
                    local pArm = self.Owner.InnerHelper:GetArm()
                    pArm:K2_SetRelativeRotation(ZERO_ROTATOR)
                    local nMoveX, nMoveY = self.Owner:GetCameraMoveScale()
                    GCMgr:SetHandleMoveParam(nMoveX, nMoveY, EHandleInputType.UseController)
                    ResetPitchViewByState(self)
                end
            end
        end
        self.bInhibitActive = bActive
    end
end

local function IsWeaponWand(self)
    local tbPlayer = PlayerSelfHelper:Get()
    local tbCurrentWeapon = tbPlayer.HumanWeaponComponent:GetCurrentWeapon()
    if not tbCurrentWeapon then return false end 
    local nCategory = HumanWeaponHelper.GetWeaponCategory(tbCurrentWeapon.nTemplateId)
    if nCategory == HumanWeaponDef.WeaponCategory.Wand then
        return true
    end
    return false
end

local function OnWandFocus(self, bFocus)
    if not IsWeaponWand(self) then return end 

    self.Owner:DeactiveMode(tbModeDef.ModeFov)
    if bFocus then 
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = CameraIni.nWandFovRate, nBlendTime = CameraIni.nWandFocusTimes })
    else  
        self.Owner:ActiveCameraMode(tbModeDef.ModeFov, { nTargetFovRate = 0, nBlendTime = CameraIni.nWandFocusTimes })
    end
end

function CLAiming:OnCreate()
end

function CLAiming:OnDestroy()
   
end

function CLAiming:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, self, OnActiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, self, OnDeactiveCameraGroup)
    EventHelper:RegisterEvent(ClientEventDef.EV_INHIBIT_ATTACK_ACTIVE, self, ActiveInhibitAttack)

    EventHelper:RegisterEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, self, OnWandFocus)
end

function CLAiming:OnUnbindEvent(EventHelper)
end

return CLAiming
