-----------------------------------------------------
--File Name    : ULLobbyShipBdrRotate.lua
--Author       : chenyixin
--Description  : 舰船界面划屏旋转逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShipBdrRotate = luaclass("ULLobbyShipBdrRotate", UILogicBase)

ULLobbyShipBdrRotate.bIsDrag = false
ULLobbyShipBdrRotate.nLastPosX = 0
ULLobbyShipBdrRotate.pRotateActor = nil
ULLobbyShipBdrRotate.pOriginRotation = nil

---------------------------------------
-- Widget事件
---------------------------------------
local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    self.bIsDrag = true
    self.nLastPosX = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent).X
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    if self.bIsDrag then
        local nCurrentPosX = KismetInputLibrary.PointerEvent_GetScreenSpacePosition(pMouseEvent).X
        if isvalidhandle(self.pRotateActor) then
            self.OwnerSub:RotateActor(self.pRotateActor, nCurrentPosX - self.nLastPosX)
        end
        self.nLastPosX = nCurrentPosX
    end
    return WidgetBlueprintLibrary.Handled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    self.bIsDrag = false
    return WidgetBlueprintLibrary.Handled()
end

---------------------------------------
-- life cycle
---------------------------------------
function ULLobbyShipBdrRotate:OnLoad()
    self.OwnerSub = self.Owner.OwnerSub
end

function ULLobbyShipBdrRotate:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef

    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseMoveEvent, self, OnMouseMove)
    EventHelper:RegisterCppDelegate(pWidgetRef.bdrRotate.OnMouseButtonUpEvent, self, OnMouseButtonUp)
end

---------------------------------------
-- 接口
---------------------------------------
function ULLobbyShipBdrRotate:SetRotateActor(pActor)
    self.pRotateActor = pActor
    if isvalidhandle(self.pRotateActor) then
        self.pOriginRotation = self.pRotateActor:K2_GetActorRotation()
    end
end

function ULLobbyShipBdrRotate:ResetActorRotation()
    if isvalidhandle(self.pRotateActor) and self.pOriginRotation then
        self.pRotateActor:K2_SetActorRotation(self.pOriginRotation)
    end
end

return ULLobbyShipBdrRotate