-----------------------------------------------------
--File Name    : UPFFASailControl.lua
--Author       : Song Fuhao
--Create Time  : 2018-01-16
--Description  : Prefab SailControl
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFASailControl = luaclass("UPFFASailControl", PrefabBase)

local MathUtil = require("MathUtil")
local UISetUtils = require("UISetUtils")
local InputHandle = require("InputHandle")
local UIResourceDef = require("UIResourceDef")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
-- local SaveGameDef = dynamic_require("SaveGameDef")
local ClientEventDef = require("ClientEventDef")
local SettingSystemNew = require("SettingSystemNew")
local SettingClassType = require("SettingClassType")

local LuaGear = {
    FullSpeed   = 1,    -- 行驶档位
    LowSpeed    = 2,    -- 低速档位
    Stopped     = 3,    -- 停船档位
    Reverse     = 4     -- 倒船档位
}

local IDLE_STATE = 5    -- 停船时展示闲置ui

local CppToLuaGear = {
    [EShipGear.FullSpeed] = LuaGear.FullSpeed,
    [EShipGear.LowSpeed]  = LuaGear.LowSpeed,
    [EShipGear.Stopped]   = LuaGear.Stopped,
    [EShipGear.Reverse]   = LuaGear.Reverse,
}

local CppToGearString = {
    [EShipGear.FullSpeed] = "FullSpeed",
    [EShipGear.LowSpeed]  = "LowSpeed",
    [EShipGear.Stopped]   = "Stopped",
    [EShipGear.Reverse]   = "Reverse",
}

local LuaToCppGear = {
    [LuaGear.FullSpeed] = EShipGear.FullSpeed,
    [LuaGear.LowSpeed]  = EShipGear.LowSpeed,
    [LuaGear.Stopped]   = EShipGear.Stopped,
    [LuaGear.Reverse]   = EShipGear.Reverse,
}

-- local tbSailButtonAngles = {
--     [LuaGear.FullSpeed] = 0,
--     [LuaGear.LowSpeed]  = 0,
--     [LuaGear.Reverse]   = -180,
--     [LuaGear.Stopped]   = 0,
-- }

local tbDirectionText = {
    [LuaGear.FullSpeed] = "UI_STATIC_SHIP_SAIL_FULLSPEED",
    [LuaGear.LowSpeed]  = "UI_STATIC_SHIP_SAIL_FULLSPEED",
    [LuaGear.Reverse]   = "UI_STATIC_SHIP_SAIL_REVERSE",
    [LuaGear.Stopped]   = "UI_STATIC_SHIP_SAIL_STOPPED"
}

local MIN_CUSTOM_GEAR   = 1
local MAX_CUSTOM_GEAR   = 4

UPFFASailControl.nCurrentGearValue   = LuaGear.Stopped
UPFFASailControl.bRudderLeftPressed  = false
UPFFASailControl.bRudderRightPressed = false
UPFFASailControl.tbKeyboardHandles = {}

local function LOG(...)
    log("[SailControl]", ...)
end

local function StopAnimLeft(self)
    self:StopAnimation("animLeft")
    self.pWidgetRef.imgLeft:SetVisibility(ESlateVisibility.Collapsed)
    -- self.pWidgetRef.imgLeftBg:SetVisibility(ESlateVisibility.Collapsed)
end

local function StopAnimRight(self)
    self:StopAnimation("animRight")
    self.pWidgetRef.imgRight:SetVisibility(ESlateVisibility.Collapsed)
    -- self.pWidgetRef.imgRightBg:SetVisibility(ESlateVisibility.Collapsed)
end

local function RequestSteerRight(self)
    local nSteerValue = 0
    if self.bRudderLeftPressed or self.bRudderRightPressed then
        if self.bRudderLeftPressed then
            nSteerValue = -1
            StopAnimRight(self)
            self:PlayAnimation("animLeft", 0, 0, EUMGSequencePlayMode.Forward, 1)
        else
            nSteerValue = 1
            StopAnimLeft(self)
            self:PlayAnimation("animRight", 0, 0, EUMGSequencePlayMode.Forward, 1)
        end
    else
        StopAnimLeft(self)
        StopAnimRight(self)
    end
    LOG("RequestSteerRight", nSteerValue)
    local pUEActor = GamePlayerSelfHelper:GetUEActor()
    if pUEActor and pUEActor.ShipMovementComponent then
        pUEActor.ShipMovementComponent:SteerRight(nSteerValue)
    end
end

local function RequestSetBasicGear(nGearValue)
    LOG("RequestSetBasicGear", nGearValue)
    local pUEActor = GamePlayerSelfHelper:GetUEActor()
    if pUEActor and pUEActor.ShipMovementComponent then
        pUEActor.ShipMovementComponent:SetBasicGear(LuaToCppGear[nGearValue])
    end
end

-- 更新船速
local function OnGearValueChanged(self, pGearValue)
    local nGearValue = CppToLuaGear[pGearValue]
    LOG("OnGearValueChanged", CppToGearString[pGearValue])
    if self.nCurrentGearValue ~= nGearValue then
        self.nCurrentGearValue = nGearValue

        local nUpBtnGear = MathUtil.Clamp(nGearValue - 1, MIN_CUSTOM_GEAR, MAX_CUSTOM_GEAR)
        local nDownBtnGear = nGearValue
        if nDownBtnGear == LuaGear.FullSpeed then
            nDownBtnGear = LuaGear.Stopped
        end

        if nGearValue == LuaGear.Stopped then
            nUpBtnGear = IDLE_STATE
            nDownBtnGear = IDLE_STATE
        end

        UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnSailUp, UIResourceDef.FFA_SAIL_CONTROL_GEAR[nUpBtnGear]:load(), true)
        UISetUtils.SetButtonBrushRes(self.pWidgetRef.btnSailDown, UIResourceDef.FFA_SAIL_CONTROL_GEAR[nDownBtnGear]:load(), true)
        
        self.pWidgetRef.bdrDirection:SetBrushColor(UIResourceDef.FFA_SAIL_CONTROL_DIRECTION_LINEAR_COLOR[nGearValue])
        -- self.pWidgetRef.btnSailUp:SetBackgroundColor((nGearValue == LuaGear.FullSpeed) and UIResourceDef.COLOR.YELLOW.LINEAR_COLOR or UIResourceDef.COLOR.WHITE.LINEAR_COLOR)
        -- self.pWidgetRef.btnSailDown:SetBackgroundColor((nGearValue == LuaGear.Reverse) and UIResourceDef.COLOR.YELLOW.LINEAR_COLOR or UIResourceDef.COLOR.WHITE.LINEAR_COLOR)

        self.pWidgetRef.btnSailDown:SetRenderTransformAngle(nGearValue == LuaGear.Stopped and 180 or 0)
        self.pWidgetRef.txtDirection:SetText(UISetUtils.GetL10NTextByKey(tbDirectionText[nGearValue]))
    end
end

-- 按下左转舵
local function OnPressedBtnRudderLeft(self)
    self.bRudderLeftPressed = true
    RequestSteerRight(self)
end

-- 按下右转舵
local function OnPressedBtnRudderRight(self)
    self.bRudderRightPressed = true
    RequestSteerRight(self)
end

-- 松开左转舵
local function OnReleasedBtnRudderLeft(self)
    self.bRudderLeftPressed = false
    RequestSteerRight(self)
end

-- 松开右边转舵
local function OnReleasedBtnRudderRight(self)
    self.bRudderRightPressed = false
    RequestSteerRight(self)
end

local function StopRudderMove(self, nDirect)
    if nDirect == 1 then
        OnReleasedBtnRudderLeft(self)
    elseif nDirect == 2 then
        OnReleasedBtnRudderRight(self)
    end
end

-- 点击升帆按钮
local function OnClickedBtnSailUp(self)
    local nGearValue = self.nCurrentGearValue
    nGearValue = MathUtil.Clamp(nGearValue - 1, MIN_CUSTOM_GEAR, MAX_CUSTOM_GEAR)
    if nGearValue == LuaGear.LowSpeed then
        nGearValue = LuaGear.FullSpeed
    end
    RequestSetBasicGear(nGearValue)
    self.pWidgetRef.bShowPostureHint = false
end

-- 点击降帆按钮
local function OnClickedBtnSailDown(self)
    local nGearValue = self.nCurrentGearValue
    nGearValue = MathUtil.Clamp(nGearValue + 1, MIN_CUSTOM_GEAR, MAX_CUSTOM_GEAR)
    if nGearValue == LuaGear.LowSpeed then
        nGearValue = LuaGear.Stopped
    end
    RequestSetBasicGear(nGearValue)
    self.pWidgetRef.bShowPostureHint = false
end

local function SetJoystickMoveEnabled(bEnabled)
    local ShipActor = GamePlayerSelfHelper:Get():GetModelActor()
    if ShipActor and ShipActor.ShipInputComponent then
        log("[UPFFASailControl] set SetJoystickMoveEnabled", bEnabled)
        ShipActor.ShipInputComponent.JoystickMoveEnabled = bEnabled
    end
end

function UPFFASailControl:SailControlUnbindKeyboard()
    local EventHelper = self.EventHelper
    for _,v in pairs(self.tbKeyboardHandles) do 
        EventHelper:UnRegisterHandle(v)
    end
    self.tbKeyboardHandles = {}

    SetJoystickMoveEnabled(true)
end

local function ShowPostureHint(self, nOldPosture, nNewPosture)
    self.pWidgetRef.bShowPostureHint = true
end

function UPFFASailControl:SailControlBindKeyboard()
    local EventHelper = self.EventHelper
    self:SailControlUnbindKeyboard()
    table.insert(self.tbKeyboardHandles, InputHandle:BindKeyPressed(EInputKey.A, OnPressedBtnRudderLeft, self))
    table.insert(self.tbKeyboardHandles, InputHandle:BindKeyPressed(EInputKey.D, OnPressedBtnRudderRight, self))
    table.insert(self.tbKeyboardHandles, InputHandle:BindKeyPressed(EInputKey.W, OnClickedBtnSailUp, self))
    table.insert(self.tbKeyboardHandles, InputHandle:BindKeyPressed(EInputKey.S, OnClickedBtnSailDown, self))
    table.insert(self.tbKeyboardHandles, InputHandle:BindKeyReleased(EInputKey.A, OnReleasedBtnRudderLeft, self))
    table.insert(self.tbKeyboardHandles, InputHandle:BindKeyReleased(EInputKey.D, OnReleasedBtnRudderRight, self))

    for _,v in pairs(self.tbKeyboardHandles) do 
        EventHelper:RegisterHandle(v)
    end

    SetJoystickMoveEnabled(false)
end

local function RegisterEvent(self)
    LOG("RegisterEvent")
    local EventHelper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRudderLeft.OnPressed, self, OnPressedBtnRudderLeft)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRudderLeft.OnReleased, self, OnReleasedBtnRudderLeft)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRudderRight.OnPressed, self, OnPressedBtnRudderRight)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRudderRight.OnReleased, self, OnReleasedBtnRudderRight)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSailUp.OnClicked, self, OnClickedBtnSailUp)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnSailDown.OnClicked, self, OnClickedBtnSailDown)

    EventHelper:RegisterEvent(ClientEventDef.EV_STOP_SHIP_RUDDER_MOVE, self, StopRudderMove)
    EventHelper:RegisterEvent(ClientEventDef.EV_UI_SHIP_SET_POSTURE, self, ShowPostureHint)
    local tbSettingOperationMode = SettingSystemNew:GetInstance(SettingClassType.Setting_OperationMode)
    local nOperationMode = tbSettingOperationMode:GetShipOperationMode()
    if nOperationMode == tbSettingOperationMode.ModeDef.WithButton then
        self:SailControlBindKeyboard()
    end

    local DelegateComponent = GamePlayerSelfHelper:Get().DelegateComponent
    EventHelper:RegisterLuaDelegate(DelegateComponent.OnGearValueChanged, OnGearValueChanged, self)
end

local function UnregisterEvent(self)
    LOG("UnregisterEvent")
    self.EventHelper:UnregisterAll()
    self.tbKeyboardHandles = {}
end

function UPFFASailControl:Activate()
    LOG("Activate")
    RegisterEvent(self)
    OnGearValueChanged(self, EShipGear.Stopped)
    self.bRudderLeftPressed = false
    self.bRudderRightPressed = false
    self.pWidgetRef.PostureRaisedText = UISetUtils.GetL10NTextByKey("UI_STATIC_SHIP_POSTURE_RAISED")
    self.pWidgetRef.PostureLoweredText = UISetUtils.GetL10NTextByKey("UI_STATIC_SHIP_POSTURE_LOWERED")
end

function UPFFASailControl:Deactivate()
    LOG("Deactivate")
    UnregisterEvent(self)
end

return UPFFASailControl
