-----------------------------------------------------
--File Name    : UPCurrencyBar.lua
--Author       : Ran Jie
--Create Time  : 2019-03-06
-----------------------------------------------------
local luaclass       = require ("luaclass")
local UPWidgetBase   = require("UPWidgetBase")
local UPCurrencyBar  = luaclass("UPCurrencyBar", UPWidgetBase)

local UIManager       = require("UIManager")
local BaseUtil        = require("BaseUtil")
local UISetUtils      = require("UISetUtils")
local CurrencySystem  = require("CurrencySystem")
local ClientEventDef  = require("ClientEventDef")
local UIToolTipHelper = require("UIToolTipHelper")
local ItemDataTable   = require("ItemDataTable")
local UIUtils         = require("UIUtils")
local UIDef           = require("UIDef")
local IAPSystem       = require("IAPSystem")
local CurrencyIni     = require("CurrencyIni")

local POINT_TICKET = 1400002

local DEFAULT_CURRENCY_SHOW = CurrencySystem:GetDefaultDisplayCurrencyIds()
local SHOW_MAX = 4
local VISIBLE = ESlateVisibility.Visible
local COLLAPSED = ESlateVisibility.Collapsed
local SELF_HIT_TEST_INVISIBLE = ESlateVisibility.SelfHitTestInvisible
local SHOW_MAX_VALUE = 9999999

UPCurrencyBar.tbShowCurrency = nil

local function SetCurrencyInfo(self, nIndex, nTemplateId)
    local szSmallIcon = CurrencySystem:GetCurrencySmallIcon(nTemplateId)
    if szSmallIcon then
        local pIcon = szSmallIcon:load()
        if pIcon then
            UISetUtils.SetImageBrushRes(self.pWidgetRef["imgCoinIcon0"..nIndex], pIcon, true)
        end
    else
        logerror("UPCurrencyBar:SetCurrencyInfo,szSmallIcon is nil", nTemplateId)
    end
    local nCount = CurrencySystem:GetCurrencyCount(nTemplateId)
    if nCount > SHOW_MAX_VALUE then
        nCount = SHOW_MAX_VALUE
    end
    log("SetCurrencyInfo,nTemplateId,nCount=",nTemplateId,nCount)
    self.pWidgetRef["txtCoinCount0"..nIndex]:SetText(nCount)
    if nTemplateId == POINT_TICKET then
        self.pWidgetRef["imgAdd0"..nIndex]:SetVisibility(SELF_HIT_TEST_INVISIBLE)
    else
        self.pWidgetRef["imgAdd0"..nIndex]:SetVisibility(COLLAPSED)
    end
end

-- 刷新当前设置的道具类型的道具数量
local function ShowCurrency(self, tbShowCurrency)
    local pWidgetRef = self.pWidgetRef
    pWidgetRef:SetVisibility(ESlateVisibility_SelfHitTestInvisible)
    for k, v in ipairs(tbShowCurrency) do
        local btnCoinWidget = pWidgetRef["btnCurrencyCoin0"..k]
        if btnCoinWidget then
            btnCoinWidget:SetVisibility(VISIBLE)
            SetCurrencyInfo(self, k, v)
        end
    end
    for i = #tbShowCurrency + 1, SHOW_MAX do
        pWidgetRef["btnCurrencyCoin0"..i]:SetVisibility(COLLAPSED)
    end
end

local function OnCoinOnPressed(self, nIndex)
    local nTemplateId = self.tbShowCurrency[nIndex]
    if nTemplateId == POINT_TICKET then
        return
    end
    local nCount = CurrencySystem:GetCurrencyCount(nTemplateId)
    local tbTipData = {}
    tbTipData.tbTemplate = ItemDataTable:GetTemplate(nTemplateId)
    tbTipData.nCount = nCount
    local pWidgetRef = self.pWidgetRef["btnCurrencyCoin0"..nIndex]
    if nTemplateId == CurrencyIni.tbCurrencyCeiling.nCurrencyId then
        UIToolTipHelper:ShowCustomTipInAutoLayout(UIDef.UP_COIN_DETAIL_TIPS,tbTipData,pWidgetRef)
    else
        UIToolTipHelper:ShowTipInAutoLayout(UIToolTipHelper.TipType.ITEM_TIP,tbTipData,pWidgetRef)
    end
end

local function OnCoinOnReleased(self)
    UIToolTipHelper:HideTip()
end

local function OnCoinOnClicked(self, i)
    local nTemplateId = self.tbShowCurrency[i]
    if nTemplateId == POINT_TICKET then
        if IAPSystem:IsIAPEnabled() then
            UIManager:OpenWnd(UIDef.UI_LOBBY_IAP)
        else
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("FFA_FUNCTION_NOT_OPEN"))
        end
    end
end

local function OnCurrencyCountSync(self)
    ShowCurrency(self, self.tbShowCurrency)
end

function UPCurrencyBar:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    for i = 1, SHOW_MAX do
        EventHelper:RegisterCppDelegate(pWidgetRef["btnCurrencyCoin0"..i].OnPressed, self, function() OnCoinOnPressed(self, i) end)
        EventHelper:RegisterCppDelegate(pWidgetRef["btnCurrencyCoin0"..i].OnReleased, self, function() OnCoinOnReleased(self) end)
        EventHelper:RegisterCppDelegate(pWidgetRef["btnCurrencyCoin0"..i].OnClicked, self, function() OnCoinOnClicked(self, i) end)
    end
    EventHelper:RegisterEvent(ClientEventDef.EV_CURRENCY_COUNT_SYNC, self, OnCurrencyCountSync)
end

function UPCurrencyBar:OnLoad()
    self:ResetCurrency()
end

function UPCurrencyBar:OnShow()
    ShowCurrency(self, self.tbShowCurrency)
end

---外部接口----------------
--默认显示货币：金币、金券、点券
--最多显示四种货币


--添加货币显示，在默认显示货币的基础上增加一种货币显示
function UPCurrencyBar:SetSpecialCurrency(nCurrencyTemplateId)
    if #self.tbShowCurrency > #DEFAULT_CURRENCY_SHOW then
        self.tbShowCurrency[1] = nCurrencyTemplateId
    else
        table.insert(self.tbShowCurrency, 1, nCurrencyTemplateId)
    end

    ShowCurrency(self, self.tbShowCurrency)
end

-- 重置货币为默认显示列表
function UPCurrencyBar:ResetCurrency()
    self.tbShowCurrency = BaseUtil:LightCopyTable(DEFAULT_CURRENCY_SHOW)
    ShowCurrency(self, self.tbShowCurrency)
end

--仅显示参数提供的货币
function UPCurrencyBar:ReloadCurrency(tbCurrencyList)
    self.tbShowCurrency = tbCurrencyList
    ShowCurrency(self, self.tbShowCurrency)
end

function UPCurrencyBar:HideCurrency()
    self.pWidgetRef:SetVisibility(ESlateVisibility_Collapsed)
end

return UPCurrencyBar