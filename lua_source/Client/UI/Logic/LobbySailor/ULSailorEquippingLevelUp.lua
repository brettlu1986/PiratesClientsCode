local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULSailorEquippingLevelUp = luaclass("ULSailorEquippingLevelUp", UILogicBase)

local UIDef = require("UIDef")
local L10N = require("L10N")
local Timer = require("Timer")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local LobbySailorHelper = require("LobbySailorHelper")
local EventManager = require("EventManager")
local UIResourceDef = require("UIResourceDef")
local ClientEventDef = require("ClientEventDef")
local CurrencySystem = require("CurrencySystem")
local UILobbySailorDef = require("UILobbySailorDef")
local PropertyComboSystem = require("PropertyComboSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local MIN_COUNT = 1             -- 最小选择数量
local TOP_GRADE = 4
local MIN_GRADE = 0             -- 水手最低等级
local szAnimBtnLoop = "animLevelUpLoop"
local szAnimResetIn = "animSailorResetIn"
local szAnimReset = "animFxSailorReset"
local EQUIP_MAIN_TIMER = "ToEquipMain"
local SHOW_HIDE_TOUCH2 = "HideTouchTimer2"
local RESET_ANIM_TIMER = "ResetAnimTimer"
local nResetDelay = 0.5
local nDelayTime = 0.6
local DELAY_BTN_LOOP = "DelayBtnLoopTimer"
local tbSailorTypeLevelUp = 
{
    "imgFxLevelUpFlow01",
    "imgFxLevelUpFlow02",
    "imgFxLevelUpFlow03"
}

ULSailorEquippingLevelUp.nAccumulativeDegradeCurrencyAmount = nil
ULSailorEquippingLevelUp.bOneKeyLevelUp = false
ULSailorEquippingLevelUp.nCurrencyId = -1
ULSailorEquippingLevelUp.nCount = MIN_COUNT
ULSailorEquippingLevelUp.nMaxCount = MIN_COUNT
ULSailorEquippingLevelUp.nBaseUpgradeCurrencyAmount = 0
ULSailorEquippingLevelUp.nBaseUpgradeToTopCurrencyAmount = 0
ULSailorEquippingLevelUp.nUpgradeToTopCurrencyAmount = 0
ULSailorEquippingLevelUp.bUpgradeEnough = false
ULSailorEquippingLevelUp.bUpgradeToTopEnough = false
ULSailorEquippingLevelUp.bOneUpgradeEnough = false
ULSailorEquippingLevelUp.nSailorId = -1

ULSailorEquippingLevelUp.tbEquippedSailorUpgradeData = nil

local PROPERTY_MAX_COUNT = 3    -- 最大属性条数
local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE.SLATE_COLOR
local SLATE_COLOR_RED = UIResourceDef.COLOR.RED.SLATE_COLOR


local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function ShowForbiddenTouchUi(self, bShow)
    self.pWidgetRef.bdrForbiddenTouch:SetVisibility(bShow and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
end

local function PlayBtnLoopByWidgetsVisible(self)
    local bUpgradeVisible = self.pWidgetRef.UpgradeBox:IsVisible()
    local bUpgradeTopVisible = self.pWidgetRef.hbLevelUpTo5:IsVisible()
   
    self.pWidgetRef.UpgradeFx01:SetVisibility(bUpgradeVisible and ESlateVisibility.SelfHitTestInvisible or 
        ESlateVisibility.Collapsed)
    self.pWidgetRef.UpgradeFx02:SetVisibility(bUpgradeTopVisible and ESlateVisibility.SelfHitTestInvisible or 
        ESlateVisibility.Collapsed)

    if bUpgradeVisible then  
        self.pWidgetRef.UpgradeFx01:SetRenderOpacity(1)
    end
    if bUpgradeTopVisible then  
        self.pWidgetRef.UpgradeFx02:SetRenderOpacity(1)
    end

    if bUpgradeVisible or bUpgradeTopVisible then  
        Timer.StartOwnerTimer(self, DELAY_BTN_LOOP, function()
            if self.pWidgetRef then
                self.Owner:PlayAnimation(szAnimBtnLoop, 0, 0,  EUMGSequencePlayMode.Forward, 1)
            end
        end, nDelayTime)
    else  
        self.Owner:StopAnimation(szAnimBtnLoop)
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

--单一升级/升至5级 

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
    self.tbSingleListHelper:SetData(tbPropertiesData)
end

local function UpdateCurrencyCountInfo(self)
    local pWidgetRef = self.pWidgetRef
    local nCurrencyAmount = CurrencySystem:GetCurrencyCount(self.nCurrencyId)
    local nUpgradeCurrencyAmount = self.nBaseUpgradeCurrencyAmount * self.nCount
    self.nUpgradeToTopCurrencyAmount = self.nBaseUpgradeToTopCurrencyAmount * self.nCount
    pWidgetRef.txtCount:SetText(nUpgradeCurrencyAmount)
    pWidgetRef.txtToTopCount:SetText(self.nUpgradeToTopCurrencyAmount)

    self.bUpgradeEnough = nCurrencyAmount >= nUpgradeCurrencyAmount
    self.bUpgradeToTopEnough = nCurrencyAmount >= self.nUpgradeToTopCurrencyAmount
    pWidgetRef.txtCount:SetColorAndOpacity(self.bUpgradeEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
    pWidgetRef.txtToTopCount:SetColorAndOpacity(self.bUpgradeToTopEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
end

local function UpdateCurrencyBaseInfo(self, tbTemplate)
    self.nCurrencyId = tbTemplate.nCurrencyId
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(self.nCurrencyId)
    local pCurrencySmallIcon = szCurrencySmallIcon:load()

    local pWidgetRef = self.pWidgetRef
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgCurrency, pCurrencySmallIcon)
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgToTopCurrency, pCurrencySmallIcon)

    self.nBaseUpgradeCurrencyAmount = tbTemplate.nUpgradeCurrencyAmount
    self.nBaseUpgradeToTopCurrencyAmount = tbTemplate.nUpgradeToTopCurrencyAmount
end

-- 刷新控件显隐
local function UpdateWidgetVisible(self, tbTemplate)
    local nGrade = tbTemplate.nGrade
    local pWidgetRef = self.pWidgetRef
    -- 当前未4、5级水手时，隐藏升级至5级按钮
    local nMaxGrade = UILobbySailorDef.MAX_GRADE
    if nGrade >= nMaxGrade - 1 then
        pWidgetRef.hbLevelUpTo5:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.hbLevelUpTo5:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    end

     -- 当前5级水手时，隐藏升级按钮，切隐藏右侧水手
    if nGrade == nMaxGrade then
        pWidgetRef.btnUpgrade:SetIsEnabled(false)
        pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.Collapsed)
    else
        pWidgetRef.btnUpgrade:SetIsEnabled(true)
        pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        pWidgetRef.txtLevelUp:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_SINGLE"))
    end
    
    -- 当前为1级水手时，隐藏重置按钮
    if tbTemplate.nGrade == MIN_GRADE then
        pWidgetRef.hbREset:SetVisibility(ESlateVisibility.Collapsed)
    else
        if pWidgetRef.hbREset:IsVisible() == false then
            self.Owner:PlayAnimation(szAnimResetIn, 0, 1,  EUMGSequencePlayMode.Forward, 1)
            pWidgetRef.hbREset:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    end

    PlayBtnLoopByWidgetsVisible(self)
end

local function FillSingleLevelUpInfo(self)
    if self.pbSingleInfo then  
        self.pbSingleInfo:SetData(self.nSailorId)
    end

    local nCountLeft = ItemSystem:GetItemCount(self.nSailorId)
    self.nMaxCount = nCountLeft
    local tbTemplate = ItemSystem:GetItemTemplate(self.nSailorId)

    self.l10nName = tbTemplate.l10nName
    self.nAccumulativeDegradeCurrencyAmount = tbTemplate.nAccumulativeDegradeCurrencyAmount

    local nSailorUpGradeTo = tbTemplate.nUpgradeTo
    local tbTemplateRight = ItemSystem:GetItemTemplate(nSailorUpGradeTo)

    LobbySailorHelper.RefreshSailorItemResState(self.pWidgetRef.ImgStone, self.pWidgetRef.ImgPattern, true, self.nSailorId)
    LobbySailorHelper.RefreshSailorMaterialEffect(self.pWidgetRef, self.pWidgetRef.img_FxSign, self.nSailorId, self.pWidgetRef.img_FxAttack)
    
    UpdateWidgetVisible(self, tbTemplate)
    UpdateProperties(self, tbTemplate, tbTemplateRight)

    UpdateCurrencyBaseInfo(self, tbTemplate)
    UpdateCurrencyCountInfo(self)
end

local function HideLevelUpOtherCategoryWideget(self, nUpgradeSailorId)
    local tbTemplateLeft = ItemSystem:GetItemTemplate(nUpgradeSailorId)
    for k, v in ipairs(tbSailorTypeLevelUp) do  
        if tbTemplateLeft.nSubCategory == k then  
            self.pWidgetRef[v]:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        else   
            self.pWidgetRef[v]:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end

local function PlayLevelUpAnim(self, nUpgradeSailorId)
    HideLevelUpOtherCategoryWideget(self, nUpgradeSailorId)
    self.Owner:PlayAnimation("animFxSailorLevelUp", 0, 1,  EUMGSequencePlayMode.Forward, 1)
end

local function HideTouchInSeconds(self, nSec)
    if self.pWidgetRef then
        ShowForbiddenTouchUi(self, true)
    end
    Timer.StartOwnerTimer(self, SHOW_HIDE_TOUCH2, function() 
        if self.pWidgetRef then
            ShowForbiddenTouchUi(self, false)
        end
    end, nSec, false)
end

local function OnReceiveUpgradeEquippedSailorResult(self, tbUpgradedSailorInfos, bOneKeyUpgrade)
    local tbUpgradedInfo = tbUpgradedSailorInfos[1]
    if not bOneKeyUpgrade then
        if tbUpgradedInfo.nSailorId  == self.nSailorId then
            self:SetSailorId(tbUpgradedInfo.nUpgradeTo)
        end
        PlayLevelUpAnim(self, tbUpgradedInfo.nUpgradeTo)
    else 
        PlayLevelUpAnim(self, tbUpgradedInfo.nUpgradeTo)
        LobbySailorHelper.RefreshSailorItemResState(self.pWidgetRef.ImgStone, self.pWidgetRef.ImgPattern, true, tbUpgradedInfo.nUpgradeTo)
        LobbySailorHelper.RefreshSailorMaterialEffect(self.pWidgetRef, self.pWidgetRef.img_FxSign, tbUpgradedInfo.nUpgradeTo, self.pWidgetRef.img_FxAttack)
        Timer.StartOwnerTimer(self, EQUIP_MAIN_TIMER, function() 
            self.Owner:ShowEquipMain()
        end, 1)
    end
    HideTouchInSeconds(self, 1.5)
end

-- 升到最高级（5级）
local function OnClickedBtnUpLevelToTop(self)
    if self.bUpgradeToTopEnough then
        local l10nTitle = UISetUtils.GetL10NTextByKey("SAILOR_UP_LEVEL_TO_TOP_DIALOG_TITLE")
        local l10nMessage = L10N:Format(UISetUtils.GetL10NTextByKey("SAILOR_UP_LEVEL_TO_TOP_DIALOG_MESSAGE"), self.nUpgradeToTopCurrencyAmount)
        UIUtils.ShowChoiceDialog(l10nTitle, l10nMessage, function()
            ShowForbiddenTouchUi(self, true)
            GetSailorComponent():RequestEquippedSailorUpgrade(self.nSailorId, self.nCount, true, self.nSailorCategory, self.nSlotIndex)
        end)
    else
        ShowCurrencyNotEnoughDialog(self)
    end
end

-- 升1级
local function OnClickedBtnLevelUp(self)
    if self.bOneKeyLevelUp then  
        if self.bOneUpgradeEnough then
            ShowForbiddenTouchUi(self, true)
            GetSailorComponent():RequestUpgradeEquippedSailor(self.tbEquippedSailorUpgradeData)
        else
            ShowCurrencyNotEnoughDialog(self)
        end
    else 
        if self.bUpgradeEnough then
            ShowForbiddenTouchUi(self, true)
            GetSailorComponent():RequestEquippedSailorUpgrade(self.nSailorId, self.nCount, false, self.nSailorCategory, self.nSlotIndex)
        else
            ShowCurrencyNotEnoughDialog(self)
        end
    end
end

local function OnDisableClickedBtnLevelUp(self)
    UIUtils.ShowToastWithKey("SAILOR_TOP_GRADE")
end

--一键升级
local function UpdateOneKeyCurrencyInfo(self, nTotalCurrency)
    local pWidgetRef = self.pWidgetRef

    local nCurrencyAmount = CurrencySystem:GetCurrencyCount(UILobbySailorDef.CURRENCY_ID)

    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(UILobbySailorDef.CURRENCY_ID)
    local pCurrencySmallIcon = szCurrencySmallIcon:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.ImgCurrency, pCurrencySmallIcon)

    pWidgetRef.txtCount:SetText(nTotalCurrency)
    self.bOneUpgradeEnough = nCurrencyAmount >= nTotalCurrency
    pWidgetRef.txtCount:SetColorAndOpacity(self.bOneUpgradeEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
end

local function UpdateOneKeyProperties(self)
    local tbComboIdWithCountMap = {}
    local tbComboIdWithCountMapUpgradeTo = {}
    for _, tbData in ipairs(self.tbEquippedSailorUpgradeData) do
        local tbTemplate = ItemSystem:GetItemTemplate(tbData.nSailorId)
        tbComboIdWithCountMap[tbTemplate.nPropertyComboId] = (tbComboIdWithCountMap[tbTemplate.nPropertyComboId] or 0) + 1
        local tbTemplateUpgradeTo = ItemSystem:GetItemTemplate(tbData.nIdUpgradeTo)
        tbComboIdWithCountMapUpgradeTo[tbTemplateUpgradeTo.nPropertyComboId] = (tbComboIdWithCountMapUpgradeTo[tbTemplateUpgradeTo.nPropertyComboId] or 0) + 1
    end
    local tbDisplayInfoListLeft = PropertyComboSystem:GetMultiPropertyComboDisplayInfoList(tbComboIdWithCountMap)
    local tbDisplayInfoListRight = PropertyComboSystem:GetMultiPropertyComboDisplayInfoList(tbComboIdWithCountMapUpgradeTo)
    local tbPropertiesData = {}
    for i = 1, #tbDisplayInfoListLeft do
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
    self.tbOneKeyListHelper:SetData(tbPropertiesData)
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

function ULSailorEquippingLevelUp:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpgradeToTop.OnClicked, self, OnClickedBtnUpLevelToTop)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpgrade.OnClicked, self, OnClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnUpgrade.OnDisableClicked, self, OnDisableClickedBtnLevelUp)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnReset.OnClicked, self, OnClickedBtnReset)

    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_UPGRADE_EQUIPPED_SAILOR_RESULT, self, OnReceiveUpgradeEquippedSailorResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, OnReceiveSailorDegradeResult)
end

function ULSailorEquippingLevelUp:ShowOneKeyLevelUp()
    local pWidgetRef = self.pWidgetRef
    -- pWidgetRef.cpEquipMain:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.cpLevelUpMain:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.hbREset:SetVisibility(ESlateVisibility.Collapsed)

    pWidgetRef.vbSingleInfo:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.vbTotalInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtOneKey:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.hbLevelUpTo5:SetVisibility(ESlateVisibility.Collapsed)
    --pWidgetRef.btnBack:SetVisibility(ESlateVisibility.Collapsed)
    
    pWidgetRef.btnUpgrade:SetIsEnabled(true)
    pWidgetRef.UpgradeBox:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.txtLevelUp:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_ALL"))

    local tbSlotInfos = GetSailorComponent():GetSailorSlotInfo()
    local tbCurrentCategorySlotInfos = tbSlotInfos[self.nSailorCategory]
    local nFirstNotTopLevelId = -1
    for i, tbEquippedData in ipairs(tbCurrentCategorySlotInfos) do
        local tbTemplate = ItemSystem:GetItemTemplate(tbEquippedData.nSailorId)
        if tbTemplate and tbTemplate.nGrade < TOP_GRADE then  
            nFirstNotTopLevelId = tbEquippedData.nSailorId
            break
        end
    end

    if nFirstNotTopLevelId ~= -1 then
        LobbySailorHelper.RefreshSailorItemResState(pWidgetRef.ImgStone, pWidgetRef.ImgPattern, true, nFirstNotTopLevelId)
        LobbySailorHelper.RefreshSailorMaterialEffect(pWidgetRef, pWidgetRef.img_FxSign, nFirstNotTopLevelId, pWidgetRef.img_FxAttack)
    end
    
    self.bOneKeyLevelUp = true

    local nTotalGrade, nTotalGradeUpgradeTo, nTotalCurrency, tbEquippedSailorUpgradeData = GetSailorComponent():GetEquippedSailorUpgradeData(self.nSailorCategory)
    self.tbEquippedSailorUpgradeData = tbEquippedSailorUpgradeData
    self.pWidgetRef.txtLevelLeft:SetText(nTotalGrade)
    self.pWidgetRef.txtLevelRight:SetText(nTotalGradeUpgradeTo)
    UpdateOneKeyCurrencyInfo(self, nTotalCurrency)
    UpdateOneKeyProperties(self)
    PlayBtnLoopByWidgetsVisible(self)
end

function ULSailorEquippingLevelUp:ShowLevelUpOneSailor()
    local pWidgetRef = self.pWidgetRef
    -- pWidgetRef.cpEquipMain:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.cpLevelUpMain:SetVisibility(ESlateVisibility.SelfHitTestInvisible)

    pWidgetRef.vbSingleInfo:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    pWidgetRef.vbTotalInfo:SetVisibility(ESlateVisibility.Collapsed)
    pWidgetRef.txtOneKey:SetVisibility(ESlateVisibility.Collapsed)

    PlayBtnLoopByWidgetsVisible(self)
    LobbySailorHelper.RefreshSailorItemResState(pWidgetRef.ImgStone, pWidgetRef.ImgPattern, true, self.nSailorId)
    LobbySailorHelper.RefreshSailorMaterialEffect(pWidgetRef, pWidgetRef.img_FxSign, self.nSailorId, pWidgetRef.img_FxAttack)
    self.bOneKeyLevelUp = false
    
end 

function ULSailorEquippingLevelUp:SetSailorId(nSailorId)
    self.nSailorId = nSailorId
    FillSingleLevelUpInfo(self)
end

function ULSailorEquippingLevelUp:SetSailorCategory(nSailorCategory)
    self.nSailorCategory = nSailorCategory
end

function ULSailorEquippingLevelUp:SetSlotIndex(nSlotIndex)
    self.nSlotIndex = nSlotIndex
end

function ULSailorEquippingLevelUp:OnCreate()
end

function ULSailorEquippingLevelUp:OnLoad()
    local PrefabHelper = self.PrefabHelper
    self.pbSingleInfo = PrefabHelper:BindPrefab(self.pWidgetRef.pbSingleInfo, UIDef.UP_LOBBY_SAILOR_SINGLE_INFO)

    self.tbSingleListHelper = SelfVerticalListHelper()
    self.tbSingleListHelper:Init(self, self.pWidgetRef.listPropertiesSingle)

    self.tbOneKeyListHelper = SelfVerticalListHelper()
    self.tbOneKeyListHelper:Init(self, self.pWidgetRef.listPropertiesAll)
end

function ULSailorEquippingLevelUp:OnUnload()
    self.tbSingleListHelper:Uninit()
    self.tbSingleListHelper = nil

    self.tbOneKeyListHelper:Uninit()
    self.tbOneKeyListHelper = nil

    Timer.StopOwnerAllTimer(self, true)
end

function ULSailorEquippingLevelUp:OnEnter()
end

return ULSailorEquippingLevelUp