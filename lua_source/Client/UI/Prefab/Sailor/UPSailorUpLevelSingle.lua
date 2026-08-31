-----------------------------------------------------
--File Name    : UPSailorUpLevelSingle.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-17
--Description  :
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSailorUpLevelSingle = luaclass("UPSailorUpLevelSingle", PrefabBase)

local L10N = require("L10N")
local UIUtils = require("UIUtils")
local MathUtil = require("MathUtil")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local EventManager = require("EventManager")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local ClientEventDef = require("ClientEventDef")
local PropertyComboSystem = require("PropertyComboSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local MIN_COUNT = 1             -- 最小选择数量
local MIN_GRADE = 0             -- 水手最低等级
local MAX_GRADE = 4             -- 水手最高等级
local PROPERTY_MAX_COUNT = 3    -- 最大属性条数
local SINGLE_COLUMN_SPAN = 0    -- 显示单个水手时参数
local COMMON_COLUMN_SPAN = 3    -- 显示新老水手时参数
local SAILOR_GRADE_ICONS = UIResourceDef.SAILOR_GRADE_ICONS
local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE.SLATE_COLOR
local SLATE_COLOR_RED = UIResourceDef.COLOR.RED.SLATE_COLOR

UPSailorUpLevelSingle.DialogFrame = nil
UPSailorUpLevelSingle.nSailorId = -1
UPSailorUpLevelSingle.nUpgradedSailorId = -1
UPSailorUpLevelSingle.nCount = MIN_COUNT
UPSailorUpLevelSingle.nMaxCount = MIN_COUNT
UPSailorUpLevelSingle.nCurrencyId = -1
UPSailorUpLevelSingle.nBaseUpgradeCurrencyAmount = 0
UPSailorUpLevelSingle.nBaseUpgradeToTopCurrencyAmount = 0
UPSailorUpLevelSingle.nUpgradeToTopCurrencyAmount = 0
UPSailorUpLevelSingle.bUpgradeEnough = false
UPSailorUpLevelSingle.bUpgradeToTopEnough = false
UPSailorUpLevelSingle.l10nName = nil
UPSailorUpLevelSingle.nAccumulativeDegradeCurrencyAmount = nil
UPSailorUpLevelSingle.bEquippedMode = false

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function ShowCurrencyNotEnoughDialog(self)
    local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_CURRENCY_NOT_ENOUGH_DIALOG_TITLE")
    local l10nMessage = UISetUtils.GetL10NTextByKey("SAILOR_CURRENCY_NOT_ENOUGH_DIALOG_MESSAGE")
    UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
        self.DialogFrame:HideDialog()
        EventManager:OnFireEvent(ClientEventDef.EV_ON_SHOW_SAILOR_SUMMONING)
    end)
end

local function UpdateCurrencyCountInfo(self)
    local pWidgetRef = self.pWidgetRef
    local nCurrencyAmount = CurrencySystem:GetCurrencyCount(self.nCurrencyId)
    local nUpgradeCurrencyAmount = self.nBaseUpgradeCurrencyAmount * self.nCount
    self.nUpgradeToTopCurrencyAmount = self.nBaseUpgradeToTopCurrencyAmount * self.nCount
    pWidgetRef.txtCurrencyCount:SetText(nCurrencyAmount)
    pWidgetRef.txtUpLevelCurrencyCount:SetText(nUpgradeCurrencyAmount)
    pWidgetRef.txtUpLevelToTopCurrencyCount:SetText(self.nUpgradeToTopCurrencyAmount)

    self.bUpgradeEnough = nCurrencyAmount >= nUpgradeCurrencyAmount
    self.bUpgradeToTopEnough = nCurrencyAmount >= self.nUpgradeToTopCurrencyAmount
    pWidgetRef.txtUpLevelCurrencyCount:SetColorAndOpacity(self.bUpgradeEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
    pWidgetRef.txtUpLevelToTopCurrencyCount:SetColorAndOpacity(self.bUpgradeToTopEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
end

local function UpdateCurrencyBaseInfo(self, tbTemplate)
    self.nCurrencyId = tbTemplate.nCurrencyId
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(self.nCurrencyId)
    local pCurrencySmallIcon = szCurrencySmallIcon:load()

    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency, pCurrencySmallIcon)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgUpLevelCurrency, pCurrencySmallIcon)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgUpLevelToTopCurrency, pCurrencySmallIcon)

    self.nBaseUpgradeCurrencyAmount = tbTemplate.nUpgradeCurrencyAmount
    self.nBaseUpgradeToTopCurrencyAmount = tbTemplate.nUpgradeToTopCurrencyAmount
end

-- 刷新属性
local function UpdateProperties(self, tbTemplateLeft, tbTemplateRight)
    local nPropertyComboIdLeft = tbTemplateLeft.nPropertyComboId
    local nPropertyComboIdRight = tbTemplateRight and tbTemplateRight.nPropertyComboId
    local tbDisplayInfoListLeft = PropertyComboSystem:GetPropertyComboDisplayInfoList(nPropertyComboIdLeft)
    local tbDisplayInfoListRight = nPropertyComboIdRight and PropertyComboSystem:GetPropertyComboDisplayInfoList(nPropertyComboIdRight) or {}
    local tbPropertiesData = {}
    for i = 1, PROPERTY_MAX_COUNT do
        local tbDisplayInfoLeft = tbDisplayInfoListLeft[i]
        local tbDisplayInfoRight = tbDisplayInfoListRight[i]
        if tbDisplayInfoLeft then
            tbPropertiesData[i] = {
                l10nDisplayName = tbDisplayInfoLeft.l10nDisplayName,
                szOldDisplayValue = tbDisplayInfoLeft.szDisplayValue,
                szNewDisplayValue = tbDisplayInfoRight and tbDisplayInfoRight.szDisplayValue
            }
        end
    end
    self.tbListHelper:SetData(tbPropertiesData)
end

-- 刷新控件显隐
local function UpdateWidgetVisible(self, tbTemplate)
    local nGrade = tbTemplate.nGrade
    local pWidgetRef = self.pWidgetRef
    -- 当前未4、5级水手时，隐藏升级至5级按钮
    if nGrade >= MAX_GRADE - 1 then
        pWidgetRef.btnUpLevelToTop:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxUpLevelToTop:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnUpLevelToTop:SetVisibility(ESlateVisibility.Visible)
        pWidgetRef.hboxUpLevelToTop:SetVisibility(ESlateVisibility.HitTestInvisible)
    end

    -- 当前5级水手时，隐藏升级按钮，切隐藏右侧水手
    if nGrade == MAX_GRADE then
        pWidgetRef.btnUpLevel:SetIsEnabled(false)
        pWidgetRef.txtUpLevel:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_TOP"))
        pWidgetRef.hboxUpLevel:SetVisibility(ESlateVisibility.Collapsed)
        -- 隐藏右侧水手
        pWidgetRef.imgArrow:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgIconRight:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.imgGradeRight:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtNameRight:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.txtCountRight:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.sizeFx:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hboxCount.Slot:SetColumnSpan(SINGLE_COLUMN_SPAN)
    else
        pWidgetRef.btnUpLevel:SetIsEnabled(true)
        pWidgetRef.txtUpLevel:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_SINGLE"))
        pWidgetRef.hboxUpLevel:SetVisibility(ESlateVisibility.HitTestInvisible)
        -- 显示右侧水手
        pWidgetRef.imgArrow:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.imgIconRight:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.imgGradeRight:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtNameRight:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.txtCountRight:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.sizeFx:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.hboxCount.Slot:SetColumnSpan(COMMON_COLUMN_SPAN)
    end

    -- 当前为1级水手时，隐藏重置按钮
    if nGrade == MIN_GRADE then
        pWidgetRef.btnReset:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnReset:SetVisibility(ESlateVisibility.Visible)
    end

    -- 上阵水手升级默认一直隐藏数据控制UI和重置UI
    if self.bEquippedMode then
        self.pWidgetRef.hboxCount:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.btnReset:SetVisibility(ESlateVisibility.Collapsed)
    end
end

-- 刷新当前水手信息
local function UpdateSailorInfo(self)
    local pWidgetRef = self.pWidgetRef
    local nSailorIdLeft = self.nSailorId
    local tbTemplateLeft = ItemSystem:GetItemTemplate(nSailorIdLeft)
    pWidgetRef.txtNameLeft:SetText(tbTemplateLeft.l10nName)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgGradeLeft, SAILOR_GRADE_ICONS[tbTemplateLeft.nGrade + 1]:load())
    local tbResTemplateLeft = ItemSystem:GetItemResTemplate(nSailorIdLeft)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgIconLeft, tbResTemplateLeft.szIconPath:load())
    local nCountLeft = ItemSystem:GetItemCount(nSailorIdLeft)
    pWidgetRef.txtCountLeft:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_OWNED_FORMAT"), nCountLeft))
    self.nMaxCount = nCountLeft
    self.l10nName = tbTemplateLeft.l10nName
    self.nAccumulativeDegradeCurrencyAmount = tbTemplateLeft.nAccumulativeDegradeCurrencyAmount

    local nSailorIdRight = tbTemplateLeft.nUpgradeTo
    local tbTemplateRight = ItemSystem:GetItemTemplate(nSailorIdRight)
    if tbTemplateRight then
        pWidgetRef.txtNameRight:SetText(tbTemplateRight.l10nName)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgGradeRight, SAILOR_GRADE_ICONS[tbTemplateRight.nGrade + 1]:load())
        local nCountRight = ItemSystem:GetItemCount(nSailorIdRight)
        pWidgetRef.txtCountRight:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_OWNED_FORMAT"), nCountRight))
        local tbResTemplateRight = ItemSystem:GetItemResTemplate(nSailorIdRight)
        UISetUtils.SetImageBrushRes(pWidgetRef.imgIconRight, tbResTemplateRight.szIconPath:load())
    end

    UpdateWidgetVisible(self, tbTemplateLeft)
    UpdateProperties(self, tbTemplateLeft, tbTemplateRight)
    UpdateCurrencyBaseInfo(self, tbTemplateLeft)
    UpdateCurrencyCountInfo(self)
end

local function UpdateCount(self, nCount)
    self.nCount = MathUtil.Clamp(nCount, 1, self.nMaxCount)
    self.pWidgetRef.txtCount:SetText(self.nCount)
    UpdateCurrencyCountInfo(self)
end

-- 数量增加
local function OnClickedBtnMinus(self)
    UpdateCount(self, self.nCount - 1)
end

-- 数量减少
local function OnClickedBtnPlus(self)
    UpdateCount(self, self.nCount + 1)
end

-- 最大数量
local function OnClickedBtnMax(self)
    UpdateCount(self, self.nMaxCount)
end

-- 升到最高级（5级）
local function OnClickedBtnUpLevelToTop(self)
    if self.bUpgradeToTopEnough then
        local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_UP_LEVEL_TO_TOP_DIALOG_TITLE")
        local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_UP_LEVEL_TO_TOP_DIALOG_MESSAGE"), self.nUpgradeToTopCurrencyAmount)
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
            if self.bEquippedMode then
                GetSailorComponent():RequestEquippedSailorUpgrade(self.nSailorId, self.nCount, true, self.nSailorCategory, self.nSlotIndex)
            else
                GetSailorComponent():RequestSailorUpgrade(self.nSailorId, self.nCount, true)
            end
        end)
    else
        ShowCurrencyNotEnoughDialog(self)
    end
end

-- 升1级
local function OnClickedBtnLevelUp(self)
    if self.bUpgradeEnough then
        if self.bEquippedMode then
            GetSailorComponent():RequestEquippedSailorUpgrade(self.nSailorId, self.nCount, false, self.nSailorCategory, self.nSlotIndex)
        else
            GetSailorComponent():RequestSailorUpgrade(self.nSailorId, self.nCount, false)
        end
    else
        ShowCurrencyNotEnoughDialog(self)
    end
end

local function OnDisableClickedBtnLevelUp(self)
    UIUtils.ShowToastWithKey("SAILOR_TOP_GRADE")
end

-- 重置
local function OnClickedBtnReset(self)
    local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_RESET_DIALOG_TITLE")
    local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_RESET_DIALOG_MESSAGE"), self.nCount, self.l10nName, self.nAccumulativeDegradeCurrencyAmount * self.nCount)
    UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
        GetSailorComponent():RequestSailorDegrade(self.nSailorId, self.nCount)
    end)
end

local function PlayLevelUpAnimation(self)
    self:StopAnimation("animItemLevelStatic")
    self:PlayAnimation("animItemLevelUp", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        self:PlayAnimation("animItemLevelStatic", 0, 1, EUMGSequencePlayMode.Forward, 1)
    end)
end

local function OnReceiveSailorUpgradeResult(self, nSailorId, nUpgradeSailorId)
    if nSailorId == self.nSailorId then
        self:SetSailorId(nUpgradeSailorId)
        PlayLevelUpAnimation(self)
    end
end

local function OnReceiveSailorDegradeResult(self, nSailorId, nDegradedSailorId)
    if nSailorId == self.nSailorId then
        self:SetSailorId(nDegradedSailorId)
    end
end

local function OnReceiveUpgradeEquippedSailorResult(self, tbUpgradedSailorInfos, bOneKeyUpgrade)
    if not bOneKeyUpgrade then
        local tbUpgradedInfo = tbUpgradedSailorInfos[1]
        if tbUpgradedInfo.nSailorId  == self.nSailorId then
            self:SetSailorId(tbUpgradedInfo.nUpgradeTo)
            PlayLevelUpAnimation(self)
        end
    end
end

function UPSailorUpLevelSingle:OnLoad()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.listProperties)
    self:PlayAnimation("animItemLevelStatic", 0, 1, EUMGSequencePlayMode.Forward, 1)
end

function UPSailorUpLevelSingle:OnUnload()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UPSailorUpLevelSingle:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPlus.OnClicked, self, OnClickedBtnPlus)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMax.OnClicked, self, OnClickedBtnMax)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpLevelToTop.OnClicked, self, OnClickedBtnUpLevelToTop)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpLevel.OnClicked, self, OnClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpLevel.OnDisableClicked, self, OnDisableClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReset.OnClicked, self, OnClickedBtnReset)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT, self, OnReceiveSailorUpgradeResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, OnReceiveSailorDegradeResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UPGRADE_EQUIPPED_SAILOR_RESULT, self, OnReceiveUpgradeEquippedSailorResult)
end

-- 启用装备中水手升级模式
function UPSailorUpLevelSingle:EnableEquippedMode(nSailorCategory, nSlotIndex)
    self.nSailorCategory = nSailorCategory
    self.nSlotIndex = nSlotIndex
    self.bEquippedMode = true
end

function UPSailorUpLevelSingle:SetSailorId(nSailorId)
    self.nSailorId = nSailorId
    UpdateSailorInfo(self)
    UpdateCount(self, self.nCount)
end

function UPSailorUpLevelSingle:SetDialogFrame(DialogFrame)
    self.DialogFrame = DialogFrame
end

return UPSailorUpLevelSingle