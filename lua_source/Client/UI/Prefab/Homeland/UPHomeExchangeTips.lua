-----------------------------------------------------
--File Name    : UPHomeExchangeTips.lua
--Author       : zhiyuan
--Create Time  : 2019-05-09
--Description  : 家园道具兑换的确认框
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomeExchangeTips = luaclass("UPHomeExchangeTips", PrefabBase)

local L10N = require("L10N")
local UITextDef = require("UITextDef")
local ItemDataTable = require("ItemDataTable")
local UIDef = require("UIDef")
local HomelandSystem = require("HomelandSystem")
local UIUtils = require("UIUtils")

UPHomeExchangeTips.tbPbItems = nil
UPHomeExchangeTips.tbExchangeTemplate = nil

local MAX_ITEM_COST = 4

local function SetDescText(self, tbExchangeTemplate)
    local nItemTemplateId = tbExchangeTemplate.nItemTemplateId
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCount = tbExchangeTemplate.nCount
    self.pWidgetRef.kmtxtExchange:SetText(L10N:Format(UITextDef.HOMELAND_EXCHANGE_DESC_FORMAT, nCount, tbItemTemplate.l10nName))
end

local function SetCostItem(self, tbExchangeTemplate)
    local tbPbItems = self.tbPbItems
    local tbCostItems = tbExchangeTemplate.tbCostItems
    local nItemCount = #tbCostItems
    for i = 1, MAX_ITEM_COST do
        local pbItem = tbPbItems[i]
        if i <= nItemCount then
            local tbItemData = tbCostItems[i]
            pbItem:SetDisplayItemData(tbItemData.nItemTemplateId, tbItemData.nCost, true, true)
        else
            pbItem:SetVisible(false)
        end
    end
end

function UPHomeExchangeTips:OnRefresh(tbExchangeTemplate)
    self.tbExchangeTemplate = tbExchangeTemplate
    SetDescText(self, tbExchangeTemplate)
    SetCostItem(self, tbExchangeTemplate)
end

function UPHomeExchangeTips:OnCommitExchange()
    local HomelandExchangeSystem = HomelandSystem:GetSubSystem("HomelandExchangeSystem")
    HomelandExchangeSystem:RequestBuildingExchange(self.tbExchangeTemplate.nId)
end

function UPHomeExchangeTips:OnDisableButtonClicked()
    UIUtils.ShowToast(UITextDef.HOMELAND_EXCHANGE_ITEM_NOT_ENOUGH_TOAST)
end

function UPHomeExchangeTips:OnLoad()
    local pWidgetRef = self.pWidgetRef
    self.tbPbItems = {}
    local tbPbItems = self.tbPbItems
    for i = 1, MAX_ITEM_COST do
        local pbItem = self.PrefabHelper:BindPrefab(pWidgetRef["pbItem0"..i], UIDef.UP_LOBBY_DISPLAY_ITEM)
        tbPbItems[i] = pbItem
    end
end

function UPHomeExchangeTips:OnBindEvent(EventHelper)

end

return UPHomeExchangeTips
