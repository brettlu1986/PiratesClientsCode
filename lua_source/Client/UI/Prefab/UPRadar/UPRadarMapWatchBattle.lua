-----------------------------------------------------
--File Name    : UPRadarMapNew.lua
--Author       : Ran Jie
--Create Time  : 2017-3-14
--Description  : UPRadarMapWatchBattle
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPRadarMapWatchBattle = luaclass("UPRadarMapWatchBattle", PrefabBase)

-- import require
local UIMapResDataTable = require("UIMapResDataTable")
local GameWorldSystem = require("GameWorldSystem")
local UPRadarMapOperationRegister = require("UPRadarMapOperationRegister")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local SceneDataTable = require("SceneDataTable")
local DungeonDataTable = require("DungeonDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local ClientEventDef = require("ClientEventDef")
local DelayTimer = require("DelayTimer")
local BattleTeammateSystem = require("BattleTeammateSystem")
local GMOpenModeDef = require("GMOpenModeDef")
local GMIni = require("GMIni")

--member veriable
UPRadarMapWatchBattle.MapOrigin = nil
UPRadarMapWatchBattle.UIMapOrigin = nil
UPRadarMapWatchBattle.UIMapValidSize = nil
UPRadarMapWatchBattle.UIMapValidOffset = nil
UPRadarMapWatchBattle.RealMapSize = nil
UPRadarMapWatchBattle.tbObjPool = nil
UPRadarMapWatchBattle.tbMapResData = nil
UPRadarMapWatchBattle.UIViewSize = nil
UPRadarMapWatchBattle.nSceneId = nil
UPRadarMapWatchBattle.ShipViewerChangedDelegate = nil
UPRadarMapWatchBattle.ShipActorEndPlayDelegate = nil
UPRadarMapWatchBattle.nUIRadarMapId = nil
UPRadarMapWatchBattle.bPrepareTimer = true
UPRadarMapWatchBattle.bOpenWorldMap = true
UPRadarMapWatchBattle.nCurrentScope = nil
UPRadarMapWatchBattle.nTargetScope = nil
UPRadarMapWatchBattle.tbTimer = nil
UPRadarMapWatchBattle.bFirstTransportDeactivate = false
UPRadarMapWatchBattle.tbDelayHandle = nil

--local veriable
local FInterpTo_Func = KismetMathLibrary.FInterpTo
local IMAGE_MAX_COUNT = 2
local TIMER_TICK = 0.1
local FFA_MODE =
{
    SHIP = 3,
    HUMAN = 4,
}


-- local function

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
    --logdebug("MapSize,UIMapValidSize,UIMapValidSize,MapOrigin,UIMapOrigin=",MapSize.X, MapSize.Y, UIMapValidSize.X,UIMapValidSize.Y, UIMapValidOffset.X, UIMapValidOffset.Y,MapOrigin.X,MapOrigin.Y,UIMapOrigin.X,UIMapOrigin.Y)
    UPRadarMapOperationRegister:Refresh()
end

----点击事件
local function OnClickedMap(self)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if not bIsInDungeon then
        UIManager:OpenWnd(UIDef.UI_WORLD_MAP)
    elseif self.bOpenWorldMap then --吃鸡副本
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
        UIManager:OpenWnd(UIDef.UI_WORLD_MAP, { ViewObj = self.ViewerObj })
    end
end

local function OnDoubleClickedMap(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function OnLongPressedMap(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function ScopeAnimTimerFunc(self)
    if math.abs(self.nCurrentScope - self.nTargetScope) <= 0.001 then
        self.TimerHelper:ClearAllTimer()
        self.tbTimer = nil
    end
    local nSpeed = self.nCurrentScope / self.nTargetScope
    local nDelta = 0.5 / (nSpeed)
    self.nCurrentScope = FInterpTo_Func(self.nTargetScope, self.nCurrentScope, nDelta, nSpeed)

    --logdebug("SizeAnimTimerFunc, nCurrentScope, nTargetScope=",self.nCurrentScope, self.nTargetScope)
    local ViewSize = self.UIViewSize
    local ValidSize = {X = self.tbMapResData.nUIMapSizeX - self.tbMapResData.nUIMapOffsetX * 2,
                        Y= self.tbMapResData.nUIMapSizeY - self.tbMapResData.nUIMapOffsetY * 2}

    local Scale = ViewSize.X / ((ValidSize.X / self.tbMapResData.nMapSizeX) * self.nCurrentScope)
    self.UIMapValidSize = {X = ValidSize.X * Scale,Y = ValidSize.Y * Scale}
    self.RealMapSize = {X = self.tbMapResData.nUIMapSizeX * Scale,Y = self.tbMapResData.nUIMapSizeY * Scale}
    self.UIMapValidOffset = {
        X = (self.RealMapSize.X - self.UIMapValidSize.X)/2,
        Y = (self.RealMapSize.Y - self.UIMapValidSize.Y)/2}


    local pMapSize = Vector2D{X = self.RealMapSize.X, Y = self.RealMapSize.Y}
    self.pWidgetRef.cvsMapPos.Slot:SetSize(pMapSize)
    self.pWidgetRef.cvsFlag.Slot:SetSize(pMapSize)
    self.pWidgetRef.cvsMapContent.Slot:SetSize(pMapSize)
    InitUserWidgetParam(self)
end

local function SetMapScope(self, nScope)
    self.nTargetScope = nScope
    if self.tbTimer then
        self.TimerHelper:ClearAllTimer()
        self.tbTimer = nil
    end
    self.tbTimer = self.TimerHelper:NewTimerMethod(self, ScopeAnimTimerFunc, TIMER_TICK, true)

end

local function SetMapData(self, tbMapResData, nFFAMode)
    self.tbMapResData = tbMapResData
    local pWidgetRef = self.pWidgetRef
    local ViewSize = pWidgetRef.cvsMapPanel.Slot:GetSize()
    local tbMapResTex = UIMapResDataTable:LoadMapRes(tbMapResData.nResId)
    local nScope = tbMapResData.nScope
    local bMirror = false
    if nFFAMode == FFA_MODE.HUMAN then
        nScope = tbMapResData.nLandScope
    end
    if not self.nCurrentScope then
        self.nCurrentScope = nScope
    end
    local ValidSize = {X = self.tbMapResData.nUIMapSizeX - self.tbMapResData.nUIMapOffsetX * 2,
                        Y= self.tbMapResData.nUIMapSizeY - self.tbMapResData.nUIMapOffsetY * 2}
    local Scale = ViewSize.X / ((ValidSize.X / self.tbMapResData.nMapSizeX) * self.nCurrentScope)
    self.UIViewSize = ViewSize
    self.MapOrigin = {X = -tbMapResData.nMapSizeX / 2,Y = -tbMapResData.nMapSizeY / 2}
    self.UIMapOrigin = {X = ViewSize.X / 2,Y = ViewSize.Y / 2}
    self.UIMapValidSize = {X = ValidSize.X * Scale,Y = ValidSize.Y * Scale}
    self.RealMapSize = {X = self.tbMapResData.nUIMapSizeX * Scale,Y = self.tbMapResData.nUIMapSizeY * Scale}
    self.UIMapValidOffset = {
        X = (self.RealMapSize.X - self.UIMapValidSize.X)/2,
        Y = (self.RealMapSize.Y - self.UIMapValidSize.Y)/2}
    SetMapScope(self, nScope)
    local nResCount = #tbMapResData.tbResPath
    for i = 1, nResCount do
        local imgMap = pWidgetRef["imgMap"..i]
        if(imgMap ~= nil)then
            imgMap:SetVisibility(ESlateVisibility.Visible)
            -- imgMap.Slot:SetSize(Vector2D{X=self.RealMapSize.X / nResCount,Y = self.RealMapSize.Y})
            -- imgMap.Slot:SetPosition(Vector2D{X = (i - 1) * self.RealMapSize.X / nResCount, Y = 0})
            local pIcon = tbMapResTex[i]
            if bMirror then
                pIcon = tbMapResTex[nResCount - i + 1]
                imgMap.Brush.Mirroring = ESlateBrushMirrorType.Horizontal
            else
                imgMap.Brush.Mirroring = ESlateBrushMirrorType.NoMirror
            end

            imgMap:SetBrushFromTexture(pIcon, false)
        end

    end
    for i=nResCount + 1, IMAGE_MAX_COUNT do
        local imgMap = pWidgetRef["imgMap"..i]
        imgMap:SetVisibility(ESlateVisibility.Collapsed)
    end
    --logdebug("[UI] UPRadarMap:InitData,rescount="..nResCount)
    --logdebug("UPRadarMapForBase:SetMapData,UIViewSize,x="..self.UIViewSize.X.." y="..self.UIViewSize.Y)
end

local function HideAll(self)
    -- pWidgetRef.kmpgbsViewFov:SetVisibility(ESlateVisibility.Collapsed)
    -- pWidgetRef.kmFFAPoisonCircle:SetVisibility(ESlateVisibility.Collapsed)
    -- pWidgetRef.pbFFASafeCircle:SetVisibility(ESlateVisibility.Collapsed)
    -- pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.Collapsed)
end

local function OnControlModeActive(self, nFFAMode)
    log("OnControlModeActive, state=",nFFAMode)
    local tbMapResData = UIMapResDataTable:GetTemplate(self.nUIRadarMapId)
    SetMapData(self, tbMapResData, nFFAMode)
    UPRadarMapOperationRegister:Reinit()
    self.bOpenWorldMap = true
end

local function OnCloseUI(self, szWndName)
    if szWndName == UIDef.UI_WORLD_MAP then
        self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
end

function UPRadarMapWatchBattle:OnResetMapTarget()
    self.ViewerObj = self.Owner.tbCurrrentWatchObj
    if self.ViewerObj:IsShip() then
        OnControlModeActive(self, FFA_MODE.SHIP)
    else
        OnControlModeActive(self, FFA_MODE.HUMAN)
    end
    --logdebug("reset map for new Obj")
end

function UPRadarMapWatchBattle:OnLoad()
    if GlobalVariableSystem:IsDevMode() then
        self.pWidgetRef.pbMapRealLocationInfo:EnableUpdate()
    end
end

function UPRadarMapWatchBattle:OnBindEvent(EventHelper)
    local btnBigMap = self.pWidgetRef.btnBigMap
    EventHelper:RegisterCppDelegate(btnBigMap.OnClicked, self, OnClickedMap)
    EventHelper:RegisterEvent(ClientEventDef.EV_PRE_CLOSE_UI, self, OnCloseUI)

    btnBigMap.bDoubleClickEnabled = false
    btnBigMap.bLongPressedEnabled = false
    if GlobalVariableSystem:IsDevMode() then
        local nGMOpenMode = GlobalVariableSystem:GetGMOpenMode()
        if nGMOpenMode == GMOpenModeDef.DOUBLE_CLICK then
            btnBigMap.DoubleClickInterval = GMIni.nDoubleClickInterval
            btnBigMap.bDoubleClickEnabled = true
            EventHelper:RegisterCppDelegate(btnBigMap.OnDoubleClicked, self, OnDoubleClickedMap)
            log("[UPRadarMapWatchBattle] Enable GM Panel, OpenMode : DoubleClick, DoubleClickInterval =", GMIni.nDoubleClickInterval)
        elseif nGMOpenMode == GMOpenModeDef.LONG_PRESS then
            btnBigMap.LongPressedInterval = GMIni.nLongPressedInterval
            btnBigMap.bLongPressedEnabled = true
            EventHelper:RegisterCppDelegate(btnBigMap.OnLongPressed, self, OnLongPressedMap)
            log("[UPRadarMapWatchBattle] Enable GM Panel, OpenMode : LongPress, LongPressedInterval =", GMIni.nLongPressedInterval)
        end
    end
end

function UPRadarMapWatchBattle:OnShow()

end

--
function UPRadarMapWatchBattle:InitWatchBattleRadar()
    self.ViewerObj = nil
    local pWidgetRef = self.pWidgetRef
    local nSceneId = nil
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    local tbSceneOrDungeonTemplate = nil
    if(bIsInDungeon) then
        pWidgetRef.kmpgbsViewFov:SetVisibility(ESlateVisibility.HitTestInvisible)

        nSceneId = BattleGameModeSystem.nDungeonId
        tbSceneOrDungeonTemplate = DungeonDataTable:GetTemplate(nSceneId)

        --local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
        -- self.ShipViewerChangedDelegate = self.EventHelper:RegisterCppDelegate(pPlayerController.OnShipViewerChanged, self, OnShipViewerChanged)
       --self.ShipActorEndPlayDelegate = self.EventHelper:RegisterCppDelegate(pPlayerController.OnEndPlay, self, OnShipActorEndPlay)
    else
        pWidgetRef.kmpgbsViewFov:SetVisibility(ESlateVisibility.Collapsed)

        nSceneId = GameWorldSystem:GetWorld().nSceneId
        tbSceneOrDungeonTemplate = SceneDataTable:GetTemplate(nSceneId)
    end
    if(tbSceneOrDungeonTemplate == nil)then
        logerror("[UPRadarMapNew] OnShow:tbSceneOrDungeonTemplate is nil")
        return
    end
    self.nSceneId = nSceneId
    self.nUIRadarMapId = tbSceneOrDungeonTemplate.nUIRadarMapId
    HideAll(self)
    pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.Collapsed)
    self:OnResetMapTarget()
    UPRadarMapOperationRegister:RegisterOperations(self)
    if BattleTeammateSystem:GetTeamMode() == 1 then
        UPRadarMapOperationRegister:UnregisterOperation("MapOpFFATeamMember")
    end
end

function UPRadarMapWatchBattle:OnUnload()
    UPRadarMapOperationRegister:UnregisterOperations()
    self.tbTimer = nil
    if self.tbDelayHandle then
        DelayTimer:ClearTimer(self.tbDelayHandle)
        self.tbDelayHandle = nil
    end
end

function UPRadarMapWatchBattle:GetObservedSceneId()
    return self.nSceneId
end

function UPRadarMapWatchBattle:GetCurrentSceneId()
    return self.nSceneId
end

return UPRadarMapWatchBattle
