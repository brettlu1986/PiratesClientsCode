local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPFFASelectPointMap = luaclass("UPFFASelectPointMap", PrefabBase)

-- import require
local UIDef       = require("UIDef")
local SceneTable = require("SceneDataTable")
local DungeonDataTable = require("DungeonDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
-- local MapContentPointTable = require("MapContentPointTable")
local WorldMapUtil = require("WorldMapUtil")
local GameWorldSystem = require("GameWorldSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ControlModeSystem = require("ControlModeSystem")
local ControlModeDef = require("ControlModeDef")
local ClientEventDef = require("ClientEventDef")
local ProtoDR = require("DungeonRepProtoNames")
local ProtoDP = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local DelayTimer = require("DelayTimer")
local ParachutingNewIni = require("ParachutingNewIni")
local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local ParachutionSystem_C = require("ParachutionSystem_C")
-- local MapOpForCoreArea = require("MapOpForCoreArea")
local NoobParachutingJsonTable = require("NoobParachutingJsonTable")
local EventManager = require("EventManager")
local SoundManager = require("SoundManager")
local UIResourceDef = require("UIResourceDef")

--local veraible
local VIEWPORT_SIZE_X = 922
local VIEWPORT_SIZE_Y = 922
--local FInterpTo_Func = KismetMathLibrary.FInterpTo
local tbTempSize = Vector2D()
local FUNC_GET_POINTER_INDEX = KismetInputLibrary.PointerEvent_GetPointerIndex
local FUNC_GET_SCREEN_SPACE_POS = KismetInputLibrary.PointerEvent_GetScreenSpacePosition

--member veriable
UPFFASelectPointMap.MapOrigin = nil
UPFFASelectPointMap.ViewPortSize = nil
UPFFASelectPointMap.ZoomMapSize = nil
UPFFASelectPointMap.UIMapValidSize = nil
UPFFASelectPointMap.UIMapValidOffset = nil
UPFFASelectPointMap.CurrentZoomFactor = nil         --当前缩放的屏幕倍数
UPFFASelectPointMap.CurrentMapZoom = 1            --当前缩放的地图倍数
UPFFASelectPointMap.nCurrentGrade = nil
UPFFASelectPointMap.ViewPortScale = 1
UPFFASelectPointMap.nObservedSceneID = nil
UPFFASelectPointMap.nCurrentSceneID = nil
UPFFASelectPointMap.nObservedMapMode = UIDef.UI_MAP_MODE.WILD_OCEAN
UPFFASelectPointMap.tbMapResData = nil
UPFFASelectPointMap.bPlayZoomAnim = false
UPFFASelectPointMap.DragTargetPos = nil
UPFFASelectPointMap.tbLastPos = nil
UPFFASelectPointMap.MapAlignmentX = 0.5
UPFFASelectPointMap.MapAlignmentY = 0.5
UPFFASelectPointMap.CurAlignmentX = 0.5
UPFFASelectPointMap.CurAlignmentY = 0.5
UPFFASelectPointMap.tbTimer = nil
UPFFASelectPointMap.bMirror = false
UPFFASelectPointMap.bDragMap = false

UPFFASelectPointMap.tbMapOpForBornPoint = nil
UPFFASelectPointMap.tbMapOpForGOPath = nil
UPFFASelectPointMap.tbMapOpForGOPathTarget = nil
UPFFASelectPointMap.tbMapOpFFAStaticPoint = nil
UPFFASelectPointMap.bSelectPoint = true
UPFFASelectPointMap.tbDelayTimer = nil
UPFFASelectPointMap.tbCachePoint = nil
UPFFASelectPointMap.bNoobDungeon = nil
UPFFASelectPointMap.bEnableClick = false
UPFFASelectPointMap.bEnablePinch = true
UPFFASelectPointMap.tbSelectedPoint = nil
UPFFASelectPointMap.tbMapOp = nil
UPFFASelectPointMap.tbSelectedTransporter = nil

--local function
local function RegisterOrOpenMapOp(self, szMapOpClass)
    if not self.tbMapOp then
        return
    end
    local tbMapOpInstance = self.tbMapOp[szMapOpClass]
    if tbMapOpInstance then
        tbMapOpInstance:Open()
    else
        local MapOpClass = require(szMapOpClass)
        tbMapOpInstance = MapOpClass()
        tbMapOpInstance:Init(self)
        tbMapOpInstance:BindEvent()
        self.tbMapOp[szMapOpClass] = tbMapOpInstance
    end
    return tbMapOpInstance
end

local function InitMapOp(self)
    -- if self.tbMapOpForBornPoint ~= nil then
    --     return
    -- end
    --logdebug("InitMapOp")
    RegisterOrOpenMapOp(self, "MapOpSizeScale")
    self.tbMapOpFFAStaticPoint = RegisterOrOpenMapOp(self, "MapOpFFAStaticPoint")
    self.tbMapOpForBornPoint = RegisterOrOpenMapOp(self, "MapOpForBornPoint")
    self.tbMapOpForGOPath = RegisterOrOpenMapOp(self, "MapOpForGOPathNew")
    self.tbMapOpForGOPathTarget = RegisterOrOpenMapOp(self, "MapOpForGOPathTarget")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
end

local function GetViewMapCenter(self)
    local tbSelectedPoint = ParachutionSystem_C:GetSelectedPoint()
    if tbSelectedPoint then
        if not self.tbSelectedPoint then
            self.tbSelectedPoint = {X = 0, Y = 0}
        end
        self.tbSelectedPoint.X = tbSelectedPoint.nX
        self.tbSelectedPoint.Y = tbSelectedPoint.nY
        --logdebug("GetViewMapCenter, self.tbSelectedPoint.X,self.tbSelectedPoint.Y=",self.tbSelectedPoint.X,self.tbSelectedPoint.Y)
        return self.tbSelectedPoint
    end
end

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
    --pWidgetRef.cvsMapNav:SetPanelOffset(TargetPos, bAnim)

    local ViewPortPos = Vector2D{X = -(PosX - BorderXLeft + nHalfViewPortSizeX), Y = -(PosY - BorderYTop + nHalfViewPortSizeY)}
    self.pWidgetRef.radarMap:OnViewPortPosChange(ViewPortPos)
    return PosX, PosY
end

local function OnFFAProcessStateChanged(self, nState)
    if nState == ProtoDR.rFFAProcessState_EState.SELECTION_LOCK then
        self.bSelectPoint = false
    end
end

local function OnFFASelectPoint(self, tbPacket)
    log("select point map 1")
    if self.tbSelectedTransporter == nil then
        self.tbSelectedTransporter = {nTransporterId = 0, nInstanceId = 0, nCount = 0}
    end
    local tbTransporter = self.tbSelectedTransporter

    local tbTeamInfos = GamePlayerSelfHelper:Get().BattleTeamComponent:GetTeamInfos()
    local nLeaderId = 0
    if tbTeamInfos ~= nil and #tbTeamInfos > 0 then
        nLeaderId = tbTeamInfos[1].nInstanceId
    end
    local nSelfId = GamePlayerSelfHelper:GetServerInstanceId()
    local nFirstId = tbPacket.PointInfos[1].nInstanceId
    log("OnFFASelectPoint ", nFirstId)
    local nOldId = tbTransporter.nInstanceId
    local nLeaderTransporterId, nSelfTransporterId, nFirstTransporterId, nOldTransporterId = 0, 0, 0, 0
    local nLeaderTCount, nSelfTCount, nFirstTCount, nOldTCount = 0, 0, 0, 0

    for i, v in ipairs(tbPacket.PointInfos) do
        if v.nInstanceId == nSelfId then
            nSelfTransporterId = ParachutionSystem_C:GetTransporterId(v.nX, v.nY) 
            nSelfTCount = v.nCount
        elseif v.nInstanceId == nLeaderId then
            nLeaderTransporterId = ParachutionSystem_C:GetTransporterId(v.nX, v.nY)
            nLeaderTCount = v.nCount
        elseif v.nInstanceId == nOldId then
            nOldTransporterId = ParachutionSystem_C:GetTransporterId(v.nX, v.nY)
            nOldTCount = v.nCount
        end
        if i == 1 then
            nFirstTransporterId = ParachutionSystem_C:GetTransporterId(v.nX, v.nY)
            nFirstTCount = v.nCount
        end
        log("OnFFASelectPoint set born pos ", v.nInstanceId)
        self.tbMapOpForBornPoint:SetBornPos(v.nInstanceId, {X = v.nX * 1, Y = v.nY * 1}, v.nTransporterId == 0)
    end
    log("select point map 2")

    local nOld = tbTransporter.nTransporterId
    if nSelfTransporterId and nSelfTransporterId > 0 then
        tbTransporter.nTransporterId = nSelfTransporterId
        tbTransporter.nInstanceId = nSelfId
        tbTransporter.nCount = nSelfTCount
    elseif nLeaderTransporterId and nLeaderTransporterId > 0 then
        if tbTransporter.nInstanceId ~= nSelfId then
            tbTransporter.nTransporterId = nLeaderTransporterId
            tbTransporter.nInstanceId = nLeaderId
            tbTransporter.nCount = nLeaderTCount
        end
    elseif nOldTransporterId and nOldTransporterId > 0 then
        if tbTransporter.nInstanceId ~= nSelfId 
            and tbTransporter.nInstanceId ~= nLeaderId then
            tbTransporter.nTransporterId = nOldTransporterId
            tbTransporter.nInstanceId = nOldId
            tbTransporter.nCount = nOldTCount
        end
    else
        if tbTransporter.nInstanceId == 0 then
            tbTransporter.nTransporterId = nFirstTransporterId
            tbTransporter.nInstanceId = nFirstId
            tbTransporter.nCount = nFirstTCount
        end
    end
    if nOld == tbTransporter.nTransporterId then
        log("SelectTransporter old = new ", nOld, tbTransporter.nTransporterId)
        return
    end
    log("SelectTransporter ", tbTransporter.nTransporterId)
    self.tbMapOpForGOPath:SetSelfTransporterLine(tbTransporter.nTransporterId)
    self.tbMapOpForGOPathTarget:SetSelfTransporterLine(tbTransporter.nTransporterId)

    if tbTransporter.nCount ~= nil then
        self.Owner:SetTransporterPlayerCount(tbTransporter.nCount)
    end
end

local function OnFFASelectPointes(self)
    local tbPointes = ParachutionSystem_C:GetSelectionPointes()
    if tbPointes == nil or #tbPointes == 0 then
        return
    end
    OnFFASelectPoint(self, {PointInfos = tbPointes})
end

local function OnFFACancelSelectPoint(self, tbSelectionPointes, nInstanceId)
    self.tbMapOpForBornPoint:CancelBornPos(nInstanceId)
    self.tbSelectedTransporter = nil
    if #tbSelectionPointes > 0 then
        OnFFASelectPoint(self, {PointInfos = tbSelectionPointes})
    else
        self.tbMapOpForGOPath:CancelSelfTransporterLine()
        self.tbMapOpForGOPathTarget:CancelSelfTransporterLine()
        self.Owner:SetTransporterPlayerCount(0)
    end
end

local function OnFFATeamInfo(self)
    self.tbMapOpForBornPoint:RefreshTeam()
end

local function DestroyTimer(self)
    if self.tbDelayTimer ~= nil then
        DelayTimer:ClearTimer(self.tbDelayTimer)
        self.tbDelayTimer = nil
    end
end

local function SetTargetFactor(self, nZoomFactor)
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


    self.CurrentZoomFactor = nZoomFactor
end

function UPFFASelectPointMap:GetNoobParachutingArea()
    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbAreaData = NoobParachutingJsonTable[nDungeonId]
    if not tbAreaData then
        return
    end

    local pGeometry = self.pWidgetRef.cvsWorldMap:GetCachedGeometry()
    local CalculateUIMapLocation = function(Location)
        local MapOrigin = self.MapOrigin
        local UIMapValidSize = self.UIMapValidSize
        local tbMapResData = self.tbMapResData
        local nUIX = (Location.X - MapOrigin.X) * UIMapValidSize.X / tbMapResData.nMapSizeX + self.UIMapValidOffset.X
        local nUIY = (Location.Y - MapOrigin.Y) * UIMapValidSize.Y / tbMapResData.nMapSizeY + self.UIMapValidOffset.Y
        local Pos = SlateBlueprintLibrary.LocalToAbsolute(pGeometry, Vector2D{X = nUIX, Y = nUIY})
        return {X = Pos.X, Y = Pos.Y}
    end
    local CalculateUISize = function (nSceneSizeX, nSceneSizeY)
        local tbMapResData = self.tbMapResData
        local nUIRealMapSizeX = self.UIMapValidSize.X + 2 * self.UIMapValidOffset.X
        local nUIRealMapSizeY = self.UIMapValidSize.Y + 2 * self.UIMapValidOffset.Y
        local nUISizeX = nSceneSizeX / tbMapResData.nMapSizeX * nUIRealMapSizeX
        local nUISizeY = nSceneSizeY / tbMapResData.nMapSizeY * nUIRealMapSizeY
        return {X = nUISizeX, Y = nUISizeY}
    end


    local tbData = {}
    for i, v in ipairs(tbAreaData) do
        local tbBoxSize = CalculateUISize(v.tbSize.X, v.tbSize.Y)
        local tbBoxPos = CalculateUIMapLocation(v.tbCenter)
        table.insert(tbData, {BoxSize = tbBoxSize, BoxPos = tbBoxPos})
        log("GetNoobParachutingArea:", tbBoxPos.X, tbBoxPos.Y, tbBoxSize.X, tbBoxSize.Y)
    end

    return tbData
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

function UPFFASelectPointMap:OnLoad()
    self.tbLastPos = {}
    self.tbMapOp = {}
    -- self.ViewPortSize = {X = 922, Y = 922}

    -- self.pWidgetRef.cvsWorldMap:SetInterSpeed(10)
    -- self.pWidgetRef.cvsMapContent:SetInterSpeed(10)
    self.nAnimZoom = WorldMapUtil.tbZoomFactor.ZOOM_MAX
    LoadMapData(self)
end

-- local function ShowFFATransportInfo(self)
--     local tbInfos = ParachutionSystem_C:GetTransporterInfos()
--     if tbInfos ~= nil then
--         self.tbMapOpForGOPath:SetTransporterLines(tbInfos)
--         self.tbMapOpForGOPathTarget:SetTransporterLines(tbInfos)
--     end
--     --self.tbMapOpForCoreArea:InitCoreArea()
-- end

local function OnFFATransportInfo(self, tbPacket)
    local tbInfos 
    if not tbPacket then
        tbInfos = ParachutionSystem_C:GetTransporterInfos()
    else
        tbInfos = tbPacket.Infos
    end
    if tbInfos then
        self.tbMapOpForGOPath:SetTransporterLines(tbInfos)
        self.tbMapOpForGOPathTarget:SetTransporterLines(tbInfos)
    end
end

local function SetPinchEnable(self, bEnable)
    self.bEnablePinch = bEnable
end

local function OnControlModeActivate(self)
    for k, v in pairs(self.tbMapOp) do
        v:Reinit()
    end
end

function UPFFASelectPointMap:OnBindEvent(Helper)
    local bdrListener = self.pWidgetRef.bdrListener
    Helper:RegisterCppDelegate(bdrListener.OnMouseButtonDownEvent, self, self.OnMouseButtonDown)
    Helper:RegisterCppDelegate(bdrListener.OnMouseMoveEvent, self, self.OnMouseMove)
    Helper:RegisterCppDelegate(bdrListener.OnMouseButtonUpEvent, self, self.OnMouseButtonUp)
    Helper:RegisterCppDelegate(bdrListener.OnMouseLeaveEvent, self, self.OnMouseButtonLeave)
    Helper:RegisterCppDelegate(bdrListener.OnPinchEvent, self, self.OnPinch)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_PROCESS_STATE_CHANGED, self, OnFFAProcessStateChanged)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINT, self, OnFFASelectPoint)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINTES_UPDATE, self, OnFFASelectPointes)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_TEAM_INFO_CHANGED, self, OnFFATeamInfo)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_TRANSPORT_INFO_NEW, self, OnFFATransportInfo)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_ENABLE_SELECTPOINT_MAP_PINCH, self, SetPinchEnable)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_CONTROL_MODE_ACTIVATE, self, OnControlModeActivate)
    Helper:RegisterEvent(ClientEventDef.EV_FFA_SELECT_POINT_CANCEL, self, OnFFACancelSelectPoint)
end

function UPFFASelectPointMap:OnEnter()
    self.bDragMap = false
end

function UPFFASelectPointMap:OnShow()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.kmFFAPoisonCircle:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pbFFASafeCircle:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.Collapsed)
    OnFFASelectPointes(self)
    OnFFATransportInfo(self)
    local nState = ParachutionSystem_C:GetState()
    if nState then
        self.bSelectPoint = nState < ProtoDR.rFFAProcessState_EState.SELECTION_LOCK
    else
        self.bSelectPoint = true
    end
end

function UPFFASelectPointMap:OnHide()
    for k, v in pairs(self.tbMapOp) do
        v:Close()
    end
    self.bSelectPoint = false
end

-- function UPFFASelectPointMap:OnHide()
--     self.tbMapOpSizeScale:Uninit()
--     self.tbMapOpSizeScale = nil
--     self.tbMapOpForBornPoint:Uninit()
--     self.tbMapOpForBornPoint = nil
--     self.tbMapOpForGOPath:Uninit()
--     self.tbMapOpForGOPath = nil
--     self.tbMapOpForGOPathTarget:Uninit()
--     self.tbMapOpForGOPathTarget = nil
--     self.tbMapOpForCoreArea:Uninit()
--     self.tbMapOpForCoreArea = nil
--     self.tbMapOpFFAStaticPoint:Uninit()
--     self.tbMapOpFFAStaticPoint = nil
--     self.bSelectPoint = false
--     self.pWidgetRef:UnregisterAllOperation()
-- end

function UPFFASelectPointMap:Unload()
    for k, v in pairs(self.tbMapOp) do
        v:Uninit()
    end
    self.tbMapOp = nil
    self.tbMapOpForBornPoint = nil
    self.tbMapOpForGOPath = nil
    self.tbMapOpForGOPathTarget = nil
    self.tbMapOpFFAStaticPoint = nil
    self.bSelectPoint = false
    self.pWidgetRef:UnregisterAllOperation()
end

function UPFFASelectPointMap:OnDestroy()
    DestroyTimer(self)
    --logdebug("UPFFASelectPointMap:OnDestroy")
end

function UPFFASelectPointMap:RefreshSceneMap(nObservedSceneID, nObservedMapMode, nZoomFactor, nCurrentGrade)
    --logdebug("RefreshSceneMap,self.CurrentZoomFactor,nZoomFactor=",self.CurrentZoomFactor,nZoomFactor)
    if(self.CurrentZoomFactor == nZoomFactor)then
        return
    end
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    local tbSceneTemplate = nil
    if bIsInDungeon then
        nObservedSceneID = BattleGameModeSystem.nDungeonId
        --logdebug("nObservedSceneID=",nObservedSceneID)
        tbSceneTemplate = DungeonDataTable:GetTemplate(nObservedSceneID)
    else
        tbSceneTemplate = SceneTable:GetTemplate(nObservedSceneID)
    end
    local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneTemplate.nUIMapId)
    --logdebug("tbSceneTemplate.nUIMapId=",tbSceneTemplate.nUIMapId,tbMapResData)
    self.tbMapResData = tbMapResData

    local nUIMapSizeX = tbMapResData.nUIMapSizeX
    local nUIMapSizeY = tbMapResData.nUIMapSizeY

    self.ViewPortRealSize = {
        X = nUIMapSizeX * self.ViewPortSize.Y / nUIMapSizeY,
        Y = self.ViewPortSize.Y
    }

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

    self.nObservedSceneID = nObservedSceneID
    self.CurrentZoomFactor = nZoomFactor
    self.nCurrentGrade = nCurrentGrade
    self.nObservedMapMode = nObservedMapMode
    --self.bMirror = bMirror
    InitUserWidgetParam(self)


    local radarMapWidget = self.pWidgetRef.radarMap
    radarMapWidget:SetViewPortSize(Vector2D{X = self.ViewPortSize.X, Y = self.ViewPortSize.Y})
    radarMapWidget:OnWidgetSizeChange(Vector2D{X = self.UIMapValidSize.X, Y = self.UIMapValidSize.Y})
end

function UPFFASelectPointMap:OnTick()
    if(self.bPlayZoomAnim)then
        self:MapSizeAnim()
    end
end

function UPFFASelectPointMap:RefreshMapPos(MoveDelta)
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

local function RefreshMapAlignmentWhenSlider(self, pWidgetRef, nZoomFactor)
    local tbViewMapCenter = GetViewMapCenter(self)
    local bSetAlignmentImmediately = true
    if tbViewMapCenter then
        local nUIX, nUIY = CalculateUIMapLocation(self, tbViewMapCenter)
        --logdebug("tbViewMapCenter=",tbViewMapCenter.X, tbViewMapCenter.Y)
        if nZoomFactor == 1 then
            SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
        elseif nUIX >= self.UIMapValidSize.X or nUIY >= self.UIMapValidSize.Y then
            SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
            --bSetAlignmentImmediately = false
        else
            SetMapAlignment(self, {X = nUIX, Y = nUIY})
            --bSetAlignmentImmediately = false
        end
        self.bDragMap = false
    else
        SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
        self.bDragMap = false
        --bSetAlignmentImmediately = false
    end
    -- if nZoomFactor == 1 then
    --     SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
    --     self.bDragMap = false
    -- elseif self.bDragMap then
    --     self.CurAlignmentX = self.MapAlignmentX
    --     self.CurAlignmentY = self.MapAlignmentY
    -- elseif nUIX >= self.UIMapValidSize.X or nUIY >= self.UIMapValidSize.Y then
    --     SetMapAlignment(self, {X = self.ZoomMapSize.X / 2, Y = self.ZoomMapSize.Y / 2})
    --     self.bDragMap = false
    -- else
    --     if self.bMirror then
    --         nUIX = self.ZoomMapSize.X - nUIX;
    --     end
    --     SetMapAlignment(self, {X = nUIX, Y = nUIY})
    --     self.bDragMap = false
    --     bSetAlignmentImmediately = false
    -- end
    return bSetAlignmentImmediately
end


function UPFFASelectPointMap:SliderToZoomMap(nZoomFactor, nCurrentGrade, nObservedSceneID, nObservedMapMode)
    local pWidgetRef = self.pWidgetRef
    self.DragTargetPos = nil

    --RefreshCurrentSceneID(self)
    self:RefreshSceneMap(nObservedSceneID, nObservedMapMode, nZoomFactor, nCurrentGrade)
    pWidgetRef.imgNaviEnd:SetVisibility(ESlateVisibility.Hidden)

    RefreshMapAlignmentWhenSlider(self, pWidgetRef, nZoomFactor)

    local Alignment = Vector2D{X = self.MapAlignmentX, Y = self.MapAlignmentY}
    --logdebug("Alignment=",Alignment.X, Alignment.Y,self.ZoomMapSize.X,self.ZoomMapSize.Y)
    self.pWidgetRef.cvsWorldMap.Slot:SetAlignment(Alignment)
    self.pWidgetRef.cvsMapContent.Slot:SetAlignment(Alignment)
    --self.pWidgetRef.cvsMapNav.Slot:SetAlignment(Alignment)
    tbTempSize.X = self.ZoomMapSize.X
    tbTempSize.Y = self.ZoomMapSize.Y
    pWidgetRef.cvsWorldMap.Slot:SetSize(tbTempSize)
    pWidgetRef.cvsMapContent.Slot:SetSize(tbTempSize)

    SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, 0, 0, false)
    --self:PlayZoomAnim()
    InitMapOp(self)
end

function UPFFASelectPointMap:OnClickLocationPlayer()
    local UIMapPos = self:GetPlayerUIMapPos()
    self:LocateUIMapPosToScreenCenter(UIMapPos)

    self.DragTargetPos = nil
    self.bDragMap = false
end


-- 将UIMapPos坐标显示到视口中心位置
function UPFFASelectPointMap:LocateUIMapPosToScreenCenter(UIMapPos, bAnim)
    local ZoomMapSize = self.ZoomMapSize
    bAnim = bAnim == nil or bAnim
    local BorderXLeft = ZoomMapSize.X * self.CurAlignmentX
    local BorderYTop = ZoomMapSize.Y * self.CurAlignmentY
    local UIPosOffsetX = - (UIMapPos.X - BorderXLeft)
    local UIPosOffsetY = - (UIMapPos.Y - BorderYTop)
    SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, UIPosOffsetX, UIPosOffsetY)
end

--drag event
local function UpdateFingerCount(self)
    local nFingerCount = 0
    for k, v in pairs(self.tbLastPos) do
        nFingerCount = nFingerCount + 1
    end
    self.nFingerCount = nFingerCount
    if nFingerCount == 0 then
        log("UpdateFingerCount set enable click false")
        --self.bDragMap = false
        self.bEnableClick = false
    end
end

function UPFFASelectPointMap:OnMouseButtonDown(pGeometry, pMouseEvent)
    -- printScreen("OnMouseButtonDown")
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    if nTouchIndex == 10 then
        log("UPFFASelectPointMap:OnMouseButtonDown return")
        return WidgetBlueprintLibrary.Unhandled()
    end
    local pos = FUNC_GET_SCREEN_SPACE_POS(pMouseEvent)
    self.tbLastPos[nTouchIndex] = pos
    UpdateFingerCount(self)
    if self.nFingerCount == 1 then
        log("UPFFASelectPointMap:OnMouseButtonDown set enable click true")
        self.bEnableClick = true
    else
        log("UPFFASelectPointMap:OnMouseButtonDown set enable click false")
        self.bEnableClick = false
    end
    return WidgetBlueprintLibrary.Unhandled()
end

function UPFFASelectPointMap:OnMouseMove(pGeometry, pMouseEvent)
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
        if nX*nX + nY*nY < 25 then
            return WidgetBlueprintLibrary.Unhandled()
        end
    end
    local MoveDelta = {
        X = curPos.X - lastScreenPos.X,
        Y = curPos.Y - lastScreenPos.Y,
    }
    self:RefreshMapPos(MoveDelta)
    self.tbLastPos[nTouchIndex] = curPos
    if self.nFingerCount == 1 then
        self.bDragMap = true
    end
    log("UPFFASelectPointMap:OnMouseMove set enable click false")
    self.bEnableClick = false
    return WidgetBlueprintLibrary.Unhandled()
end

function UPFFASelectPointMap:OnPinch(nDeltaDistance, CenterScreenPos)
    if not self.bEnablePinch then
        return WidgetBlueprintLibrary.Unhandled()
    end
    --logdebug("UPWorldMapNew:OnPinch,nDeltaDistance=",nDeltaDistance)
    local nRatio = nDeltaDistance / WorldMapUtil.PinchSize
    --self.Owner:SetSliderValue(nRatio)
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

local function IsInNoobSelectArea(self, WorldPosX, WorldPosY)
    local nDungeonId = BattleGameModeSystem.nDungeonId
    local tbAreaData = NoobParachutingJsonTable[nDungeonId]
    if not tbAreaData then
        return false
    end

    local bInArea = false
    for i, v in ipairs(tbAreaData) do
        local nRadius = math.min(v.tbSize.X, v.tbSize.Y)
        local tbBoxPos = v.tbCenter
        local nDistance = math.sqrt((WorldPosX - tbBoxPos.X)^2 + (WorldPosY - tbBoxPos.Y)^2)
        if nDistance <= nRadius then
            bInArea = true
            break
        end
    end

    return bInArea
end

local function SelectBornPoint(self, WorldPosX, WorldPosY)
    if not self.bSelectPoint then
        UIUtils.ShowToast(UITextDef.FFA_SELECT_POINT_ISLOCK)
        return
    end

    local tbReadyArea = ParachutingNewIni.tbReadyArea
    local nDistance = math.sqrt((WorldPosX)^2 + (WorldPosY)^2)
    if nDistance <= tbReadyArea.nCoreAreaRadius then
        UIUtils.ShowToast(UITextDef.FFA_SELECT_POINT_INVALID)
        return
    end

    -- self.bNoobDungeon = true
    if (self.bNoobDungeon and not IsInNoobSelectArea(self, WorldPosX, WorldPosY)) then
        UIUtils.ShowToast(UITextDef.FFA_SELECT_POINT_INVALID)
        return
    end

    local tbDungeonTemplate = DungeonDataTable:GetTemplate(BattleGameModeSystem.nDungeonId)
    local tbMapResData = UIMapResDataTable:GetTemplate(tbDungeonTemplate.nUIRadarMapId)
    if tbMapResData then
        local nMaxX = (tbMapResData.nMapSizeX - tbMapResData.nScope) / 2
        local nMaxY = (tbMapResData.nMapSizeY - tbMapResData.nScope) / 2
        if math.abs(WorldPosX) >= nMaxX or math.abs(WorldPosY) >= nMaxY then
            UIUtils.ShowToast(UITextDef.FFA_SELECT_POINT_INVALID)
            return
        end
    end

    local nInstanceId = GamePlayerSelfHelper:GetServerInstanceId()

    local fnSelectPoint = function(nX, nY)
        log("Location SelectBornPoint", nInstanceId, nX, nY)
        self.tbMapOpForBornPoint:SetBornPos(nInstanceId, {X = nX, Y = nY}, nil, true)
        SoundManager:PlaySoundEffect(UIResourceDef.SC_SELECTION_POINT)
        UIUtils.ShowToast(UITextDef.FFA_SELECT_POINT_SUCCESS)
    end

    if self.tbDelayTimer ~= nil then
        self.tbCachePoint = {X = WorldPosX, Y = WorldPosY}
        fnSelectPoint(WorldPosX, WorldPosY)
        return
    end

    local fnSendPoint = function(nX, nY, bSelected)
        log("Send SelectBornPoint", nInstanceId, nX, nY)
        local c2d_FFASelectionPoint = {
            nInstanceId = nInstanceId,
            nX = math.floor(nX),
            nY = math.floor(nY)
        }
        NetworkManager:GetRPCNetworkProxy():SendToServer(ProtoDP.c2d_FFASelectionPoint, c2d_FFASelectionPoint)
        if not bSelected then
            fnSelectPoint(nX, nY)
        end
    end
    self.tbDelayTimer = DelayTimer:DelayRun(function()
        DestroyTimer(self)
        if self.tbCachePoint ~= nil then
            fnSendPoint(self.tbCachePoint.X, self.tbCachePoint.Y, true)
            self.tbCachePoint = nil
        end
    end, 1)
    fnSendPoint(WorldPosX, WorldPosY, false)
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_SELECT_POINTE_SUCCES)
    self.tbCachePoint = nil
end

function UPFFASelectPointMap:ClearCachePoint()
    DestroyTimer(self)
    self.tbCachePoint = nil
end

function UPFFASelectPointMap:OnMouseButtonUp(pGeometry, pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    if nTouchIndex == 10 then
        log("UPFFASelectPointMap:OnMouseButtonUp return")
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
        log("UPFFASelectPointMap select Pos,WorldPosX, WorldPosY, WorldPosZ=",LocalPos.X, LocalPos.Y, WorldPosX, WorldPosY, WorldMapUtil.nMaxHight)
        --local pMapSize = self.pWidgetRef.cvsWorldMap.Slot:GetSize()
        -- logdebug("UPFFASelectPointMap self.ZoomMapSize.X,self.ZoomMapSize.Y,self.tbMapResData.nUIMapOffsetX,self.tbMapResData.nUIMapOffsetY=",self.ZoomMapSize.X,self.ZoomMapSize.Y,self.tbMapResData.nUIMapOffsetX,self.tbMapResData.nUIMapOffsetY,self.CurrentMapZoom,pMapSize.X, pMapSize.Y)
        SelectBornPoint(self, WorldPosX, WorldPosY)
    else
        log("UPFFASelectPointMap select Pos failed ", ScreenPos, self.bEnableClick)
    end

    self.tbLastPos[nTouchIndex] = nil
    UpdateFingerCount(self)
    return WidgetBlueprintLibrary.Unhandled()
end

function UPFFASelectPointMap:OnMouseButtonLeave(pMouseEvent)
    local nTouchIndex = FUNC_GET_POINTER_INDEX(pMouseEvent)
    self.tbLastPos[nTouchIndex] = nil
    UpdateFingerCount(self)
end

function UPFFASelectPointMap:IsMMap()
    return true
end

function UPFFASelectPointMap:SetMapSizeZoomFactor(nZoomFactor)
    --logdebug("SetMapSizeZoomFactor,nZoomFactor=",nZoomFactor,self.ZoomMapSize.X,self.ZoomMapSize.Y)
    SetTargetFactor(self, nZoomFactor)
    local bSetAlignmentImmediately = RefreshMapAlignmentWhenSlider(self, self.pWidgetRef, nZoomFactor)
    if bSetAlignmentImmediately then
        local Alignment = Vector2D{X = self.MapAlignmentX, Y = self.MapAlignmentY}
        self.pWidgetRef.cvsWorldMap.Slot:SetAlignment(Alignment)
        self.pWidgetRef.cvsMapContent.Slot:SetAlignment(Alignment)
        --logdebug("SetMapSizeZoomFactor,Alignment=",Alignment.X, Alignment.Y)
    end
    SetMapPanelOffset(self, self.ZoomMapSize.X, self.ZoomMapSize.Y, 0, 0, false)
    self.EventHelper:FireEvent(ClientEventDef.EV_MAP_PINCH_CHANGED, self.ZoomMapSize, not bSetAlignmentImmediately)
end

return UPFFASelectPointMap
