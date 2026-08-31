-----------------------------------------------------
--File Name    : UIWorldMap.lua
--Author       : Ran Jie
--Create Time  : 2016-12-9
--Description  : 世界地图
-----------------------------------------------------


local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIWorldMap = luaclass("UIWorldMap", WndBase)

---import
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local GameWorldSystem = require("GameWorldSystem")
local WorldMapUtil = require("WorldMapUtil")

--local SelfVerticalListHelperClass = require("SelfVerticalListHelper")
local ClientEventDef = require("ClientEventDef")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local DungeonDataTable = require("DungeonDataTable")
local SceneTable = require("SceneDataTable")
local UIMapResDataTable = require("UIMapResDataTable")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local GameCameraSystem = require("GameCameraSystem")
local GameCameraModeGroupDef = require("GameCameraModeGroupDef")
local FlagMapLocationSystem = require("FlagMapLocationSystem")

local COLLAPSED = ESlateVisibility_Collapsed
local MAP_GUIDE_MODULE_ID = 200
local MAP_GUIDE_GROUP_ID = 20019
local MAP_GUIDE_STEP_ID = 2
local SINGLE_GUIDE_MODULE_ID = 300

UIWorldMap.pbMap = nil
UIWorldMap.tbTimerParam = nil
UIWorldMap.nCurrentGrade = 1
UIWorldMap.nCurrentSceneID = nil
UIWorldMap.nCurrentMapMode = nil
UIWorldMap.nObservedSceneID = nil
UIWorldMap.nObservedMapMode = nil
UIWorldMap.nCurrentZoomValue = nil


local function GetMapResData(nSceneId)
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    local tbSceneTemplate = nil
    if bIsInDungeon then
        local nDungeonId = BattleGameModeSystem.nDungeonId
        tbSceneTemplate = DungeonDataTable:GetTemplate(nDungeonId)
    else
        tbSceneTemplate = SceneTable:GetTemplate(nSceneId)
    end
    local tbMapResData = UIMapResDataTable:GetTemplate(tbSceneTemplate.nUIMapId)
    return tbMapResData
end

local function IsSlideZoom(nSceneId)
    local tbMapResData = GetMapResData(nSceneId)
    return tbMapResData ~= nil and tbMapResData.bIsSlideToZoom
end

local nAdjustFactor = 1

local function ConvertToZoomFactor(self, nValue)
    local tbMapResData = GetMapResData(self.nCurrentSceneID)
    local nScope = tbMapResData.nScope
    local ViewSize = self.pWidgetRef.pbMap.Slot:GetSize()
    local nZoomFactor = 1
    if nScope ~= 0 then
        local nMapSizeX = tbMapResData.nMapSizeX
        local nUIMapSizeX = tbMapResData.nUIMapSizeX - tbMapResData.nUIMapOffsetX * 2
        local nScale = (nMapSizeX / nScope) * ViewSize.X / nUIMapSizeX -- * (tbMapResData.nUIMapSizeX / nUIMapSizeX)
        nZoomFactor = (nScale * nAdjustFactor - 1) * nValue + 1
    end
    return nZoomFactor
end


local function OnSliderValueChanged(self, nValue)
    if nValue < 0 or nValue > 1 then
        return
    end
    local nZoomFactor = ConvertToZoomFactor(self, nValue)
    WorldMapUtil.nCurrentSliderValue = nValue
    if nZoomFactor == 1 then
        self.nCurrentGrade = WorldMapUtil.tbMapGrade.None
    else
        self.nCurrentGrade = WorldMapUtil.tbMapGrade.Second
    end
    --self:ZoomMap(nZoomFactor, true)
    -- local nDeltaValue = nValue - self.nLastSliderValue
    -- self.nLastSliderValue = nValue
    -- local nDeltaChangeDistance = nDeltaValue * WorldMapUtil.PinchSize
    -- self.pbMap:OnPinch(nDeltaChangeDistance)
    --logdebug("OnSliderValueChanged,nValue,nZoomFactor=",nValue,nZoomFactor)
    self.pbMap:SetMapSizeZoomFactor(nZoomFactor)
end

local function OnDelFlagPosClicked(self)
    --self.EventHelper:FireEvent(ClientEventDef.EV_FFA_DEL_FLAG_POS)
    FlagMapLocationSystem:SetFlagPos(false, 0, 0)
end

local function OnFlagSelfClicked(self)
    local WorldPos = GamePlayerSelfHelper:Get():GetLocation()
    --self.EventHelper:FireEvent(ClientEventDef.EV_FFA_ADD_FLAG_POS, WorldPos.X, WorldPos.Y)
    FlagMapLocationSystem:SetFlagPos(true, WorldPos.X, WorldPos.Y)
end

local function OnZoomUpClick(self)
    local nValue = self.pWidgetRef.sldrZoom:GetValue()
    nValue = math.min(nValue + 0.1, 1)
    if math.abs(1 - nValue) < 0.05 then
        nValue = 1
    end
    self.nLastSliderValue = nValue
    self.pWidgetRef.sldrZoom:SetValue(nValue)
    OnSliderValueChanged(self, nValue)
end

local function OnZoomDownClick(self)
    local nValue = self.pWidgetRef.sldrZoom:GetValue()
    nValue = math.max(nValue - 0.1, 0)
    if nValue < 0.05 then
        nValue = 0
    end
    self.nLastSliderValue = nValue
    self.pWidgetRef.sldrZoom:SetValue(nValue)
    OnSliderValueChanged(self, nValue)
end

local function OnFreeViewEnd(self)
    self.pWidgetRef.cvsPanel:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
end

local function OnUserWidgetTouchEnded(self, pGeometry, pMouseEvent)
    self.EventHelper:FireEvent(ClientEventDef.EV_USER_WIDGET_TOUCH_END, UIDef.UI_WORLD_MAP, pGeometry, pMouseEvent)
end

local function OnExitLoading(self)
    self:CloseSelf()
end

function UIWorldMap:OnCreate()
end

function UIWorldMap:OnLoad()
    self.PrefabHelper:BindPrefab(self.pWidgetRef.pbCutoutScreenAdapter)
    self.pbMap = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbMap, UIDef.UP_WORLD_MAP)
    self.UILogicHelper:CreateUILogic("ULMapPointSymbol")
end

function UIWorldMap:OnBindEvent()
    local Helper = self.EventHelper
    local pWidgetRef = self.pWidgetRef
    Helper:RegisterCppDelegate(pWidgetRef.btnClose.OnClicked, self, self.CloseSelf)
    Helper:RegisterCppDelegate(pWidgetRef.btnLocationPlayer.OnClicked, self, self.OnClickLocationPlayer)
    Helper:RegisterCppDelegate(pWidgetRef.sldrZoom.OnValueChanged, self, OnSliderValueChanged)
    Helper:RegisterCppDelegate(pWidgetRef.btnZoomUp.OnClicked, self, OnZoomUpClick)
    Helper:RegisterCppDelegate(pWidgetRef.btnZoomDown.OnClicked, self, OnZoomDownClick)
    Helper:RegisterCppDelegate(pWidgetRef.btnDelFlagPos.OnClicked, self, OnDelFlagPosClicked)
    Helper:RegisterCppDelegate(pWidgetRef.btnFlagSelf.OnClicked, self, OnFlagSelfClicked)
    Helper:RegisterCppDelegate(pWidgetRef.OnTouchEndedEvent, self, OnUserWidgetTouchEnded)

    Helper:RegisterEvent(ClientEventDef.EV_FREE_VIEW_END, self, OnFreeViewEnd)
    Helper:RegisterEvent(ClientEventDef.EV_UI_GUIDE_BEGIN_STEP, self, self.HideWhenGuide)
    Helper:RegisterEvent(ClientEventDef.EV_EXIT_LOADING, self, OnExitLoading)
end

function UIWorldMap:OnShow()
    local bIsInDungeon = GlobalVariableSystem:IsInDungeon()
    if not bIsInDungeon then
        self.pWidgetRef.ovlDelFlag:SetVisibility(COLLAPSED)
        self.pWidgetRef.ovlFlagSelf:SetVisibility(COLLAPSED)
    end
    self.nObservedSceneID = nil

    local World = GameWorldSystem:GetWorld()
    -- local bIsInOcean = World:IsOcean()
    -- local nCurrentMapMode = nil
    -- if(not bIsInOcean)then
    --     nCurrentMapMode = UIDef.UI_MAP_MODE.TOWN
    -- else
    --     nCurrentMapMode = UIDef.UI_MAP_MODE.WILD_OCEAN
    -- end
    self.nCurrentSceneID = World.nSceneId
    self.nObservedSceneID = self.nCurrentSceneID
    local pWidgetRef = self.pWidgetRef

    if IsSlideZoom(self.nCurrentSceneID) then
        pWidgetRef.vboxSlider:SetVisibility(ESlateVisibility_Visible)
        if self.tbOpenArgs.bPrepareTimer then
            pWidgetRef.ovlDelFlag:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.ovlFlagSelf:SetVisibility(ESlateVisibility_Collapsed)
            pWidgetRef.btnLocationPlayer:SetVisibility(ESlateVisibility_Collapsed)
        end
        local nSliderValue = WorldMapUtil.nCurrentSliderValue ~= nil and WorldMapUtil.nCurrentSliderValue or 0
        pWidgetRef.sldrZoom:SetValue(nSliderValue)
        self.nLastSliderValue = nSliderValue
        local nZoomFactor = ConvertToZoomFactor(self, nSliderValue)
        self.pbMap:ShowMapData(nZoomFactor)
        OnSliderValueChanged(self, nSliderValue)
    end

    --如果是在freeview mode下，屏蔽输入事件
    if GameCameraSystem:IsCameraLogicActive(GameCameraModeGroupDef.HumanFreeView) then
        self.pWidgetRef.cvsPanel:SetVisibility(ESlateVisibility_HitTestInvisible)
    end

end


function UIWorldMap:OnDestroy()
   
end

function UIWorldMap:HideWhenGuide(nModuleId, nGroup, nStep)
    if (nModuleId ~= MAP_GUIDE_MODULE_ID and nGroup ~= MAP_GUIDE_GROUP_ID and nStep ~= MAP_GUIDE_STEP_ID) and nModuleId ~= SINGLE_GUIDE_MODULE_ID then
        self:CloseSelf()
    end
end

function UIWorldMap:OnClickedBtnClose()
    UIManager:CloseWnd(UIDef.UI_WORLD_MAP)
end

function UIWorldMap:OnClickLocationPlayer()
    self.pbMap:LocationPlayer()
end


function UIWorldMap:SetSliderValue(nDeltaValue)
    local nCurrentValue = self.pWidgetRef.sldrZoom:GetValue()
    nCurrentValue = math.min(1, math.max(nCurrentValue + nDeltaValue, 0))
    self.pWidgetRef.sldrZoom:SetValue(nCurrentValue)
    OnSliderValueChanged(self, nCurrentValue)
end

function UIWorldMap:GetMaxZoomFactor()
    return ConvertToZoomFactor(self, 1)
end
return UIWorldMap