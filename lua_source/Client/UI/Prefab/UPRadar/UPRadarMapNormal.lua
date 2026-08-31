-----------------------------------------------------
--File Name    : UPRadarMapNormal.lua
--Author       : Ran Jie
--Create Time  : 2019-9-9
--Description  : UPRadarMapNormal
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPRadarMapNormal = luaclass("UPRadarMapNormal", PrefabBase)

-- import require
local UPRadarMapOperationRegister = require("UPRadarMapOperationRegister")
local UIDef = require("UIDef")
local UIManager = require("UIManager")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local MiniMapSystem = require("MiniMapSystem")
-- local GameObjectSystem = dynamic_require("GameObjectSystem")
local ClientEventDef = require("ClientEventDef")
local UIMapModeDataTable = require("UIMapModeDataTable")
local GMOpenModeDef = require("GMOpenModeDef")
local GMIni = require("GMIni")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

--member veriable
UPRadarMapNormal.MapOrigin = nil
UPRadarMapNormal.UIMapOrigin = nil
UPRadarMapNormal.UIMapValidSize = nil
UPRadarMapNormal.UIMapValidOffset = nil
UPRadarMapNormal.RealMapSize = nil
UPRadarMapNormal.tbMapResData = nil
UPRadarMapNormal.UIViewSize = nil
UPRadarMapNormal.nSceneId = nil
UPRadarMapNormal.nUIRadarMapId = nil
UPRadarMapNormal.bOpenWorldMap = true
UPRadarMapNormal.nCurrentScope = nil
UPRadarMapNormal.nTargetScope = nil
UPRadarMapNormal.tbTimer = nil
UPRadarMapNormal.ulMapOp = nil

--local veriable
local FInterpTo_Func = KismetMathLibrary.FInterpTo
local TIMER_TICK = 0.1
local DEFAULT_MAP_OP_LOGIC_SCRIPT = "ULMapOp"
local pRealMapSize = Vector2D()
local pViewPortSize = Vector2D()
local pMapSize = Vector2D()
local pUIMapValidSize = Vector2D()
local pUIMapValidOffset = Vector2D()
local pUIMapOrigin = Vector2D()
local pMapOrigin = Vector2D()


-- local function
local function InitUserWidgetParam(self)
    local tbMapResData = self.tbMapResData
    
    pMapSize.X = tbMapResData.nMapSizeX
    pMapSize.Y = tbMapResData.nMapSizeY
    
    pUIMapValidSize.X = self.UIMapValidSize.X
    pUIMapValidSize.Y = self.UIMapValidSize.Y
    
    pUIMapValidOffset.X = self.UIMapValidOffset.X
    pUIMapValidOffset.Y = self.UIMapValidOffset.Y

    pMapOrigin.X = self.MapOrigin.X
    pMapOrigin.Y = self.MapOrigin.Y

    pUIMapOrigin.X = self.UIMapOrigin.X
    pUIMapOrigin.Y = self.UIMapOrigin.Y

    self.pWidgetRef:InitMapParam(pMapSize, pUIMapValidSize, pUIMapValidOffset, pMapOrigin, pUIMapOrigin)
    --logdebug("MapSize,UIMapValidSize,UIMapValidSize,MapOrigin,UIMapOrigin=",MapSize.X, MapSize.Y, UIMapValidSize.X,UIMapValidSize.Y, UIMapValidOffset.X, UIMapValidOffset.Y,MapOrigin.X,MapOrigin.Y,UIMapOrigin.X,UIMapOrigin.Y)
    UPRadarMapOperationRegister:Refresh()
end

----点击事件
local function OnClickedMap(self)
    if self.bOpenWorldMap then
        log("OnClickedMap start")
        local tbViewObj = self.ViewerObj
        if not tbViewObj then
            tbViewObj = GamePlayerSelfHelper:Get()
        end
        if not UIManager:IsWndVisible(UIDef.UI_FFA_SELECT_BORNPOINT) and isvalidhandle(tbViewObj.pUEActor)then
            self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
            UIManager:OpenWnd(UIDef.UI_WORLD_MAP, { ViewObj = tbViewObj })
        end
        log("OnClickedMap end")
    end
end

local function OnDoubleClickedMap(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function OnLongPressedMap(self)
    UIManager:OpenWnd(UIDef.UI_DEBUG_WIDGET)
end

local function OnCloseUI(self, szWndName)
    if szWndName == UIDef.UI_WORLD_MAP then
        self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
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
    --local pMapSize = Vector2D{X = self.RealMapSize.X, Y = self.RealMapSize.Y}
    pRealMapSize.X = self.RealMapSize.X
    pRealMapSize.Y = self.RealMapSize.Y
    self.pWidgetRef.cvsMapPos.Slot:SetSize(pRealMapSize)
    self.pWidgetRef.cvsFlag.Slot:SetSize(pRealMapSize)
    self.pWidgetRef.cvsMapContent.Slot:SetSize(pRealMapSize)
    InitUserWidgetParam(self)
    self.pWidgetRef.radarMap:OnWidgetSizeChange(pRealMapSize)
end

local function SetMapScope(self, nScope)
    self.nTargetScope = nScope
    if self.tbTimer then
        self.TimerHelper:ClearAllTimer()
        self.tbTimer = nil
    end
    self.tbTimer = self.TimerHelper:NewTimerMethod(self, ScopeAnimTimerFunc, TIMER_TICK, true)
    log("UPRadarMapNormal:SetMapScope,nScope=",nScope, self.RealMapSize.X,self.RealMapSize.Y,self.tbTimer)
end

local function RegisterOperations(self)
    local tbModeTemplate = UIMapModeDataTable:GetTemplate(self.nMapMode)
    if not tbModeTemplate then
        return
    end
    self.ulMapOp:OnRegisterOperations(tbModeTemplate.nRadarMapOpGroup, nil)
end

local function LoadMapData(self)
    -- local nSceneId = nil
    -- local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    -- local tbSceneOrDungeonTemplate = nil
    -- if(bIsInDungeon) then
    --     pWidgetRef.kmpgbsViewFov:SetVisibility(ESlateVisibility.HitTestInvisible)
    --     nSceneId = BattleGameModeSystem.nDungeonId
    --     tbSceneOrDungeonTemplate = DungeonDataTable:GetTemplate(nSceneId)
    -- else
    --     pWidgetRef.kmpgbsViewFov:SetVisibility(ESlateVisibility.Collapsed)
    --     nSceneId = GameWorldSystem:GetWorld().nSceneId
    --     tbSceneOrDungeonTemplate = SceneDataTable:GetTemplate(nSceneId)
    -- end
    -- if(tbSceneOrDungeonTemplate == nil)then
    --     logerror("[UPRadarMapNormal] OnShow:tbSceneOrDungeonTemplate is nil")
    --     return
    -- end
    -- local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneOrDungeonTemplate.nUIRadarMapId)
    local tbMapResData = MiniMapSystem:GetMapResData()
    -- local tbMapResTex = UIMapResDataTable:LoadMapRes(tbMapResData.nResId)
    -- local nResCount = #tbMapResData.tbResPath
    -- for i = 1, nResCount do
    --     local imgMap = pWidgetRef["imgMap"..i]
    --     if(imgMap ~= nil)then
    --         imgMap:SetVisibility(ESlateVisibility_Visible)
    --         local pIcon = tbMapResTex[i]
    --         imgMap:SetBrushFromTexture(pIcon, false)
    --     end
    -- end
    -- for i=nResCount + 1, IMAGE_MAX_COUNT do
    --     local imgMap = pWidgetRef["imgMap"..i]
    --     imgMap:SetVisibility(ESlateVisibility_Collapsed)
    -- end
    local radarMapWidget = self.pWidgetRef.radarMap
    radarMapWidget:SetSpliceNum(tbMapResData.nSplitNum)
    radarMapWidget:SetFilePath(tbMapResData.szPath)
    radarMapWidget:SetCommonFilePath(tbMapResData.szCommonPath)
    radarMapWidget:SetWorldSize(Vector2D{X = tbMapResData.nMapSizeX, Y = tbMapResData.nMapSizeY})
    radarMapWidget:SetMapTextureSize(tbMapResData.nUIMapSizeX)
    


    -- self.nSceneId = nSceneId
    -- self.nUIRadarMapId = tbSceneOrDungeonTemplate.nUIRadarMapId
    self.tbMapResData = tbMapResData
    self.nMapMode = MiniMapSystem:GetMapMode()
end

function UPRadarMapNormal:OnLoad()
    LoadMapData(self)
    log("UPRadarMapNormal:OnLoad,nMode=",self.nMapMode,self.tbMapResData.nResId)
    self:RefreshMap(self.tbMapResData.nScope)
    local tbModeTemplate = UIMapModeDataTable:GetTemplate(self.nMapMode)
    local UILogicHelper = self.UILogicHelper
    local szRadarMapScript = DEFAULT_MAP_OP_LOGIC_SCRIPT
    if tbModeTemplate then
        szRadarMapScript = tbModeTemplate.szRadarMapScript
    end
    self.ulMapOp = UILogicHelper:CreateUILogic(szRadarMapScript)
    if GlobalVariableSystem:IsDevMode() then
        self.pWidgetRef.pbMapRealLocationInfo:EnableUpdate()
    end
end

function UPRadarMapNormal:OnUnload()
    self.ulMapOp:UnregisterAllOperations()
end

function UPRadarMapNormal:OnEnter()
    self.ViewerObj = self.Owner.tbCurrrentWatchObj
    self:HideAll()
    RegisterOperations(self)
end

function UPRadarMapNormal:OnBindEvent(EventHelper)
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
            log("[UPRadarMapNormal] Enable GM Panel, OpenMode : DoubleClick, DoubleClickInterval =", GMIni.nDoubleClickInterval)
        elseif nGMOpenMode == GMOpenModeDef.LONG_PRESS then
            btnBigMap.LongPressedInterval = GMIni.nLongPressedInterval
            btnBigMap.bLongPressedEnabled = true
            EventHelper:RegisterCppDelegate(btnBigMap.OnLongPressed, self, OnLongPressedMap)
            log("[UPRadarMapNormal] Enable GM Panel, OpenMode : LongPress, LongPressedInterval =", GMIni.nLongPressedInterval)
        end
    end
end

function UPRadarMapNormal:RefreshMap(nScope)
    log("UPRadarMapNormal:RefreshMap,nScope=",nScope)
    local pWidgetRef = self.pWidgetRef
    local ViewSize = pWidgetRef.cvsMapPanel.Slot:GetSize()
    local tbMapResData = self.tbMapResData
    local pScale = pWidgetRef.RenderTransform.Scale
    ViewSize = {X = ViewSize.X * pScale.X, Y = ViewSize.Y * pScale.Y}
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
    local radarMapWidget = self.pWidgetRef.radarMap
    pViewPortSize.X = ViewSize.X
    pViewPortSize.Y = ViewSize.Y
    radarMapWidget:SetViewPortSize(pViewPortSize)
    radarMapWidget:Init()
    SetMapScope(self, nScope)
    
end

function UPRadarMapNormal:HideAll()
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.kmpgbsViewFov:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.kmFFAPoisonCircle:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.pbFFASafeCircle:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ovlArrow:SetVisibility(ESlateVisibility.Collapsed)
end



function UPRadarMapNormal:OnExit()
    --self.ulMapOp:UnregisterAllOperations()
    self.tbTimer = nil
end

function UPRadarMapNormal:GetObservedSceneId()
    return self.nSceneId
end

function UPRadarMapNormal:GetCurrentSceneId()
    return self.nSceneId
end

function UPRadarMapNormal:RefreshMapViewSize()
    self:RefreshMap(self.nCurrentScope)
end

function UPRadarMapNormal:OnResetMapTarget()
    self.ViewerObj = self.Owner.tbCurrrentWatchObj
    log("UPRadarMapNormal:OnResetMapTarget",self.ViewerObj:GetName())
    if self.ulMapOp then
        self.ulMapOp:Reinit()
    end
end


return UPRadarMapNormal
