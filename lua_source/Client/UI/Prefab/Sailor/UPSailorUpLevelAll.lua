-----------------------------------------------------
--File Name    : UPSailorUpLevelAll.lua
--Author       : Song Fuhao
--Create Time  : 2019-04-17
--Description  : 
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPSailorUpLevelAll = luaclass("UPSailorUpLevelAll", PrefabBase)

local UIUtils = require("UIUtils")
local ItemSystem = require("ItemSystem")
local UISetUtils = require("UISetUtils")
local EventManager = require("EventManager")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local ClientEventDef = require("ClientEventDef")
local PropertyComboSystem = require("PropertyComboSystem")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local CURRENCY_ID = 1400003
local SLATE_COLOR_WHITE = UIResourceDef.COLOR.WHITE.SLATE_COLOR
local SLATE_COLOR_RED = UIResourceDef.COLOR.RED.SLATE_COLOR

UPSailorUpLevelAll.DialogFrame = nil
UPSailorUpLevelAll.tbEquippedSailorUpgradeData = nil

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

local function UpdateCurrencyInfo(self, nTotalCurrency)
    local pWidgetRef = self.pWidgetRef

    local nCurrencyAmount = CurrencySystem:GetCurrencyCount(CURRENCY_ID)
    pWidgetRef.txtCurrency:SetText(nCurrencyAmount)

    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(CURRENCY_ID)
    local pCurrencySmallIcon = szCurrencySmallIcon:load()
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency, pCurrencySmallIcon)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgUpLevelCurrency, pCurrencySmallIcon)

    self.pWidgetRef.txtUpLevelCurrencyCount:SetText(nTotalCurrency)
    self.bUpgradeEnough = nCurrencyAmount >= nTotalCurrency
    pWidgetRef.txtUpLevelCurrencyCount:SetColorAndOpacity(self.bUpgradeEnough and SLATE_COLOR_WHITE or SLATE_COLOR_RED)
end

local function UpdateProperties(self)
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
    self.tbListHelper:SetData(tbPropertiesData)
end

local function OnClickedBtnLevelUp(self)
    if self.bUpgradeEnough then
        GetSailorComponent():RequestUpgradeEquippedSailor(self.tbEquippedSailorUpgradeData)
        self.DialogFrame:HideDialog()
    else
        ShowCurrencyNotEnoughDialog(self)
    end
end

function UPSailorUpLevelAll:OnLoad()
    self.tbListHelper = SelfVerticalListHelper()
    self.tbListHelper:Init(self, self.pWidgetRef.listProperties)
end

function UPSailorUpLevelAll:OnUnload()
    self.tbListHelper:Uninit()
    self.tbListHelper = nil
end

function UPSailorUpLevelAll:OnEnter()
    local nTotalGrade, nTotalGradeUpgradeTo, nTotalCurrency, tbEquippedSailorUpgradeData = GetSailorComponent():GetEquippedSailorUpgradeData()
    self.tbEquippedSailorUpgradeData = tbEquippedSailorUpgradeData
    self.pWidgetRef.txtLevelLeft:SetText(nTotalGrade)
    self.pWidgetRef.txtLevelRight:SetText(nTotalGradeUpgradeTo)
    UpdateCurrencyInfo(self, nTotalCurrency)
    UpdateProperties(self)
end

function UPSailorUpLevelAll:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnUpLevel.OnClicked, self, OnClickedBtnLevelUp)
end

function UPSailorUpLevelAll:SetDialogFrame(DialogFrame)
    self.DialogFrame = DialogFrame
end

return UPSailorUpLevelAll