local luaclass = require("luaclass")
local HumanWeaponThrow = require("HumanWeaponThrow")
local HumanWeaponThrow_C = luaclass("HumanWeaponThrow_C", HumanWeaponThrow)

local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponHelper = require("HumanWeaponHelper")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local Timer = require("Timer")
local HumanWeaponType = require("HumanWeaponType")
local HumanThrownItemDef = require("HumanThrownItemDef")
local SelfEventHelper = require("SelfEventHelper")
local HumanMovementStateType = require("HumanMovementStateType")
local ThrowStateResDataTable = require("ThrowStateResDataTable")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local AnimDef = require("AnimDef")
local PropName = require("PropName")

local ABS = math.abs
local ThrownState = HumanWeaponMisc.ThrownState
local pTempVector = Vector()
local FAKE_READY_KEEP = 4

local THROW_EXPLODE_TIMER = "ThrowExplodeTimer"
local THROW_OUT_HAND_TIMER = "ThrowOutHandTimer"
local THROW_TAKE_AWAY_TIMER = "ThrowTakeAwayTimer"

local ThrownItemCategory = HumanThrownItemDef.ItemCategory

HumanWeaponThrow_C.tbAttackInfo = nil
HumanWeaponThrow_C.nThrownState = ThrownState.NONE
HumanWeaponThrow_C.nCurrentCount = 0
HumanWeaponThrow_C.bReset = true
HumanWeaponThrow_C.pThrowSoundEvent = nil
HumanWeaponThrow_C.EventHelper = nil
HumanWeaponThrow_C.nCurrentMovementState = -1
HumanWeaponThrow_C.pCurrentMontage = nil

local tbTempVector = {}
local function VectorToTempTable(pVector)
    tbTempVector.X = pVector.X
    tbTempVector.Y = pVector.Y
    tbTempVector.Z = pVector.Z
    return tbTempVector
end

-- local function ConvertThrowState(nState)
--     if ABS(nState) == ThrownState.NONE then 
--         return nState > 0 and "NONE" or "-NONE"
--     elseif ABS(nState) == ThrownState.IDLE then  
--         return nState > 0 and "IDLE" or "-IDLE"
--     elseif ABS(nState) == ThrownState.READY then  
--         return nState > 0 and "READY" or "-READY"
--     elseif ABS(nState) == ThrownState.THROWED then  
--         return nState > 0 and "THROWED" or "-THROWED"
--     end
-- end

local function GetThrowPosition(self)
    return VectorToTempTable(self.pOwnerActor.ThrowComponent:GetNewThrowLocation())
    -- if self.pWeaponActor then
    --     return VectorToTempTable(self.pWeaponActor:K2_GetActorLocation())
    -- end 
    -- return VectorToTempTable(self.pOwnerActor.ThrowComponent:GetThrowSocketLocation())

    
   -- if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == ThrownItemCategory.Hit then  
   -- else
        --return VectorToTempTable(self.pOwnerActor.ThrowComponent:GetStartLocation())
    --end
end

local function SetTrojectoryVisible(self, bVisible)
    if(not self.bSelf) then
        return
    end
    local pComponent = self.pOwnerActor.ThrowComponent
    if bVisible then  
        local tbProperty = self:GetProperty()
        pTempVector.X = self:IsHighThrow() and tbProperty.nInitialSpeed * 100 or tbProperty.nInitialLowSpeed * 100
        pTempVector.Y = 0
        pTempVector.Z = self:IsHighThrow() and tbProperty.nVerticleHighSpeed * 100 or tbProperty.nVerticleLowSpeed * 100
        pComponent:SetTrojectoryParam(pTempVector, Enum_ThrowTrojectory.Parabola, self:IsHighThrow())
        pComponent:ShowTrojectory()
    else  
        pComponent:HideTrojectory()
    end
end

local function SetWeaponVisibility(self, bVisible)
    self.pWeaponActor:SetActorHiddenInGame(not bVisible)
    if not bVisible then 
        self.pWeaponActor:DestroyReadyEffect()
    end
end

local function GetHumanArmorId(self)
    local HumanBattlePropertyComponent = self.Owner.HumanBattlePropertyComponent
    if HumanBattlePropertyComponent then
        local nCurrentArmorTemplatedId = self.Owner.HumanBattlePropertyComponent:GetProp(PropName.nCurrentArmorTemplateId)
        if nCurrentArmorTemplatedId < 0 then
            return 0
        end
        return nCurrentArmorTemplatedId
    end
    return 0
end

local function GetCurrentMontage(self, nThrowState, nMovementState)
    if nMovementState ~= HumanMovementStateType.Crawl_State and nMovementState ~= HumanMovementStateType.Crouch_State 
        and nMovementState ~= HumanMovementStateType.UpRight_State then  
        return nil
    end

    local nHumanTempateId = -1
    if self.Owner then 
        nHumanTempateId = self.Owner:GetHumanTemplateId()
    else  
        local tbPlayer = PlayerSelfHelper:Get()
        nHumanTempateId = tbPlayer:GetHumanTemplateId()
    end
    local nArmorId = GetHumanArmorId(self)
    local szAnim = ThrowStateResDataTable:GetAnimRes(nHumanTempateId, nThrowState, nMovementState, self.nTemplateId, nArmorId)
    log("[ThrowMontage] ::::",nHumanTempateId, nThrowState, nMovementState, self.nTemplateId, nArmorId)
    if not szAnim then 
        logerror("[ThrowMontage] can not find montage :", nHumanTempateId, nThrowState, nMovementState, self.nTemplateId, nArmorId)
        return nil
    end
    return szAnim:load()
end

local function PlayMontageByState(self, nNewState, nOldState)
    assert(nNewState ~= nil)
    if(nOldState == nNewState) then
        return 0
    end

    -- ready状态中切换则直接播keep
    local szMontage
    local nABSNewState = ABS(nNewState)
    local nAnimMovementState = self.nCurrentMovementState
    if(nOldState ~= nil and ABS(nOldState) == nABSNewState and nABSNewState == ThrownState.READY) then
        if(nOldState > nNewState) then
            -- ready high to ready low
            szMontage = GetCurrentMontage(self, -FAKE_READY_KEEP, nAnimMovementState)
        else
            -- ready low to ready high
            szMontage = GetCurrentMontage(self, FAKE_READY_KEEP, nAnimMovementState)
        end
    else
        szMontage = GetCurrentMontage(self, nNewState, nAnimMovementState)
    end
    self.pCurrentMontage = szMontage

    if(szMontage == nil) then
        return 0
    end

    local pUEActor = self.pOwnerActor
    return pUEActor:PlayAnimMontage(szMontage, 1, nil)
end

local function OnHumanMovementStateChange(self, Player, nOldState, nNewState)
    if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end

    if nNewState == HumanMovementStateType.Crawl_State or nNewState == HumanMovementStateType.Crouch_State or nNewState == HumanMovementStateType.UpRight_State then  
        self.nCurrentMovementState = nNewState
        if ABS(self.nThrownState) == ThrownState.READY or ABS(self.nThrownState) == ThrownState.THROW then 
            PlayMontageByState(self, self.nThrownState, nil)
        end
    end
end

local function UpdateReadyEffect(self, nNewState)
    if self.pWeaponActor == nil then    
        return
    end
    local nABSState = ABS(nNewState)
    if nABSState == ThrownState.READY then 
        self.pWeaponActor:PlayReadyEffect()
    elseif nABSState == ThrownState.IDLE or nABSState == ThrownState.NONE then
        self.pWeaponActor:DestroyReadyEffect()
    end
end

local function UpdateThrownState(self, nNewState, bUseOldThrowType)
   
    local nOldState = self.nThrownState
    
    if(bUseOldThrowType) then
        nNewState = self:ConvertToState(nOldState > 0, nNewState)
    end
    UpdateReadyEffect(self, nNewState)

    self.nThrownState = nNewState

    local nABSNewState = ABS(nNewState)
    if(nABSNewState == ThrownState.IDLE or nABSNewState == ThrownState.NONE) then
        self.pOwnerActor:StopAnimMontage(nil)
    else
        return PlayMontageByState(self, nNewState, nOldState)
    end
end

-- 拉引信，进到ready
local function OnPreAttack(self, _, tbSubInfo)

    self:SetThrowIsReset(false)
    local nState = self.nThrownState
    -- assert(ABS(nState) == ThrownState.IDLE)
    if ABS(nState) ~= ThrownState.IDLE then
        logerror("[WeaponThrow] : PreAttack, the thrown state should be idle")
    end

    --开始拉线的时候 就通知服务器 进入ready，不然其他人看不到 ready动作， rep下来也没有ready状态
    local nReadyMontageTime = UpdateThrownState(self, ThrownState.READY, true)
    local nLoopTime = 0
    if self.pCurrentMontage then
        nLoopTime = ExtendBlueprintFunctions.GetMontageSectionLength(self.pCurrentMontage, AnimDef.SectionName.THROW_ATTACK_LOOP)
        nLoopTime = nLoopTime <= 0 and 0 or nLoopTime
    end
    tbSubInfo.nDuration = nReadyMontageTime - nLoopTime

    HumanWeaponHelper.SendThrowReady(self.nInstanceId, self:IsHighThrow())
    self.nCurrentCount = HumanWeaponHelper.GetCurrentThrownItemCount(self)
    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) ~= ThrownItemCategory.Hit then  
        SetTrojectoryVisible(self, true)
    else 
        tbSubInfo.bCanDeactivateExternally = true
    end 

end

-- 保持拿到手上
local function OnBeginReadyState(self, _, tbSubInfo)

    local tbProperty = self:GetProperty()
    --这里客户端起一个timer是因为在OnPreAttack发送到服务器在Ready也会起 一个Timer,
    --如果客户端在下面的OnThrow不加这个Timer判断的话客户端OnThrow也会发送个消息到服务器，这样炸弹在手里炸的时候就会在服务器端调用两次OnThrow，会多扣一次投掷物
    if tbProperty.nPreExplodeTime and tbProperty.nPreExplodeTime > 0 then 
        tbSubInfo.nDuration = tbProperty.nPreExplodeTime + 0.1  --玩家在Ready会发消息给服务器，服务器起倒计时的Timer,这里加0.1是为了假设一个发送时间
        Timer.StartOwnerTimer(self, THROW_EXPLODE_TIMER, function() end, tbProperty.nPreExplodeTime )
    end
    --此时开始倒计时
    HumanWeaponHelper.SendThrowExplodeBegin(self.nInstanceId)
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_THROW_READY, self.Owner, self)
end

local function OnThrow(self, _, tbSubInfo)
    self.pOwnerActor:StopAnimMontage(nil)
    local tbProperty = self:GetProperty()
    local nPreExplodeTime = tbProperty.nPreExplodeTime
    local bExplodeInHand = false
    --燃烧弹没有 nPreExplodeTime
    if nPreExplodeTime and nPreExplodeTime > 0 then 
        local ThrowTimer = Timer.GetOwnerTimer(self, THROW_EXPLODE_TIMER)
        if not ThrowTimer or (nPreExplodeTime - ThrowTimer:GetElapsedTime() <= 0 ) then  
            bExplodeInHand = true
        end
        Timer.StopOwnerTimer(self, THROW_EXPLODE_TIMER)
    end
    
    if bExplodeInHand then  
        tbSubInfo.nDuration = 0
        SetWeaponVisibility(self, false)
    else  
        -- local pLocation = self.pOwnerActor.ThrowComponent:GetStartLocation()
        -- self.pOwnerActor.ThrowComponent:GetThrowWeaponDir(pLocation, 5000)
        Timer.StopOwnerTimer(self, THROW_OUT_HAND_TIMER)
        tbSubInfo.nDuration = UpdateThrownState(self, ThrownState.THROWED, true)

        --飞刀飞斧 需要扔的动作播一点了再扔出去
        local nThrowOutTime = 0
        HumanWeaponHelper.SendBeginThrow(self.nInstanceId)
        if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == ThrownItemCategory.Hit then  
            nThrowOutTime = tbSubInfo.nDuration * 0.2
        else  
            nThrowOutTime = tbSubInfo.nDuration * 0.12
        end
        Timer.StartOwnerTimer(self, THROW_OUT_HAND_TIMER, function() 
            SetWeaponVisibility(self, false)
            HumanWeaponHelper.SendThrowRequest(self.nInstanceId, GetThrowPosition(self), tbSubInfo.nDuration)
        end, nThrowOutTime )
    end
    
    SetTrojectoryVisible(self, false)
    self.nCurrentCount = self.nCurrentCount - 1
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_THROWED, self.Owner, self)
end

local function OnAttackFinished(self, _, bCancel)
    local bPreThrow = ABS(self.nThrownState) == ThrownState.THROWED
    UpdateThrownState(self, ThrownState.IDLE, true)
    SetTrojectoryVisible(self, false)

    if(bCancel) then
        --主动cancel，如果是从ready cancel过来的，可以cancel，如果已经扔出去了，不能cancel
        if not bPreThrow then 
            EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_THROW_CANCEL, self.Owner, self)
            HumanWeaponHelper.SendCancelThrow(self.nInstanceId)
        else
            EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_THROW_FINISHED, self.Owner, self)
        end
    else
        -- 必须放这发，这里attack状态还没切出去，执行完这个函数attackhelper就要判断是否有当前武器，然后进行状态切换了
        EventManager:OnFireEvent(CommonEventDef.EV_HUMAN_WEAPON_THROW_FINISHED, self.Owner, self)
    end
end

local function StopThrowTimers(self)
    Timer.StopOwnerTimer(self, THROW_EXPLODE_TIMER)
    Timer.StopOwnerTimer(self, THROW_OUT_HAND_TIMER)
    Timer.StopOwnerTimer(self, THROW_TAKE_AWAY_TIMER)
end

function HumanWeaponThrow_C:SetThrowIsReset(bSet)
    self.bReset = bSet
    if self.bReset then  
        StopThrowTimers(self)
    end
end

local function OnPlayThrowSound(self, pSoundEvent)
    if self.pWeaponActor == nil then  
        return 
    end
    local pSound = nil
    if pSoundEvent == Enum_SoundEventNotifyType.ExplosiveReady then  
        pSound = self.pWeaponActor.ReadySound
    elseif pSoundEvent == Enum_SoundEventNotifyType.ExplosiveLowThrow then  
        pSound = self.pWeaponActor.LowThrowSound
    elseif  pSoundEvent == Enum_SoundEventNotifyType.ExplosiveHighThrow then  
        pSound = self.pWeaponActor.HighThrowSound
    end
    if pSound then 
        local location = self.pWeaponActor:K2_GetActorLocation()
        local ZERO_ROTATOR = Rotator{Pitch = 0, Yaw = 0, Roll = 0}
        GameplayStatics.PlaySoundAtLocation(GWorld, pSound, location, ZERO_ROTATOR, 1, 1, 0, nil, nil, nil)
    end

end

local function UnregisterSoundEvent(self)
    if self.pThrowSoundEvent ~= nil then  
        self.EventHelper:UnregisterCppDelegate(self.pThrowSoundEvent)
        self.pThrowSoundEvent = nil
    end
    self.EventHelper:UnregisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED)
end

local function RegisterSoundEvent(self)
    self.EventHelper = SelfEventHelper()
    local OwnerObj = self.OwnerComponent.Owner
    if OwnerObj.pUEActor and OwnerObj.pUEActor.AnimationSoundComponent then
        local ThrowSoundDel = OwnerObj.pUEActor.AnimationSoundComponent.OnPlayThrowSound
        UnregisterSoundEvent(self)
        self.pThrowSoundEvent = self.EventHelper:RegisterCppDelegate(ThrowSoundDel, self, OnPlayThrowSound)
    end
    self.EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChange)
end  

function HumanWeaponThrow_C:IsThrowWeaponHit() 
    return HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == ThrownItemCategory.Hit
end

function HumanWeaponThrow_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponThrow_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    RegisterSoundEvent(self)
    --local tbProperty = self:GetProperty()
    local tbAttackInfo = {}
    self.tbAttackInfo = tbAttackInfo
    self.nCurrentCount = HumanWeaponHelper.GetCurrentThrownItemCount(self)
    self:SetThrowIsReset(true)

    tbAttackInfo.nExitTypeWhenFinish = HumanWeaponMisc.AttackExitType.ALL_STATE_FINISHED
    tbAttackInfo.nAllLoopCount = 1
    tbAttackInfo.OnFinished = OnAttackFinished

    -- 拉保险
    self:AddAttackSubState(tbAttackInfo, {
        OnActivate = OnPreAttack,
        --bCanDeactivateExternally = true,
        --nDuration = tbProperty.nPreActionTime,    用了这时间效果不好，用montage时间了
    })

    -- 维持在ready状态，这会可以切高低
    self:AddAttackSubState(tbAttackInfo, {
        OnActivate = OnBeginReadyState,
        bCanDeactivateExternally = true,
    })

    -- 松手投掷，发包给服务器，服务器扣道具，然后扔actor
    self:AddAttackSubState(tbAttackInfo, {
        OnActivate = OnThrow,
    })
end

function HumanWeaponThrow_C:CreateWeaponActor()
    HumanWeaponThrow_C.super.CreateWeaponActor(self)
    SetWeaponVisibility(self, false)
end

function HumanWeaponThrow_C:HideThrow()
    SetWeaponVisibility(self, false)
end

function HumanWeaponThrow_C:OnDestroyed()
    UnregisterSoundEvent(self)
    StopThrowTimers(self)
    UpdateThrownState(self, ThrownState.NONE)
    HumanWeaponThrow_C.super.OnDestroyed(self)
end

function HumanWeaponThrow_C:OnStateActivate(nState)
    HumanWeaponThrow_C.super.OnStateActivate(self, nState)

    if(nState == HumanWeaponStateDef.HOLDED or nState == HumanWeaponStateDef.HOLDING) then
        local OwnerObj = self.OwnerComponent.Owner
        self.nCurrentMovementState = OwnerObj ~= nil and OwnerObj.HumanMovementStateComponent:GetCurrentState() or -1

        local bLastHighThrow = self.OwnerComponent:IsLastHighThrow()
        self.OwnerComponent.bPendingHoldThrowWeapon = false
        self.nThrownState = bLastHighThrow and ThrownState.IDLE or -ThrownState.IDLE

        if nState == HumanWeaponStateDef.HOLDED then
            SetWeaponVisibility(self, true)
        end

    elseif (nState == HumanWeaponStateDef.UNHOLDING) then
        
        Timer.StartOwnerTimer(self, THROW_TAKE_AWAY_TIMER, function() 
            SetWeaponVisibility(self, false)
        end, 1 )
    elseif(nState == HumanWeaponStateDef.UNHOLDED) then
        self.nThrownState = ThrownState.NONE
        SetWeaponVisibility(self, false)
        SetTrojectoryVisible(self, false)
        self:SetThrowIsReset(true)
    end
end

function HumanWeaponThrow_C:GenerateAttackInfo()
    return self.tbAttackInfo
end

function HumanWeaponThrow_C:IsThrowing()
    return ABS(self.nThrownState) ~= ThrownState.NONE
end

function HumanWeaponThrow_C:CanThrowNext()
    return self.nCurrentCount > 0
end

function HumanWeaponThrow_C:SetThrowType(bHigh)
    local nState = self.nThrownState
    local nABSState = ABS(nState)
    if(nABSState ~= ThrownState.READY and nABSState ~= ThrownState.IDLE) then
        -- 只有idle和ready才能切
        return false
    end

    if(bHigh == self:IsHighThrow()) then
        return false
    end

    UpdateThrownState(self, self:ConvertToState(bHigh, nABSState), false)

    local pComponent = self.pOwnerActor.ThrowComponent
    local tbProperty = self:GetProperty()
    pTempVector.X = self:IsHighThrow() and tbProperty.nInitialSpeed * 100 or tbProperty.nInitialLowSpeed * 100
    pTempVector.Y = 0
    pTempVector.Z = self:IsHighThrow() and tbProperty.nVerticleHighSpeed * 100 or tbProperty.nVerticleLowSpeed * 100
    pComponent:SetTrojectoryParam(pTempVector, Enum_ThrowTrojectory.Parabola, self:IsHighThrow())

    if(nABSState == ThrownState.READY) then
        -- 只有ready才有必要发服务器，idle本地切就完事了
        HumanWeaponHelper.SendChangeThrowType(self.nInstanceId, bHigh)
    end
    return true
end

function HumanWeaponThrow_C:OnWeaponAttached(bAttached)
    HumanWeaponThrow_C.super.OnWeaponAttached(self, bAttached)
    SetWeaponVisibility(self, bAttached)
end

function HumanWeaponThrow_C:IsHighThrow()
    return self.nThrownState > 0
end

function HumanWeaponThrow_C:OnRepThrownState(nState)
    --用于更新其他人的 ThrownState
    local nABSState = ABS(nState)
    if nABSState == ThrownState.THROWED then 
        SetWeaponVisibility(self, false)
    elseif nABSState == ThrownState.NONE then 
        local id = self.OwnerComponent.nNextWeapon
        if id == nil then 
            SetWeaponVisibility(self, true)
        end
    end

    if(self.nThrownState == nState) then
        return
    end

    UpdateThrownState(self, nState, false)
end

function HumanWeaponThrow_C:GetWeaponBPType()
    if HumanWeaponHelper.GetWeaponCategory(self.nTemplateId) == ThrownItemCategory.Hit then  
        return HumanWeaponType.ThrowWeapon
    end 
    return HumanWeaponType.Explosive
end 



return HumanWeaponThrow_C