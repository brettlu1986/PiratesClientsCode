-----------------------------------------------------
--File Name    : ULHomeShipPartResearchChoose.lua
--Author       : zhiyuan
--Create Time  : 2019-05-16
--Description  : 零件研发的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULHomeShipPartResearchChoose = luaclass("ULHomeShipPartResearchChoose", UILogicBase)

local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemDataTable = require("BattleItemDataTable")
local UITextDef = require("UITextDef")
local SelfVerticalListHelper = require("SelfVerticalListHelper")
local ItemCategoryDef = require("ItemCategoryDef")
local ItemDataTable = require("ItemDataTable")
local HomelandSystem = require("HomelandSystem")
local ItemResearchDataTable = require("ItemResearchDataTable")
local ItemSystem = require("ItemSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local CurrencySystem = require("CurrencySystem")
local UISetUtils = require("UISetUtils")
local ClientEventDef = require("ClientEventDef")
local UIResourceDef = require("UIResourceDef")
local UIUtils = require("UIUtils")
local TimeUtil = require("TimeUtil")
local L10N = require("L10N")
local ShipPartTypeDef = require("ShipPartTypeDef")

local DEFAULT_CHOOSE_INDEX = 1

local STATUS_CLICK_OPEN = 1
local STATUS_CLICK_CLOSE = 2

local SUB_CATEGORY_MAX = ShipPartTypeDef.Max

local ANIM_NAME = "animSelect"

ULHomeShipPartResearchChoose.nCurrentStatus = nil
ULHomeShipPartResearchChoose.nCurrentIndex = nil
ULHomeShipPartResearchChoose.tbTemplates = nil

ULHomeShipPartResearchChoose.nResearchItemTemplateId = nil

ULHomeShipPartResearchChoose.ListHelper = nil

local function GetHomelandItemSystem()
    return HomelandSystem:GetSubSystem("HomelandItemSystem")
end

local function ShowCommitDialog(self)
    local Dialog = UIUtils.CreateDialog(L10N.NullString)
    local nItemTemplateId = self.nResearchItemTemplateId
    local l10nFormat = UISetUtils.GetL10NTextByKey("HOMELAND_RESEARCH_COMMIT_FORMAT")
    local tbTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    Dialog:SetMessage(L10N:Format(l10nFormat, tbTemplate.l10nName))
    Dialog:SetPositiveButtonVisible(true)
    --Dialog:SetPositiveText(UISetUtils.GetL10NTextByKey("LOBBYCHAT_TEAMING_TITLE"))
    local HomelandItemSystem = GetHomelandItemSystem()

    Dialog:SetPositiveButtonCallback(function() HomelandItemSystem:RequestResearchItem(nItemTemplateId) end, self)
    Dialog:SetNegativeButtonVisible(false)
    Dialog:ShowDialog()
end

local function OnClickResearch(self)
    local HomelandItemSystem = GetHomelandItemSystem()
    local nItemTemplateId = self.nResearchItemTemplateId
    if HomelandItemSystem:HasSameCategoryItemResearching(nItemTemplateId) then
        UIUtils.ShowToastWithKey("HOME_RESEARCH_FAILED_SHIP_PART_RESEARCHING")
    else
        ShowCommitDialog(self)
    end
end

local function ShowLockState(self, nGrade)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.Collapsed)

    pWidgetRef.kmtxtNeedGrade:SetText("Lv."..nGrade)
    pWidgetRef.btnYes:SetIsEnabled(false)
end

local function ShowAlreadyOwned(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Hidden)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowTimer(self, nRemainSeconds)
    local PRECISION = 2
    local pWidget = self.pWidgetRef
    pWidget.kmtimerCountDown.MinTimeUnit = EMinTimeUnit.Second
    pWidget.kmtimerCountDown:SetPrecision(PRECISION)
    local DELAY_TIME = 1
    local TIMEFORMAT = {
        L10N:ToString(UITextDef.UI_LANDMARK_UPGRADE_COUNT_DOWN_MINUTE),
        L10N:ToString(UITextDef.UI_LANDMARK_UPGRADE_COUNT_DOWN_SECOND),
    }
    pWidget.kmtimerCountDown:StartTimer(nRemainSeconds, DELAY_TIME, TIMEFORMAT, EMinTimeUnit.Second)
end

local function ShowIsResearching(self, nCompleteTime)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Hidden)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.HitTestInvisible)

    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRemainSeconds = nCompleteTime - now
    ShowTimer(self, nRemainSeconds)
end

local function ShowCanResearch(self, tbItemResearchTemplate)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.btnYes:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.hboxMoney:SetVisibility(ESlateVisibility.HitTestInvisible)
    pWidgetRef.hboxNeedLv:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.ktxtNeed:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.hboxTime:SetVisibility(ESlateVisibility.Collapsed)

    local nCurrencyId = tbItemResearchTemplate.nCurrencyId
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency, szCurrencySmallIcon:load())
    local nCurrencyCost = tbItemResearchTemplate.nCurrencyCost
    pWidgetRef.txtCurrency:SetText(nCurrencyCost)
    local nCurrentCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
    if nCurrentCount >= nCurrencyCost then
        pWidgetRef.txtCurrency:SetColorAndOpacity(UIResourceDef.COLOR.YELLOW.SLATE_COLOR)
        pWidgetRef.btnYes:SetIsEnabled(true)
    else
        pWidgetRef.txtCurrency:SetColorAndOpacity(UIResourceDef.COLOR.RED.SLATE_COLOR)
        pWidgetRef.btnYes:SetIsEnabled(false)
    end
    local nTimeCost = tbItemResearchTemplate.nTimeCost
    if nTimeCost > 0 then
        local szTime = TimeUtil.GetTimeString(nTimeCost)
        pWidgetRef.kmtxtTotalTime:SetText(szTime)
    else
        pWidgetRef.hboxTotalTime:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function RefreshBtnActivateState(self)
    local nTemplateId = self.nResearchItemTemplateId
    local tbItemResearchTemplate = ItemResearchDataTable:GetTemplate(nTemplateId)
    local nUnlockLandmarkType = tbItemResearchTemplate.nUnlockLandmarkType
    local nUnlockLandmarkGrade = tbItemResearchTemplate.nUnlockLandmarkGrade
    local nCurrentGrade = HomelandSystem:GetLandmarkGrade(nUnlockLandmarkType)
    if ItemSystem:GetItemCount(nTemplateId) > 0 then
        ShowAlreadyOwned(self)
    else
        if nCurrentGrade < nUnlockLandmarkGrade then
            ShowLockState(self, nUnlockLandmarkGrade)
        else
            local HomelandItemSystem = GetHomelandItemSystem()
            local tbResearchingItemData = HomelandItemSystem:GetResearchingItemData(nTemplateId)
            if tbResearchingItemData ~= nil then
                ShowIsResearching(self, tbResearchingItemData.nCompleteTime)
            else
                ShowCanResearch(self, tbItemResearchTemplate)
            end
        end
    end
end

local function ShowPartData(self, nIndex)
    local tbTemplate = self.tbTemplates[nIndex]
    if tbTemplate then
        self.nResearchItemTemplateId = tbTemplate.nId
        self.pWidgetRef.txtDetailName:SetText(tbTemplate.l10nName)
        for i, nTemplateId in ipairs(tbTemplate.tbBattleItemIdList) do
            local tbBattleTemplate = BattleItemDataTable:GetTemplate(nTemplateId)
            self.pWidgetRef["kmtxtEffectDesc"..i]:SetText(tbBattleTemplate.l10nDesc)
        end
        RefreshBtnActivateState(self)
    end
end

local function OnListSelectedChanged(self, nIndex)
    ShowPartData(self, nIndex)
end

local function SetChooseData(self, nSubCategory)
    local l10nSubCategoryName = BattleItemDataTable:GetSubCategoryName(BattleItemCategoryDef.SHIP_PART, nSubCategory)
    self.pWidgetRef["kmtxtPartType"..nSubCategory]:SetText(l10nSubCategoryName)

    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_OPEN then
        self.pWidgetRef["kmtxtState"..nSubCategory]:SetText(UITextDef.UI_HOMELAND_RESEARCH_OPEN)
        self.pWidgetRef["btnPartType"..nSubCategory]:SetVisibility(ESlateVisibility.Visible)
    elseif nCurrentStatus == STATUS_CLICK_CLOSE then
        if self.nCurrentIndex ~= nSubCategory then
            self.pWidgetRef["btnPartType"..nSubCategory]:SetVisibility(ESlateVisibility.Collapsed)
        else
            self.pWidgetRef["kmtxtState"..nSubCategory]:SetText(UITextDef.UI_HOMELAND_RESEARCH_CLOSE)
            self.pWidgetRef["btnPartType"..nSubCategory]:SetVisibility(ESlateVisibility.Visible)
        end
    end
end

local function CollapsedDetail(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrAtt:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.listPart:SetVisibility(ESlateVisibility.Collapsed)
end

local function ShowDetail(self)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef.bdrAtt:SetVisibility(ESlateVisibility.Visible)
    pWidgetRef.listPart:SetVisibility(ESlateVisibility.Visible)

    local nCurrentIndex = self.nCurrentIndex
    local tbAllTemplates = ItemDataTable:GetTemplatesByCategory(ItemCategoryDef.SHIP_PART)
    local tbTemplates = {}
    for _, v in pairs(tbAllTemplates) do
        if v.nSubCategory == nCurrentIndex then
            table.insert(tbTemplates, v)
        end
    end

    table.sort(tbTemplates, function(A, B) return A.nId < B.nId end)

    self.tbTemplates = tbTemplates
    self.ListHelper:SetData(tbTemplates)
    self.ListHelper:SetSelectedIndex(DEFAULT_CHOOSE_INDEX)
end

local function RefreshChooseDatas(self)
    for i = 1, SUB_CATEGORY_MAX do
        SetChooseData(self, i)
    end
    local nCurrentStatus = self.nCurrentStatus

    if nCurrentStatus == STATUS_CLICK_OPEN then
        CollapsedDetail(self)
    elseif nCurrentStatus == STATUS_CLICK_CLOSE then
        ShowDetail(self)
    end
end

local function ChangeStatus(self, nStatus, nIndex)
    self.nCurrentStatus = nStatus
    self.nCurrentIndex = nIndex
end

local function PlayOpenAnimation(self)
    self.Owner:PlayAnimation(ANIM_NAME, 0, 1, EUMGSequencePlayMode.Forward, 1)
end

local function PlayCloseAnimation(self)
    self.Owner:PlayAnimation(ANIM_NAME, 0, 1, EUMGSequencePlayMode.Reverse, 1)
end

local function OnClickButton(self, nIndex)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_OPEN then
        ChangeStatus(self, STATUS_CLICK_CLOSE, nIndex)
        PlayOpenAnimation(self)
    elseif nCurrentStatus == STATUS_CLICK_CLOSE then
        ChangeStatus(self, STATUS_CLICK_OPEN)
        PlayCloseAnimation(self)
    end

    RefreshChooseDatas(self)
end

local function OnHomeItemResearchBegin(self, nTemplateId)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_CLOSE then
        if self.nResearchItemTemplateId == nTemplateId then
            RefreshBtnActivateState(self)
        end
    end
end

local function OnHomeItemResearchComplete(self, nTemplateId)
    local nCurrentStatus = self.nCurrentStatus
    if nCurrentStatus == STATUS_CLICK_CLOSE then
        if self.nResearchItemTemplateId == nTemplateId then
            RefreshBtnActivateState(self)
        end
    end
end

function ULHomeShipPartResearchChoose:OnShow()
    self.nCurrentStatus = STATUS_CLICK_OPEN
    RefreshChooseDatas(self)
    PlayCloseAnimation(self)
end

function ULHomeShipPartResearchChoose:OnLoad()
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, self.pWidgetRef.listPart)
    self.ListHelper.OnSelectedChangedDelegate:Bind(OnListSelectedChanged, self)
end

function ULHomeShipPartResearchChoose:OnBindEvent(EventHelper)
    for i = 1, SUB_CATEGORY_MAX do
        EventHelper:RegisterCppDelegate(self.pWidgetRef["btnPartType"..i].OnClicked, self, function() OnClickButton(self, i) end)
    end
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnYes.OnClicked, self, OnClickResearch)

    EventHelper:RegisterEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_BEGIN, self, OnHomeItemResearchBegin)
    EventHelper:RegisterEvent(ClientEventDef.EV_HOME_ITEM_RESEARCH_COMPLETE, self, OnHomeItemResearchComplete)
end

function ULHomeShipPartResearchChoose:OnUnload()
    self.ListHelper:Uninit()
end

return ULHomeShipPartResearchChoose