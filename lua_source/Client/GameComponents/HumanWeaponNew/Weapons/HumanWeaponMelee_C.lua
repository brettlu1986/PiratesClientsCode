local luaclass = require("luaclass")
local HumanWeaponMelee = require("HumanWeaponMelee")
local HumanWeaponMelee_C = luaclass("HumanWeaponMelee_C", HumanWeaponMelee)

local HumanWeaponMisc = require("HumanWeaponMisc")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local HumanWeaponHelper = require("HumanWeaponHelper")
local Timer = require("Timer")
local HumanWeaponType = require("HumanWeaponType")
local HumanWeaponDef = require("HumanWeaponDef")
local HumanBodyDef   = require("HumanBodyDef")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
-- local EventManager = require("EventManager")
-- local ClientEventDef = require("ClientEventDef")
-- local CameraGameHelper = require("CameraGameHelper")
-- local CameraIni = require("CameraIni")
local PropName = require("PropName")
local HumanWeaponHitEffectHelper = require("HumanWeaponHitEffectHelper")

local GetActorsInSectorRange = ExtendBlueprintFunctions.GetActorsInSectorRange
local REP_MONTAGE_TIMER = "RepMontageTimer"
local DELAY_CLEAR_ANIMINDEX = "DelayClearAnimIndex"
-- local DEFAULT_RANGE = 120

-- local TwoHandUnholdedSocket = "TwoHandUnholdedSocket"
-- local TwoHandHoldedSocket= "TwoHandHoldedSocket"
local DOOR_PATH = "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_DoorBase.BP_DoorBase_C'"
local WINDOW_PATH = "Blueprint'/Game/Game/OtherObject/DestructibleObject/BP_WindowBase.BP_WindowBase_C'"
local ATTACK_RANGE_ADDTO_DOOR = 100
local ATTACK_ANGLE_TO_DOOR = 360

HumanWeaponMelee_C.tbAttackInfo = nil

HumanWeaponMelee_C.nPostAttackDuration = nil
HumanWeaponMelee_C.nCurrentMontageIndex = 1

local END_TIME = 0.1
local JUMP_EMPTY_HAND_ATTACK_CD = 0.2

local TempTable = {}

local function CopyVector(Dest, From)
    Dest.X = From.X
    Dest.Y = From.Y
    Dest.Z = From.Z
end

local function VectorToTempTable(tbVector)
    CopyVector(TempTable, tbVector)
    return TempTable
end

-- local function CommonMeleeAttackCamera(self, nMontageIndex)
--     local nLocationLagSpeed = CameraIni.nMeleeLagSpeed
--     CameraGameHelper.EnableCameraLocationLag(true, self.tbCurrentMontageData.nHitSectionTime * 2, nLocationLagSpeed)
-- end

local function OnPreAttackActivate(self, tbAttackInfo, tbSubInfo)
    local pUEActor = self.pOwnerActor
    pUEActor.bUseRootMotion = self:IsUseRootMotion()
    -- local tbTemplate = self:GetMeleeTemplate()
    local isInJumping = pUEActor.CharacterMovement:IsFalling()

    local nMontageIndex = 1
    if not isInJumping then 
        nMontageIndex = self:GetNextMontageIndex()
    end
    
    self.pOwnerActor.CharacterMovement:DiscardPendingMove()
    self.nCurrentMontageIndex = nMontageIndex
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    self:PlayMontage(nMontageIndex, isInJumping, nAttackCoefficient)
    -- if self:IsUseRootMotion() then
        -- EventManager:OnFireEvent(ClientEventDef.EV_MELEE_COMBO_ATTACK_BGEIN)
        -- CommonMeleeAttackCamera(self, nMontageIndex)
    -- end

    tbSubInfo.nDuration = self.tbCurrentMontageData.nHitSectionTime
    self.nPostAttackDuration = self.tbCurrentMontageData.nSequenceLength
    local nStartTime = self.tbCurrentMontageData.nEndSectionTime

    if nStartTime > 0 then 
        self.nPostAttackDuration = nStartTime - self.tbCurrentMontageData.nHitSectionTime
    else 
        self.nPostAttackDuration = self.nPostAttackDuration  - self.tbCurrentMontageData.nHitSectionTime - END_TIME
    end
    if self.nPostAttackDuration  < 0 then  
        self.nPostAttackDuration  = 0
    end 

    if(not self.bServer) then
        local StartPos = VectorToTempTable(self.Owner:GetLocation())
        local pRotator = self.pOwnerActor:K2_GetActorRotation()
        -- local isInJumping = pUEActor.CharacterMovement:IsFalling()
        HumanWeaponHelper.SendMeleeAttackRoute(self.nInstanceId, nMontageIndex, pUEActor.CharacterMovement:IsFalling(), StartPos, pRotator.Yaw)
    end
end

local function OnPreAttackDeactivate(self, tbAttackInfo, bCancel)
end

local function CheckPlayHitEffect(tbTaker)
    if not tbTaker or not tbTaker.pUEActor then
        return false
    end

    if tbTaker:GetObjectType() == GameObjectTypeDef.DestructibleObject then
        return false
    end
    if not tbTaker.IsHuman then
        logerror("tbTaker cannot find IsHuman(), taker type is", tbTaker:GetObjectType())
        return false
    end
    if not tbTaker:IsHuman() then
        return false
    end

    return true
end

local function OnPostAttackActivate(self, tbAttackInfo, tbSubInfo)
    local pUEActor = self.pOwnerActor
    local isInJumping = pUEActor.CharacterMovement:IsFalling()
    if self.bEmptyHand and  isInJumping then 
        tbSubInfo.nDuration = self.nPostAttackDuration + JUMP_EMPTY_HAND_ATTACK_CD
    else 
        tbSubInfo.nDuration = self.nPostAttackDuration 
    end 

    
    -- local pUEActor = self.pOwnerActor
    local MeleeComponent = pUEActor.MeleeComponent
    local nAttackRange = MeleeComponent.AttackRange
    -- local nAttackRange = DEFAULT_RANGE
    local tbWeaponProperty = self:GetProperty()
    if not self.bEmptyHand then
        nAttackRange = tbWeaponProperty.nEffectiveRange*100
    end

    -- 这里不建议遍历所有pawn，遍历所有object撑死了也就一百个，所有pawn就不止这数了
    local pLocation = pUEActor:K2_GetActorLocation()
    local pRotation = pUEActor:K2_GetActorRotation()
    local pDoorClass = DOOR_PATH:load()
    local OutDoors = GetActorsInSectorRange(GWorld, pDoorClass, pLocation, pRotation,
        nAttackRange + ATTACK_RANGE_ADDTO_DOOR, ATTACK_ANGLE_TO_DOOR)
    local pWindowClass = WINDOW_PATH:load()

    local nSectorAngle = self:GetSectorAngle(isInJumping, self.nCurrentMontageIndex)

    local OutWindows = GetActorsInSectorRange(GWorld, pWindowClass, pLocation, pRotation,
        nAttackRange, nSectorAngle)
    local OutActors = GetActorsInSectorRange(GWorld, Pawn, pLocation, pRotation, nAttackRange, nSectorAngle)
    for i, v in ipairs(OutDoors) do
        table.insert(OutActors, v)
    end
    for i, v in ipairs(OutWindows) do
        table.insert(OutActors, v)
    end    

    local tbTakerIds, tbTaker
    local pMeleeComponent = self.pOwnerActor.MeleeComponent
    for _, v in ipairs(OutActors) do
        if v ~= pUEActor then
            tbTaker = GameObjectSystem:FindByUEActor(v)
            if tbTaker and HumanWeaponHelper.CanBeAttacked(tbTaker) and not tbTaker:IsDead() and 
                ((tbTaker.ObjectType ~= GameObjectTypeDef.DestructibleObject and pMeleeComponent:CheckCanHitOther(tbTaker.pUEActor)) or tbTaker.ObjectType == GameObjectTypeDef.DestructibleObject) then
                if(tbTakerIds == nil) then
                    tbTakerIds = {}
                end
                -- self:PlayHitAnimation(tbTaker)
                -- pMeleeComponent:PlayHitEffect(tbTaker.pUEActor)
                self:PlayHitEffect(tbTaker)

                table.insert(tbTakerIds, tbTaker:GetServerInstanceId())
            else  
                if not tbTaker then 
                    log("Can't Find Hit Player ")
                else  
                    log("Player is Dead ", tbTaker.szName)
                end 
            end
        end
    end

    if(tbTakerIds) then
        if(self.bServer) then
            self:AttackInServer(tbTakerIds)
        else
            HumanWeaponHelper.SendAttackRequest(self:GetInstanceId(), tbTakerIds)
        end
    end
end

local function OnPostAttackDeactivate(self, tbAttackInfo, bCancel)
    self.pOwnerActor.bUseRootMotion = false
    -- EventManager:OnFireEvent(ClientEventDef.EV_MELEE_COMBO_ATTACK_OVER)
end

function HumanWeaponMelee_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponMelee_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    self.tbAttackInfo = {
        nExitTypeWhenFinish = HumanWeaponMisc.AttackExitType.ALL_STATE_FINISHED,
        nAllLoopCount = self.OwnerComponent.bHasAuthority and -1 or 1,  -- 模拟客户端就loop一次
        nStateCount = 2,

        [1] = {
            OnActivate = OnPreAttackActivate,
            OnDeactivate = OnPreAttackDeactivate,
            bCanDeactivateExternally = false,
        },
        [2] = {
            OnActivate = OnPostAttackActivate,
            OnDeactivate = OnPostAttackDeactivate,
            bCanDeactivateExternally = false,
        },
    }
end

function HumanWeaponMelee_C:GenerateAttackInfo()
    return self.tbAttackInfo
end

local function OnEndRepMontage(self)
    local pOwnerActor = self.pOwnerActor
    local OwnerComponent = self.OwnerComponent
    local nCurrentState = OwnerComponent:GetCurrentState()
    local tbBPState = OwnerComponent:GetLuaToBPState()
    pOwnerActor:SetCurrentWeaponState(tbBPState[nCurrentState])
    pOwnerActor.bUseRootMotion = false
    local CharacterMovement = pOwnerActor.CharacterMovement
    CharacterMovement.bEnableSlideAlongSurface = true 
    CharacterMovement.bEnableClientAdjustPosition = true
end

function HumanWeaponMelee_C:PlayHitEffect(tbTaker)
    HumanWeaponHitEffectHelper:PlayHitEffectAndSound(tbTaker, HumanBodyDef.HUMAN_BODY, self.nTemplateId, nil, self:GetDamageFactor())
end

function HumanWeaponMelee_C:PlayRepMeleeAttackRoute(nMontageIndex, bJumping, StartPos, Yaw, bForce)
    local pOwnerActor = self.pOwnerActor
    local tbMontageData, pMontage = HumanWeaponMelee_C.super.PlayRepMeleeAttackRoute(self, nMontageIndex, bJumping, StartPos, Yaw, bForce)
    -- if not self:IsUseRootMotion() then 
    --     Timer.StartOwnerTimer(self, REP_MONTAGE_TIMER, OnEndRepMontage, self.tbCurrentMontageData.nHitSectionTime / self.tbCurrentMontageData.nRateScale)
    -- end
    pOwnerActor:SetCurrentWeaponState(Enum_HumanWeaponState.Attacking)
    return tbMontageData, pMontage
end


function HumanWeaponMelee_C:OnRepMeleeAttackRoute(tbRepData)
    if(not tbRepData) then
        return
    end
    -- local StartPos = tbRepData.start
    -- logdebug("tbRepData.start", self.rHumanMeleeAttackRoute.start.X, self.rHumanMeleeAttackRoute.start.Y, self.rHumanMeleeAttackRoute.start.Z)
    local nMontageIndex = tbRepData.montage_index
    local bJumping = tbRepData.in_jumping
    if(nMontageIndex == 0) then
        return
    end
 
    if(nMontageIndex < 0) then
        nMontageIndex = -nMontageIndex
    end
   
    local pOwnerActor = self.pOwnerActor
    local CharacterMovement = pOwnerActor.CharacterMovement
    CharacterMovement.bEnableSlideAlongSurface = false 
    CharacterMovement.bEnableClientAdjustPosition = false
    local StartPos = tbRepData.start
    -- logdebug("OnRepMeleeAttackRoute", nMontageIndex)
    self:PlayRepMeleeAttackRoute(nMontageIndex, bJumping, StartPos, tbRepData.yaw)
    pOwnerActor.bUseRootMotion = self:IsUseRootMotion()
end
function HumanWeaponMelee_C:OnRepMeleeAttackHits(tbRepData)
    if(tbRepData == nil) then
        return
    end
    local tbTakerIds = tbRepData.takers
    -- local pMeleeComponent = self.pOwnerActor.MeleeComponent
    local tbTaker

    for _, nId in ipairs(tbTakerIds) do
        if nId < 0 then  
            nId = nId * -1
        end
        tbTaker = GameObjectSystem:FindByInstanceId(nId)
        if(tbTaker and not tbTaker:IsDead()) then
            if self.Owner.ObjectType ~= GameObjectTypeDef.PlayerSelf and CheckPlayHitEffect(tbTaker) then
                -- self:PlayHitAnimation(tbTaker)
                -- pMeleeComponent:PlayHitEffect(tbTaker.pUEActor)
                self:PlayHitEffect(tbTaker)
            end
        end
    end
end

function HumanWeaponMelee_C:OnDestroyed()
    Timer.StopOwnerAllTimer(self, true)
    OnEndRepMontage(self)

    HumanWeaponMelee_C.super.OnDestroyed(self)
end

function HumanWeaponMelee_C:GetWeaponBPType()
    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == HumanWeaponDef.WeaponCategory.TwoHand then  
        return HumanWeaponType.TwoHand
    end 
    return HumanWeaponType.Melee
end 

-- function HumanWeaponMelee_C:GetHoldSocketName()
--     if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == HumanWeaponDef.WeaponCategory.TwoHand then  
--         return TwoHandHoldedSocket
--     end     
--     return HumanWeaponMelee_C.super.GetHoldSocketName(self)
-- end 

-- function HumanWeaponMelee_C:GetUnholdSocketName()
--     if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == HumanWeaponDef.WeaponCategory.TwoHand then  
--         return TwoHandUnholdedSocket
--     end     
--     return HumanWeaponMelee_C.super.GetUnholdSocketName(self)
-- end 
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

function HumanWeaponMelee_C:OnStateActivate(nState)
    HumanWeaponMelee_C.super.OnStateActivate(self, nState)
    if nState == HumanWeaponStateDef.ATTACKING then  
        Timer.StopOwnerTimer(self, DELAY_CLEAR_ANIMINDEX)
        local CharacterMovement = self.pOwnerActor.CharacterMovement
        CharacterMovement.bEnableSlideAlongSurface = false 
        CharacterMovement.bEnableClientAdjustPosition = false
        -- self.pOwnerActor:SetReplicateMovement(true)
        -- if self:IsUseRootMotion() then 
            -- CameraGameHelper.SetLockCameraScroll(true)
        -- end
        if self.bSelf and self:IsUseRootMotion() then 
            local PlayerSelf = GamePlayerSelfHelper:Get()
            if PlayerSelf then 
                if PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then 
                    PlayerSelf.pUEActor.PlayerInputComponent.MoveEnabled = false
                end
            end
        end
    end 
end

function HumanWeaponMelee_C:OnStateDeactivate(nState, bCancel)
    HumanWeaponMelee_C.super.OnStateDeactivate(self, nState, bCancel)
    if nState == HumanWeaponStateDef.ATTACKING then  
        HumanWeaponHelper.SendMeleeAttackRoute(self.nInstanceId, 0)
        local CharacterMovement = self.pOwnerActor.CharacterMovement
        CharacterMovement.bEnableSlideAlongSurface = true 
        CharacterMovement.bEnableClientAdjustPosition = true
        -- CameraGameHelper.SetLockCameraScroll(false)
        if self.bSelf then 
            local PlayerSelf = GamePlayerSelfHelper:Get()
            if PlayerSelf then 
                if PlayerSelf.pUEActor and PlayerSelf.pUEActor.PlayerInputComponent then 
                    PlayerSelf.pUEActor.PlayerInputComponent.MoveEnabled = true
                end
            end
        end
        local tbTemplate = self:GetMeleeTemplate()
        Timer.StartOwnerTimer(self, DELAY_CLEAR_ANIMINDEX, function() 
            self.LastMontageIndex = 0
        end, tbTemplate.nComboTime)
    end 
end

return HumanWeaponMelee_C