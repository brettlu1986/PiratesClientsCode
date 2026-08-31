-----------------------------------------------------
--File Name    : UPShipVirtualJoystick.lua
--Author       : Song Fuhao
--Create Time  : 2018-09-03
--Description  : UPShipVirtualJoystick
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPShipVirtualJoystick = luaclass("UPShipVirtualJoystick", PrefabBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local InputHandle = require("InputHandle")
local DungeonIni = require("DungeonIni")
local MathUtil = require("MathUtil")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local AbortTypeDef = require("AbortTypeDef")
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")
local SettingLayoutFromDef = require("SettingLayoutFromDef")
local DelayTimer = require("DelayTimer")

local FN_MULTIPLY_VECTOR_2D_FLOAT = KismetMathLibrary.Multiply_Vector2DFloat
local FN_MAKE_VECTOR_2D = KismetMathLibrary.MakeVector2D

local STOP_GEAR_PERCENT = DungeonIni.tbUIConfig.nStopGearPercent
local STOP_STEER_PERCENT = DungeonIni.tbUIConfig.nStopSteerPercent
local FULL_SPEED_PERCENT = DungeonIni.tbUIConfig.nFullSpeedPercent
local STEER_CHANGE_FREQUENCY = 0.05
local MAX_DISTANCE = 140
local FULL_AHEAD_POSITION = FN_MAKE_VECTOR_2D(0, -MAX_DISTANCE)
local nScale = 1
local JOYSTICK_LOCAL_ID = 211
local CONTINUOUS_LOCAL_ID = 212
local CONTINUS_ANGLE = 60
local nYOffset = 0
local nXOffset = 0

local LuaGear = {
    FullSpeed   = 1,    -- 行驶档位
    LowSpeed    = 2,    -- 低速档位
    Stopped     = 3,    -- 停船档位
    Reverse     = 4     -- 倒船档位
}

local CppGear = {
    [LuaGear.FullSpeed] = EShipGear.FullSpeed,
    [LuaGear.LowSpeed]  = EShipGear.LowSpeed,
    [LuaGear.Stopped]   = EShipGear.Stopped,
    [LuaGear.Reverse]   = EShipGear.Reverse,
}

UPShipVirtualJoystick.nSteer = 0
UPShipVirtualJoystick.nGear = LuaGear.Stopped
UPShipVirtualJoystick.bFullAhead = false
UPShipVirtualJoystick.bInLock = false
UPShipVirtualJoystick.bInContinuous = false
UPShipVirtualJoystick.bContinuousAreaActive = false

UPShipVirtualJoystick.bKeyBoardSimulating = false
UPShipVirtualJoystick.bPressedKeyA = false
UPShipVirtualJoystick.bPressedKeyD = false
UPShipVirtualJoystick.bPressedKeyW = false
UPShipVirtualJoystick.bPressedKeyS = false
UPShipVirtualJoystick.tbLayoutTimer = nil

local function UpdateSteer(self, nSteer)
    nSteer = MathUtil.Clamp(nSteer, -1, 1)
    if (nSteer * self.nSteer <= 0) or (math.abs(nSteer - self.nSteer) > STEER_CHANGE_FREQUENCY) then
        if self.nSteer ~= nSteer then
            self.nSteer = nSteer
            local pUEActor = GamePlayerSelfHelper:GetUEActor()
            if pUEActor and pUEActor.ShipMovementComponent then
                pUEActor.ShipMovementComponent:SteerRight(nSteer)
            end
        end
    end
end

local function UpdateGear(self, nGear)
    -- if self.nGear ~= nGear then
        self.nGear = nGear
        local pUEActor = GamePlayerSelfHelper:GetUEActor()
        if pUEActor and pUEActor.ShipMovementComponent then
            pUEActor.ShipMovementComponent:SetBasicGear(CppGear[nGear])
        end
    -- end
end

local function SetFullAhead(self, bFullAhead)
    UpdateGear(self, bFullAhead and LuaGear.FullSpeed or LuaGear.Stopped)
    self.bFullAhead = bFullAhead
    if bFullAhead then
        self.pWidgetRef.hbxLock:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.imgContinuous:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.pWidgetRef.imgThumb.Slot:SetPosition(FULL_AHEAD_POSITION)
    else
        self.pWidgetRef.imgThumb.Slot:SetPosition(FN_MAKE_VECTOR_2D(0, 0))
        self.pWidgetRef.hbxLock:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.imgContinuous:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function Brake(self)
    UpdateSteer(self, 0)
    SetFullAhead(self, false)
end

local function OnShipMoveStateChanged(self, bShipMoving)
    if not bShipMoving then
        Brake(self)
    end
end

local function OnMouseEnterLock(self)
    if self.bContinuousAreaActive then
        self.bInLock = true
        self.pWidgetRef.chkContinuous:SetIsChecked(true)
    end
end

local function OnMouseLeaveLock(self)
    if self.bContinuousAreaActive and self.bInLock then
        self.bInLock = false
        self.pWidgetRef.chkContinuous:SetIsChecked(false)
    end
end

local function OnMouseEnterContinuous(self)
    if self.bContinuousAreaActive then
        self:PlayAnimation("animGO", 0, 0, EUMGSequencePlayMode.Forward, 1)
        self.pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

local function OnMouseLeaveContinuous(self)
    if self.bContinuousAreaActive then
        self:StopAnimation("animGO")
        self.pWidgetRef.cvsContinuous:SetVisibility(ESlateVisibility.Collapsed)
        OnMouseLeaveLock(self)
    end
end

local function ActivateContinuousArea(self)
    SetFullAhead(self, false)
    self.bContinuousAreaActive = true
end

local function DeactiveContinuousArea(self)
    OnMouseLeaveLock(self)
    OnMouseLeaveContinuous(self)
    self.bContinuousAreaActive = false
end

--[[
    UI Event
]]
local function OnMoveTouchStarted(self, pCenterPosition)
    local ShipActor = GamePlayerSelfHelper:Get():GetModelActor()
    if(ShipActor == nil)then
        logerror("UPShipVirtualJoystick:OnMoveTouchStarted, ship actor is nil")
        return
    end
    local ShipInputComponent = ShipActor.ShipInputComponent
    local pMoveCenterPosition = ShipInputComponent.MoveCenterPosition
    if pMoveCenterPosition then
        log("UPShipVirtualJoystick:OnMoveTouchStarted, MoveCenterPosition is " .. tostring(pMoveCenterPosition.X, pMoveCenterPosition.Y))
    end
    ActivateContinuousArea(self)
    EventManager:OnFireEvent(ClientEventDef.EV_COMMON_ABORT, AbortTypeDef.MOVE)
    if pCenterPosition then
        local pGeometry = self.pWidgetRef.cvsVirtualSticker:GetCachedGeometry()
        local pLocCenter = SlateBlueprintLibrary.AbsoluteToLocal(pGeometry, pCenterPosition)
        pLocCenter.X = pLocCenter.X - nXOffset * nScale
        pLocCenter.Y = pLocCenter.Y + nYOffset
        self.pWidgetRef.cvsContinuous.Slot:SetPosition(pLocCenter)
    end
    self.pWidgetRef.bdrSprint:SetVisibility(ESlateVisibility.Visible)
    self.pWidgetRef.bdrLock:SetVisibility(ESlateVisibility.Visible)
end

local function OnMoveTouchMoved(self, pCenterPosition, pMoveDelta)
    local nDeltaX = pMoveDelta.X
    local nDeltaY = pMoveDelta.Y
    
    self.pWidgetRef.imgThumb.Slot:SetPosition(FN_MULTIPLY_VECTOR_2D_FLOAT(pMoveDelta, MAX_DISTANCE))
    if not self.bFullAhead then
        if math.abs(nDeltaY) < STOP_GEAR_PERCENT then                                       -- 中心横向带上不升帆/目前没有后退操作，所以向后滑动也不升帆
            UpdateGear(self, LuaGear.Stopped)
        elseif nDeltaY < 0 then                                                             -- 判断圆心距来控制满帆半帆
            -- local nDistance = nDeltaX * nDeltaX + nDeltaY * nDeltaY                         -- 不开方，减少开销
            UpdateGear(self, (math.abs( nDeltaY ) > FULL_SPEED_PERCENT) and LuaGear.FullSpeed or LuaGear.LowSpeed)
            if math.abs( nDeltaY ) > FULL_SPEED_PERCENT and (nDeltaX == 0 or math.abs(nDeltaY / nDeltaX) >= math.tan(math.rad(CONTINUS_ANGLE))) then
                OnMouseEnterContinuous(self)
            else
                OnMouseLeaveContinuous(self)
            end
        else
            UpdateGear(self, LuaGear.Reverse)                                               -- 倒挡
        end
    end

    if math.abs(nDeltaX) < STOP_STEER_PERCENT then                                          -- 中心纵向带上不转向
        UpdateSteer(self, 0)
    else                                                                                    -- 判断偏移角度来控制转向
        -- local nSteer = MathUtil.Sign(nDeltaX) * (math.abs(nDeltaX) - STOP_STEER_PERCENT) / FULL_STEER_PERCENT
        local nSteer = nDeltaX > 0 and 1 or -1
        UpdateSteer(self, nSteer)
    end
end

local function OnMoveTouchEnded(self)
    if self.bInLock then
        SetFullAhead(self, true)
        UpdateSteer(self, 0)
    else
        Brake(self)
    end
    DeactiveContinuousArea(self)
end

local function OnPressedKeyboard(self, szKey, bValue)
    self["bPressedKey" .. szKey] = bValue

    if self.bPressedKeyA or self.bPressedKeyD or self.bPressedKeyW or self.bPressedKeyS then
        if self.bKeyBoardSimulating == false then
            self.bKeyBoardSimulating = true
            OnMoveTouchStarted(self)
        end

        local nX = self.bPressedKeyA and -1 or (self.bPressedKeyD and 1 or 0)
        local nY = self.bPressedKeyW and -1 or (self.bPressedKeyS and 1 or 0)
        local pMoveDelta = FN_MAKE_VECTOR_2D(nX, nY)
        OnMoveTouchMoved(self, nil, pMoveDelta)
    else
        self.bKeyBoardSimulating = false
        OnMoveTouchEnded(self)
    end
end

local function LoadLayoutSetting(self)
    nYOffset = 0
    local pWidgetRef = self.pWidgetRef
    local SettingLayout = SettingSystemNew:GetInstance(SettingClassType.Setting_Layout)
    local tbAllLayout = SettingLayout:GetCurrentLayoutFrom(SettingLayoutFromDef.SHIP)
    local pViewPortSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
    local nViewPortScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
    local tbOperationModeDef = tbSettingOperationMode.ModeDef
    for k, v in pairs(tbAllLayout) do
        if v.nFrom == SettingLayoutFromDef.SHIP and (v.tbTemplate.nOperationMode == tbOperationModeDef.WithJoystick or v.tbTemplate.nOperationMode == 0) then
            local tbTemplate = v.tbTemplate
            local pWidget = pWidgetRef[tbTemplate.szMainWidgetName]
            local pScaleWidget = pWidgetRef[tbTemplate.szMainScaleWidgetName]
            local pAlphaWidget = pWidgetRef[tbTemplate.szMainAlphaWidgetName]
            if pWidget and pScaleWidget and pAlphaWidget then
                pWidget.Slot:SetPosition(Vector2D{X = v.nX, Y = v.nY})
                pAlphaWidget:SetRenderOpacity(v.nAlpha)
                local SetUserSpecifiedScaleFunc = pScaleWidget.SetUserSpecifiedScale
                if tbTemplate.szMainScaleWidgetName == "sboxVirtualStickerBar" then
                    nScale = v.nScale
                end
                if SetUserSpecifiedScaleFunc then
                    SetUserSpecifiedScaleFunc(pScaleWidget, v.nScale)
                else
                    pScaleWidget:SetRenderTransformPivot(pScaleWidget.Slot:GetAlignment())
                    pScaleWidget:SetRenderScale(Vector2D{X = v.nScale, Y = v.nScale})
                end
                if v.nLocalId == JOYSTICK_LOCAL_ID then
                    local ShipActor = GamePlayerSelfHelper:Get():GetModelActor()
                    if(ShipActor == nil)then
                        logerror("UPShipVirtualJoystick:OnMoveTouchStarted, ship actor is nil")
                        return
                    end
                    if ShipActor and ShipActor.ShipInputComponent then
                        local pLocalSize = pScaleWidget.Slot:GetSize()
                        local pPos = Vector2D()
                        pPos.X = (v.nX + nScale * pLocalSize.X / 2) * nViewPortScale
                        pPos.Y = pViewPortSize.Y + (v.nY - nScale * pLocalSize.Y / 2) * nViewPortScale
                        ShipActor.ShipInputComponent.JoystickPadCenterPosition = pPos
                        pLocalSize.X = pLocalSize.X * nScale * nViewPortScale
                        pLocalSize.Y = pLocalSize.Y * nScale * nViewPortScale
                        ShipActor.ShipInputComponent.JoystickPadSize = pLocalSize
                    end
                    if self.tbLayoutTimer then
                        DelayTimer:ClearTimer(self.tbLayoutTimer)
                        self.tbLayoutTimer = nil
                    end
                    self.tbLayoutTimer = DelayTimer:DelayRun(function()
                        local pLocalSize = SlateBlueprintLibrary.GetLocalSize(pWidgetRef.sboxVirtualStickerBar:GetCachedGeometry())
                        local pCvsLocalSize = SlateBlueprintLibrary.GetLocalSize(pWidgetRef.cvsVirtualSticker:GetCachedGeometry())
                        nYOffset = nYOffset - pCvsLocalSize.Y + pLocalSize.Y / 2
                        pWidgetRef.hbxLock.Slot:SetPosition(Vector2D{X = 0, Y = -pLocalSize.Y })
                    end, 0.1)
                end
                if v.nLocalId == CONTINUOUS_LOCAL_ID then
                    nYOffset = nYOffset + v.nY
                end
            end
        end
    end
    local pSize = self.pWidgetRef.cvsVirtualSticker.Slot:GetSize()
    nXOffset = pSize.X/2
end

local function SetJoystickMoveEnabled(bEnabled)
    local ShipActor = GamePlayerSelfHelper:Get():GetModelActor()
    if ShipActor and ShipActor.ShipInputComponent then
        log("[UPShipVirtualJoystick] set SetJoystickMoveEnabled", bEnabled)
        ShipActor.ShipInputComponent.JoystickMoveEnabled = bEnabled
    end
end

function UPShipVirtualJoystick:OnLoad()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.chkContinuous:SetIsChecked(false)
    pWidgetRef.chkContinuous:SetVisibility(ESlateVisibility.HitTestInvisible)

    UISetUtils.SetImageBrushRes(pWidgetRef.imgContinuous, UIResourceDef.FFA_VIRTUALSTICK_SHIP_RUN:load())
    UISetUtils.SetCheckBoxCheckedBrushRes(pWidgetRef.chkContinuous, UIResourceDef.FFA_VIRTUALSTICK_SHIP_CHECK:load())
    UISetUtils.SetCheckBoxUncheckedBrushRes(pWidgetRef.chkContinuous, UIResourceDef.FFA_VIRTUALSTICK_SHIP_UNCHECK:load())
end

function UPShipVirtualJoystick:OnEnter()
    LoadLayoutSetting(self)
    SetJoystickMoveEnabled(true)
end

function UPShipVirtualJoystick:OnExit()
    SetJoystickMoveEnabled(false)
end

function UPShipVirtualJoystick:OnDestroy()
    SetFullAhead(self, false)
    if self.tbLayoutTimer then
        DelayTimer:ClearTimer(self.tbLayoutTimer)
        self.tbLayoutTimer = nil
    end
end

function UPShipVirtualJoystick:SetContinuousEnable()
    -- body
end

function UPShipVirtualJoystick:RefreshLayout()
    LoadLayoutSetting(self)
end

function UPShipVirtualJoystick:SetVirtualJoystickIcon(szIconRes)
    local IconResObj = szIconRes:load()
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgThumb, IconResObj)
end

function UPShipVirtualJoystick:OnBindEvent()
    SetFullAhead(self, false)

    local EventHelper = self.EventHelper
    self.EventHelper:UnregisterAll()

    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrLock.OnMouseEnterEvent, self, OnMouseEnterLock)

    local DelegateComponent = GamePlayerSelfHelper:Get().DelegateComponent
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnMoveTouchStarted, OnMoveTouchStarted, self)
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnMoveTouchMoved, OnMoveTouchMoved, self)
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnMoveTouchEnded, OnMoveTouchEnded, self)
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnShipMoveStateChanged, OnShipMoveStateChanged, self)

    EventHelper:RegisterHandle(InputHandle:BindKeyPressed(EInputKey.A, function() OnPressedKeyboard(self, "A", true) end, self))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed(EInputKey.D, function() OnPressedKeyboard(self, "D", true) end, self))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed(EInputKey.W, function() OnPressedKeyboard(self, "W", true) end, self))
    EventHelper:RegisterHandle(InputHandle:BindKeyPressed(EInputKey.S, function() OnPressedKeyboard(self, "S", true) end, self))

    EventHelper:RegisterHandle(InputHandle:BindKeyReleased(EInputKey.A, function() OnPressedKeyboard(self, "A", false) end, self))
    EventHelper:RegisterHandle(InputHandle:BindKeyReleased(EInputKey.D, function() OnPressedKeyboard(self, "D", false) end, self))
    EventHelper:RegisterHandle(InputHandle:BindKeyReleased(EInputKey.W, function() OnPressedKeyboard(self, "W", false) end, self))
    EventHelper:RegisterHandle(InputHandle:BindKeyReleased(EInputKey.S, function() OnPressedKeyboard(self, "S", false) end, self))
end

function UPShipVirtualJoystick:OnUnbindEvent()
    self.EventHelper:UnregisterAll()
end

return UPShipVirtualJoystick
