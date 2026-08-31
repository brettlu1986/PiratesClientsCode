--File Name    : ULFFAHumanMovement.lua
--Description  : ULFFAHumanMovement
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAHumanMovement = luaclass("ULFFAHumanMovement", UILogicBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanWeaponHelper = require("HumanWeaponHelper")
local GameCameraSystem = require("GameCameraSystem")
local BattlePickupSystem = require("BattlePickupSystem")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local InputHandle = require("InputHandle")
local BattleAbilitySystem = require("BattleAbilitySystem")
local Timer = require("Timer")

local AbortEventReciever = dynamic_require("AbortEventReciever")

local HumanMovementStateType = require("HumanMovementStateType")
local HumanCapsuleDataTable = require("HumanCapsuleDataTable")
local HumanJumpTypeDef = require("HumanJumpTypeDef")
local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponDef = require("HumanWeaponDef")
local ProhibitTypeDefine = require("ProhibitTypeDefine")
local GameObjectTypeDef = require("GameObjectTypeDef")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local AbortType = require("AbortTypeDefine")
local HumanSwimmingIni = require("HumanSwimmingIni")
local PropName = require("PropName")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local HumanWeaponType = HumanWeaponMisc.Type
-------------------------------------------------------------------------------

ULFFAHumanMovement.tbSpaceBarPressedHandle = nil
ULFFAHumanMovement.tbSpaceBarReleasedHandle = nil
ULFFAHumanMovement.tbHumanMovementModeHandle = nil

ULFFAHumanMovement.bAutoSwimming = false
ULFFAHumanMovement.bShowAutoSwiming = nil
ULFFAHumanMovement.tbSwimmingStaminaTimer = nil
ULFFAHumanMovement.bSwimming = false
ULFFAHumanMovement.bOtherPostProcess = nil
ULFFAHumanMovement.nPostProcessRetId = nil

-------------------------------------------------------------------------------

local SWIMMINGSTAMINA_EFFECT_ID = 5
local SWIMING_STAMINA_TIME = 5
local SWIMMING_DROWNING_BUFF_ID = 31005

-------------------------------------------------------------------------------

-- Utils & network
local function GetChangeStateHeight(nState)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nCurrentMovementState  = PlayerSelf.HumanMovementStateComponent:GetCurrentState()

    local nTemplateId = PlayerSelf:GetHumanTemplateId()
    local CapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, nCurrentMovementState)
    if not CapsuleData then
        return 0
    end

    if nCurrentMovementState == HumanMovementStateType.Crawl_State and nState ==  HumanMovementStateType.Crouch_State then
        return CapsuleData.nToCrouchHeight
    end
    return CapsuleData.nToUpRightHeight
end

local function GetStateHeight(nState)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nCurrentMovementState  = PlayerSelf.HumanMovementStateComponent:GetCurrentState()

    local nTemplateId = PlayerSelf:GetHumanTemplateId()
    local CapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, nCurrentMovementState)
    if not CapsuleData then
        return 0
    end

    return CapsuleData.nCapsuleHalfHeight
end

-- ui显示相关
local function BoolToVisibility(bShow)
    return bShow and ESlateVisibility.Visible or ESlateVisibility.Hidden
end

local function OnHumanCrawlToCrouch(self)
    self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
    self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Checked)
end

local function UpdateSwimmingWidget(self, bSwimming)
    local Player = GamePlayerSelfHelper:Get()
    self.bSwimming = bSwimming
    local pWidgetRef = self.pWidgetRef
    
    pWidgetRef.ovlAutoSwitch:SetVisibility(BoolToVisibility(bSwimming))
    pWidgetRef.btnFight2:SetVisibility(BoolToVisibility(not bSwimming))

    self:SetPostureBtnsVisibility(not bSwimming)
    self.Owner.ulFFAHumanThrownItem:SetShortcutVisibility(not bSwimming)

    if bSwimming then
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        local pLocation = Player:GetLocation()
        local nRealRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)      
        if self.IsSwimmingVolume(nRealRegionType) then
            if self.bShowAutoSwiming then  
                pWidgetRef.btnAuto:SetVisibility(ESlateVisibility.Visible)
            end
        else  
            pWidgetRef.btnAuto:SetVisibility(ESlateVisibility.Hidden)
        end 

        local nStamina = Player.HumanBattlePropertyComponent:GetSwimmingStamina()
        local nPercent = nStamina / HumanSwimmingIni.nMaxStamina
        pWidgetRef.pbrgHeard:SetPercent(nPercent)
        bSwimming = nStamina < HumanSwimmingIni.nMaxStamina
    end
    pWidgetRef.ovlHeard:SetVisibility(BoolToVisibility(bSwimming))
    
    self.EventHelper:FireEvent(ClientEventDef.EV_SETTING_LEFT_HAND_FIRE)
end

local function OnUEMovementChanged(self, pUEActor, PrevMovementMode, PrevCustomMode)
    local CurrentMovementMode = pUEActor.CharacterMovement.MovementMode
    if CurrentMovementMode == EMovementMode.MOVE_Falling then
        if not GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanAiming) then
            return
        end
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
    end

end

local function ExitAimForBow(self)
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon()
    if not tbCurrentWeapon then  
        return 
    end
    if HumanWeaponHelper.GetWeaponCategory(tbCurrentWeapon.nTemplateId) == HumanWeaponDef.WeaponCategory.Bow
        and  HumanWeaponComponent:IsAiming() then  
        self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
    end
end

-- 跳
local function OnJumpClicked(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsDead() then
        return
    end
    local pUEActor = PlayerSelf.pUEActor

    if not pUEActor then
        return
    end

    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    local CharacterMovement = pUEActor.CharacterMovement
    if not PlayerSelf:IsHuman() or not HumanMovementStateComponent or not CharacterMovement or CharacterMovement:GetFallLandingStunTime() > -1 then
        return
    end
    local nCurrentMovementState = HumanMovementStateComponent:GetCurrentState()
    if nCurrentMovementState == HumanMovementStateType.Jumping_SpeelWall  then
        log("OnJumpClicked OnSpeel")
        return
    end
    if (pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling) then
        return
    end

    if not HumanMovementStateComponent.bEnableMove or nCurrentMovementState == HumanMovementStateType.Dying_State
        or HumanMovementStateComponent:IsInVehicle() 
        or HumanMovementStateComponent.bIsCrouching then
        return
    end

    local ProgressBarComponent = PlayerSelf.ProgressBarComponent
    if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
        ProgressBarComponent:Abort()
        -- return
    end

    if GameCameraSystem:IsCameraLockInput() then  
        return 
    end
    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
    local WeaponState = HumanWeaponComponent:GetCurrentState()
    if nCurrentMovementState == HumanMovementStateType.Crouch_State or nCurrentMovementState == HumanMovementStateType.Crawl_State then
        local bUseBox = true 
        if nCurrentMovementState == HumanMovementStateType.Crouch_State then  
            bUseBox = false
        end 
        if not pUEActor:CheckPawnCanUp(GetChangeStateHeight(), bUseBox) then 
            return 
        end 

        if HumanWeaponComponent:IsAttacking() then
            return 
        end
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
        -- OnMovementStateChanged(HumanMovementStateType.UpRight_State)
        self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
        self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)
        return
    end

    if WeaponState ~= HumanWeaponStateDef.HOLDING and WeaponState ~= HumanWeaponStateDef.UNHOLDING and not HumanWeaponComponent:IsAttacking() and not BattlePickupSystem:IsPickingUp()then
        
        local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
        local pLocation = PlayerSelf:GetLocation()
        local nRealRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)             
        
        --攀爬系数小于等于0说明有盔甲或者其他buff限制不让使用攀爬
        local nClimbCoefficient = PlayerSelf.HumanBattlePropertyComponent:GetProp(PropName.nClimbCoefficient)
        log("ULFFAHumanMovement OnJumpClicked nClimbCoefficient:", nClimbCoefficient)
        if not self.IsSwimmingVolume(nRealRegionType) and nClimbCoefficient > 0 then
            local tbDestructible = HumanMovementStateComponent:GetDestructibleObject()
            local nDestructibleInstanceId = 0
            if tbDestructible then  
                nDestructibleInstanceId = tbDestructible:GetServerInstanceId()
                tbDestructible.pUEActor:SetCollisionEnabled(false)
            end 
            -- logdebug("nDestructibleInstanceId", nDestructibleInstanceId)
            if GlobalVariableSystem.bUseNewSpeel then
                local eWallType, pRotator, pSpeelPos, pTargetPos, pExpectStartPos = pUEActor:GetSpeelInfo()
	            local WallType = enumtoint(eWallType)
	            
	            if WallType ~= HumanJumpTypeDef.None then
	            	local tbSpeelPos       = {X = pSpeelPos.X,       Y = pSpeelPos.Y,       Z = pSpeelPos.Z}
                    local tbTargetPos      = {X = pTargetPos.X,      Y = pTargetPos.Y,      Z = pTargetPos.Z}
                    local tbExpectStartPos = {X = pExpectStartPos.X, Y = pExpectStartPos.Y, Z = pExpectStartPos.Z}
	            
                    HumanMovementStateComponent:RequestSpeelNew(WallType, nDestructibleInstanceId, tbSpeelPos, tbTargetPos, tbExpectStartPos, pRotator.Yaw)
                    destroyUserData(pSpeelPos)
	            	destroyUserData(pTargetPos)
	            	destroyUserData(pExpectStartPos)
                    destroyUserData(pRotator)
                    
	                self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
                    return
	            end
            else
                local eWallType, WallLocation, Rotator = pUEActor:GetJumpType()
                local WallType = enumtoint(eWallType)
                if WallType ~= HumanJumpTypeDef.None then 
                    HumanMovementStateComponent:RequestSpeel(WallType, nDestructibleInstanceId, WallLocation, Rotator.Yaw)
                    destroyUserData(WallLocation)
                    destroyUserData(Rotator)
                    
                    self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
                    return
                end
            end
            
            if tbDestructible then  
                tbDestructible.pUEActor:SetCollisionEnabled(true)
            end
        end
    else 
        local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon()
        if(not tbCurrentWeapon or tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.MELEE)) then
            return 
        end
    
    end
    pUEActor:Jump()
    self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
    --self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, HumanWeaponCalculator.SpreadEnum.MOVE_JUMP)
end

local function OnJumpRelease(self)

    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsDead() or not PlayerSelf:IsHuman() then
        return
    end
    PlayerSelf.pUEActor:StopJumping()
    --self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_MOVE_TYPE_CHANGED, HumanWeaponCalculator.SpreadEnum.MOVE_JUMP)
end

-- 蹲
local function OnSquatStateChanged(self, bIsChecked)

    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsDead() then
        return
    end
    local pUEActor = PlayerSelf.pUEActor
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent

    if not HumanWeaponComponent or not HumanMovementStateComponent then  
        return
    end

    local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon(true)
    -- 由于动画问题，弓攻击时不能蹲下
    local bOtherAttacking = tbCurrentWeapon and HumanWeaponHelper.GetWeaponCategory(tbCurrentWeapon.nTemplateId) == HumanWeaponDef.WeaponCategory.Bow and HumanWeaponComponent:IsAttacking()

    if bIsChecked then
        self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)

        local _, _, Z = PlayerSelf:GetLocationXYZ()
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        if Z < GetStateHeight(nMovementState) then  
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CROUCH_LOCK"), 1)
            return            
        end 
        if pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling or
        not HumanMovementStateComponent:CanChangeState(HumanMovementStateType.Crouch_State)
        or bOtherAttacking
        or self.Owner.ulFFAHumanVehicle.bPendingToVechicle then
            -- self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)
            return
        end
        if nMovementState == HumanMovementStateType.Crawl_State and 
            not pUEActor:CheckPawnCanUp(GetChangeStateHeight(HumanMovementStateType.Crouch_State), false) then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CROUCH_LOCK"), 1)
            -- self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)
            return
        end

        if GameCameraSystem:IsCameraLockInput() then  
            -- self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)
            return 
        end

        if HumanMovementStateComponent:GetLastState() == HumanMovementStateType.Crawl_State then 
            local ProgressBarComponent = PlayerSelf.ProgressBarComponent
            if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
                ProgressBarComponent:Abort()
                -- return
            end
        end
        
        self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
        -- OnMovementStateChanged(HumanMovementStateType.Crouch_State)
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.Crouch_State)
        self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_POSE_CHANGED, HumanWeaponCalculator.SpreadEnum.POSE_CROUCH)
    else
        self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Checked)
        if  bOtherAttacking  or HumanMovementStateComponent.bIsCrouching then
            -- self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Checked)
            return
        end
        if not pUEActor:CheckPawnCanUp(GetChangeStateHeight(), false) then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_UPRIGHT_LOCK"), 1)
            -- self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Checked)
            return
        end
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
        -- OnMovementStateChanged(HumanMovementStateType.UpRight_State)
        self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_POSE_CHANGED, HumanWeaponCalculator.SpreadEnum.POSE_STAND)
    end
    -- UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 1)
end

local function OnSquatStateClicked(self)
    local bChecked = self.pWidgetRef.chkSquat:IsChecked()
    OnSquatStateChanged(self, not bChecked)
end

--趴
local function OnGrovelStateChanged(self, bIsChecked)
    
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf:IsDead() or PlayerSelf:IsShip() then
        return
    end
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
    if not HumanWeaponComponent or not HumanMovementStateComponent then 
        return 
    end

    local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon(true)
    -- 武器为近战或弓且在攻击时不能趴
    local bOtherAttacking = tbCurrentWeapon and (tbCurrentWeapon:IsType(HumanWeaponType.MELEE) or HumanWeaponHelper.GetWeaponCategory(tbCurrentWeapon.nTemplateId) == HumanWeaponDef.WeaponCategory.Bow) and HumanWeaponComponent:IsAttacking()
    
    if bIsChecked then
        self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
        local _, _, Z = PlayerSelf:GetLocationXYZ()
        local nMovementState = HumanMovementStateComponent:GetCurrentState()
        if Z < GetStateHeight(nMovementState) then  
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CRAWL_LOCK"), 1)
            return            
        end         
        local ProgressBarComponent = PlayerSelf.ProgressBarComponent
        if ProgressBarComponent and ProgressBarComponent:IsProhibit(ProhibitTypeDefine.CRAWL) then
            self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CRAWL_LOCK"), 1)
            return
        end
        if PlayerSelf.pUEActor.CharacterMovement.MovementMode == EMovementMode.MOVE_Falling or
         bOtherAttacking  or not HumanMovementStateComponent:CanChangeState(HumanMovementStateType.Crawl_State)
            or self.Owner.ulFFAHumanVehicle.bPendingToVechicle then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CRAWL_LOCK"), 1)
            -- self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
            return
        end
        local nTemplateId = PlayerSelf:GetHumanTemplateId()
        local CapsuleData = HumanCapsuleDataTable:GetTemplate(nTemplateId, HumanMovementStateType.Crawl_State)
        if not PlayerSelf.pUEActor:CheckCanCrawl(CapsuleData.nCapsuleRadius, CapsuleData.nCapsuleHalfHeight) then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CRAWL_LOCK"), 1)
            -- self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
            return
        end

        if GameCameraSystem:IsCameraLockInput() then  
            -- self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
            return 
        end

        ExitAimForBow(self)
        self.pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.Crawl_State)
        -- OnMovementStateChanged(HumanMovementStateType.Crawl_State)
        self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_POSE_CHANGED, HumanWeaponCalculator.SpreadEnum.POSE_CRAWL)
    else
        self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Checked)
        if not HumanMovementStateComponent.bEnableMove or bOtherAttacking or HumanMovementStateComponent.bIsCrouching then
            -- UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_CRAWL_LOCK"), 1)
            -- self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Checked)
            return
        end

        if not PlayerSelf.pUEActor:CheckPawnCanUp(GetChangeStateHeight(), true) then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_UPRIGHT_LOCK"), 1)
            -- self.pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Checked)
            return
        end
        local ProgressBarComponent = PlayerSelf.ProgressBarComponent
        if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
            ProgressBarComponent:Abort()
            -- return
        end        
        HumanMovementStateComponent:RequestChangeMovement(HumanMovementStateType.UpRight_State)
        -- OnMovementStateChanged(HumanMovementStateType.UpRight_State)
        self.EventHelper:FireEvent(ClientEventDef.EV_HUMAN_POSE_CHANGED, HumanWeaponCalculator.SpreadEnum.POSE_STAND)
    end
    -- UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"), 1)
end

local function OnGrovelStateClicked(self)
    local bChecked = self.pWidgetRef.chkGrovel:IsChecked()
    OnGrovelStateChanged(self, not bChecked)
end

-- 游泳
local function OnAutoSwimming(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or not PlayerSelf:IsHuman() or not PlayerSelf.pUEActor then
        return 
    end 
    if self.bAutoSwimming then  
        -- PlayerSelf.pUEActor:AbortNavMove()
        -- self.bAutoSwimming = false 
        return 
    end 
    
    local ProgressBarComponent = PlayerSelf.ProgressBarComponent
    if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
        ProgressBarComponent:Abort()
        -- return
    end

    local tbAbortTypes = {AbortType.HUMAN_MOVE, AbortType.HUMAN_PROGRESS_BAR}
    local function OnAbort()
        if PlayerSelf and PlayerSelf:IsHuman() and PlayerSelf.pUEActor then 
            PlayerSelf.pUEActor:AbortNavMove()
        end
        self.bAutoSwimming = false 
    end
    if self.EventReciever and self.EventReciever.Uninit then
        self.EventReciever:Uninit()
    end
    
    self.EventReciever = AbortEventReciever()
    self.EventReciever:Init(ProgressBarComponent, tbAbortTypes, OnAbort)


    local Location = PlayerSelf:GetLocation()
    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local nRealRegionType = GridTypeManager:GetRegionType(Location.X, Location.Y)   
    if nRealRegionType == EPiratesGridRegionType.Shore then  
        return false
    end 
    local bRet, NewLoction = GridTypeManager:GetClosestPositionOfRegionType(Location.X, Location.Y, EPiratesGridRegionType.Shore)
    if(not bRet) then
        logerror("OnAutoSwimming GetClosestPositionOfRegionType failed,", Location.X, Location.Y)
        return false
    end
    local TargetPosition = Vector{X=NewLoction.X, Y=NewLoction.Y, Z=0}
    local _Ret = PlayerSelf.pUEActor:SwimNavMove(TargetPosition, 100)
    self.bAutoSwimming = true
    -- logdebug("OnAutoSwimming", enumtoint(Ret))
end

local function StopSwimmingStaminaEffect(self)
    local tbSelfPlayer = GamePlayerSelfHelper:Get()
    log("PostProcessEffect stop swimming stamina", self.nPostProcessRetId, tbSelfPlayer)
    if self.nPostProcessRetId ~= nil and tbSelfPlayer ~= nil then
        BattleAbilitySystem:StopPostProcessEffect(tbSelfPlayer, self.nPostProcessRetId)
    end
    self.nPostProcessRetId = nil
end

local function ClearSwimmingStaminaTimer(self)
    if self.tbSwimmingStaminaTimer then
        self.tbSwimmingStaminaTimer:Clear()
        self.tbSwimmingStaminaTimer = nil
    end
end

local function PlaySwimmingStaminaEffect(self)
    if self.bOtherPostProcess then
        return
    end
    local tbSelfPlayer = GamePlayerSelfHelper:Get()
    log("PostProcessEffect play swimming stamina", tbSelfPlayer, self.nPostProcessRetId)
    if tbSelfPlayer ~= nil and self.nPostProcessRetId == nil then
        self.nPostProcessRetId = BattleAbilitySystem:PlayPostProcessEffect(tbSelfPlayer, SWIMMINGSTAMINA_EFFECT_ID)
    end
end

local function OnSwimmingStaminaChange(self, nServerInstanceId, nStamina)
    if GamePlayerSelfHelper:GetServerInstanceId()  ~= nServerInstanceId then
        return
    end
    local Hidden, Collapsed, Visible, SelfHitTestInvisible = 
        ESlateVisibility.Hidden, ESlateVisibility.Collapsed, ESlateVisibility.Visible, ESlateVisibility.SelfHitTestInvisible
    local pWidgetRef = self.pWidgetRef

    pWidgetRef.imgSwimmingWarning1:SetVisibility(Collapsed)     
    pWidgetRef.imgSwimmingWarning2:SetVisibility(Collapsed)

    if nStamina >= HumanSwimmingIni.nMaxStamina then
        pWidgetRef.ovlHeard:SetVisibility(Hidden)
        StopSwimmingStaminaEffect(self)
        ClearSwimmingStaminaTimer(self)   
    else
        pWidgetRef.ovlHeard:SetVisibility(Visible)
        if nStamina <= 0 then
            pWidgetRef.imgSwimmingWarning1:SetVisibility(SelfHitTestInvisible)     
            pWidgetRef.imgSwimmingWarning2:SetVisibility(SelfHitTestInvisible)     
            PlaySwimmingStaminaEffect(self)
            if self.tbSwimmingStaminaTimer == nil then
                local fnShowToast = function()
                    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SWIMMING_WARNING"))                
                end
                self.tbSwimmingStaminaTimer = Timer.NewTimer(fnShowToast, SWIMING_STAMINA_TIME, true)
            end
        end
    end
    local nPercent = nStamina / HumanSwimmingIni.nMaxStamina
    -- logdebug("nPercent", nPercent, "nStamina", nStamina)
    self.pWidgetRef.pbrgHeard:SetPercent(nPercent)
    self.EventHelper:FireEvent(ClientEventDef.EV_FFA_HUMAN_SWIMMING_STAMINA_CHANGE, nStamina, nPercent)
    if nStamina <= 0 then
        self.Owner:PlayAnimation("animHeard", 0, 0, EUMGSequencePlayMode.Forward, 1)
    else
        self.Owner:StopAnimation("animHeard")
    end
end

local function SetShowAutoSwimingEnable(self, bEnable)
    self.bShowAutoSwiming = bEnable
end

local function OnPressedKeyboard(self, szKey, bValue)
    if szKey ~= "SpaceBar" then
        return
    end

    if bValue then
        OnJumpClicked(self)
    else
        OnJumpRelease(self)
    end
end

local function OnPostProcessEffect(self, bPlay)
    log("PostProcessEffect play", bPlay, self.tbSwimmingStaminaTimer)
    self.bOtherPostProcess = bPlay
    if bPlay then
        StopSwimmingStaminaEffect(self)
    else
        if self.tbSwimmingStaminaTimer ~= nil then
            PlaySwimmingStaminaEffect(self)
        end
    end
end

local function OnBuffRemoved(self, nInstanceId, nTemplateId)
    if nTemplateId == SWIMMING_DROWNING_BUFF_ID then
        StopSwimmingStaminaEffect(self)
        ClearSwimmingStaminaTimer(self)   
    end 
end

local function UnregisterPCInput(self)
    if self.tbSpaceBarPressedHandle then
        self.EventHelper:UnRegisterHandle(self.tbSpaceBarPressedHandle)
    end
    if self.tbSpaceBarReleasedHandle then
        self.EventHelper:UnRegisterHandle(self.tbSpaceBarReleasedHandle)
    end
    self.tbSpaceBarPressedHandle = nil
    self.tbSpaceBarReleasedHandle = nil
end

local function RegisterPCInput(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local GameVehicleComponent =  PlayerSelf.GameVehicleComponent
    if not GameVehicleComponent then  
        return 
    end
    if not PlayerSelf:IsHuman() then
        return
    end
    UnregisterPCInput(self)
    self.tbSpaceBarPressedHandle = InputHandle:BindKeyPressed(EInputKey.SpaceBar, function() OnPressedKeyboard(self, "SpaceBar", true) end, self)
    self.tbSpaceBarReleasedHandle = InputHandle:BindKeyReleased(EInputKey.SpaceBar, function() OnPressedKeyboard(self, "SpaceBar", false) end, self)
    self.EventHelper:RegisterHandle(self.tbSpaceBarPressedHandle)
    self.EventHelper:RegisterHandle(self.tbSpaceBarReleasedHandle)
end

local function OnHumanMovementStateChange(self, Player, nOldState, nNewState)
    if not Player or Player.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local pWidgetRef = self.pWidgetRef

    pWidgetRef.chkGrovel:SetIsChecked(nNewState == HumanMovementStateType.Crawl_State)
    pWidgetRef.chkSquat:SetIsChecked(nNewState == HumanMovementStateType.Crouch_State)
    
    if nNewState == HumanMovementStateType.Swimming then
        UpdateSwimmingWidget(self, true)
    elseif nOldState == HumanMovementStateType.Swimming and nNewState ~= HumanMovementStateType.Swimming then
        self.bAutoSwimming = false 
        UpdateSwimmingWidget(self, false)
    end
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
    if HumanWeaponComponent then
        self.Owner:SetCheckRange()
    end

    if nNewState == HumanMovementStateType.Vehicle then
        UnregisterPCInput(self)
    end

    if nNewState == HumanMovementStateType.UpRight_State then
        RegisterPCInput(self)
    end

    self.Owner.ulFFAHumanVehicle:UpdateCvsHorseVisibility()
end

-------------------------------------------------------------------------------

function ULFFAHumanMovement:Activate()
    local EventHelper = self.EventHelper

    RegisterPCInput(self)

    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChange)

    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf:IsHuman() then 
        local pUEActor = PlayerSelf.pUEActor
        self.tbHumanMovementModeHandle = EventHelper:RegisterCppDelegate(pUEActor.MovementModeChangedDelegate, self, OnUEMovementChanged)
    end

    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    local MovementState = HumanMovementStateComponent:GetCurrentState()
    if MovementState == HumanMovementStateType.Swimming then
        UpdateSwimmingWidget(self, true)
    else 
        UpdateSwimmingWidget(self, false)
    end
end

function ULFFAHumanMovement:Deactivate()
    local pWidgetRef = self.pWidgetRef
    local EventHelper = self.EventHelper

    pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Unchecked)
    pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Unchecked)

    UnregisterPCInput(self)

    EventHelper:UnregisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED)

    if self.tbHumanMovementModeHandle then
        EventHelper:UnregisterCppDelegate(self.tbHumanMovementModeHandle)
        self.tbHumanMovementModeHandle = nil 
    end

    StopSwimmingStaminaEffect(self)
    ClearSwimmingStaminaTimer(self)

    if self.EventReciever and self.EventReciever.Uninit then
        self.bAutoSwimming = false 
        self.EventReciever:Uninit()
    end
end

function ULFFAHumanMovement:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    local BuffComponentClient = GamePlayerSelfHelper:Get().BuffComponentClient


    EventHelper:RegisterCppDelegate(pWidgetRef.btnJump.OnPressed, self, OnJumpClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnJump.OnReleased, self, OnJumpRelease)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkSquat.OnCheckStateChanged , self, OnSquatStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSquat.OnClicked , self, OnSquatStateClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.chkGrovel.OnCheckStateChanged, self, OnGrovelStateChanged)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnGrovel.OnClicked, self, OnGrovelStateClicked)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnAuto.OnClicked, self, OnAutoSwimming)

    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_HUMAN_CRAWL_TO_CROUCH, self, OnHumanCrawlToCrouch)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_SWIMMING_STAMINA_CHANGE, self, OnSwimmingStaminaChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_SET_SHOW_AUTOSWIMING, self, SetShowAutoSwimingEnable)
    EventHelper:RegisterEvent(ClientEventDef.EV_POST_PROCESS_EFFECT, self, OnPostProcessEffect)

    EventHelper:RegisterLuaDelegate(BuffComponentClient.OnBuffRemoveDelegate, OnBuffRemoved, self)

end

function ULFFAHumanMovement:OnCreate()
end

function ULFFAHumanMovement:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.bShowAutoSwiming = true

    pWidgetRef.btnAuto:SetVisibility(ESlateVisibility.Hidden)
end

function ULFFAHumanMovement:SetPostureBtnsVisibility(bShow)
    local pVisibility = bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnJump:SetVisibility(pVisibility)
    pWidgetRef.chkGrovel:SetVisibility(pVisibility)
    pWidgetRef.btnGrovel:SetVisibility(pVisibility)
    pWidgetRef.chkSquat:SetVisibility(pVisibility)
    pWidgetRef.btnSquat:SetVisibility(pVisibility)
    pWidgetRef.btnFight1:SetVisibility(pVisibility)
    pWidgetRef.cvsFight2:SetVisibility(pVisibility)
end

function ULFFAHumanMovement:RestoreUIStateForReconnect(HumanMovementStateComponent)
    local nCurState = HumanMovementStateComponent:GetCurrentState() 
    local pWidgetRef = self.pWidgetRef
    if nCurState == HumanMovementStateType.Crawl_State then   
        pWidgetRef.chkGrovel:SetCheckedState(ECheckBoxState.Checked)
    elseif nCurState == HumanMovementStateType.Crouch_State then  
        pWidgetRef.chkSquat:SetCheckedState(ECheckBoxState.Checked)
    end
end

function ULFFAHumanMovement.IsSwimmingVolume(nRegionType)
    if nRegionType ==EPiratesGridRegionType.Ocean or nRegionType ==EPiratesGridRegionType.Port or nRegionType ==EPiratesGridRegionType.Lake then 
        return true
    end
    return false
end

return ULFFAHumanMovement