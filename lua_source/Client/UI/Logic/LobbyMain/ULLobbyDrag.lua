-----------------------------------------------------
--File Name    : ULLobbyDrag.lua
--Author       : Ranjie
--Create Time  : 2020-4-20
--Description  : ULLobbyDrag
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyDrag = luaclass("ULLobbyDrag", UILogicBase)

local GameplayUtilityHelper = require("GameplayUtilityHelper")
local LobbySystem = require("LobbySystem")
local LobbySubTypeDef = require("LobbySubTypeDef")
local InputHandle = require("InputHandle")

local FUNC_GET_POINTER_INDEX = KismetInputLibrary.PointerEvent_GetPointerIndex
local FUNC_GET_SCREEN_SPACE_POS = KismetInputLibrary.PointerEvent_GetScreenSpacePosition
local DRAG_SPEED = 1

local pEndPos = Vector()
local tbTempRotation = Rotator()
local DEBUG_MODE = false
local INTERACTION_DISTANCE = 10000

local function DragPlayerActor(self, pActor, tbMoveDelta)
    if not pActor then
        --log("UILobbyTeam:DragPlayerActor, can not find player, nPosIndex=", nPosIndex)
        return
    end
    local tbRotation = pActor:K2_GetActorRotation()
    tbTempRotation.Pitch = tbRotation.Pitch
    tbTempRotation.Roll = tbRotation.Roll
    tbTempRotation.Yaw = tbRotation.Yaw -tbMoveDelta.X * DRAG_SPEED
    pActor:K2_SetActorRotation(tbTempRotation)

end

local function OnTouchStarted(self, pGeometry, pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    local pScreenSpacePos = FUNC_GET_SCREEN_SPACE_POS(pMouseEvent)
    local pScreenPos, _ = SlateBlueprintLibrary.AbsoluteToViewport(GWorld, pScreenSpacePos)
    local pController = GameplayStatics.GetPlayerController(GWorld, 0)
    local __, pStartPos, pWorldDirection = GameplayStatics.DeprojectScreenToWorld(pController, pScreenPos)
    --local UIResourceDef = require("UIResourceDef")
    --KismetSystemLibrary.DrawDebugSphere(GWorld, pStartPos, 1, 12, UIResourceDef.COLOR.YELLOW.LINEAR_COLOR, 2, 0)
    local nEndPosX, nEndPosY, nEndPosZ = pStartPos.X + pWorldDirection.X*INTERACTION_DISTANCE, pStartPos.Y + pWorldDirection.Y*INTERACTION_DISTANCE, pStartPos.Z + pWorldDirection.Z*INTERACTION_DISTANCE
    pEndPos.X = nEndPosX
    pEndPos.Y = nEndPosY
    pEndPos.Z = nEndPosZ
    local pTraceActor = nil
    local bRet, pHitResult = GameplayUtilityHelper.TraceActor(GWorld, pStartPos, pEndPos, {}, DEBUG_MODE, false, true, true, true, false, GWorld)
    --logdebug("OnTouchStarted",bRet, pHitResult,nTouchIndex)
    if bRet and pHitResult then
        --logdebug("OnTouchStarted:actor=",KismetSystemLibrary.GetObjectName(pHitResult.Actor))
        if LobbySystem:GetSub(LobbySubTypeDef.MAIN):IsSelfOrTeamMember(pHitResult.Actor) then
            pTraceActor = pHitResult.Actor
        end
    end
    if pTraceActor then
        local tbDragData = {}
        tbDragData.pCurrentPos = pScreenSpacePos
        tbDragData.pActor = pTraceActor
        self.tbDragIndex[nTouchIndex] = tbDragData
    end
    
    return WidgetBlueprintLibrary.Unhandled()
end

-- local function OnTouchMoved(self, pGeometry, pMouseEvent)
--     local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
--     local tbDragData = self.tbDragIndex[nTouchIndex]
--     if not tbDragData or not isvalidhandle(tbDragData.pActor) then
--         return WidgetBlueprintLibrary.Handled()
--     end
--     local pLastPos = tbDragData.pCurrentPos
--     tbDragData.pCurrentPos = FUNC_GET_SCREEN_SPACE_POS(pMouseEvent)
--     local tbMoveDelta = {
--         X = tbDragData.pCurrentPos.X - pLastPos.X
--     }
    
--     DragPlayerActor(self, tbDragData.pActor, tbMoveDelta)
--     return WidgetBlueprintLibrary.Unhandled()
-- end

local function OnTouchEnded(self, pGeometry, pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    --logdebug("OnTouchEnded",nTouchIndex)
    self.tbDragIndex[nTouchIndex] = nil
    return WidgetBlueprintLibrary.Unhandled()
end

local function OnGestureDragActive(self, pGestureResult)
    --logdebug("OnGestureDragActive")
    local nTouchIndex = enumtoint(pGestureResult.FingerIndex)
    local tbDragData = self.tbDragIndex[nTouchIndex]
    if not tbDragData or not isvalidhandle(tbDragData.pActor) then
        return
    end
    local tbMoveDelta = {
        X = pGestureResult.DeltaPosition.X
    }
    --logdebug("OnGestureDragActive", pGestureResult.DeltaDistance, pGestureResult.DeltaPosition,nTouchIndex)
    DragPlayerActor(self, tbDragData.pActor, tbMoveDelta)
end

local function OnGestureDragDeactive(self, pGestureResult)
    local nTouchIndex = enumtoint(pGestureResult.FingerIndex)
    --logdebug("OnGestureDragDeactive", pGestureResult.DeltaDistance, pGestureResult.DeltaPosition,nTouchIndex)
    self.tbDragIndex[nTouchIndex] = nil
end

function ULLobbyDrag:OnLoad()
    
end

function ULLobbyDrag:OnEnter()
    self.tbDragIndex = {}
    CommonShell.GetCommon(GWorld):GetInputManager():OpenGestureSelfTouchListen()
end

function ULLobbyDrag:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchStartedEvent, self, OnTouchStarted)
    --EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchMovedEvent, self, OnTouchMoved)
    EventHelper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnTouchEnded)
end

function ULLobbyDrag:OnUnbindEvent()
    self.InputDragActiveHandle = nil
    self.InputDragDeactiveHandle = nil
end

function ULLobbyDrag:SetEnable(bEnable)
    if bEnable then
        if not self.InputDragActiveHandle then
            self.InputDragActiveHandle = InputHandle:BindGestureActive(EGestureType.Drag, OnGestureDragActive, self)
            self.EventHelper:RegisterHandle(self.InputDragActiveHandle)
        end
        if not self.InputDragDeactiveHandle then
            self.InputDragDeactiveHandle = InputHandle:BindGestureDeactive(EGestureType.Drag, OnGestureDragDeactive, self)
            self.EventHelper:RegisterHandle(self.InputDragDeactiveHandle)
        end
        self.pWidgetRef.bdrTouch:SetVisibility(ESlateVisibility_Visible)
    else
        if self.InputDragActiveHandle then
            self.EventHelper:UnRegisterHandle(self.InputDragActiveHandle)
            self.InputDragActiveHandle = nil
        end
        if self.InputDragDeactiveHandle then
            self.EventHelper:UnRegisterHandle(self.InputDragDeactiveHandle)
            self.InputDragDeactiveHandle = nil
        end
        self.pWidgetRef.bdrTouch:SetVisibility(ESlateVisibility_Collapsed)
    end
end

return ULLobbyDrag