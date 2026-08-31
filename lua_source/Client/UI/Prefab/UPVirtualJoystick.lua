-----------------------------------------------------
--File Name    : UPVirtualJoystick.lua
--Author       : Song Fuhao
--Create Time  : 2017-06-15
--Description  : UPVirtualJoystick
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPVirtualJoystick = luaclass("UPVirtualJoystick", PrefabBase)

local GamePlayerSelfHelper = require("GamePlayerSelfHelper")


local Divide_Vector2DFloat = KismetMathLibrary.Divide_Vector2DFloat
local Multiply_Vector2DFloat = KismetMathLibrary.Multiply_Vector2DFloat

local MAX_DISTANCE = 80
local MOVED_ANCHORS = Anchors{Minimum=Vector2D{X=0, Y=0}, Maximum=Vector2D{X=0, Y=0}}

local function OnMoveTouchStarted( self )
    self.pWidgetRef.imgThumb:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    self.pWidgetRef.cvsTouchStyle.Slot:SetAnchors(MOVED_ANCHORS)
end

local function OnMoveTouchMoved( self, pCenterPosition, pMoveDelta )
    self.pWidgetRef.cvsTouchStyle.Slot:SetPosition(Divide_Vector2DFloat(pCenterPosition, self.nViewportScale))
    self.pWidgetRef.imgThumb.Slot:SetPosition(Multiply_Vector2DFloat(pMoveDelta, MAX_DISTANCE))
end

local function OnMoveTouchEnded( self )
    self.pWidgetRef.cvsTouchStyle.Slot:SetAnchors(self.pDefaultPadAchors)
    self.pWidgetRef.cvsTouchStyle.Slot:SetPosition(self.pDefaultPadPosition)
    self.pWidgetRef.imgThumb:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnPlayerActorEndPlay(self)
    self.EventHelper:UnregisterAll()
end

-- Public
UPVirtualJoystick.nViewportScale = 1
UPVirtualJoystick.bEnable = false
UPVirtualJoystick.pDefaultPadPosition = nil
UPVirtualJoystick.pDefaultPadAchors = nil

function UPVirtualJoystick:OnEnter()
    self.pDefaultPadPosition = self.pWidgetRef.cvsTouchStyle.Slot:GetPosition()
    self.pDefaultPadAchors = self.pWidgetRef.cvsTouchStyle.Slot:GetAnchors()
    self.nViewportScale = WidgetLayoutLibrary.GetViewportScale(GWorld)
    self:SetEnable(true)
end

-- 需要在OnEnter时期调用
function UPVirtualJoystick:SetEnable(bEnable)
    self.bEnable = bEnable
    self.pWidgetRef:SetVisibility(bEnable and ESlateVisibility.HitTestInvisible or ESlateVisibility.Collapsed)
    local EventHelper = self.EventHelper
    EventHelper:UnregisterAll()
    if bEnable then
        local pUEActor = GamePlayerSelfHelper:Get().pUEActor
        local pPlayerInputComponent = pUEActor.PlayerInputComponent
        EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveTouchStarted, self, OnMoveTouchStarted)
        EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveTouchMoved, self, OnMoveTouchMoved)
        EventHelper:RegisterCppDelegate(pPlayerInputComponent.OnMoveTouchEnded, self, OnMoveTouchEnded)
        EventHelper:RegisterCppDelegate(pUEActor.OnEndPlay, self, OnPlayerActorEndPlay)
    end
end

return UPVirtualJoystick
