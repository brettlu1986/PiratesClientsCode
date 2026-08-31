-----------------------------------------------------
--File Name    : UPHomelandRadarMap.lua
--Author       : ranjie
--Create Time  : 2019-5-14
--Description  : UPHomelandRadarMap
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomelandRadarMap = luaclass("UPHomelandRadarMap", PrefabBase)

-- import require
local UIMapResDataTable = require("UIMapResDataTable")
local UPRadarMapOperationRegister = require("UPRadarMapOperationRegister")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GameWorldSystem = require("GameWorldSystem")
local SceneDataTable = require("SceneDataTable")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local GMOpenModeDef = require("GMOpenModeDef")
local GMIni = require("GMIni")
-- local GameObjectSystem = dynamic_require("GameObjectSystem")

--member veriable
UPHomelandRadarMap.MapOrigin = nil
UPHomelandRadarMap.UIMapOrigin = nil
UPHomelandRadarMap.UIMapValidSize = nil
UPHomelandRadarMap.UIMapValidOffset = nil
UPHomelandRadarMap.RealMapSize = nil
UPHomelandRadarMap.tbObjPool = nil
UPHomelandRadarMap.tbMapResData = nil
UPHomelandRadarMap.UIViewSize = nil
UPHomelandRadarMap.nSceneId = nil
UPHomelandRadarMap.nUIRadarMapId = nil

local IMAGE_MAX_COUNT = 2
local COLLAPSED = ESlateVisibility.Collapsed

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
    local MapOrigin = Vector2D{X = self.MapOrigin.X, Y = self.MapOrigin.Y}
    local UIMapOrigin = Vector2D{X = self.UIMapOrigin.X, Y = self.UIMapOrigin.Y}
    self.pWidgetRef:InitMapParam(MapSize, UIMapValidSize, UIMapValidOffset, MapOrigin, UIMapOrigin)
    UPRadarMapOperationRegister:Refresh()
end

----点击事件
local function OnClickedMap(self)
    UIManager:OpenWnd(UIDef.UI_WORLD_MAP)
end

local function OnDoubleClickedMap(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function OnLongPressedMap(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function SetMapImage(pWidgetRef, tbMapResData)
    local tbMapResTex = UIMapResDataTable:LoadMapRes(tbMapResData.nResId)
    local nResCount = #tbMapResData.tbResPath
    for i = 1, IMAGE_MAX_COUNT do
        local imgMap = pWidgetRef["imgMap"..i]
        if not imgMap then
            return
        end
        if i <= nResCount then
            imgMap:SetVisibility(ESlateVisibility.Visible)
            local pIcon = tbMapResTex[i]
            imgMap.Brush.Mirroring = ESlateBrushMirrorType.NoMirror
            imgMap:SetBrushFromTexture(pIcon, false)
        else
            imgMap:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end


local function SetMapParams(self, tbMapResData, pWidgetRef)
    self.tbMapResData = tbMapResData
    local ViewSize = pWidgetRef.cvsMapPanel.Slot:GetSize()
    local nScope = tbMapResData.nScope
    local ValidSize = {X = self.tbMapResData.nUIMapSizeX - self.tbMapResData.nUIMapOffsetX * 2,
                        Y= self.tbMapResData.nUIMapSizeY - self.tbMapResData.nUIMapOffsetY * 2}
    local Scale = ViewSize.X / ((ValidSize.X / self.tbMapResData.nMapSizeX) * nScope)
    self.UIViewSize = ViewSize
    self.MapOrigin = {X = -tbMapResData.nMapSizeX / 2,Y = -tbMapResData.nMapSizeY / 2}
    self.UIMapOrigin = {X = ViewSize.X / 2,Y = ViewSize.Y / 2}
    self.UIMapValidSize = {X = ValidSize.X * Scale,Y = ValidSize.Y * Scale}
    self.RealMapSize = {X = self.tbMapResData.nUIMapSizeX * Scale,Y = self.tbMapResData.nUIMapSizeY * Scale}
    self.UIMapValidOffset = {
        X = (self.RealMapSize.X - self.UIMapValidSize.X) / 2,
        Y = (self.RealMapSize.Y - self.UIMapValidSize.Y) / 2
    }
    local pMapSize = Vector2D{X = self.RealMapSize.X, Y = self.RealMapSize.Y}
    pWidgetRef.cvsMapPos.Slot:SetSize(pMapSize)
    pWidgetRef.cvsFlag.Slot:SetSize(pMapSize)
    pWidgetRef.cvsMapContent.Slot:SetSize(pMapSize)
end

local function SetMapData(self, tbMapResData)
    local pWidgetRef = self.pWidgetRef
    SetMapParams(self, tbMapResData, pWidgetRef)
    InitUserWidgetParam(self)
    SetMapImage(pWidgetRef, tbMapResData)
end

local function HideAll(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.kmpgbsViewFov:SetVisibility(COLLAPSED)
    pWidgetRef.kmFFAPoisonCircle:SetVisibility(COLLAPSED)
    pWidgetRef.pbFFASafeCircle:SetVisibility(COLLAPSED)
    pWidgetRef.hbxPoisonProgress:SetVisibility(COLLAPSED)
    pWidgetRef.ovlSelfPos:SetVisibility(COLLAPSED)
end

function UPHomelandRadarMap:OnBindEvent(EventHelper)
    local btnBigMap = self.pWidgetRef.btnBigMap
    EventHelper:RegisterCppDelegate(btnBigMap.OnClicked, self, OnClickedMap)

    btnBigMap.bDoubleClickEnabled = false
    btnBigMap.bLongPressedEnabled = false
    if GlobalVariableSystem:IsDevMode() then
        local nGMOpenMode = GlobalVariableSystem:GetGMOpenMode()
        if nGMOpenMode == GMOpenModeDef.DOUBLE_CLICK then
            btnBigMap.DoubleClickInterval = GMIni.nDoubleClickInterval
            btnBigMap.bDoubleClickEnabled = true
            EventHelper:RegisterCppDelegate(btnBigMap.OnDoubleClicked, self, OnDoubleClickedMap)
            log("[UPHomelandRadarMap] Enable GM Panel, OpenMode : DoubleClick, DoubleClickInterval =", GMIni.nDoubleClickInterval)
        elseif nGMOpenMode == GMOpenModeDef.LONG_PRESS then
            btnBigMap.LongPressedInterval = GMIni.nLongPressedInterval
            btnBigMap.bLongPressedEnabled = true
            EventHelper:RegisterCppDelegate(btnBigMap.OnLongPressed, self, OnLongPressedMap)
            log("[UPHomelandRadarMap] Enable GM Panel, OpenMode : LongPress, LongPressedInterval =", GMIni.nLongPressedInterval)
        end
    end
end

function UPHomelandRadarMap:OnShow()
    HideAll(self)
    self.ViewerObj = nil
    local nSceneId = GameWorldSystem:GetWorld().nSceneId
    local tbSceneOrDungeonTemplate = SceneDataTable:GetTemplate(nSceneId)
    if(tbSceneOrDungeonTemplate == nil)then
        logerror("UPHomelandRadarMap:OnShow(), tbSceneOrDungeonTemplate is nil, scene id is ", nSceneId)
        return
    end
    self.nSceneId = nSceneId
    self.nUIRadarMapId = tbSceneOrDungeonTemplate.nUIRadarMapId
    local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneOrDungeonTemplate.nUIRadarMapId)
    SetMapData(self, tbMapResData)
    -- RegisterEventOnShow(self)
    UPRadarMapOperationRegister:RegisterOperations(self)
end

function UPHomelandRadarMap:OnHide()
    UPRadarMapOperationRegister:UnregisterOperations()
end

function UPHomelandRadarMap:GetObservedSceneId()
    return self.nSceneId
end

function UPHomelandRadarMap:GetCurrentSceneId()
    return self.nSceneId
end

return UPHomelandRadarMap
