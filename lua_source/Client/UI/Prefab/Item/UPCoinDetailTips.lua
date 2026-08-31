-----------------------------------------------------
--File Name    : UPCoinDetailTips.lua
--Author       : zhiyuan
--Create Time  : 2019-08-07
--Description  : 金币的详情tips，会显示出周获得上限
-----------------------------------------------------
local luaclass          = require ("luaclass")
local UPTipBase         = require("UPTipBase")
local UPCoinDetailTips  = luaclass("UPCoinDetailTips", UPTipBase)

local ItemDataTable     = require("ItemDataTable")
local UIDef             = require("UIDef")
local ItemSystem        = require("ItemSystem")
local L10N              = require("L10N")
local UISetUtils        = require("UISetUtils")
local CurrencySystem    = require("CurrencySystem")

UPCoinDetailTips.pbLobbyDisplayItem = nil

local function GetCoinDetailDesc(nItemTemplateId)
    local l10nItemIntro = ItemSystem:GetItemIntro(nItemTemplateId)
    local szDetailDesc = L10N:ToString(l10nItemIntro) .. "\n"
    local l10nCurrencyLimitDescFormat = UISetUtils.GetL10NTextByKey("CURRENCY_LIMIT_DESC")
    local tbRecords = CurrencySystem:GetCurrencyCeilingsRecords(nItemTemplateId)
    local nObtainCount = 0
    local nObtainMax = 0
    if tbRecords ~= nil then
        nObtainCount = tbRecords.nPeriodicCount
        nObtainMax = tbRecords.nCeiling
    end

    if nObtainCount > nObtainMax then
        nObtainCount = nObtainMax
    end
    local l10nCurrencyLimitDesc = nil
    if nObtainCount == nObtainMax then
        local l10nCurrencyObtainMaxFormat = UISetUtils.GetL10NTextByKey("CURRENCY_OBTAIN_MAX")
        local l10nCurrencyObtainMax = L10N:Format(l10nCurrencyObtainMaxFormat, nObtainCount)
        l10nCurrencyLimitDesc = L10N:Format(l10nCurrencyLimitDescFormat, l10nCurrencyObtainMax, nObtainMax)
    else
        l10nCurrencyLimitDesc = L10N:Format(l10nCurrencyLimitDescFormat, nObtainCount, nObtainMax)
    end

    szDetailDesc = szDetailDesc .. L10N:ToString(l10nCurrencyLimitDesc)
    return szDetailDesc
end

local function SetName(self, l10nName)
    self.pWidgetRef.txtName:SetText(l10nName)
end

local function SetDesc(self, l10nDesc)
    self.pWidgetRef.kmtxtDesc:SetText(l10nDesc)
end

local function CollapsedSizeText(self)
    self.pWidgetRef.kmtxtSize:SetVisibility(ESlateVisibility.Collapsed)
end

local function SetData(self, nItemTemplateId)
    self.pbLobbyDisplayItem:SetDisplayItemData(nItemTemplateId)

    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    SetName(self, tbItemTemplate.l10nName)
    SetDesc(self, GetCoinDetailDesc(nItemTemplateId))
    CollapsedSizeText(self)
end

local function Init(self)
    local tbTipData = self.tbTipData
    if (tbTipData == nil) or (tbTipData.tbTemplate == nil) then
        return
    end

    SetData(self, tbTipData.tbTemplate.nId)
end

function UPCoinDetailTips:OnLoad()
    self.pbLobbyDisplayItem = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItem, UIDef.UP_LOBBY_DISPLAY_ITEM)
end

function UPCoinDetailTips:OnShow()
    Init(self)
end

return UPCoinDetailTips
