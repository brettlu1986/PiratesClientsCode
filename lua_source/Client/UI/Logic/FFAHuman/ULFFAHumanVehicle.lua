-----------------------------------------------------
--File Name    : ULFFAHumanVehicle.lua
--Description  : ULFFAHumanVehicle
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULFFAHumanVehicle = luaclass("ULFFAHumanVehicle", UILogicBase)

local ClientEventDef = require("ClientEventDef")
local CommonEventDef = require("CommonEventDef")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
local HumanMovementStateType = require("HumanMovementStateType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanWeaponMisc = require("HumanWeaponMisc")
local InputHandle = require("InputHandle")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local HumanVehicleHelper = require("HumanVehicleHelper")

local GameObjectSystem = dynamic_require("GameObjectSystem")
local CameraGameHelper = require("CameraGameHelper")
local SettingSystemNew = require("SettingSystemNew")
local SettingKeyDef = require("SettingKeyDef")
local SettingClassType = require("SettingClassType")

local HumanWeaponType = HumanWeaponMisc.Type

local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)

local SETTING_BASIC_CLOSE = 0
local SETTING_BASIC_OPEN = 1

local ENUM_JumpMode = {
    HideJump = 0,
    Jump = 1,
    Stop = 2,
}

-------------------------------------------------------------------------------

ULFFAHumanVehicle.nVehicleInstanceId = nil
ULFFAHumanVehicle.tbNearbyVehicles = {}
ULFFAHumanVehicle.bInVehicle = false
-- ULFFAHumanVehicle.VehicleTriggerType = nil

ULFFAHumanVehicle.tbVehicleLeftPressHandle = nil  
ULFFAHumanVehicle.tbVehicleLeftReleaseHandle = nil  
ULFFAHumanVehicle.tbVehicleRightPressHandle = nil
ULFFAHumanVehicle.tbVehicleRightReleaseHandle = nil
ULFFAHumanVehicle.tbSpaceBarPressedHandle = nil
ULFFAHumanVehicle.bPendingToVechicle = false

-------------------------------------------------------------------------------

-- Utils
local function RequestVehicleState(self, nState, vehicle_id, nVehicleTriggerType)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local ProgressBarComponent = PlayerSelf.ProgressBarComponent
    if ProgressBarComponent and ProgressBarComponent:IsInProgress() then
        ProgressBarComponent:Abort()
        -- return
    end
    -- logdebug(vehicle_id)
    HumanVehicleHelper.RequestVehicleState(nState, vehicle_id, nil, nVehicleTriggerType)
    self.bPendingToVechicle = true
end

local function FindNearestVehicle(self, PlayerSelf)
    local nVehicleInstanceId = nil
    local nNearsetAngle = 180
    local pForwardVector = KismetMathLibrary.GetForwardVector(PlayerSelf:GetRotation())
    local pPlayerLoc = PlayerSelf:GetLocation()

    for i, v in pairs(self.tbNearbyVehicles) do
        if v then
            local tbVehicle = GameObjectSystem:FindByInstanceId(i)
            if tbVehicle and tbVehicle.pUEActor:CanAttachToVehicle(true, PlayerSelf.pUEActor) then
                local nAngle = tbVehicle.pUEActor:GetAngleBetweenPlayerForward(pPlayerLoc, pForwardVector)
                if nAngle < nNearsetAngle then
                    nNearsetAngle = nAngle
                    nVehicleInstanceId = i
                end
            end
        end
    end
    return nVehicleInstanceId
end

-- UI显示相关
local function HideEmptyAimCenter(self, bHide)
    local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
    local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon(true)
    if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponType.MELEE) then  
        self.Owner.ulHumanAim:HideMeleeAimCenter(bHide)
    end
end

local function SetWeaponSlotsShow(self, bShow)
    local pWidgetRef = self.pWidgetRef
    if not pWidgetRef then
        return
    end
    local pVisibility = bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed
    pWidgetRef.ovlReload1:SetVisibility(pVisibility)
    pWidgetRef.pbFFAHumanSub1:SetVisibility(pVisibility)
    pWidgetRef.pbFFAHumanSub2:SetVisibility(pVisibility)
    --pWidgetRef.pbFFAHumanSub3:SetVisibility(pVisibility)
end

local function SetVehicleBtnsVisibility(self, bShow)
    local pVisibility = bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnForward:SetVisibility(pVisibility)
    pWidgetRef.btnBack:SetVisibility(pVisibility)
    pWidgetRef.btnRight:SetVisibility(pVisibility)
    pWidgetRef.btnLeft:SetVisibility(pVisibility)
    pWidgetRef.btnHorseJump:SetVisibility(pVisibility)
end

local function UpdateCvsHorseVisibility(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    -- local nVehicleInstanceId = nil

    local bShow = false

    for i, v in pairs(self.tbNearbyVehicles) do
        if v then
            local tbVehicle = GameObjectSystem:FindByInstanceId(i)
            if tbVehicle and tbVehicle.pUEActor:CanAttachToVehicle(true, PlayerSelf.pUEActor) and tbVehicle:IsAlive() then
                bShow = true 
                -- nVehicleInstanceId = i
                -- log("[Vehicle log] UPFFAHuman:UpdateCvsHorseVisibility, attachable vehicle is", nVehicleInstanceId)
                break
            end
        end
    end

    -- if not bShow then
        -- log("[Vehicle log] UPFFAHuman:UpdateCvsHorseVisibility, cannot find attachable vehicle")
    -- end

    local nVehicleState = HumanMovementStateComponent:GetVehicleState()
    -- log("[Vehicle log] UPFFAHuman:UpdateCvsHorseVisibility, nVehicleState is", nVehicleState)
    if (nVehicleState == HumanVehicleStateDef.PreAttachToVehicle or nVehicleState == HumanVehicleStateDef.AttachToVehicle) then  
        bShow = true 
    else
        if (nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle) then 
            bShow = false 
        end
        -- self.nVehicleInstanceId = nVehicleInstanceId
    end 

    -- log("[Vehicle log] UPFFAHuman:UpdateCvsHorseVisibility, bShow = ", bShow)
    
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.cvsHorse:SetVisibility(bShow and ESlateVisibility.SelfHitTestInvisible or ESlateVisibility.Collapsed)
    HideEmptyAimCenter(self, bShow)
end

local function UpdateVehicleControlWidget(self, bInVehicle)
    local pWidgetRef = self.pWidgetRef
    self.bInVehicle = bInVehicle
    SetWeaponSlotsShow(self, not bInVehicle)
    UpdateCvsHorseVisibility(self)

    -- show if not in vehicle and not swiming
    local bShow = not bInVehicle
    if bShow then
        local PlayerSelf = GamePlayerSelfHelper:Get()
        local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
        local nCurState = HumanMovementStateComponent:GetCurrentState() 
        bShow = nCurState ~= HumanMovementStateType.Swimming
    end
    self.Owner.ulFFAHumanMovement:SetPostureBtnsVisibility(bShow)
    pWidgetRef.btnFight2:SetVisibility(bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    self.Owner.ulFFAHumanThrownItem:SetShortcutVisibility(bShow)

    -- show if not in vehicle
    pWidgetRef.btnHorseUp:SetVisibility(bInVehicle and ESlateVisibility.Collapsed or ESlateVisibility.Visible)

    -- show if in vehicle
    pWidgetRef.btnHorseDown:SetVisibility(bInVehicle and ESlateVisibility.Visible or ESlateVisibility.Collapsed)

    -- show if in vehicle and use btn control
    bShow = bInVehicle
    if bShow then
        local nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
        bShow = nOperationMode == tbSettingOperationMode.ModeDef.WithButton
    end
    SetVehicleBtnsVisibility(self, bShow)

    self.EventHelper:FireEvent(ClientEventDef.EV_UI_ON_HORSE_BTN_UP_VISIBLE, not bInVehicle)
    self.EventHelper:FireEvent(ClientEventDef.EV_SETTING_LEFT_HAND_FIRE)
end

local function OnSelfEnterVehicleArea(self, bEnter, tbVehicle, TriggerType)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local nInstanceId = tbVehicle:GetServerInstanceId()
    -- log("[Vehicle log] UPFFAHuman:OnSelfEnterVehicleArea, bEnter, nInstanceId is", bEnter, nInstanceId)
    if bEnter then 
        self.tbNearbyVehicles[nInstanceId] = true
    else
        local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
        local nVehicleState = HumanMovementStateComponent:GetVehicleState()
        if nVehicleState == HumanVehicleStateDef.None or nVehicleState == HumanVehicleStateDef.PreDetachFromVehicle or nInstanceId ~= self.nVehicleInstanceId then
            self.tbNearbyVehicles[nInstanceId] = nil
        end
    end 
    self.bPendingToVechicle = false
    UpdateCvsHorseVisibility(self)
    -- self.VehicleTriggerType = TriggerType
end

local function OnHorseJumpClicked(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local GameVehicleComponent =  PlayerSelf.GameVehicleComponent
    if not GameVehicleComponent then  
        return 
    end     
    local nVehicleState = GameVehicleComponent:GetVehicleState()
    if nVehicleState ~= HumanVehicleStateDef.AttachToVehicle then return end

    local nVehicleInstanceId = GameVehicleComponent:GetVehicleInstanceId()
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if tbVehicle and tbVehicle.VehicleMovementComponent then
        tbVehicle.VehicleMovementComponent:Jump()
    end
end

local function UnregisterPCInput(self)
    if self.tbSpaceBarPressedHandle then
        self.EventHelper:UnRegisterHandle(self.tbSpaceBarPressedHandle)
    end
    self.tbSpaceBarPressedHandle = nil
end

local function RegisterPCInput(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local GameVehicleComponent =  PlayerSelf.GameVehicleComponent
    if not GameVehicleComponent then  
        return 
    end
    if not GameVehicleComponent:IsInVehicle() then
        return
    end
    UnregisterPCInput(self)
    self.tbSpaceBarPressedHandle = InputHandle:BindKeyPressed(EInputKey.SpaceBar, OnHorseJumpClicked, self)
    self.EventHelper:RegisterHandle(self.tbSpaceBarPressedHandle)
end

local function OnVehicleStateChange(self, Player, nState, nVehicleId)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local GameVehicleComponent = PlayerSelf.GameVehicleComponent

    if Player.ObjectType == PlayerSelf.ObjectType then
        local bUp = false  
        if nState == HumanVehicleStateDef.AttachToVehicle then  
            bUp = true
            self.nVehicleInstanceId = GameVehicleComponent:GetVehicleInstanceId()
            self.tbNearbyVehicles[self.nVehicleInstanceId] = true
        end
        -- if nState == HumanVehicleStateDef.PreDetachFromVehicle then
        --     self.VehicleTriggerType = 1
        -- end
        self.bPendingToVechicle = false
        UpdateVehicleControlWidget(self, bUp)
        RegisterPCInput(self)
    end 
    if not GameVehicleComponent:IsInVehicle() then
        UpdateCvsHorseVisibility(self)
        UnregisterPCInput(self)
    end
end

local function OnVehicleOperationModeChanged(self, nForm)
    if nForm ~= SettingLayoutFromDef.VEHICLE or not self.bInVehicle then
        return
    end
    UpdateCvsHorseVisibility(self)
    local nOperationMode = tbSettingOperationMode:GetVehicleOperationMode()
    SetVehicleBtnsVisibility(self, nOperationMode == tbSettingOperationMode.ModeDef.WithButton)
end

local function OnMoveStopped(self, pVehicleActor)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf:IsHuman() and self.nVehicleInstanceId then
        if PlayerSelf.pUEActor:IsInVehicleArea(pVehicleActor) then
            self.tbNearbyVehicles[self.nVehicleInstanceId] = true
        else
            self.tbNearbyVehicles[self.nVehicleInstanceId] = false
        end
        UpdateCvsHorseVisibility(self)
    end
end

-- 行为相关
local function OnVehicleForwardClick(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end 
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveForward(true)
    end
end

local function OnVehicleForwardRelease(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end    
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveForward(false)
    end
end 

local function OnVehicleBackClick(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveBack(true)
    end
end 
local function OnVehicleBackRelease(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveBack(false)
    end
end

local function OnVehicleLeftClick(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveLeft(true)
    end
end 

local function OnVehicleLeftRelease(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveLeft(false)
    end
end 

local function OnVehicleRightClick(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveRight(true)
    end
end 
local function OnVehicleRightRelease(self)
    local HumanMovementStateComponent =  GamePlayerSelfHelper:Get().HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local tbVehicle = GameObjectSystem:FindByInstanceId(HumanMovementStateComponent:GetVehicleInstanceId())
    if tbVehicle then
        tbVehicle.pUEActor:SetMoveRight(false)
    end
end 

local function OnVehicleKeyLeft(self, bPressed)
    if bPressed then   
        OnVehicleLeftClick(self)
    else   
        OnVehicleLeftRelease(self)
    end
end  

local function OnVehicleKeyRight(self, bPressed)
    if bPressed then  
        OnVehicleRightClick(self)
    else  
        OnVehicleRightRelease(self)
    end
end

local function RegisterVehicleInput(self)
    self.tbVehicleLeftPressHandle = InputHandle:BindKeyPressed(EInputKey.A, function() OnVehicleKeyLeft(self,  true) end, self)
    self.tbVehicleLeftReleaseHandle = InputHandle:BindKeyReleased(EInputKey.A, function() OnVehicleKeyLeft(self,  false) end, self)
    self.tbVehicleRightPressHandle = InputHandle:BindKeyPressed(EInputKey.D, function() OnVehicleKeyRight(self,  true) end, self)
    self.tbVehicleRightReleaseHandle = InputHandle:BindKeyReleased(EInputKey.D, function() OnVehicleKeyRight(self,  false) end, self)

    self.EventHelper:RegisterHandle(self.tbVehicleLeftPressHandle)
    self.EventHelper:RegisterHandle(self.tbVehicleLeftReleaseHandle)
    self.EventHelper:RegisterHandle(self.tbVehicleRightPressHandle)
    self.EventHelper:RegisterHandle(self.tbVehicleRightReleaseHandle)
end

local function UnRegisterVehicleInput(self)
    if self.tbVehicleLeftPressHandle then
        self.EventHelper:UnRegisterHandle(self.tbVehicleLeftPressHandle)
    end
    if self.tbVehicleLeftReleaseHandle then
        self.EventHelper:UnRegisterHandle(self.tbVehicleLeftReleaseHandle)
    end
    if self.tbVehicleRightPressHandle then
        self.EventHelper:UnRegisterHandle(self.tbVehicleRightPressHandle)
    end
    if self.tbVehicleRightReleaseHandle then
        self.EventHelper:UnRegisterHandle(self.tbVehicleRightReleaseHandle)
    end

    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not (PlayerSelf and PlayerSelf.pUEActor) then
        log("[VehicleDebugLog] PlayerSelf or PlayerSelf.pUEActor is nil", PlayerSelf)
        return 
    end
    local PlayerInputComponent = PlayerSelf.pUEActor.PlayerInputComponent
    if PlayerInputComponent then  
        PlayerInputComponent:RebindEventForLeftRight()
    end
end

local function OnVehicleUpBtnClick(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    if nMovementState ~= HumanMovementStateType.UpRight_State and nMovementState ~= HumanMovementStateType.Crouch_State and nMovementState ~= HumanMovementStateType.Crawl_State then
        return
    end
    self.nVehicleInstanceId = FindNearestVehicle(self, PlayerSelf)
    local tbVehicle = GameObjectSystem:FindByInstanceId(self.nVehicleInstanceId)
    if not tbVehicle then
        return
    end

    local GridTypeManager = CommonShell.GetCommon(GWorld):GetGridTypeManager()
    local pLocation = tbVehicle:GetLocation()
    local nVehicleRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)
    pLocation = PlayerSelf:GetLocation()
    local nHumanRegionType = GridTypeManager:GetRegionType(pLocation.X, pLocation.Y)
    if self.Owner.ulFFAHumanMovement.IsSwimmingVolume(nVehicleRegionType) or self.Owner.ulFFAHumanMovement.IsSwimmingVolume(nHumanRegionType) then  
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_HUMAN_VEHICLE_IN_SWIMMING"), 1)
        return 
    end

    local nVehicleState = HumanMovementStateComponent:GetVehicleState()
    if nVehicleState == HumanVehicleStateDef.None or nVehicleState == HumanVehicleStateDef.DetachFromVehicle then
        if tbVehicle and tbVehicle.pUEActor:CanAttachToVehicle(true, PlayerSelf.pUEActor) and tbVehicle:IsAlive() then 
            RegisterVehicleInput(self)
            --第二个参数需要读设置界面的 数据设置
            local nAutoValue = SettingSystemNew:Get(SettingKeyDef.LocalKeys.AUTO_ROT)
            CameraGameHelper.SetOnVehicleAutoRotateFollowFlags(nAutoValue == SETTING_BASIC_OPEN)
            self.EventHelper:FireEvent(ClientEventDef.EV_EXIT_OPEN_AIM_CAMERA)
            self.EventHelper:FireEvent(CommonEventDef.EV_INTERRUPT_CONTINUOUS_RUN)
            self.EventHelper:FireEvent(ClientEventDef.EV_UI_ON_HORSE_BTN_UP)
            local nTriggerType = tbVehicle.pUEActor:CalculateVehicleTriggerType()
            RequestVehicleState(self, HumanVehicleStateDef.PreAttachToVehicle, self.nVehicleInstanceId, nTriggerType)
        end
    end
end

local function OnVehicleDownBtnClick(self)
    local PlayerSelf = GamePlayerSelfHelper:Get()     
    local HumanMovementStateComponent =  PlayerSelf.HumanMovementStateComponent
    if not HumanMovementStateComponent then  
        return 
    end     
    local nVehicleState = HumanMovementStateComponent:GetVehicleState()
    if nVehicleState ~= HumanVehicleStateDef.AttachToVehicle then return end

    local nVehicleInstanceId = HumanMovementStateComponent:GetVehicleInstanceId()
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if tbVehicle and tbVehicle.pUEActor:CanDetachFromVehicle() then
        UnRegisterVehicleInput(self)
        RequestVehicleState(self, HumanVehicleStateDef.PreDetachFromVehicle, nVehicleInstanceId)
        self.EventHelper:FireEvent(ClientEventDef.EV_UI_ON_HORSE_BTN_DOWN)
    end
end

local function OnVehicleAutoRot(self, nIndex)
    local CameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    if nIndex == SETTING_BASIC_CLOSE then 
        CameraManager:EnableAutoRot(false)
    elseif nIndex == SETTING_BASIC_OPEN then   
        CameraManager:EnableAutoRot(true)
    end
end

local function OnJumpModeChanged(self, nJumpMode)
    local pWidgetRef = self.pWidgetRef
    if nJumpMode == ENUM_JumpMode.HideJump then
        pWidgetRef.btnHorseJump:SetVisibility(ESlateVisibility.Collapsed)
    elseif nJumpMode == ENUM_JumpMode.Jump then
        pWidgetRef.txtHorseJump:SetText(UISetUtils.GetL10NTextByKey("UI_VEHICLE_JUMP"))
        if self.bInVehicle then
            pWidgetRef.btnHorseJump:SetVisibility(ESlateVisibility.Visible)
        end
    elseif nJumpMode == ENUM_JumpMode.Stop then
        pWidgetRef.txtHorseJump:SetText(UISetUtils.GetL10NTextByKey("UI_VEHICLE_STOP"))
        if self.bInVehicle then
            pWidgetRef.btnHorseJump:SetVisibility(ESlateVisibility.Visible)
        end
    end
end

-------------------------------------------------------------------------------

function ULFFAHumanVehicle:Activate()
    local EventHelper = self.EventHelper

    EventHelper:RegisterEvent(ClientEventDef.EV_IN_VEHICLE_AREA,            self, OnSelfEnterVehicleArea)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE,    self, OnVehicleStateChange)
    EventHelper:RegisterEvent(ClientEventDef.EV_OPERATION_MODE_CHANGED,     self, OnVehicleOperationModeChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_REQUEST_VEHICLE_FAILED,  self, UnRegisterVehicleInput)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_MOVE_STOPPED,            self, OnMoveStopped)
    EventHelper:RegisterEvent(ClientEventDef.EV_SETTING_AUTO_ROT,           self, OnVehicleAutoRot)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_JUMP_MODE_CHANGED,       self, OnJumpModeChanged)
    

    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHorseUp.OnClicked,    self, OnVehicleUpBtnClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnHorseDown.OnClicked,  self, OnVehicleDownBtnClick)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnForward.OnPressed,    self, OnVehicleForwardClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnForward.OnReleased,   self, OnVehicleForwardRelease)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnPressed,       self, OnVehicleBackClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnReleased,      self, OnVehicleBackRelease)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRight.OnPressed,      self, OnVehicleRightClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRight.OnReleased,     self, OnVehicleRightRelease)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnLeft.OnPressed,       self, OnVehicleLeftClick)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnLeft.OnReleased,      self, OnVehicleLeftRelease)

    EventHelper:RegisterCppDelegate(pWidgetRef.btnHorseJump.OnClicked,  self, OnHorseJumpClicked)
    
    RegisterPCInput(self)

    self.nVehicleInstanceId = nil
    self.tbNearbyVehicles = {}
    UpdateVehicleControlWidget(self, false)
end

function ULFFAHumanVehicle:Deactivate()
    UnregisterPCInput(self)
    self.EventHelper:UnregisterAll()
end

function ULFFAHumanVehicle:OnBindEvent(EventHelper)
end

function ULFFAHumanVehicle:UpdateCvsHorseVisibility()
    UpdateCvsHorseVisibility(self)
end

function ULFFAHumanVehicle:OnVehicleStateChange(Player, nState, nVehicleId)
    OnVehicleStateChange(self, Player, nState, nVehicleId)
end

function ULFFAHumanVehicle:UpdateVehicleControlWidget(bInVehicle)
    UpdateVehicleControlWidget(self, bInVehicle)
end

return ULFFAHumanVehicle