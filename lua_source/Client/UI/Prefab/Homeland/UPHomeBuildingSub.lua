-----------------------------------------------------
--File Name    : UPHomeBuildingSub.lua
--Author       : zhiyuan
--Create Time  : 2019-04-23
--Description  : 标志性建筑在主界面的交互UP
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomeBuildingSub = luaclass("UPHomeBuildingSub", PrefabBase)

local HomelandSceneDataTable = require("HomelandSceneDataTable")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local BuildingUiDataTable = require("BuildingUiDataTable")
local HomelandSystem = require("HomelandSystem")
local UIManager = require("UIManager")
local BuildingDataTable = require("BuildingDataTable")
local UISetUtils = require("UISetUtils")
local L10N = require("L10n")
local UITextDef = require("UITextDef")
local BlockTypeDataTable = require("BlockTypeDataTable")
local ClientEventDef = require("ClientEventDef")
local LandmarkStatusDef = require("LandmarkStatusDef")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

local MAX_BUTTON_COUNT = 3

local SHOW_UI = 0
local SCRIPT = 1

UPHomeBuildingSub.tbFuncs = nil
UPHomeBuildingSub.tbBlockData = nil

local function GetLandmarkName(self, l10nName, nLandmarkType)
    local nGrade = HomelandSystem:GetLandmarkGrade(nLandmarkType)
    return L10N:Format(UITextDef.LANDMARK_NAME_FORMAT, l10nName, nGrade)
end

local function SetName(self, szName)
    self.pWidgetRef.ktxtName:SetText(szName)
end

local function SetImage(self, szImagePath)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBuilding, szImagePath:load())
end

local function ShowTimer(self, nRemainSecond)
    self.pWidgetRef.hboxTimer:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    local PRECISION = 2
    local pWidget = self.pWidgetRef
    pWidget.kmtimerCountDown.MinTimeUnit = EMinTimeUnit.Second
    pWidget.kmtimerCountDown:SetPrecision(PRECISION)
    local DELAY_TIME = 1
    local TIMEFORMAT = {
        L10N:ToString(UITextDef.UI_LANDMARK_UPGRADE_COUNT_DOWN_MINUTE),
        L10N:ToString(UITextDef.UI_LANDMARK_UPGRADE_COUNT_DOWN_SECOND),
    }
    pWidget.kmtimerCountDown:StartTimer(nRemainSecond, DELAY_TIME, TIMEFORMAT, EMinTimeUnit.Second)
end

local function CollapsedTimer(self)
    self.pWidgetRef.hboxTimer:SetVisibility(ESlateVisibility.Collapsed)
end

local function CheckScriptPrerequisite(self, nBlockId, tbUiTemplate)
    local szPrerequisiteName = tbUiTemplate.szPrerequisiteName
    local szPrerequisiteFunction = tbUiTemplate.szPrerequisiteFunction
    if szPrerequisiteName == nil or szPrerequisiteFunction == nil then
        return true
    end
    local tbArgs = {}
    tbArgs.nBlockId = nBlockId
    local tbScript = require(szPrerequisiteName)
    return tbScript[szPrerequisiteFunction](tbArgs)
end

local function CheckUi(self, nBlockId, tbUiTemplate, nStatus)
    local bIsOk = false
    if not tbUiTemplate.bNeedUnlock then
        bIsOk = true
    else
        local nCurrentGrade = HomelandSystem:GetLandmarkGrade(tbUiTemplate.nLandmarkType)
        if nCurrentGrade <= tbUiTemplate.nLandmarkGrade then
            bIsOk = true
        end
    end
    if bIsOk then
        return CheckScriptPrerequisite(self, nBlockId, tbUiTemplate)
    end
    return bIsOk
end

local function GetUiDatas(self, nBlockId, tbUiList, nStatus)
    local tbNeedShowUiTemplate = {}
    for _, v in ipairs(tbUiList) do
        local tbUiTemplate = BuildingUiDataTable:GetTemplate(v)
        if CheckUi(self, nBlockId, tbUiTemplate, nStatus) then
            table.insert(tbNeedShowUiTemplate, tbUiTemplate)
        end
    end
    return tbNeedShowUiTemplate
end

local function ShowFuncBtn(self, index, szDesc, Func)
    local pWidgetRef = self.pWidgetRef
    local kmbtnFun = pWidgetRef["kmbtnFun"..index]
    kmbtnFun:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef["ktxtFun"..index]:SetText(szDesc)

    self.tbFuncs[index] = Func
end

local function ShowDockBtn(self, index)
    local FuncClickDelegate = function()
        HomelandSystem:LeaveHomeland()
    end

    ShowFuncBtn(self, index, UITextDef.DOCK_FUNCTION_DESC, FuncClickDelegate)
end

local function ShowLandmarkFuncBtn(self, index, tbUiTemplate, nBlockId)

    local FuncClickDelegate = function()
        local nDisplayType = tbUiTemplate.nDisplayType
        if nDisplayType == SHOW_UI then
            local tbOpenArgs = {}
            tbOpenArgs.nBlockId = nBlockId
            tbOpenArgs.nParam1 = tbUiTemplate.szParam1
            tbOpenArgs.nParam2 = tbUiTemplate.szParam2
            UIManager:OpenWnd(tbUiTemplate.szDisplayName, tbOpenArgs)
        elseif nDisplayType == SCRIPT then
            local tbArgs = {}
            tbArgs.PrefabHelper = self.PrefabHelper
            tbArgs.nBlockId = nBlockId
            tbArgs.nParam = tbUiTemplate.szParam2
            local tbScript = require(tbUiTemplate.szDisplayName)
            tbScript[tbUiTemplate.szParam1](tbArgs)
        end
    end

    ShowFuncBtn(self, index, tbUiTemplate.l10nDialogText, FuncClickDelegate)
end

local function CollapsedFuncBtn(self, index)
    self.pWidgetRef["kmbtnFun"..index]:SetVisibility(ESlateVisibility.Collapsed)
    self.tbFuncs[index] = nil
end

local function RefreshWhenLandmardChanged(self, nLandmarkType)
    if self.tbBlockData == nil then
        return
    end
    local nBlockId = self.tbBlockData.nBlockId
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    if tbBlockTemplate == nil then
        error("Cannot find block template! nBlockId:"..nBlockId)
    end
    if nLandmarkType == tbBlockTemplate.nDefaultLandmarkType then
        self:ShowLandmarkDetail(self.tbBlockData)
    end
end

local function OnLandmarkUpgradeBegin(self, nLandmarkType)
    RefreshWhenLandmardChanged(self, nLandmarkType)
end

local function OnLandmarkUpgradeComplete(self, nLandmarkType)
    RefreshWhenLandmardChanged(self, nLandmarkType)
end

local function OnCompleteBuildingTimer(self)
    if self.tbBlockData == nil then
        return
    end
    local nBlockId = self.tbBlockData.nBlockId
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    if tbBlockTemplate == nil then
        error("Cannot find block template! nBlockId:"..nBlockId)
    end
    self:ShowLandmarkDetail(self.tbBlockData)
end

-- tbBlockData.nBlockId = 1
-- tbBlockData.nBlockType = 1
-- tbBlockData.bIsLandmark = true
-- tbBlockData.bCanPlaceBuilding = true
-- tbBlockData.bUnlock = true
-- tbBlockData.bBought = true
-- tbBlockData.nBuildingId = 1
-- tbBlockData.nItemInstanceId = 1
-- tbBlockData.nRotationId = 1
function UPHomeBuildingSub:ShowDockDetail(tbBlockData)
    self.tbBlockData = tbBlockData
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    local nBlockType = tbBlockData.nBlockType
    local tbBlockTypeTemplate = BlockTypeDataTable:GetTemplate(nBlockType)

    SetName(self, tbBlockTypeTemplate.l10nName)
    SetImage(self, tbBlockTypeTemplate.szIcon)
    CollapsedTimer(self)
    for i = 1, MAX_BUTTON_COUNT do
        if i == 1 then
            ShowDockBtn(self, i)
        else
            CollapsedFuncBtn(self, i)
        end
    end
end

local function ShowUpgrade(self, tbLandmarkData)
    if tbLandmarkData.nStatus == LandmarkStatusDef.UPGRADING then
        local now = GlobalVariableSystem:GetServerTimeUtc()
        local nRemainSecond = tbLandmarkData.nCompleteTime - now
        if nRemainSecond > 0 then
            ShowTimer(self, nRemainSecond)
        else
            CollapsedTimer(self)
        end
    else
        CollapsedTimer(self)
    end
end

function UPHomeBuildingSub:ShowLandmarkDetail(tbBlockData)
    self.tbBlockData = tbBlockData
    self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
    local nBlockId = tbBlockData.nBlockId
    local tbBlockTemplate = HomelandSceneDataTable:GetBlockTemplate(nBlockId)
    if tbBlockTemplate == nil then
        error("Cannot find block template! nBlockId:"..nBlockId)
    end
    local nLandmarkType = tbBlockTemplate.nDefaultLandmarkType
    if nLandmarkType == nil or nLandmarkType <= 0 then
        error("landmark type invalid!")
    end
    local tbLandmarkTemplate = LandmarkBuildingTypeDataTable:GetTemplate(nLandmarkType)
    if tbLandmarkTemplate == nil then
        error("Cannot find landmark type!"..nLandmarkType)
    end
    SetName(self, GetLandmarkName(self, tbLandmarkTemplate.l10nName, nLandmarkType))

    local tbBuildingTemplate = BuildingDataTable:GetTemplate(tbBlockData.nBuildingId)
    SetImage(self, tbBuildingTemplate.szIcon)

    local tbLandmarkData = HomelandSystem:GetLandmarkData(nLandmarkType)

    ShowUpgrade(self, tbLandmarkData)

    local tbNeedShowUiTemplate = GetUiDatas(self, nBlockId, tbLandmarkTemplate.tbUiList, tbLandmarkData.nStatus)
    local nCount = #tbNeedShowUiTemplate
    for i = 1, MAX_BUTTON_COUNT do
        if i <= nCount then
            local tbUiTemplate = tbNeedShowUiTemplate[i]
            ShowLandmarkFuncBtn(self, i, tbUiTemplate, nBlockId)
        else
            CollapsedFuncBtn(self, i)
        end
    end
end

function UPHomeBuildingSub:Collapsed()
    self.tbBlockData = nil
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    self.tbFuncs = {}
end

----------life cycle----------

function UPHomeBuildingSub:OnLoad()
    self.tbFuncs = {}
end

function UPHomeBuildingSub:OnShow()
end

local function OnCommitBtnClicked(self, nIndex)
    local tbFunc = self.tbFuncs[nIndex]
    if tbFunc ~= nil then
        tbFunc()
    end
end

local function OnCommitBtn1Clicked(self)
    OnCommitBtnClicked(self, 1)
end

local function OnCommitBtn2Clicked(self)
    OnCommitBtnClicked(self, 2)
end

local function OnCommitBtn3Clicked(self)
    OnCommitBtnClicked(self, 3)
end

function UPHomeBuildingSub:OnBindEvent(EventHelper)
    EventHelper:RegisterEvent(ClientEventDef.EV_LANDMARK_UPGRADE_BEGIN, self, OnLandmarkUpgradeBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_LANDMARK_UPGRADE_COMPLETE, self, OnLandmarkUpgradeComplete)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmtimerCountDown.OnCompleteTimer, self, OnCompleteBuildingTimer)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmbtnFun1.OnClicked, self, OnCommitBtn1Clicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmbtnFun2.OnClicked, self, OnCommitBtn2Clicked)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.kmbtnFun3.OnClicked, self, OnCommitBtn3Clicked)
end

return UPHomeBuildingSub