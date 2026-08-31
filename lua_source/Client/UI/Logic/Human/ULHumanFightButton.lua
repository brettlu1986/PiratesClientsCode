-----------------------------------------------------
--File Name    : ULHumanFightButton.lua
--Description  : fight 按钮
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHumanFightButton = luaclass("ULHumanFightButton", UILogicBase)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local HumanWeaponDef = require("HumanWeaponDef")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local InputHandle = require("InputHandle")
local CommonEventDef = require("CommonEventDef")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraSystem = require("GameCameraSystem")
local HumanMovementStateType = require("HumanMovementStateType")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local HumanWeaponMisc = require("HumanWeaponMisc")
local UIResourceDef = require("UIResourceDef")
local FFAHumanUIHelper = require("FFAHumanUIHelper")
local HumanWeaponType = require("HumanWeaponType")

ULHumanFightButton.bIsFightDrag = false
ULHumanFightButton.pbFFAMain = nil
ULHumanFightButton.bInitFinger = false
ULHumanFightButton.pCurrentFingerIndex = nil
ULHumanFightButton.tbFPressedHandle = nil
ULHumanFightButton.tbFReleasedHandle  = nil
ULHumanFightButton.bDragEnable = true

local PRESSED_SCALE = 0.9
local RELEASE_SCALE = 1.0
local MAX_TOUCH_INDEX = 9

local function GetSelfWeaponComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf and PlayerSelf.HumanWeaponComponent then 
        return PlayerSelf.HumanWeaponComponent
    end
    return nil  
end

local function IsFreeCameraCantAttack(nCurrentWeaponId)
    --logdebug("nCurrentWeaponId ",nCurrentWeaponId)

    local bNotAttack = true
    if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
        if nCurrentWeaponId ~= 0 then
            local tbWeapon = BattleItemSystemClient:GetItem(nCurrentWeaponId)
            if tbWeapon and tbWeapon:GetCategory() == BattleItemCategoryDef.HUMAN_THROWN_ITEM then
                bNotAttack =  false
            end
        end
    else
        bNotAttack = false
    end
    return bNotAttack
end

--投掷物的取消按钮 可能在服务器没下来之前来不及隐藏而被点到，客户端这里直接设置下隐藏先加一层保险
local function TryHideBoomCancel(self)
    if self.btnBoomCancel then
        self.btnBoomCancel:SetVisibility(ESlateVisibility.Collapsed)
    end
end

--攻击
local function OnAttackReleased(self)
    local WeaponComponent = GetSelfWeaponComponent()
    if not WeaponComponent then
        return
    end

    --临时解决 空中开枪，落地动作状态被打断，装备没有重置的问题
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if PlayerSelf.pUEActor then 
        if not PlayerSelf.pUEActor:IsJumpAnimOver() then  
            PlayerSelf.pUEActor:SetJumpAnimOver(true)
        end
    end

    BattleHumanWeaponSystemNew:RequestFinishAttack()

    TryHideBoomCancel(self)
end

local function IsValidThrowWeapon(WeaponComponent)
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if tbCurrentWeapon and WeaponComponent:GetCurrentState() == HumanWeaponStateDef.HOLDED and
            tbCurrentWeapon:IsType(HumanWeaponMisc.Type.THROW) then
        return tbCurrentWeapon.bReset
    end
    return true
end

local function OnAttackPressed(self)
    local WeaponComponent = GetSelfWeaponComponent()
    local PlayerSelf = GamePlayerSelfHelper:Get()
    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if not WeaponComponent or not HumanMovementStateComponent then
        return
    end
    local nMovementState = HumanMovementStateComponent:GetCurrentState()
    if nMovementState == HumanMovementStateType.Dying_State or nMovementState == HumanMovementStateType.Jumping_SpeelWall then
        return
    end

    if HumanMovementStateComponent:IsInVehicle() then
        return
    end
    local nCurrentWeaponId = WeaponComponent:GetCurrentWeaponInstanceId()

    --察看模式 只能扔投掷物， 其他攻击都不能做
    if IsFreeCameraCantAttack(nCurrentWeaponId) then
        return
    end

    if(nCurrentWeaponId ~= 0) then
        local tbWeapon = BattleItemSystemClient:GetItem(nCurrentWeaponId)
        if not tbWeapon then
            return
        end

        if tbWeapon:GetTemplate().nPrimaryCategory ~= HumanWeaponDef.WeaponPrimaryCategory.Melee then
            local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
            if  tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponMisc.Type.GUN) then
                local nRemainAmmo, _ = tbCurrentWeapon:GetAmmoInfo()
                if nRemainAmmo <= 0 then
                    return
                end
            end
        end

        -- 判断当前武器是不是手雷，并且处于holded
        if not IsValidThrowWeapon(WeaponComponent) then
            return
        end
    end
    --zheng throw
    BattleHumanWeaponSystemNew:RequestStartAttack()
end

local function ScaleButton(self, nScale)
    local PressScale2d = Vector2D{X = nScale, Y = nScale}
    self.pWidgetRef.btnFight2:SetRenderScale(PressScale2d)
    local pBtnFight2 = self.pWidgetRef.btnFight2
    if nScale == RELEASE_SCALE then
        UISetUtils.SetButtonNormalBrushRes(pBtnFight2, pBtnFight2.WidgetStyle.Hovered.ResourceObject)
    else
        UISetUtils.SetButtonNormalBrushRes(pBtnFight2, pBtnFight2.WidgetStyle.Pressed.ResourceObject)
    end
end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if nTouchIndex > MAX_TOUCH_INDEX then
        log("OnMouseButtonDown return,nTouchIndex=",nTouchIndex)
        nTouchIndex = 0
    end
    if not self.bInitFinger then 
        self.pCurrentFingerIndex = nTouchIndex
        self.bInitFinger = true
    end
    --logdebug("OnMouseButtonDown,nTouchIndex,self.pCurrentFingerIndex=",nTouchIndex,self.pCurrentFingerIndex)
    self.bIsFightDrag = true
    local pWidgetRef = self.pbFFAMain.pWidgetRef
    pWidgetRef:InputTouchStart(pMouseEvent)

    OnAttackPressed(self)
    ScaleButton(self, PRESSED_SCALE)
    self.EventHelper:FireEvent(ClientEventDef.EV_ON_FIGHTBDR_MOUSE_DOWN)
    return WidgetBlueprintLibrary.Handled()
end

local function SetFightBtnDragEnable(self, bEnable)
    self.bDragEnable = bEnable
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if not self.bDragEnable then
        return WidgetBlueprintLibrary.Handled()
    end
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if not self.bIsFightDrag or self.pCurrentFingerIndex ~= nTouchIndex then
        return WidgetBlueprintLibrary.Unhandled()
    end

    local pWidgetRef = self.pbFFAMain.pWidgetRef
    pWidgetRef:InputTouchMove(pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function FightButtonUp(self, pGeometry, pMouseEvent)
    local pWidgetRef = self.pbFFAMain.pWidgetRef
    if pGeometry and pMouseEvent then
        pWidgetRef:InputTouchStop(pMouseEvent)
        local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
        if self.pCurrentFingerIndex ~= nTouchIndex then
            return
        end
    else
        pWidgetRef:InterruptTouch()
    end
    if self.bIsFightDrag then
        OnAttackReleased(self)
        ScaleButton(self, RELEASE_SCALE)
        self.bIsFightDrag = false
        self.pCurrentFingerIndex = nil
        self.bInitFinger = false
    end
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)

    self.EventHelper:FireEvent(CommonEventDef.EV_FREE_VIEW_FIGHT_UP, pGeometry, pMouseEvent)
    FightButtonUp(self, pGeometry, pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMainWidgetTouchEnded(self, pGeometry, pMouseEvent)
    FightButtonUp(self, pGeometry, pMouseEvent)
end

local function OnPressedKeyboard(self, szKey, bValue)
    if szKey ~= "F" then
        return
    end

    if bValue then
        OnAttackPressed(self)
    else
        OnAttackReleased(self)
    end
end

local function OnDoubleTapActive(self)
    if GlobalVariableSystem.bDoubleFire then
        OnAttackPressed(self)
    end
end

local function OnDoubleTapDeactive(self)
    if GlobalVariableSystem.bDoubleFire then
        OnAttackReleased(self)
    end
end

local function OnUserWidgetTouchEnd(self, szWndName, pGeometry, pMouseEvent)
    --if UIDef.FFA_HALF_SCREEN[szWndName] then
        FightButtonUp(self, pGeometry, pMouseEvent)
    --end
end

local function IsThrowWeaponAttacking(self)
    local WeaponComponent = GetSelfWeaponComponent()
    if not WeaponComponent then
        return false
    end
    local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()
    if tbCurrentWeapon and tbCurrentWeapon:IsType(HumanWeaponMisc.Type.THROW)
        and WeaponComponent:IsAttacking() then
        return true
    end
    return false
end

local function OnFreeViewStart(self)
    if IsThrowWeaponAttacking(self) then
        return
    end
    OnAttackReleased(self)
end

local function SetAttackBtnImage(self, szRes, szPressedRes)
    local pRes = szRes:load()
    UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnFight1, pRes)
    UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnFight2, pRes)
    local pPressRes = szPressedRes:load()
    UISetUtils.SetButtonPressedBrushRes(self.pWidgetRef.btnFight1, pPressRes)
    UISetUtils.SetButtonPressedBrushRes(self.pWidgetRef.btnFight2, pPressRes)
end

local function RefreshAttackBtnImage(self, nCurrentWeaponId)
    if not nCurrentWeaponId then
        local HumanWeaponComponent = GamePlayerSelfHelper:Get().HumanWeaponComponent
        if not HumanWeaponComponent then
            return
        end
        nCurrentWeaponId = HumanWeaponComponent:GetCurrentWeaponInstanceId()
    end
    local szRes
    local szPressedRes
    if FFAHumanUIHelper.IsEmptyInHand(nCurrentWeaponId) then
        szRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_EMPTY_HAND
        szPressedRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_EMPTY_HAND_PRESSED
    else
        local tbWeaponItem = BattleItemSystemHelper:GetItem(nCurrentWeaponId, true)
        if tbWeaponItem then
            local tbTemplate = tbWeaponItem:GetTemplate()
            szRes = tbTemplate.nNormalRes
            szPressedRes = tbTemplate.nPressRes
        end
    end
    -- elseif FFAHumanUIHelper.IsMeleeWeaponInHand(nCurrentWeaponId) then
    --     szRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_MELEE
    --     szPressedRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_MELEE_PRESSED
    -- elseif FFAHumanUIHelper.IsThrownItemInHand(nCurrentWeaponId) then
    --     szRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_THROWN_ITEM
    --     szPressedRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_THROWN_ITEM_PRESSED
    -- else
    --     szRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_GUN
    --     szPressedRes = UIResourceDef.FFA_HUMAN_WEAPON_ATTACK_IMAGE_GUN_PRESSED
    -- end
    if szRes and szPressedRes then
        SetAttackBtnImage(self, szRes, szPressedRes)
    end
end

local function ReleaseAllBtn(self)
    FightButtonUp(self)
    OnAttackReleased(self)
end

local function SwitchToPCControl(self, bPC)
    local PlayerSelf = GamePlayerSelfHelper:Get()
    if not PlayerSelf or not PlayerSelf:IsHuman() then
        return
    end
    if bPC then
        self.EventHelper:UnRegisterHandle(self.tbFPressedHandle)
        self.EventHelper:UnRegisterHandle(self.tbFReleasedHandle)
        self.tbFPressedHandle = InputHandle:BindKeyPressed(EInputKey.LeftMouseButton, function() OnPressedKeyboard(self, "F", true) end, self)
        self.tbFReleasedHandle = InputHandle:BindKeyReleased(EInputKey.LeftMouseButton, function() OnPressedKeyboard(self, "F", false) end, self)
    else
        self.EventHelper:UnRegisterHandle(self.tbFPressedHandle)
        self.EventHelper:UnRegisterHandle(self.tbFReleasedHandle)
        self.tbFPressedHandle = InputHandle:BindKeyPressed(EInputKey.F, function() OnPressedKeyboard(self, "F", true) end, self)
        self.tbFReleasedHandle = InputHandle:BindKeyReleased(EInputKey.F, function() OnPressedKeyboard(self, "F", false) end, self)
    end
end

function ULHumanFightButton:Refresh(nNewWeapon)
    RefreshAttackBtnImage(self, nNewWeapon)
end

function ULHumanFightButton:OnCreate()
    self.pbFFAMain = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    self.btnBoomCancel = self.pWidgetRef.btnBoomcancel
end

function ULHumanFightButton:OnShow()
    RefreshAttackBtnImage(self)
end

function ULHumanFightButton:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
   --
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFight1.OnPressed, self, OnAttackPressed)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnFight1.OnReleased, self, OnAttackReleased)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrFight2.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrFight2.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrFight2.OnMouseButtonUpEvent, self, OnMouseButtonUp)

    pWidgetRef = self.pbFFAMain.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnMainWidgetTouchEnded)
    EventHelper:RegisterEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, self, OnUserWidgetTouchEnd)
    EventHelper:RegisterEvent(ClientEventDef.EV_FREE_VIEW_START, self, OnFreeViewStart)
    EventHelper:RegisterEvent(ClientEventDef.EV_RELEASE_FIGHT_BTN, self, ReleaseAllBtn)
    EventHelper:RegisterEvent(ClientEventDef.EV_SET_FIGHT_BTN_ENABLE , self, SetFightBtnDragEnable)

    --检测 fight btn 是否在 小眼睛 上抬起
    EventHelper:RegisterEvent(CommonEventDef.EV_FIGHT_BTN_FREE_UP, self, FightButtonUp)
end

function ULHumanFightButton:Activate()
    self.tbFPressedHandle = InputHandle:BindKeyPressed(EInputKey.F, function() OnPressedKeyboard(self, "F", true) end, self)
    self.tbFReleasedHandle = InputHandle:BindKeyReleased(EInputKey.F, function() OnPressedKeyboard(self, "F", false) end, self)

    self.tbDoubleTapActiveHandle = InputHandle:BindGestureActive(EGestureType.DoubleTap, OnDoubleTapActive, self)
    self.tbDoubleTapDeactiveHandle = InputHandle:BindGestureDeactive(EGestureType.DoubleTap, OnDoubleTapDeactive, self)
    self.EventHelper:RegisterHandle(self.tbFPressedHandle)
    self.EventHelper:RegisterHandle(self.tbFReleasedHandle)
    self.EventHelper:RegisterHandle(self.tbDoubleTapActiveHandle)
    self.EventHelper:RegisterHandle(self.tbDoubleTapDeactiveHandle)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_APP_WILL_DEACTIVE, self, ReleaseAllBtn)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_SWITCH_TO_PC, self, SwitchToPCControl)

    self:Refresh()
end

function ULHumanFightButton:Deactivate()
    self.EventHelper:UnRegisterHandle(self.tbFPressedHandle)
    self.EventHelper:UnRegisterHandle(self.tbFReleasedHandle)
    self.EventHelper:UnRegisterHandle(self.tbDoubleTapActiveHandle)
    self.EventHelper:UnRegisterHandle(self.tbDoubleTapDeactiveHandle)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_APP_WILL_DEACTIVE)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_UI_SWITCH_TO_PC)
    self.tbFPressedHandle = nil
    self.tbFReleasedHandle = nil
    self.tbDoubleTapActiveHandle = nil
    self.tbDoubleTapDeactiveHandle = nil
end

local function CheckCancelAttack(self, szWndName)
    if szWndName == UIDef.UI_FFABACKPACK or szWndName == UIDef.UI_BUILD_ITEM then
        local PlayerSelf = GamePlayerSelfHelper:Get()
        if (not PlayerSelf) or (not PlayerSelf:IsHuman()) then
            return
        end

        local HumanWeaponComponent = PlayerSelf.HumanWeaponComponent
        if not HumanWeaponComponent then  
            return 
        end
        local tbCurrentWeapon = HumanWeaponComponent:GetCurrentWeapon(true)
        if not tbCurrentWeapon then  
            return
        end
        
        local WeaponBpType = tbCurrentWeapon:GetWeaponBPType()
        if WeaponBpType == HumanWeaponType.ThrowWeapon or WeaponBpType == HumanWeaponType.Bow 
                or WeaponBpType == HumanWeaponType.Explosive then  
            BattleHumanWeaponSystemNew:RequestCancelAttack() 
        end
    end
end

function ULHumanFightButton:OnOpenUI(szWndName)
    CheckCancelAttack(self, szWndName)
    if not UIDef.FFA_HALF_SCREEN[szWndName] and szWndName ~= UIDef.UI_PROGRESS_BAR  then
        FightButtonUp(self)
    end
end

function ULHumanFightButton:OnExit()
    OnAttackReleased(self)
end

return ULHumanFightButton