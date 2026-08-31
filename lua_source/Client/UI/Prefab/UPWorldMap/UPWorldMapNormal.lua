-----------------------------------------------------
--File Name    : UPWorldMapNormal.lua
--Author       : Ran Jie
--Create Time  : 2019-9-10
--Description  : 世界地图的地图prefab
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPWorldMapNormal = luaclass("UPWorldMapNormal", PrefabBase)

-- import require
local SceneTable = require("SceneDataTable")
local DungeonDataTable = require("DungeonDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local WorldMapUtil = require("WorldMapUtil")
local GameWorldSystem = require("GameWorldSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local ClientEventDef = require("ClientEventDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")
local UIMapModeDataTable = require("UIMapModeDataTable")

--local veraible
local VIEWPORT_SIZE_X = 990
local VIEWPORT_SIZE_Y = 990
local DEFAULT_MAP_OP_LOGIC_SCRIPT = "ULMapOp"

local COLLAPSED = ESlateVisibility_Collapsed
local FUNC_GET_POINTER_INDEX = KismetInputLibrary.PointerEvent_GetPointerIndex
local FUNC_GET_SCREEN_SPACE_POS = KismetInputLibrary.PointerEvent_GetScreenSpacePosition


--member veriable
UPWorldMapNormal.MapOrigin = nil
UPWorldMapNormal.ViewPortSize = nil
UPWorldMapNormal.ZoomMapSize = nil
UPWorldMapNormal.UIMapValidSize = nil
UPWorldMapNormal.UIMapValidOffset = nil
UPWorldMapNormal.CurrentZoomFactor = nil         --当前缩放的屏幕倍数
UPWorldMapNormal.CurrentMapZoom = 1            --当前缩放的地图倍数
UPWorldMapNormal.ViewPortScale = 1
UPWorldMapNormal.nCurrentSceneID = nil
UPWorldMapNormal.tbMapResData = nil
UPWorldMapNormal.DragTargetPos = nil
UPWorldMapNormal.tbLastPos = nil
UPWorldMapNormal.MapAlignmentX = 0.5
UPWorldMapNormal.MapAlignmentY = 0.5
UPWorldMapNormal.CurAlignmentX = 0.5
UPWorldMapNormal.CurAlignmentY = 0.5
UPWorldMapNormal.tbTimer = nil
UPWorldMapNormal.bDragMap = false
UPWorldMapNormal.bEnableClick = false
UPWorldMapNormal.ViewerObj = nil
UPWorldMapNormal.nFingerCount = nil

--local function
local function InitUserWidgetParam(self)
    local tbMapResData = self.tbMapResData
    local MapSize = Vector2D{
        X = tbMapResData.nMapSizeX,
        Y = tbMapResData.nMapSizeY}
    local UIMapValidSize = Vector2D{
        X = self.UIMapValidSize.X,
        Y = self.UIMapValidSize.Y}
    local UIMapValidOffset = Vector2D{
        X = self.UIMapValidOffset.X,
        Y = self.UIMapValidOffset.Y}
    local MapOrigin = Vector2D{X = -tbMapResData.nMapSizeX / 2, Y = - tbMapResData.nMapSizeY / 2}
    local UIMapOrigin = Vector2D{X = 0, Y = 0}
    self.pWidgetRef:InitMapParam(MapSize, UIMapValidSize, UIMapValidOffset, MapOrigin, UIMapOrigin)
end

local function SetMapAlignment(self, UIMapPos)
    local pWidgetRef = self.pWidgetRef
    local CurAlignment = pWidgetRef.cvsWorldMap.Slot:GetAlignment()
    self.CurAlignmentX = CurAlignment.X
    self.CurAlignmentY = CurAlignment.Y
    local MapAlignmentX = UIMapPos.X / self.ZoomMapSize.X
    local MapAlignmentY = UIMapPos.Y / self.ZoomMapSize.Y
    self.MapAlignmentX = MapAlignmentX
    self.MapAlignmentY = MapAlignmentY
    --logdebug("SetMapAlignment,UIMapPos=",UIMapPos.X, UIMapPos.Y, debug.traceback())
end

local function SetMapPanelOffset(self, nCurUIMapSizeX, nCurUIMapSizeY, UIPosX, UIPosY, bAnim)
    local pWidgetRef = self.pWidgetRef
    local BorderXLeft = nCurUIMapSizeX * self.CurAlignmentX
    local BorderXRight = nCurUIMapSizeX - BorderXLeft
    local BorderYTop = nCurUIMapSizeY * self.CurAlignmentY
    local BorderYBottom = nCurUIMapSizeY - BorderYTop
    local nHalfViewPortSizeX = self.ViewPortSize.X / 2
    local nHalfViewPortSizeY = self.ViewPortSize.Y / 2
    local PosX = math.min(BorderXLeft - nHalfViewPortSizeX, math.max(UIPosX, - (BorderXRight - nHalfViewPortSizeX)))
    local PosY = math.min(BorderYTop - nHalfViewPortSizeY, math.max(UIPosY, - (BorderYBottom - nHalfViewPortSizeY)))
    self.DragTargetPos = {X = PosX, Y = PosY}
    local TargetPos = Vector2D{X = PosX, Y = PosY}
    bAnim = bAnim == nil or bAnim
    pWidgetRef.cvsWorldMap:SetPanelOffset(TargetPos, bAnim)
    pWidgetRef.cvsMapContent:SetPanelOffset(TargetPos, bAnim)
    local ViewPortPos = Vector2D{X = -(PosX - BorderXLeft + nHalfViewPortSizeX), Y = -(PosY - BorderYTop + nHalfViewPortSizeY)}
    
    self.pWidgetRef.radarMap:OnViewPortPosChange(ViewPortPos)
    return PosX, PosY
end

local function SetTargetFactor(self, nZoomFactor)
    if(self.CurrentZoomFactor == nZoomFactor)then
        return
    end
    local tbMapResData = self.tbMapResData
    local nUIMapSizeX = tbMapResData.nUIMapSizeX
    local nUIMapSizeY = tbMapResData.nUIMapSizeY
    local ZoomHeight = self.ViewPortSize.Y * nZoomFactor
    local ZoomWidth = nUIMapSizeX * ZoomHeight / nUIMapSizeY
    self.ZoomMapSize = {X = ZoomWidth, Y = ZoomHeight}
    self.CurrentMapZoom = ZoomHeight / nUIMapSizeY
    self.UIMapValidOffset = {
        X = tbMapResData.nUIMapOffsetX * self.CurrentMapZoom,
        Y = tbMapResData.nUIMapOffsetY * self.CurrentMapZoom}
    self.UIMapValidSize = {
        X = self.ZoomMapSize.X - self.UIMapValidOffset.X * 2,
        Y = self.ZoomMapSize.Y - self.UIMapValidOffset.Y * 2}

    self.MapOrigin = {X = -tbMapResData.nMapSizeX / 2, Y = - tbMapResData.nMapSizeY / 2}
    self.CurrentZoomFactor = nZoomFactor
end

local function RegisterOperations(self)
    local tbModeTemplate = UIMapModeDataTable:GetTemplate(self.tbMapResData.nMode)
    if not tbModeTemplate then
        return
    end
    self.ulMapOp:OnRegisterOperations(tbModeTemplate.nWorldMapOpGroup, nil)
end


local function LoadMapData(self)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    local tbSceneTemplate = nil
    local nObservedSceneID = nil
    if bIsInDungeon then
        nObservedSceneID = BattleGameModeSystem.nDungeonId
        tbSceneTemplate = DungeonDataTable:GetTemplate(nObservedSceneID)
    else
        nObservedSceneID = GameWorldSystem:GetWorld().nSceneId
        tbSceneTemplate = SceneTable:GetTemplate(nObservedSceneID)
    end
    local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneTemplate.nUIMapId)

    local radarMapWidget = self.pWidgetRef.radarMap
    radarMapWidget:SetSpliceNum(tbMapResData.nSplitNum)
    radarMapWidget:SetFilePath(tbMapResData.szPath)
    radarMapWidget:SetCommonFilePath(tbMapResData.szCommonPath)
    radarMapWidget:SetWorldSize(Vector2D{X = tbMapResData.nMapSizeX, Y = tbMapResData.nMapSizeY})
    radarMapWidget:SetMapTextureSize(tbMapResData.nUIMapSizeX)
    radarMapWidget:Init()
    self.nCurrentSceneID = nObservedSceneID
    self.tbMapResData = tbMapResData
    self.ViewPortSize = {X = VIEWPORT_SIZE_X, Y = VIEWPORT_SIZE_Y}
    self.pWidgetRef.cvsWorldMap:SetInterSpeed(10)
    self.pWidgetRef.cvsMapContent:SetInterSpeed(10)
end

local function RefreshMapPos(self, MoveDelta)
    local pWidgetRef = self.pWidgetRef
    if(self.DragTargetPos == nil)then
        self.DragTargetPos = pWidgetRef.cvsWorldMap.Slot:GetPosition()
    end

    local PosX = self.DragTargetPos.X + (MoveDelta.X / self.ViewPortScale)
    local PosY = self.DragTargetPos.Y + (MoveDelta.Y / self.ViewPortScale)
    PosX, PosY = SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, PosX, PosY)
    self.DragTargetPos = {X = PosX, Y = PosY}
    local tbAlignPos = {X = -PosX + self.ZoomMapSize.X * self.CurAlignmentX, Y = -PosY + self.ZoomMapSize.Y * self.CurAlignmentY}
    SetMapAlignment(self, tbAlignPos)
end

local function CalculateUIMapLocation(self, Location)
    local MapOrigin = self.MapOrigin
    local UIMapValidSize = self.UIMapValidSize
    local tbMapResData = self.tbMapResData
    local nUIX = (Location.X - MapOrigin.X) * UIMapValidSize.X / tbMapResData.nMapSizeX + self.UIMapValidOffset.X
    local nUIY = (Location.Y - MapOrigin.Y) * UIMapValidSize.Y / tbMapResData.nMapSizeY + self.UIMapValidOffset.Y
    return nUIX, nUIY
end

local function GetViewerLocation(self)
    local tbViewObj = GamePlayerSelfHelper:Get()
    if self.ViewerObj then
        tbViewObj = self.ViewerObj
    end
    return tbViewObj:GetLocation()
end

local function RefreshMapAlignmentWhenSlider(self, pWidgetRef, nZoomFactor)
    -- local SelfObj = GamePlayerSelfHelper:Get()
    -- local SelfActor = SelfObj:GetModelActor()
    -- if(SelfActor == nil or not isvalidhandle(SelfActor))then
    --     return false
    -- end
    local pShipLocation = GetViewerLocation(self)
    local nUIX, nUIY = CalculateUIMapLocation(self, pShipLocation)
    local bSetAlignmentImmediately = true
    if nZoomFactor == 1 then
        SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
        self.bDragMap = false
    elseif self.bDragMap then
        self.CurAlignmentX = self.MapAlignmentX
        self.CurAlignmentY = self.MapAlignmentY
    elseif nUIX >= self.UIMapValidSize.X or nUIY >= self.UIMapValidSize.Y then
        SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
        self.bDragMap = false
    else
        SetMapAlignment(self, {X = nUIX, Y = nUIY})
        self.bDragMap = false
        bSetAlignmentImmediately = false
    end
    return bSetAlignmentImmediately
end

--drag event
local function UpdateFingerCount(self)
    local nFingerCount = 0
    for k, v in pairs(self.tbLastPos) do
        nFingerCount = nFingerCount + 1
    end
    self.nFingerCount = nFingerCount
    if nFingerCount == 0 then
        --self.bDragMap = false
        self.bEnableClick = false
    end
end

local function OnMouseButtonDown(self, pGeometry, pMouseEvent)
    -- printScreen("OnMouseButtonDown")
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    if nTouchIndex == 10 then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local pos = FUNC_GET_SCREEN_SPACE_POS(pMouseEvent)
    self.tbLastPos[nTouchIndex] = pos
    UpdateFingerCount(self)
    if self.nFingerCount == 1 then
        self.bEnableClick = true
    else
        self.bEnableClick = false
    end
    return WidgetBlueprintLibrary.Unhandled()
end

local function OnMouseMove(self, pGeometry, pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    if nTouchIndex == 10 then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local curPos = FUNC_GET_SCREEN_SPACE_POS(pMouseEvent)
    local lastScreenPos = self.tbLastPos[nTouchIndex]
    if not lastScreenPos then
        return WidgetBlueprintLibrary.Unhandled()
    else
        local nX = curPos.X - lastScreenPos.X
        local nY = curPos.Y - lastScreenPos.Y
        if nX*nX + nY*nY < 5 then
            return WidgetBlueprintLibrary.Unhandled()
        end
    end
    local MoveDelta = {
        X = curPos.X - lastScreenPos.X,
        Y = curPos.Y - lastScreenPos.Y,
    }
    RefreshMapPos(self, MoveDelta)
    self.tbLastPos[nTouchIndex] = curPos
    if self.nFingerCount == 1 then
        self.bDragMap = true
    end
    self.bEnableClick = false
    return WidgetBlueprintLibrary.Unhandled()
end

local function OnMouseButtonUp(self, pGeometry, pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    if nTouchIndex == 10 then
        return WidgetBlueprintLibrary.Unhandled()
    end
    local ScreenPos = self.tbLastPos[nTouchIndex]
    if ScreenPos and self.bEnableClick then
        --click
        local Geomy = self.pWidgetRef.cvsWorldMap:GetCachedGeometry()
        local LocalPos = SlateBlueprintLibrary.AbsoluteToLocal(Geomy, ScreenPos)
        local nCurrentMode = ControlModeSystem:GetCurrentModeType()
        if nCurrentMode == ControlModeDef.TRANSPORT then
            LocalPos.X = self.ZoomMapSize.X - LocalPos.X
        end
        LocalPos.X = LocalPos.X - self.ZoomMapSize.X/2
        LocalPos.Y = LocalPos.Y - self.ZoomMapSize.Y/2
        local WorldPosX = LocalPos.X * self.tbMapResData.nMapSizeX / (self.ZoomMapSize.X - self.tbMapResData.nUIMapOffsetX * 2 * self.CurrentMapZoom)
        local WorldPosY = LocalPos.Y * self.tbMapResData.nMapSizeY / (self.ZoomMapSize.Y - self.tbMapResData.nUIMapOffsetY * 2 * self.CurrentMapZoom)
        log("Current World Pos,WorldPosX, WorldPosY, WorldPosZ=",LocalPos.X, LocalPos.Y, WorldPosX, WorldPosY, WorldMapUtil.nMaxHight)
        self.ulMapOp:OnClickMapWorldPos(WorldPosX, WorldPosY)
    end

    self.tbLastPos[nTouchIndex] = nil
    UpdateFingerCount(self)
    return WidgetBlueprintLibrary.Unhandled()
end

local function OnMouseButtonLeave(self, pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    self.tbLastPos[nTouchIndex] = nil
    UpdateFingerCount(self)
end

local function OnPinch(self, nDeltaDistance, CenterScreenPos)
    --logdebug("UPWorldMapNormal:OnPinch,nDeltaDistance=",nDeltaDistance)
    local nRatio = nDeltaDistance / WorldMapUtil.PinchSize
    local nUIMapSizeX = self.tbMapResData.nUIMapSizeX
    local nUIMapSizeY = self.tbMapResData.nUIMapSizeY
    local ZoomHeightMax = self.ViewPortSize.Y * self.Owner:GetMaxZoomFactor()
    local ZoomWidthMax = nUIMapSizeX * ZoomHeightMax / nUIMapSizeY
    local ZoomHeightMin = self.ViewPortSize.Y
    local ZoomWidthMin = nUIMapSizeX * ZoomHeightMin / nUIMapSizeY
    local tbTargetSize = {X = self.ZoomMapSize.X + (ZoomWidthMax - ZoomWidthMin) * nRatio, Y = self.ZoomMapSize.Y + (ZoomHeightMax - ZoomHeightMin) * nRatio}
    tbTargetSize.X = math.min(ZoomWidthMax, math.max(ZoomWidthMin, self.ZoomMapSize.X + (ZoomWidthMax - ZoomWidthMin) * nRatio))
    tbTargetSize.Y = math.min(ZoomHeightMax, math.max(ZoomHeightMin, self.ZoomMapSize.Y + (ZoomHeightMax - ZoomHeightMin) * nRatio))
    local nZoomFactor = math.min(self.Owner:GetMaxZoomFactor(), math.max(1, tbTargetSize.Y / self.ViewPortSize.Y))
    self:SetMapSizeZoomFactor(nZoomFactor)
    return WidgetBlueprintLibrary.Unhandled()
end

-------------------------------------------------------------------------------------
function UPWorldMapNormal:OnLoad()
    LoadMapData(self)
    local tbModeTemplate = UIMapModeDataTable:GetTemplate(self.tbMapResData.nMode)
    log("UPWorldMapNormal:OnLoad,nMode=",self.tbMapResData.nMode,self.tbMapResData.nResId)
    local UILogicHelper = self.UILogicHelper
    local szWorldMapScript = DEFAULT_MAP_OP_LOGIC_SCRIPT
    if tbModeTemplate then
        szWorldMapScript = tbModeTemplate.szWorldMapScript
    end
    self.ulMapOp = UILogicHelper:CreateUILogic(szWorldMapScript)
    self:HideAll()
end

function UPWorldMapNormal:OnBindEvent(Helper)
    local bdrListener = self.pWidgetRef.bdrListener
    Helper:RegisterCppDelegate(bdrListener.OnMouseButtonDownEvent, self, OnMouseButtonDown)
    Helper:RegisterCppDelegate(bdrListener.OnMouseMoveEvent, self, OnMouseMove)
    Helper:RegisterCppDelegate(bdrListener.OnMouseButtonUpEvent, self, OnMouseButtonUp)
    Helper:RegisterCppDelegate(bdrListener.OnMouseLeaveEvent, self, OnMouseButtonLeave)
    Helper:RegisterCppDelegate(bdrListener.OnPinchEvent, self, OnPinch)
end

function UPWorldMapNormal:OnEnter()
    self.tbLastPos = {}
    self.nFingerCount = 0
    self.bDragMap = false
    local tbOpenArg = self.Owner.tbOpenArgs
    if tbOpenArg and tbOpenArg.ViewObj then
        self.ViewerObj = tbOpenArg.ViewObj
    end
    --self:HideAll()
end

function UPWorldMapNormal:OnHide()
    --SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, 0, 0, false)
    self.ulMapOp:CloseRegisterOperations()
end

function UPWorldMapNormal:OnUnload()
    self.ulMapOp:UnregisterAllOperations()
end

function UPWorldMapNormal:HideAll()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.ovlArrow:SetVisibility(COLLAPSED)
    pWidgetRef.kmFFAPoisonCircle:SetVisibility(COLLAPSED)
    pWidgetRef.pbFFASafeCircle:SetVisibility(COLLAPSED)
end

function UPWorldMapNormal:ShowMapData(nZoomFactor)
    --logdebug("UPWorldMapNormal:ShowMapData")
    local pWidgetRef = self.pWidgetRef
    self.DragTargetPos = nil
    SetTargetFactor(self, nZoomFactor)
    local NextSize = Vector2D{X = self.ZoomMapSize.X, Y = self.ZoomMapSize.Y}
    self.pWidgetRef.cvsWorldMap.Slot:SetSize(NextSize)
    self.pWidgetRef.cvsMapContent.Slot:SetSize(NextSize)
    RefreshMapAlignmentWhenSlider(self, pWidgetRef, nZoomFactor)
    local Alignment = Vector2D{X = self.MapAlignmentX, Y = self.MapAlignmentY}
    self.pWidgetRef.cvsWorldMap.Slot:SetAlignment(Alignment)
    self.pWidgetRef.cvsMapContent.Slot:SetAlignment(Alignment)
    --SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, 0, 0, false)
    InitUserWidgetParam(self)
    RegisterOperations(self)
    --logdebug("UPWorldMapNormal:ShowMapData1")
    local radarMapWidget = self.pWidgetRef.radarMap
    radarMapWidget:SetViewPortSize(Vector2D{X = self.ViewPortSize.X, Y = self.ViewPortSize.Y})
    radarMapWidget:OnWidgetSizeChange(Vector2D{X = self.UIMapValidSize.X, Y = self.UIMapValidSize.Y})
    --logdebug("UPWorldMapNormal:ShowMapData2")
end

function UPWorldMapNormal:SetMapSizeZoomFactor(nZoomFactor)
    SetTargetFactor(self, nZoomFactor)
    local bSetAlignmentImmediately = RefreshMapAlignmentWhenSlider(self, self.pWidgetRef, nZoomFactor)
    if bSetAlignmentImmediately then
        local Alignment = Vector2D{X = self.MapAlignmentX, Y = self.MapAlignmentY}
        self.pWidgetRef.cvsWorldMap.Slot:SetAlignment(Alignment)
        self.pWidgetRef.cvsMapContent.Slot:SetAlignment(Alignment)
    end
    SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, 0, 0, false)
    self.EventHelper:FireEvent(ClientEventDef.EV_MAP_PINCH_CHANGED, self.ZoomMapSize, not bSetAlignmentImmediately)
end

function UPWorldMapNormal:LocationPlayer()
    local UIMapPos = self.pWidgetRef.ovlArrow.Slot:GetPosition()
    local ZoomMapSize = self.ZoomMapSize
    local CurAlignment = self.pWidgetRef.cvsWorldMap.Slot:GetAlignment()
    self.CurAlignmentX = CurAlignment.X
    self.CurAlignmentY = CurAlignment.Y
    local BorderXLeft = ZoomMapSize.X * self.CurAlignmentX
    local BorderYTop = ZoomMapSize.Y * self.CurAlignmentY
    local UIPosOffsetX = - (UIMapPos.X - BorderXLeft)
    local UIPosOffsetY = - (UIMapPos.Y - BorderYTop)
    --logdebug("LocateUIMapPosToScreenCenter,",UIPosOffsetX, UIPosOffsetY,self.CurAlignmentX,self.CurAlignmentY,BorderXLeft,BorderYTop,UIMapPos.X, UIMapPos.Y)
    SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, UIPosOffsetX, UIPosOffsetY)
    self.DragTargetPos = nil
    self.bDragMap = false
end

function UPWorldMapNormal:GetCurrentSceneId()
    return self.nCurrentSceneID
end

function UPWorldMapNormal:IsMMap()
    return true
end


return UPWorldMapNormal
