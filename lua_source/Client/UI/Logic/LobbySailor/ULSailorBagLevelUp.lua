local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSailorBagLevelUp = luaclass("ULSailorBagLevelUp", UILogicBase)

local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local MathUtil = require("MathUtil")
local UIUtils = require("UIUtils")
local UIDef = require("UIDef")
local L10N = require("L10N")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local ClientEventDef = require("ClientEventDef")
local EventManager = require("EventManager")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local Timer = require("Timer")

local MIN_COUNT = 1             -- 最小选择数量
local MIN_GRADE = 0             -- 水手最低等级
local MAX_GRADE = 4             -- 水手最高等级

local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE.SLATE_COLOR
local SLATE_COLOR_RED = UIResourceDef.COLOR.RED.SLATE_COLOR
local szAnimBtnLoop = "animLevelUpLoop"
local szAnimReset = "animFxSailorReset"
local szAnimResetIn = "animSailorResetIn"
local szAnimLevelUp = "animFxSailorLevelUp"
local tbSailorTypeLevelUp = 
{
    "imgFxLevelUpFlow01",
    "imgFxLevelUpFlow02",
    "imgFxLevelUpFlow03"
}

local RESET_ANIM_TIMER = "ResetAnimTimer"
local nResetDelay = 0.5
local nDelayTime = 0.6
local DELAY_BTN_LOOP = "DelayBtnLoopTimer"

ULSailorBagLevelUp.nSailorId = -1
ULSailorBagLevelUp.nCurrencyId = -1
ULSailorBagLevelUp.nCount = MIN_COUNT
ULSailorBagLevelUp.nMaxCount = MIN_COUNT
ULSailorBagLevelUp.nAccumulativeDegradeCurrencyAmount = nil
ULSailorBagLevelUp.nBaseUpgradeCurrencyAmount = 0
ULSailorBagLevelUp.nBaseUpgradeToTopCurrencyAmount = 0
ULSailorBagLevelUp.nUpgradeToTopCurrencyAmount = 0
ULSailorBagLevelUp.bUpgradeEnough = false
ULSailorBagLevelUp.bUpgradeToTopEnough = false

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function PlayBtnLoopByWidgetsVisible(self)
    local bResetVisble = self.pWidgetRef.hbREset:IsVisible()
    local bUpgradeVisible = self.pWidgetRef.hbUpgrade:IsVisible()
    local bUpgradeTopVisible = self.pWidgetRef.hbUpgradeToTop:IsVisible()

    if bResetVisble or bUpgradeVisible or bUpgradeTopVisible then  
        Timer.StartOwnerTimer(self, DELAY_BTN_LOOP, function()
            if self.pWidgetRef then
                self.Owner:PlayAnimation(szAnimBtnLoop, 0, 0,  EUMGSequencePlayMode.Forward, 1)
                self.pWidgetRef.UpgradeFx01:SetVisibility(bUpgradeVisible and ESlateVisibility.SelfHitTestInvisible or 
                    ESlateVisibility.Collapsed)
                self.pWidgetRef.UpgradeFx02:SetVisibility(bUpgradeTopVisible and ESlateVisibility.SelfHitTestInvisible or 
                    ESlateVisibility.Collapsed)
            end
        end, nDelayTime)
    else  
        self.Owner:StopAnimation(szAnimBtnLoop)
        self.pWidgetRef.UpgradeFx01:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.UpgradeFx02:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function ShowCurrencyNotEnoughDialog(self)
    local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_CURRENCY_NOT_ENOUGH_DIALOG_TITLE")
    local l10nMessage = UISetUtils.GetL10NTextByKey("SAILOR_CURRENCY_NOT_ENOUGH_DIALOG_MESSAGE")
    UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBYSAILOR_TO_PRE)
        EventManager:OnFireEvent(ClientEventDef.EV_LOBBYSAILOR_TO_NEXT, UIDef.UI_LOBBY_SAILOR_SUMMONING)
    end)
end

-- 刷新控件显隐
local function UpdateWidgetVisible(self, tbTemplate)
    local nGrade = tbTemplate.nGrade
    local pWidgetRef = self.pWidgetRef
    -- 当前未4、5级水手时，隐藏升级至5级按钮
    if nGrade >= MAX_GRADE - 1 then
        pWidgetRef.hbUpgradeToTop:SetVisibility(ESlateVisibility.Collapsed)
        self.pWidgetRef.UpgradeFx02:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.hbUpgradeToTop:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

    -- 当前5级水手时，隐藏升级按钮，切隐藏右侧水手
    if nGrade == MAX_GRADE then
        pWidgetRef.btnUpgrade:SetIsEnabled(false)
        pWidgetRef.hbUpgrade:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnUpgrade:SetIsEnabled(true)
        pWidgetRef.hbUpgrade:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtLevelUp:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_SINGLE"))
    end

    -- 当前为1级水手时，隐藏重置按钮
    if nGrade == MIN_GRADE then
        pWidgetRef.hbREset:SetVisibility(ESlateVisibility.Collapsed)
    else
        if pWidgetRef.hbREset:IsVisible() == false then
            self.Owner:PlayAnimation(szAnimResetIn, 0, 1,  EUMGSequencePlayMode.Forward, 1)
            pWidgetRef.hbREset:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end

    PlayBtnLoopByWidgetsVisible(self)
end

local function UpdateCurrencyCountInfo(self)
    local pWidgetRef = self.pWidgetRef
    local nCurrencyAmount = CurrencySystem:GetCurrencyCount(self.nCurrencyId)
    local nUpgradeCurrencyAmount = self.nBaseUpgradeCurrencyAmount * self.nCount
    self.nUpgradeToTopCurrencyAmount = self.nBaseUpgradeToTopCurrencyAmount * self.nCount
    pWidgetRef.txtCount:SetText(nUpgradeCurrencyAmount)
    pWidgetRef.txtTopCount:SetText(self.nUpgradeToTopCurrencyAmount)

    self.bUpgradeEnough = nCurrencyAmount >= nUpgradeCurrencyAmount
    self.bUpgradeToTopEnough = nCurrencyAmount >= self.nUpgradeToTopCurrencyAmount
    pWidgetRef.txtCount:SetColorAndOpacity(self.bUpgradeEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
    pWidgetRef.txtTopCount:SetColorAndOpacity(self.bUpgradeToTopEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
end

local function UpdateCurrencyBaseInfo(self, tbTemplate)
    self.nCurrencyId = tbTemplate.nCurrencyId
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(self.nCurrencyId)
    local pCurrencySmallIcon = szCurrencySmallIcon:load()

    self.l10nName = tbTemplate.l10nName
    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgMoney, pCurrencySmallIcon)
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgTopMoney, pCurrencySmallIcon)

    self.nBaseUpgradeCurrencyAmount = tbTemplate.nUpgradeCurrencyAmount
    self.nBaseUpgradeToTopCurrencyAmount = tbTemplate.nUpgradeToTopCurrencyAmount
end

local function UpdateSailorInfo(self)
    local nSailorIdLeft = self.nSailorId
    local nCountLeft = ItemSystem:GetItemCount(nSailorIdLeft)
    local tbTemplateLeft = ItemSystem:GetItemTemplate(nSailorIdLeft)
    self.nMaxCount = nCountLeft
    self.nAccumulativeDegradeCurrencyAmount = tbTemplateLeft.nAccumulativeDegradeCurrencyAmount
    UpdateWidgetVisible(self, tbTemplateLeft)
    UpdateCurrencyBaseInfo(self, tbTemplateLeft)
    UpdateCurrencyCountInfo(self)
end

local function UpdateCount(self, nCount)
    self.nCount = MathUtil.Clamp(nCount, 1, self.nMaxCount)
    self.pWidgetRef.textBuyCount:SetText(self.nCount)
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

local function OnDisableClickedBtnLevelUp(self)
    UIUtils.ShowToastWithKey("SAILOR_TOP_GRADE")
end

-- 升1级
local function OnClickedBtnLevelUp(self)
    if self.bUpgradeEnough then
        GetSailorComponent():RequestSailorUpgrade(self.nSailorId, self.nCount, false)
    else
        ShowCurrencyNotEnoughDialog(self)
    end
end

local function HideLevelUpOtherCategoryWideget(self, nSubCategory)
    for k, v in ipairs(tbSailorTypeLevelUp) do  
        if nSubCategory == k then  
            self.pWidgetRef[v]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else   
            self.pWidgetRef[v]:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function OnReceiveSailorUpgradeResult(self, nSailorId, nUpgradeSailorId)
    
    self.Owner:PlayAnimation(szAnimLevelUp, 0, 1,  EUMGSequencePlayMode.Forward, 1)
    if nSailorId == self.nSailorId then
        local tbTemplateLeft = ItemSystem:GetItemTemplate(nUpgradeSailorId)
        HideLevelUpOtherCategoryWideget(self, tbTemplateLeft.nSubCategory)
        self:SetSailorId(nUpgradeSailorId)
    end
end

-- 升到最高级（5级）
local function OnClickedBtnUpLevelToTop(self)
    if self.bUpgradeToTopEnough then
        local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_UP_LEVEL_TO_TOP_DIALOG_TITLE")
        local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_UP_LEVEL_TO_TOP_DIALOG_MESSAGE"), self.nUpgradeToTopCurrencyAmount)
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
            GetSailorComponent():RequestSailorUpgrade(self.nSailorId, self.nCount, true)
        end)
    else
        ShowCurrencyNotEnoughDialog(self)
    end
end

local function ShowForbiddenTouchUi(self, bShow)
    self.pWidgetRef.bdrForbidden:SetVisibility(bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

-- 重置
local function OnClickedBtnReset(self)
    local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_RESET_DIALOG_TITLE")
    local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_RESET_DIALOG_MESSAGE"), self.nCount, self.l10nName, self.nAccumulativeDegradeCurrencyAmount * self.nCount)

    local fnRequestDegrade = function()
        GetSailorComponent():RequestSailorDegrade(self.nSailorId, self.nCount)
    end

    UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
        ShowForbiddenTouchUi(self, true)
        Timer.StartOwnerTimer(self, RESET_ANIM_TIMER, function() 
            self.Owner:PlayAnimation(szAnimReset, 0, 1,  EUMGSequencePlayMode.Forward, 1, fnRequestDegrade)
        end, nResetDelay, false)
    end)
end

local function OnReceiveSailorDegradeResult(self, nSailorId, nDegradedSailorId)
    ShowForbiddenTouchUi(self, false)
    if nSailorId == self.nSailorId then
        self:SetSailorId(nDegradedSailorId)
    end
end

function ULSailorBagLevelUp:OnCreate()
end

function ULSailorBagLevelUp:OnLoad()
   
end

function ULSailorBagLevelUp:OnUnload()
    Timer.StopOwnerAllTimer(self, true)
end

function ULSailorBagLevelUp:OnEnter()
end

function ULSailorBagLevelUp:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMinus.OnClicked, self, OnClickedBtnMinus)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnPlus.OnClicked, self, OnClickedBtnPlus)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnMax.OnClicked, self, OnClickedBtnMax)

    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpLevelToTop.OnClicked, self, OnClickedBtnUpLevelToTop)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpgrade.OnClicked, self, OnClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpgrade.OnDisableClicked, self, OnDisableClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReset.OnClicked, self, OnClickedBtnReset)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT, self, OnReceiveSailorUpgradeResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, OnReceiveSailorDegradeResult)
end

function ULSailorBagLevelUp:SetSailorId(nSailorId)
    local pWidgetRef = self.pWidgetRef
    self.nSailorId = nSailorId
    if nSailorId ~= nil then  
        pWidgetRef.hbUpgradeToTop:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.hbUpgrade:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.hbUpdateCount:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        UpdateSailorInfo(self)
        UpdateCount(self, MIN_COUNT)
    else  
        pWidgetRef.hbREset:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hbUpgradeToTop:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hbUpgrade:SetVisibility(ESlateVisibility.Collapsed)
        pWidgetRef.hbUpdateCount:SetVisibility(ESlateVisibility.Collapsed)
    end
    PlayBtnLoopByWidgetsVisible(self)
end

return ULSailorBagLevelUp