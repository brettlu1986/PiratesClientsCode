-----------------------------------------------------
--File Name    : UPLandmarkUpgradeView.lua
--Author       : WuJizhou
--Create Time  : 4/18/2019, 11:21:49 AM
--Description  : UPLandmarkUpgradeView
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")

local UPLandmarkUpgradeView = luaclass("UPLandmarkUpgradeView", PrefabBase)
local UIUtils = require("UIUtils")
local LandmarkBuildingUpgradeDataTable = require("LandmarkBuildingUpgradeDataTable")
local LandmarkBuildingTypeDataTable = require("LandmarkBuildingTypeDataTable")
local BuildingDataTable = require("BuildingDataTable")
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local UIDef = require("UIDef")
local ItemDataTable = require("ItemDataTable")
local TimeUtil = require("TimeUtil")
local HomelandSystem = require("HomelandSystem")
local CurrencySystem = require("CurrencySystem")
local UIResourceDef = require("UIResourceDef")

UPLandmarkUpgradeView.ListHelper = nil
UPLandmarkUpgradeView.pbDialogFrame = nil
UPLandmarkUpgradeView.nType = nil


local function RefreshView(self, nType, nGrade, nSceneId)
    local tbBuildingTypeTemplate = LandmarkBuildingTypeDataTable:GetTemplate(nType)
    if not tbBuildingTypeTemplate then
        logerror("UPLandmarkUpgradeView, Landmark building type is illegal, nType is ", nType)
        return
    end

    local tbUpgradeTemplate = LandmarkBuildingUpgradeDataTable:GetTemplate(nType, nGrade)
    if not tbUpgradeTemplate then
        logerror(string.format("UPLandmarkUpgradeView, Landmark building upgrade template is illegal, nType is %d, nGrade is %d ",
        nType, nGrade))
        return
    end
    self.nType = nType
    local nCurrentGrade = nGrade
    local nMaxGrade = LandmarkBuildingUpgradeDataTable:GetMaxGrade(nType)
    local nNextGrade = nGrade + 1
    assert(nMaxGrade >= nNextGrade)
    local tbCurBuildingTemplate = BuildingDataTable:GetLandmarkTemplate(nSceneId, nType, nCurrentGrade)
    assert(tbCurBuildingTemplate)
    local szCurrentBuildingIcon = tbCurBuildingTemplate.szIcon
    local tbNextBuildingTemplate = BuildingDataTable:GetLandmarkTemplate(nSceneId, nType, nNextGrade)
    assert(tbNextBuildingTemplate)
    local szNextBuildingIcon = tbNextBuildingTemplate.szIcon
    local pWidgetRef = self.pWidgetRef
    -- 设置建筑图片
    UISetUtils.SetImageBrushRes(pWidgetRef.img01, szCurrentBuildingIcon:load())
    UISetUtils.SetImageBrushRes(pWidgetRef.img02, szNextBuildingIcon:load())
    -- 设置建筑名和等级
    local l10nName = tbBuildingTypeTemplate.l10nName
    local l10nTitle = L10N:Format(UITextDef.HOMELAND_MARK_BUILDING_UPGRADE_TITLE, l10nName, nCurrentGrade, nNextGrade)
    pWidgetRef.txtTitle:SetText(l10nTitle)
    -- 设置消耗时间
    local nCostSeconds = tbUpgradeTemplate.nTimeCost
    local nMinute = TimeUtil.GetTotalMinutes(nCostSeconds)
    local nSecond = TimeUtil.GetSeconds(nCostSeconds)
    pWidgetRef.txtTimeCost:SetText(string.format("%02d:%02d", nMinute, nSecond))
    -- 设置消耗道具
    local nCostCurrencyId = tbUpgradeTemplate.nCurrencyId
    local nCostCurrencyCount = tbUpgradeTemplate.nCurrencyCost
    local tbResTemplate = ItemDataTable:GetResTemplate(nCostCurrencyId)
    local szCurrencyIcon = tbResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency, szCurrencyIcon:load())

    local bCanUpgrade = true
    local nOwnedCount = CurrencySystem:GetCurrencyCount(nCostCurrencyId)
    if nOwnedCount < nCostCurrencyCount then
        bCanUpgrade = bCanUpgrade and false
        pWidgetRef.txtCurrency:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
    else
        bCanUpgrade = bCanUpgrade and true
        pWidgetRef.txtCurrency:SetColorAndOpacity(UIResourceDef.COLOR.GREEN.SLATE_COLOR)
    end
    pWidgetRef.txtCurrency:SetText(nCostCurrencyCount)
    --设置前置建筑要求
    local tbPrerequisiteLandmarks = tbUpgradeTemplate.tbPrerequisiteLandmarks
    local nPrerequisiteLandmarkType = nil
    local nPrerequisiteLandmarkGrade = nil
    if tbPrerequisiteLandmarks and #tbPrerequisiteLandmarks > 0 then
        local tbPrerequisiteLandmark = tbPrerequisiteLandmarks[1]
        nPrerequisiteLandmarkType = tbPrerequisiteLandmark.nPrerequisiteLandmarkType
        nPrerequisiteLandmarkGrade = tbPrerequisiteLandmark.nPrerequisiteLandmarkGrade
    end
    if nPrerequisiteLandmarkType then
        pWidgetRef.txtPrerequisite:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        local tbPrerequisiteBuildingTypeTemplate = LandmarkBuildingTypeDataTable:GetTemplate(nPrerequisiteLandmarkType)
        local l10nPrerequisite =  L10N:Format(UITextDef.HOMELAND_MARK_BUILDING_UPGRADE_PREREQUISITE, tbPrerequisiteBuildingTypeTemplate.l10nName,
            nPrerequisiteLandmarkGrade)
            pWidgetRef.txtPrerequisite:SetText(l10nPrerequisite)
        local nActuralGrade = HomelandSystem:GetLandmarkGrade(nPrerequisiteLandmarkType)
        if nActuralGrade < nPrerequisiteLandmarkGrade then
            bCanUpgrade = bCanUpgrade and false
            pWidgetRef.txtPrerequisite:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
        else
            bCanUpgrade = bCanUpgrade and true
            pWidgetRef.txtPrerequisite:SetColorAndOpacity(UIResourceDef.COLOR.GREEN.SLATE_COLOR)
        end
    else
        pWidgetRef.txtPrerequisite:SetVisibility(ESlateVisibility.Collapsed)
    end

    if bCanUpgrade then
        pWidgetRef.btnUpgrade:SetIsEnabled(true)
    else
        pWidgetRef.btnUpgrade:SetIsEnabled(false)
    end

    -- 设置解锁内容
    local tbUnlockContents = tbUpgradeTemplate.tbUnlockContents
    local tbDatas = {}
    for _, l10nUnlockContent in ipairs(tbUnlockContents) do
        local tbData = {}
        tbData.l10nContent = l10nUnlockContent
        table.insert(tbDatas, tbData)
    end
    self.ListHelper:SetData(tbDatas)
end

local function ConfirmUpgrade(self)
    HomelandSystem:RequestLandmarkUpgrade(self.nType)
    self.pbDialogFrame:HideDialog()
end

local function OnUpgradeBtnClicked(self)
    local Dialog = UIUtils.CreateDialog(L10N.NullString)
    Dialog:SetMessage(UITextDef.HOMELAND_MARK_BUILDING_UPGRADE_CONFIRM_CONTENT)
    Dialog:SetPositiveButtonVisible(true)
    Dialog:SetPositiveText(UITextDef.HOMELAND_MARK_BUILDING_UPGRADE_CONFIRM)
    Dialog:SetPositiveButtonCallback(ConfirmUpgrade, self)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

function UPLandmarkUpgradeView:SetViewData(nType, nGrade, nSceneId)
    assert(nType)
    assert(nGrade)
    RefreshView(self, nType, nGrade, nSceneId)
end

function UPLandmarkUpgradeView:SetDialogFrame(pbDialogFrame)
    self.pbDialogFrame = pbDialogFrame
end

----------life cycle----------
function UPLandmarkUpgradeView:OnCreate()

end

-- function UPLandmarkUpgradeView:OnDestroy()
-- end

function UPLandmarkUpgradeView:OnLoad()
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listUnlockContent, {}, UIDef.UP_LANDMARK_UPGRADE_UNLOCK_CONTENT_ITEM)
end

function UPLandmarkUpgradeView:OnUnload()
    self.ListHelper:Uninit()
end

-- function UPLandmarkUpgradeView:OnEnter()
-- end

-- function UPLandmarkUpgradeView:OnShow()
-- end

-- function UPLandmarkUpgradeView:OnHide()
-- end

-- function UPLandmarkUpgradeView:OnExit()
-- end

function UPLandmarkUpgradeView:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpgrade.OnClicked, self, OnUpgradeBtnClicked)
end

-- function UPLandmarkUpgradeView:OnUnbindEvent(EventHelper)
-- end

return UPLandmarkUpgradeView