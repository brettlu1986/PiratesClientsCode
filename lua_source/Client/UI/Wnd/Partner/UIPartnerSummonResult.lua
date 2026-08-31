-----------------------------------------------------
--File Name    : UIPartnerSummonResult.lua
--Author       : Song Fuhao
--Create Time  : 2019-03-06
--Description  : 伙伴招募结果
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UIPartnerSummonResult = luaclass("UIPartnerSummonResult", WndBase)

local L10N = require("L10N")
local UIDef = require("UIDef")
local UIUtils = require("UIUtils")
local UISetUtils = require("UISetUtils")
local EventManager = require("EventManager")
local UIResourceDef = require("UIResourceDef")
local CurrencySystem = require("CurrencySystem")
local ClientEventDef = require("ClientEventDef")
local PartnerPoolDataTable = require("PartnerPoolDataTable")

local SUMMON_ONE_TIME_COUNT = 1
local SUMMON_TEN_TIMES_COUNT = 10

UIPartnerSummonResult.nPoolId = 1
UIPartnerSummonResult.nSummonCount = SUMMON_ONE_TIME_COUNT
UIPartnerSummonResult.tbPartnerMiniItems = nil

local function BindPartnerItem(self, tbSummonResults)
    self.tbPartnerMiniItems = {}
    for i,v in ipairs(tbSummonResults) do
        local pbPartnerMiniItem = self.PrefabHelper:BindPrefab(self.pWidgetRef["pbPartnerMiniItem_"..i], UIDef.UP_PARTNER_SUMMON_RESULT_ITEM)
        pbPartnerMiniItem:SetSummonResult(v)
        pbPartnerMiniItem.pWidgetRef:SetVisibility(ESlateVisibility.HitTestInvisible)
        self.tbPartnerMiniItems[i] = pbPartnerMiniItem
    end
end

local function UpdatePoolInfo(self)
    local pWidgetRef = self.pWidgetRef
    local tbTemplate = PartnerPoolDataTable:GetTemplate(self.nPoolId)
    local nCurrencyId = tbTemplate.nCurrencyId
    -- 刷新货币图标
    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    local pCurrencyIcon = szCurrencySmallIcon:load()
    local nPrice = (self.nSummonCount == SUMMON_ONE_TIME_COUNT) and tbTemplate.nOneTimeCount or tbTemplate.nTenTimesCount
    UISetUtils.SetImageBrushRes(pWidgetRef.imgCurrency, pCurrencyIcon)
    -- 刷新货币价格
    pWidgetRef.txtCurrency:SetText(nPrice)
    -- 刷新是否可以招募相关表现
    local nCurrencyCount = CurrencySystem:GetCurrencyCount(nCurrencyId)
    local bEnoughOne = nCurrencyCount >= nPrice
    pWidgetRef.txtCurrency:SetColorAndOpacity(bEnoughOne and UIResourceDef.COLOR.WHITE.SLATE_COLOR or UIResourceDef.COLOR.RED.SLATE_COLOR)
    pWidgetRef.btnSummon:SetIsEnabled(bEnoughOne)
    pWidgetRef.txtSummon:SetText(L10N:Format(UISetUtils.GetL10NTextByKey("PARTNER_SUMMON_AGAIN"), self.nSummonCount))
end

local function OnClickedBtnConfirm(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_PARTNER_SUNMMON_RESULT_CLOSED)
    self:CloseSelf()
end

local function OnClickedBtnSummon(self)
    EventManager:OnFireEvent(ClientEventDef.EV_ON_PARTNER_SUNMMON_AGAIN)
    self:CloseSelf()
end

local function OnDisableClickedBtnSummon(self)
    UIUtils.ShowToastWithKey("PARTNER_SUMMON_FAILED_MONEY")
end

local function OnPlayItemEffect(self, nStartIndex, nEndIndex)
    for i = nStartIndex, nEndIndex do
        if self.tbPartnerMiniItems[i] then
            self.tbPartnerMiniItems[i]:ShowGradeEffect()
        end
    end
end

function UIPartnerSummonResult:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnConfirm.OnClicked, self, OnClickedBtnConfirm)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummon.OnClicked, self, OnClickedBtnSummon)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnSummon.OnDisableClicked, self, OnDisableClickedBtnSummon)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.OnPlayItemEffect, self, OnPlayItemEffect)
end

function UIPartnerSummonResult:OnEnter()
    local tbSummonResults = self.tbOpenArgs.tbSummonResults
    self.nPoolId = self.tbOpenArgs.nPoolId
    self.nSummonCount = (#tbSummonResults == SUMMON_ONE_TIME_COUNT) and SUMMON_ONE_TIME_COUNT or SUMMON_TEN_TIMES_COUNT

    BindPartnerItem(self, tbSummonResults)
    UpdatePoolInfo(self)

    self:PlayAnimation("animSummonNew", 0, 1, EUMGSequencePlayMode.Forward, 1, function()
        --引导时需要的事件
    end)
end

return UIPartnerSummonResult