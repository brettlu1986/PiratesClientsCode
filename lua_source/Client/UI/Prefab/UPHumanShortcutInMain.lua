-----------------------------------------------------
--File Name    : UPHumanShortcutInMain.lua
--Author       : WuJizhou
--Create Time  : 9/19/2018, 9:49:38 PM
--Description  : UPHumanShortcutInMain
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPHumanShortcutInMain = luaclass("UPHumanShortcutInMain", PrefabBase)
local UIDef = require("UIDef")
local EventManager = require("EventManager")
local BattleItemResDataTable = require("BattleItemResDataTable")
local ClientEventDef = require("ClientEventDef")
-- local BattleHumanWeaponSystemClient = require("BattleHumanWeaponSystemClient")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local BattleHumanWeaponSystemNew = require("BattleHumanWeaponSystemNew_C")
-- local GlobalVariableSystem = require("GlobalVariableSystem_C")

UPHumanShortcutInMain.pbItemGrids       = nil
UPHumanShortcutInMain.nMainGridPosition = 1
UPHumanShortcutInMain.fnDataProvider    = nil
UPHumanShortcutInMain.fnShortcutOperate = nil
UPHumanShortcutInMain.fnSelectGridOperate = nil
UPHumanShortcutInMain.fnSelectStateChecker = nil
UPHumanShortcutInMain.nShowMode = nil

local GRID_COUNT = 8

local tbMainGridPositionType =
{
    LowerLeft  = 1,
    LowerRight = 2
}

local tbShowMode =
{
    MainGrid = 1,   --快捷栏（收缩态）
    AllGrids = 2    --选择栏（展开态）
}

local function OnClickedCollapsedBtn(self)
    self.nShowMode =  self.nShowMode == tbShowMode.MainGrid and tbShowMode.AllGrids or tbShowMode.MainGrid
    self:ShowView(self.nShowMode)
end

local function OnGridClicked(tbParams)
    local nItemTemplateId = tbParams.nItemTemplateId
    EventManager:OnFireEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_SELECTED, nItemTemplateId)
end

local function OnMainGridClicked(tbParams)
    local bSelected = tbParams.bSelected --点击前的状态
    local nItemTemplateId = tbParams.nItemTemplateId
    if bSelected then
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_DEACTIVATED, nItemTemplateId)
    else
        EventManager:OnFireEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_ACTIVATED, nItemTemplateId)
    end
end

--tbTemplatePair : { nTemplateId = xxx, nCount = xxx}
local function RefreshItemGrid(pbGrid, tbTemplatePair, nShowMode)
    if tbTemplatePair ~= nil then
        local nTemplateId = tbTemplatePair.nTemplateId
        local tbTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
        local tbResTemplate = BattleItemResDataTable:GetTemplate(tbTemplate.nResId)
        local szRes = tbResTemplate.szIconPath

        local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nTemplateId)

        if nShowMode == tbShowMode.MainGrid then
            pbGrid:ShowContent(szRes, szColorGradeImg, OnMainGridClicked, {nItemTemplateId = nTemplateId}, tbTemplatePair.nCount)
        else
            pbGrid:ShowContent(szRes, szColorGradeImg, OnGridClicked, {nItemTemplateId = nTemplateId}, tbTemplatePair.nCount)
        end
    else
        pbGrid:HideContent()
    end
end

local function SetBrushMirrorType(pWidget, MirrorType)
    local pBrush = pWidget.Brush
    pBrush.Mirroring = MirrorType
    pWidget:SetBrush(pBrush)
end

local function RefreshCollapseButtonState(self, nMainGridPosition, nShowMode)
    local pWidgetRef = self.pWidgetRef
    local Visible = ESlateVisibility.Visible
    local Invisible = ESlateVisibility.Hidden
    local pWidget = nil
    local MirrorType = nil
    if nMainGridPosition == tbMainGridPositionType.LowerLeft then
        pWidgetRef.btnRight:SetVisibility(Invisible)
        pWidgetRef.btnLeft:SetVisibility(Visible)
        pWidget = pWidgetRef.imgLeft
    elseif nMainGridPosition == tbMainGridPositionType.LowerRight then
        pWidgetRef.btnLeft:SetVisibility(Invisible)
        pWidgetRef.btnRight:SetVisibility(Visible)
        pWidget = pWidgetRef.imgRight
    else
        logerror("ShowMainGrid error, nMainGridPosition is illegal, nMainGridPosition : ", nMainGridPosition)
        return
    end
    if nShowMode == tbShowMode.MainGrid then
        MirrorType = ESlateBrushMirrorType.Vertical
    elseif nShowMode == tbShowMode.AllGrids then
        MirrorType = ESlateBrushMirrorType.NoMirror
    else
        logerror("ShowMainGrid error, nShowMode is illegal, nShowMode : ", nShowMode)
    end
    SetBrushMirrorType(pWidget, MirrorType)
end

local function GetAllItems(self)
    local tbResult = {}
    if self.fnDataProvider == nil then
        logwarning("UPHumanShortcutInMain, fnDataProvider is nil")
        return tbResult
    end
    local tbDataList, _nCategory = self.fnDataProvider()
    local nShortcutTemplateId = BattleHumanWeaponSystemNew:GetSavedThrownWeaponInfo()
    table.sort(tbDataList, function (data1, data2) return data1.nTemplateId < data2.nTemplateId end)
    for _, v in ipairs(tbDataList) do
        if v.nTemplateId == nShortcutTemplateId then
            table.insert(tbResult, 1, v)
        else
            table.insert(tbResult, v)
        end
    end
    return tbResult
end

local function ShowMainGrid(self)
    local nMainGridIndex = nil
    RefreshCollapseButtonState(self, self.nMainGridPosition, self.nShowMode)
    local pWidgetRef = self.pWidgetRef
    if self.nMainGridPosition == tbMainGridPositionType.LowerLeft then
        pWidgetRef.vboxLeft.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Bottom)
        pWidgetRef.vboxRight.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Top)
        nMainGridIndex = 1
    elseif self.nMainGridPosition == tbMainGridPositionType.LowerRight then
        pWidgetRef.vboxLeft.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Top)
        pWidgetRef.vboxRight.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Bottom)
        nMainGridIndex = GRID_COUNT
    else
        logerror("ShowMainGrid error, nMainGridPosition is illegal, nMainGridPosition : ", self.nMainGridPosition)
    end
    if not nMainGridIndex then
        return
    end
    local tbTemplateIdPairs = GetAllItems(self)
    if #tbTemplateIdPairs == 0 then
        pWidgetRef.hboxAll:SetVisibility(ESlateVisibility.Collapsed)
        return
    else
        pWidgetRef.hboxAll:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    for nIdx = 1, GRID_COUNT do
        local pbGrid = self.pbItemGrids[nIdx]
        if nIdx == nMainGridIndex then
            local tbPair = tbTemplateIdPairs[nMainGridIndex]
            RefreshItemGrid(pbGrid, tbPair, tbShowMode.MainGrid)
            local bSelected = false
            if self.fnSelectStateChecker then
                bSelected = self.fnSelectStateChecker(tbPair.nTemplateId)
            else
                logwarning("UPHumanShortcutInMain, fnSelectStateChecker is nil!")
            end
            pbGrid:SetSelected(bSelected)
        else
            pbGrid:HideContent()
        end
    end

end

local function ShowAllGrid(self)
    RefreshCollapseButtonState(self, self.nMainGridPosition, self.nShowMode)
    local tbTemplateIdPairs = GetAllItems(self)
    local pWidgetRef = self.pWidgetRef
    if #tbTemplateIdPairs == 0 then
        pWidgetRef.hboxAll:SetVisibility(ESlateVisibility.Collapsed)
        return
    else
        pWidgetRef.hboxAll:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end
    if self.nMainGridPosition == tbMainGridPositionType.LowerLeft then
        pWidgetRef.vboxLeft.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Bottom)
        pWidgetRef.vboxRight.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Top)
        for nIdx = 1, GRID_COUNT do
            local tbPair = tbTemplateIdPairs[nIdx]
            local pbGrid = self.pbItemGrids[nIdx]
            RefreshItemGrid(pbGrid, tbPair, tbShowMode.AllGrids)
            pbGrid:SetSelected(false)
        end

    elseif self.nMainGridPosition == tbMainGridPositionType.LowerRight then
        pWidgetRef.vboxLeft.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Top)
        pWidgetRef.vboxRight.Slot:SetVerticalAlignment(EVerticalAlignment.VAlign_Bottom)
        for nIdx = GRID_COUNT, 1,  -1 do
            local tbPair = tbTemplateIdPairs[GRID_COUNT - nIdx + 1]
            local pbGrid = self.pbItemGrids[nIdx]
            RefreshItemGrid(pbGrid, tbPair, tbShowMode.AllGrids)
            pbGrid:SetSelected(false)
        end
    else
        logerror("ShowAllGrid error, nMainGridPosition is illegal, nMainGridPosition : ", self.nMainGridPosition)
    end
end

local function SetMainGridSelected(self, bSelected)
    local nMainGridIndex
    if self.nMainGridPosition == tbMainGridPositionType.LowerLeft then
        nMainGridIndex = 1
    elseif self.nMainGridPosition == tbMainGridPositionType.LowerRight then
        nMainGridIndex = GRID_COUNT
    else
        return
    end
    self.pbItemGrids[nMainGridIndex]:SetSelected(bSelected)
end

local function OnMainGridActivate(self, nItemTemplateId)
    if self.nShowMode ~= tbShowMode.MainGrid then
        return
    end
    if self.fnShortcutOperate == nil then
        logwarning("UPHumanShortcutInMain, fnShortcutOperate is nil!")
        return
    end
    self.fnShortcutOperate(nItemTemplateId)
end

local function OnMainGridDeactivate(self, nItemTemplateId)
    if self.nShowMode ~= tbShowMode.MainGrid then
        return
    end
    if self.fnShortcutOperate == nil then
        logwarning("UPHumanShortcutInMain, fnShortcutOperate is nil!")
        return
    end
    self.fnShortcutOperate(nItemTemplateId)
end

local function OnItemAdded(self, tbItem)
    self:ShowView(self.nShowMode)
end

local function OnItemDeleted(self, nInstanceId)
    self:ShowView(self.nShowMode)
end

local function OnItemStackCountChanged(self)
    self:ShowView(self.nShowMode)
end

local function OnShortcutItemSelected(self, nItemTemplateId)
    self:ShowView(tbShowMode.MainGrid)
    if self.fnSelectGridOperate then
        self.fnSelectGridOperate(nItemTemplateId)
    end
end

--设置当前界面的数据来源fnDataProvider，fnDataProvider返回{list made of tbItem, category of item}
function UPHumanShortcutInMain:SetDataProvider(fnDataProvider)
    self.fnDataProvider = fnDataProvider
end

--设置从选择栏中选中某一种时的操作
function UPHumanShortcutInMain:SetShortcutOperate(fnShortcutOperate)
    self.fnShortcutOperate = fnShortcutOperate
end

--设置从展开栏中选中某一种时的操作
function UPHumanShortcutInMain:SetSelectGridOperate(fnSelectGridOperate)
    self.fnSelectGridOperate = fnSelectGridOperate
end

--设置选中状态判定器
function UPHumanShortcutInMain:SetSelectStateChecker(fnSelectStateChecker)
    self.fnSelectStateChecker = fnSelectStateChecker
end

--设置首选快捷按钮的位置，1为左下角格子，2为右下角格子
function UPHumanShortcutInMain:SetMainGridPosition(nMainGridPosition)
    self.nMainGridPosition = nMainGridPosition
end

function UPHumanShortcutInMain:SelectMainGrid(bSelected)
    SetMainGridSelected(self, bSelected)
end

--nMode: 1为只显示首选快捷按钮，2位全部展开
function UPHumanShortcutInMain:ShowView(nShowMode)
    self.nShowMode = nShowMode
    -- self.pWidgetRef:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    if nShowMode == tbShowMode.MainGrid then
        ShowMainGrid(self)
    elseif nShowMode == tbShowMode.AllGrids then
        ShowAllGrid(self)
    else
        logerror("UPHumanShortcutInMain:ShowView error, nShowMode is illegal, nMode: ", nShowMode)
    end
end

function UPHumanShortcutInMain:GetAllShortcutItems()
    return GetAllItems(self)
end

----------life cycle----------

function UPHumanShortcutInMain:OnLoad()
    local pbItemGrids = {}
    local PrefabHelper = self.PrefabHelper
    local pWidgetRef = self.pWidgetRef
    for nIdx = 1, GRID_COUNT do
        local pb = PrefabHelper:BindPrefab(pWidgetRef["pbItemGrid0" .. nIdx],  UIDef.UP_BTN_IMG_GRID)
        pb:HideContent()
        table.insert(pbItemGrids, pb)
    end
    self.pbItemGrids = pbItemGrids

end

function UPHumanShortcutInMain:OnEnter()
    self.nShowMode = tbShowMode.MainGrid
end

function UPHumanShortcutInMain:OnShow()
    self:ShowView(self.nShowMode)
end

function UPHumanShortcutInMain:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnLeft.OnClicked, self, OnClickedCollapsedBtn)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnRight.OnClicked, self, OnClickedCollapsedBtn)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_ADDED, self, OnItemAdded)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_REMOVED, self, OnItemDeleted)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_NOTIFY_REFRESH_HUMAN_UI_ON_ITEM_STACK_COUNT_CHANGED, self, OnItemStackCountChanged)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_DEACTIVATED, self, OnMainGridDeactivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_ACTIVATED, self, OnMainGridActivate)
    EventHelper:RegisterEvent(ClientEventDef.EV_FFA_HUMAN_SHORT_CUT_ITEM_SELECTED, self, OnShortcutItemSelected)
end

return UPHumanShortcutInMain