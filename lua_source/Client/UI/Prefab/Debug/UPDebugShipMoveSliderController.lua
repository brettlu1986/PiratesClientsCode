-----------------------------------------------------
--File Name    : UPDebugShipMoveSliderController.lua
--Author       : WuJizhou
--Create Time  : 2018-6-28 12:08:48
--Description  : UPDebugShipMoveSliderController
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPDebugShipMoveSliderController = luaclass("UPDebugShipMoveSliderController", PrefabBase)

UPDebugShipMoveSliderController.fnOnSliderValueChanged = nil
UPDebugShipMoveSliderController.tbOnSliderValueChangedParams = nil
UPDebugShipMoveSliderController.szShipMoveControllerType = nil
UPDebugShipMoveSliderController.nSliderValue = nil

local MAX_SCALE = 10
local MIN_SCALE = 1 / 10

local DEFAULT_SLIDER_VALUE = 0.5

local ShipMoveControllerTypeName =
{
    MaxLinearSpeed = "最大线速度",
    LinearAcceleration = "线加速度",
    LinearDeceleration ="线减速度",
    MaxAngularSpeed = "最大角速度",
    AngularAcceleration = "角加速度",
    AngularDeceleration = "角减速度" 
}

local function GetScaleValue(self)
    local nSliderValue = self.pWidgetRef.sldrController:GetValue()
    -- nSliderValue = nSliderValue- DEFAULT_SLIDER_VALUE 
    local nScaleValue
    if nSliderValue >= DEFAULT_SLIDER_VALUE then
        nScaleValue = (nSliderValue- DEFAULT_SLIDER_VALUE) * 2 * (MAX_SCALE - 1) + 1
    else
        nScaleValue = nSliderValue * 2 * (1 - MIN_SCALE) + MIN_SCALE
    end
    return nScaleValue
end

local function UpdateScaleValue(self)
    self.nSliderValue =  self.pWidgetRef.sldrController:GetValue()
    self.pWidgetRef.txtScale:SetText(string.format("当前值: %.2f", GetScaleValue(self)))
end

local function UpdateControllerTypeName( self )
    self.pWidgetRef.txtName:SetText(ShipMoveControllerTypeName[self.szShipMoveControllerType])
end



local function OnSliderValueChanged(self, nValue)
    UpdateScaleValue(self)
    if self.fnOnSliderValueChanged ~= nil then
        self.fnOnSliderValueChanged(self.tbOnSliderValueChangedParams)
    end
end


function UPDebugShipMoveSliderController:SetShipMoveControllerType(szShipMoveControllerType)
    self.szShipMoveControllerType = szShipMoveControllerType
end

function UPDebugShipMoveSliderController:SetShipMoveChangedCallback(fnCallback, tbParams)
    self.fnOnSliderValueChanged = fnCallback
    self.tbOnSliderValueChangedParams = tbParams
end


function UPDebugShipMoveSliderController:GetShipMoveControllerScaleValue()
    local nScaleValue = GetScaleValue(self)
    local nRet
    nRet = math.floor((nScaleValue - 1) * 100)
    return nRet
end

function UPDebugShipMoveSliderController:ResetShipMoveControllerScaleValue()
    self.pWidgetRef.sldrController:SetValue(DEFAULT_SLIDER_VALUE)
    UpdateScaleValue(self)
end

function UPDebugShipMoveSliderController:OnShow()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.sldrController:SetValue(self.nSliderValue == nil and DEFAULT_SLIDER_VALUE or self.nSliderValue)
    pWidgetRef.txtMin:SetText(string.format("%.2f倍", MIN_SCALE))
    pWidgetRef.txtMax:SetText(string.format("%.0f倍", MAX_SCALE))
    UpdateScaleValue(self)
    UpdateControllerTypeName(self)
end

function UPDebugShipMoveSliderController:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrController.OnValueChanged, self, OnSliderValueChanged)
end

return UPDebugShipMoveSliderController