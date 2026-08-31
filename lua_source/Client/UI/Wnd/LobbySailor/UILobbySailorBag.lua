
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UILobbySailorBag = luaclass("UILobbySailorBag", WndBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
-- local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local ClientEventDef = require("ClientEventDef")
local UILobbySailorDef = require("UILobbySailorDef")
local PropertyComboSystem = require("PropertyComboSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local LobbySailorHelper = require("LobbySailorHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local DEFAULT_SELECTED_GRADE = 1
local MAX_FILTER_GRADE = 5
local PROPERTY_MAX_COUNT = 3    -- 最大属性条数
local DEFAULT_SELECT = 1

--跟 template里的 nGrade比 要 -1
UILobbySailorBag.nSelectedGrade = DEFAULT_SELECTED_GRADE
UILobbySailorBag.bLevelUpMode = false
UILobbySailorBag.nSelectSailorId = nil
UILobbySailorBag.pbWindowFrame = nil

local szAnimBagIn = "animLobbySailorBagIn"
local szAnimLevelupIn = "animSailorLevelUpIn"

local function GetSailorComponent()
    return GamePlayerSelfHelper:Get().SailorComponent
end

local function RefreshList(self)
    local tbDatas = GetSailorComponent():GetSailorListByGrade(self.nSelectedGrade - 1)
    self.tbListHelper:SetData(tbDatas)
    self.tbListHelper:SetSelectedIndex(DEFAULT_SELECT)
end

local function OnSailorLevelSelectChanged(self, szSelection)
    
    self.nSelectedGrade = self.pWidgetRef.cmbSailorLevels:FindOptionIndex(szSelection) + 1
    RefreshList(self)
    if self.nSelectedGrade == MAX_FILTER_GRADE then  
        self.pWidgetRef.textLevelUp:SetText(UISetUtils.GetL10NTextByKey("UI_SAILOR_RESET"))
    else  
        self.pWidgetRef.textLevelUp:SetText(UISetUtils.GetL10NTextByKey("SAILOR_BUTTON_UP_LEVEL_SINGLE"))
    end
end

local function GetSelectionString(nSelectGrade)
    local l10nStr =  L10N:Format(UISetUtils.GetL10NTextByKey("UI_LOBBY_LEVEL_SAILOR"), nSelectGrade) 
    return L10N:ToString(l10nStr)
end

local function PlayBagInAnim(self, bReverse)
    self:PlayAnimation(szAnimBagIn, 0, 1, bReverse and EUMGSequencePlayMode.Reverse or EUMGSequencePlayMode.Forward, 1)
end  

local function PlayLevelUpInAnim(self, bReverse)
    self:PlayAnimation(szAnimLevelupIn, 0, 1, bReverse and EUMGSequencePlayMode.Reverse or EUMGSequencePlayMode.Forward, 1)
end

local function UpdateProperties(self, tbTemplateLeft, tbTemplateRight, bShowNextLevel)
    local nPropertyComboIdLeft = tbTemplateLeft.nPropertyComboId
    local nPropertyComboIdRight = tbTemplateRight and tbTemplateRight.nPropertyComboId
    local tbDisplayInfoListLeft = PropertyComboSystem:GetPropertyComboDisplayInfoList(nPropertyComboIdLeft)
    local tbDisplayInfoListRight = nPropertyComboIdRight and PropertyComboSystem:GetPropertyComboDisplayInfoList(nPropertyComboIdRight) or {}
    local tbPropertiesData = {}
    --背包就不显示 第二个升级的效果了
    for i = 1, PROPERTY_MAX_COUNT do
        local tbDisplayInfoLeft = tbDisplayInfoListLeft[i]
        local tbDisplayInfoRight = tbDisplayInfoListRight[i]
        local szNewDisplayTemp = tbDisplayInfoRight and tbDisplayInfoRight.szDisplayValue
        if not bShowNextLevel then szNewDisplayTemp = nil end
        if tbDisplayInfoLeft then
            tbPropertiesData[i] = {
                l10nDisplayName = tbDisplayInfoLeft.l10nDisplayName,
                szOldDisplayValue = tbDisplayInfoLeft.szDisplayValue,
                szNewDisplayValue = szNewDisplayTemp
            }
        end
    end
    self.tbSingleListHelper:SetData(tbPropertiesData)
end

local function OnSailorBagItemSelectedChanged(self, nIndex)
    local tbSailorData = self.tbListHelper:GetSelectedData()
    local nSailorId = tbSailorData.nSailorId
    self.pbSingleInfo:SetData(nSailorId)
    self.tbListHelper:ScrollToTop()

    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    local nSailorUpGradeTo = tbTemplate.nUpgradeTo
    local tbTemplateRight = ItemSystem:GetItemTemplate(nSailorUpGradeTo)
    UpdateProperties(self, tbTemplate, tbTemplateRight, false)

    self.nSelectSailorId = nSailorId
    local nCount =  ItemSystem:GetItemCount(nSailorId)
    local bVisible = nCount ~= 0  
    self.pWidgetRef.btnListSeeR:SetVisibility(bVisible and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
    LobbySailorHelper.RefreshSailorItemResState(self.pWidgetRef.ImgStone, self.pWidgetRef.ImgPattern, true, self.nSelectSailorId)
    LobbySailorHelper.RefreshSailorMaterialEffect(self.pWidgetRef, self.pWidgetRef.img_FxSign, self.nSelectSailorId, self.pWidgetRef.img_FxAttack)
end

local function RefreshListToSailorId(self, nSailorId)
    local tbTemplate = ItemSystem:GetItemTemplate(nSailorId)
    local nGrade = tbTemplate.nGrade
    self.nSelectedGrade = nGrade + 1
    self.pWidgetRef.cmbSailorLevels:SetSelectedOption(GetSelectionString(self.nSelectedGrade))
    
    local tbDatas = GetSailorComponent():GetSailorListByGrade(self.nSelectedGrade - 1)
    local nSelectIndex = -1
    for i, v in ipairs(tbDatas) do
        if v.nSailorId == nSailorId then  
            nSelectIndex = i 
            break
        end
    end
    if nSelectIndex == -1 then nSelectIndex = DEFAULT_SELECT end
    self.tbListHelper:SetData(tbDatas)
    self.tbListHelper:SetSelectedIndex(nSelectIndex)
    self.tbListHelper:ScrollToIndex(nSelectIndex, false)
end

local function UpdateSelectSailorProperties(self, bShowNextLevel)
    local tbTemplate = ItemSystem:GetItemTemplate(self.nSelectSailorId)
    local nSailorUpGradeTo = tbTemplate.nUpgradeTo
    local tbTemplateRight = ItemSystem:GetItemTemplate(nSailorUpGradeTo)
    UpdateProperties(self, tbTemplate, tbTemplateRight, bShowNextLevel)
end

local function InitModeUi(self)
    local pWidgetRef = self.pWidgetRef
    local nSailorId = self.nSelectSailorId
    local nCount =  ItemSystem:GetItemCount(nSailorId)
    if self.bLevelUpMode then  
        if nCount > 0 then
            pWidgetRef.btnListSeeR:SetVisibility(ESlateVisibility.Collapsed)
            self.ulBagLevelUp:SetSailorId(self.nSelectSailorId)
            UpdateSelectSailorProperties(self, true)
        end
    else 
        pWidgetRef.btnListSeeR:SetVisibility(nCount ~= 0 and ESlateVisibility.Visible or ESlateVisibility.Collapsed)
        pWidgetRef.vbListBox:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        self.ulBagLevelUp:SetSailorId(nil)
        UpdateSelectSailorProperties(self, false)
    end
end

local function EnableLevelUpMode(self, bEnable)
    self.bLevelUpMode = bEnable
    InitModeUi(self)
end

local function ShowLevelUp(self)
    EnableLevelUpMode(self, true)
    PlayLevelUpInAnim(self, false)
end

local function ShowBag(self)
    EnableLevelUpMode(self, false)
    PlayLevelUpInAnim(self, true)
    self.pbWindowFrame:SetBackIsCloseSelf(false)
end

local function BackToPre(self)
    if self.bLevelUpMode then   
        ShowBag(self)
    else 
        self.pbWindowFrame:SetBackIsCloseSelf(true)
        self.EventHelper:FireEvent(ClientEventDef.EV_LOBBYSAILOR_TO_PRE)
    end
end

local function OnReceiveSailorUpgradeResult(self, nSailorId, nUpgradeSailorId)
    RefreshListToSailorId(self, nUpgradeSailorId)
    local tbTemplate = ItemSystem:GetItemTemplate(nUpgradeSailorId)
    if tbTemplate.nGrade == MAX_FILTER_GRADE -1 then 
        self.pWidgetRef.btnListSeeR:SetVisibility(ESlateVisibility.Collapsed)
    end
end

local function OnReceiveSailorDegradeResult(self, nSailorId, nDegradedSailorId)
    RefreshListToSailorId(self, nDegradedSailorId)
end

function UILobbySailorBag:OnLoad()
    UILobbySailorBag.super.OnLoad(self)

    local pWidgetRef = self.pWidgetRef
    self.pbWindowFrame = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbWindowFrame)
    self.pbWindowFrame:SetBackDelegate(BackToPre, self)

    self.ulBagLevelUp = self.UILogicHelper:CreateUILogic("ULSailorBagLevelUp")

    --self.pCurrencyBar = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyCurrencyBar)
    self.pbWindowFrame:SetSpecialCurrency(UILobbySailorDef.CURRENCY_ID)

    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.pItemList)
    self.tbListHelper.OnSelectedChangedDelegate:Bind(OnSailorBagItemSelectedChanged, self)

    self.pbSingleInfo = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbSingleInfo, UIDef.UP_LOBBY_SAILOR_SINGLE_INFO)
    self.tbSingleListHelper = SelfVerticalListHelper()
    self.tbSingleListHelper:Init(self, self.pWidgetRef.listPropertiesSingle)

    for i = DEFAULT_SELECTED_GRADE, MAX_FILTER_GRADE do  
        pWidgetRef.cmbSailorLevels:AddOption(GetSelectionString(i))
    end
    pWidgetRef.cmbSailorLevels:SetSelectedOption(GetSelectionString(DEFAULT_SELECTED_GRADE))
end

function UILobbySailorBag:OnUnload()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
    self.tbSingleListHelper:Uninit()
    self.tbSingleListHelper = nil
end

function UILobbySailorBag:OnShow()
    UILobbySailorBag.super.OnShow(self)
    OnSailorLevelSelectChanged(self, GetSelectionString(DEFAULT_SELECTED_GRADE))
    EnableLevelUpMode(self, false)
    PlayBagInAnim(self, false)
end

function UILobbySailorBag:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    --EventHelper:RegisterCppDelegate(pWidgetRef.btnBack.OnClicked, self, BackToPre)
    -- EventHelper:RegisterCppDelegate(pWidgetRef.btnListSeeL.OnClicked, self, ShowBag)
    EventHelper:RegisterCppDelegate(pWidgetRef.btnListSeeR.OnClicked, self, ShowLevelUp)
    EventHelper:RegisterCppDelegate(pWidgetRef.cmbSailorLevels.OnSelectionChanged, self, OnSailorLevelSelectChanged)
    
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_UPGRADE_RESULT, self, OnReceiveSailorUpgradeResult)
    EventHelper:RegisterEvent(ClientEventDef.EV_ON_RECEIVE_SAILOR_DEGRADE_RESULT, self, OnReceiveSailorDegradeResult)
end

return UILobbySailorBag
