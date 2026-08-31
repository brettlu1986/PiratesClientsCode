-----------------------------------------------------
--File Name    : ULHumanFreeView.lua
--Description  : 查看相关
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHumanFreeView = luaclass("ULHumanFreeView", UILogicBase)
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local UIResourceDef = require("UIResourceDef")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local UIDef = require("UIDef")
local CommonEventDef = require("CommonEventDef")
local ClientEventDef = require("ClientEventDef")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local GameCameraSystem = require("GameCameraSystem")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local HumanMovementStateType = require("HumanMovementStateType")

ULHumanFreeView.bIsFreeDrag = false
ULHumanFreeView.pbFFAMain = nil
ULHumanFreeView.imgBg = nil
ULHumanFreeView.imgEye = nil
ULHumanFreeView.bInitFinger = false
ULHumanFreeView.pCurrentFingerIndex = nil
ULHumanFreeView.pMoveValues = Vector2D()

local SPRINT_ANGLE = 45
local Multiply_Vector2DFloat = KismetMathLibrary.Multiply_Vector2DFloat
local FN_MAKE_VECTOR_2D = KismetMathLibrary.MakeVector2D
local MAX_DISTANCE = 40
local FIXED_SCALE = 0.1

local function RequestEnterFreeView(self, bEnter)
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local CameraRotation = GameCameraManager:GetCameraRotation()
    local tbPlayer = PlayerSelfHelper:Get()
    if tbPlayer and tbPlayer:IsHuman() then
        local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
        local pUEActor = PlayerSelfHelper:GetUEActor()
        if pUEActor then
            if HumanMovementStateComponent and HumanMovementStateComponent:IsInVehicle() then
                CameraRotation = pUEActor:K2_GetActorRotation()
            end
            pUEActor.PlayerProperty:EnableFreeView(bEnter, CameraRotation)

            local tbPacket = {
                IsEnter = bEnter,
            }
            NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_EnterFreeView, tbPacket)
        end
    end
end

local function EnableFreeView(self, bEnable)
    local szRes, pRes
    if bEnable then
        self.imgBg:SetVisibility(ESlateVisibility.Visible)
        szRes = UIResourceDef.FFA_HUMAN_FREE_VIEW_PRESSED
    else
        self.imgBg:SetVisibility(ESlateVisibility.Collapsed)
        szRes = UIResourceDef.FFA_HUMAN_FREE_VIEW_NORMAL
    end
    pRes = szRes:load()
    UISetUtils.SetImageBrushRes(self.imgEye, pRes, true)
    if bEnable then
        RequestEnterFreeView(self, true)
        self.EventHelper:FireEvent(ClientEventDef.EV_ACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanFreeView, {nMoveScaleX = 3, nMoveScaleY = 3})
    else
        RequestEnterFreeView(self, false)
        self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanFreeView, { bWithAnim = true })
    end
end

local function GetFixedDeltaValue(nInValue)
    if nInValue > 1 or nInValue < -1 then
        nInValue = nInValue / math.abs(nInValue)
    end
    return nInValue
end

local function CalculateFixedMoveX(self, nDeltaValue)
    self.pMoveValues.X = self.pMoveValues.X + nDeltaValue * FIXED_SCALE
    return GetFixedDeltaValue(self.pMoveValues.X)
end

local function CalculateFixedMoveY(self, nDeltaValue)
    self.pMoveValues.Y = self.pMoveValues.Y + nDeltaValue * FIXED_SCALE
    return GetFixedDeltaValue(self.pMoveValues.Y)
end

local function FreeViewEnter(self)
    EnableFreeView(self, true)
    self.EventHelper:FireEvent(ClientEventDef.EV_FREE_VIEW_START)
end

--查看摇杆移动
local function FreeViewMoved(self, pMoveDelta, pFingerIndex)
    if not self.bIsFreeDrag or self.pCurrentFingerIndex ~= enumtoint(pFingerIndex) then
        return
    end

    local DeltaX = CalculateFixedMoveX(self, pMoveDelta.X)
    local DeltaY = CalculateFixedMoveY(self, pMoveDelta.Y)

    if math.abs(DeltaX) == 1 and math.abs(DeltaY) == 1 then
        DeltaX = math.cos(math.rad(SPRINT_ANGLE)) * DeltaX
        DeltaY = math.cos(math.rad(SPRINT_ANGLE)) * DeltaY
    end

    local pMoveDeltaFixed = Vector2D{X = DeltaX, Y = DeltaY}
    self.imgEye.Slot:SetPosition(Multiply_Vector2DFloat(pMoveDeltaFixed, MAX_DISTANCE))

end

function ULHumanFreeView:FreeViewEnd()
    EnableFreeView(self, false)
    self.bInitFinger = false
    self.imgEye.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
    self.pMoveValues.X = 0
    self.pMoveValues.Y = 0
    self.pCurrentFingerIndex = nil
    self.EventHelper:FireEvent(ClientEventDef.EV_FREE_VIEW_END)
end

local function InitFreeView(self)
    self.bInitFinger = false
    self.imgEye.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
    self.pMoveValues.X = 0
    self.pMoveValues.Y = 0
    self.pCurrentFingerIndex = nil
    local szRes, pRes
    self.imgBg:SetVisibility(ESlateVisibility.Collapsed)
    szRes = UIResourceDef.FFA_HUMAN_FREE_VIEW_NORMAL
    pRes = szRes:load()
    UISetUtils.SetImageBrushRes(self.imgEye, pRes, true)
end

local function MouseUp(self, pGeometry, pMouseEvent)
    self.pbFFAMain.pWidgetRef:InputTouchStop(pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)
    if self.pCurrentFingerIndex ~= nTouchIndex then
        return
    end

    if self.bIsFreeDrag then
        self:FreeViewEnd()
        self.bIsFreeDrag = false
    end
end

local function IsForbiddenEnter()
    local nGroupDef = GameCameraModeGroupDef
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    local bForbidCameraState =  GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewDeadBoxHuman) 
            or GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewDeadBoxShip)
            or GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewShipKiller)
            or GameCameraSystem:IsCameraLogicActive(nGroupDef.ViewHumanKiller)

    local bForbidUI = UIManager:IsWndOpen(UIDef.UI_FIVECOUNTDOWN) 
    local bForbidFlag = GameCameraManager.ForbiddenFreeView

    return bForbidUI or bForbidCameraState or bForbidFlag
end

-- border mouse 事件
local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)

    if IsForbiddenEnter() then
        return WidgetBlueprintLibrary.Handled()
    end

    if not self.bInitFinger then
        self.pCurrentFingerIndex = nTouchIndex
        self.bInitFinger = true
    end
    self.bIsFreeDrag = true

    local pWidgetRef = self.pbFFAMain.pWidgetRef
    FreeViewEnter(self)
    pWidgetRef:InputTouchStart(pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    local nTouchIndex = KismetInputLibrary.PointerEvent_GetPointerIndex(pMouseEvent)

    if not self.bIsFreeDrag or self.pCurrentFingerIndex ~= nTouchIndex then
        return WidgetBlueprintLibrary.Unhandled()
    end

    local pWidgetRef = self.pbFFAMain.pWidgetRef
    pWidgetRef:InputTouchMove(pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(CommonEventDef.EV_FIGHT_BTN_FREE_UP, pGeometry, pMouseEvent)
    MouseUp(self, pGeometry, pMouseEvent)
    return WidgetBlueprintLibrary.Handled()
end

-----
--border如果要是超出border范围就不会相应border的 up事件，所以需要再 widget的 ended里面处理
local function OnWidgetTouchEnded(self, pGeometry, pMouseEvent)
    MouseUp(self, pGeometry, pMouseEvent)
end

local function CheckCloseFreeView(self, szWndName)
    
    if UIDef.FFA_HALF_SCREEN[szWndName]  then
        return
    end

    local PlayerSelf = PlayerSelfHelper:Get()
    if not PlayerSelf then return end
    if not PlayerSelf:IsHuman() then return end

    local HumanMovementStateComponent = PlayerSelf.HumanMovementStateComponent
    if HumanMovementStateComponent then
        local nCurState = HumanMovementStateComponent:GetCurrentState()
        if nCurState == HumanMovementStateType.Parachutine_State or nCurState == HumanMovementStateType.Gliding_State then
            return
        end
    end

    if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
        self.bIsFreeDrag = false
        self:FreeViewEnd()
    end
end

local function OnExitFreeView(self, bDetach)
    local GameCameraManager = GameplayStatics.GetPlayerCameraManager(GWorld, 0)
    if bDetach then
        GameCameraManager:UnInitCacheArmParam(false, 1)
        GameCameraManager:UnInitCameraActorParam()
    end
    self.bIsFreeDrag = false
    --self:FreeViewEnd()
    self.imgBg:SetVisibility(ESlateVisibility.Collapsed)
    local szRes = UIResourceDef.FFA_HUMAN_FREE_VIEW_NORMAL
    local pRes = szRes:load()
    UISetUtils.SetImageBrushRes(self.imgEye, pRes, true)
    RequestEnterFreeView(self, false)

    self.bInitFinger = false
    self.imgEye.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
    self.pMoveValues.X = 0
    self.pMoveValues.Y = 0
    self.pCurrentFingerIndex = nil
    self.EventHelper:FireEvent(ClientEventDef.EV_FREE_VIEW_END)
end

local function OnPCFreeView(self, bEnter)
    if bEnter then
        if IsForbiddenEnter() then
            return
        end
        if not self.bInitFinger then
            self.bInitFinger = true
        end
        self.bIsFreeDrag = true    
        FreeViewEnter(self)
    else
        if self.bIsFreeDrag then
            self:FreeViewEnd()
            self.bIsFreeDrag = false
        end
    end
end

--ul相关
function ULHumanFreeView:HideFreeCameraButton(bHide)
    local pbFreeBtn = self.pWidgetRef.ovlJoystick
    if bHide then
        pbFreeBtn:SetVisibility(ESlateVisibility.Collapsed)
    else
        pbFreeBtn:SetVisibility(ESlateVisibility.Visible)
    end
end

function ULHumanFreeView:OnCreate()
    self.pbFFAMain = UIManager:GetWnd(UIDef.UI_FFA_MAIN)
    local pWidgetRef = self.pWidgetRef
    self.imgBg = pWidgetRef.imgBg
    self.imgEye = pWidgetRef.imgJoystick
end

function ULHumanFreeView:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
   --
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrJoystick.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrJoystick.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrJoystick.OnMouseButtonUpEvent, self, OnMouseButtonUp)


    pWidgetRef = self.pbFFAMain.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnWidgetTouchEnded)

    --检测 free view 是否在 fight上抬起
    EventHelper:RegisterEvent(CommonEventDef.EV_FREE_VIEW_FIGHT_UP, self, OnMouseButtonUp)

end

function ULHumanFreeView:Activate()
    InitFreeView(self)
    self:HideFreeCameraButton(false)
    local DelegateComponent = GamePlayerSelfHelper:Get().DelegateComponent
    self.EventHelper:RegisterLuaDelegate(DelegateComponent.OnCameraTouchMoved, FreeViewMoved, self)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_EXIT_FREE_VIEW, self, OnExitFreeView)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_UI_FREE_VIEW_PC, self, OnPCFreeView)
end

function ULHumanFreeView:Deactivate()
    self.bIsFreeDrag = false
    self.pCurrentFingerIndex = nil
    self.EventHelper:FireEvent(ClientEventDef.EV_FREE_VIEW_END)
    if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
        self.EventHelper:FireEvent(ClientEventDef.EV_DEACTIVE_CAMERA_GROUP, GameCameraModeGroupDef.HumanFreeView, { bWithAnim = false })
    end
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_EXIT_FREE_VIEW)
    local DelegateComponent = GamePlayerSelfHelper:Get().DelegateComponent
    self.EventHelper:UnregisterLuaDelegate(DelegateComponent.OnCameraTouchMoved, FreeViewMoved, self)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_UI_FREE_VIEW_PC)
    
end

function ULHumanFreeView:OnOpenUI(szWndName)
    --logdebug("the open window name is ",szWndName)
    CheckCloseFreeView(self, szWndName)
end

return ULHumanFreeView