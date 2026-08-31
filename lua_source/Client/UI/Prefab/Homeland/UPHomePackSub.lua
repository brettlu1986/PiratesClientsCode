-----------------------------------------------------
--File Name    : UPHomePackSub.lua
--Author       : zhiyuan
--Create Time  : 2019-05-06
--Description  : 仓库详情up
-----------------------------------------------------
local luaclass = require("luaclass")
local PrefabBase = require("PrefabBase")
local UPHomePackSub = luaclass("UPHomePackSub", PrefabBase)

local CurrencySystem = require("CurrencySystem")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local BuildingDataTable = require("BuildingDataTable")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

UPHomePackSub.Item = nil
UPHomePackSub.nAvailableCount = nil
UPHomePackSub.OnItemSellPressedDelegate = nil

local function OnClickedBtnSell(self)
    if self.OnItemSellPressedDelegate then
        self.OnItemSellPressedDelegate:Fire(self.Item, self.nAvailableCount)
    end
end

local function SetIcon(self, tbItemTemplate)
    local nBuildingId = tbItemTemplate.nBuildingId
    local tbBuildingTemplate = BuildingDataTable:GetTemplate(nBuildingId)
    local szIcon = tbBuildingTemplate.szIcon
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, szIcon:load())
end

local function SetName(self, l10nName)
    self.pWidgetRef.txtName:SetText(l10nName)
end

local function SetDesc(self, l10nDesc)
    self.pWidgetRef.kmtxtDesc:SetText(l10nDesc)
end

local function SetCount(self, nCount)
    self.pWidgetRef.txtCount:SetText(nCount)
end

local function ShowSellPrice(self, nCurrencyId, nPrice)
    self.pWidgetRef.hboxSell:SetVisibility(ESlateVisibility.HitTestInvisible)
    self.pWidgetRef.txtPrice:SetText(nPrice)

    local szCurrencySmallIcon = CurrencySystem:GetCurrencySmallIcon(nCurrencyId)
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgCurrency, szCurrencySmallIcon:load())
    self.pWidgetRef.kmbtnSell:SetVisibility(ESlateVisibility.Visible)
end

local function SetSizeText(self, tbItemTemplate)
    self.pWidgetRef.kmtxtSize:SetText(LobbyItemUiHelper.GetBuildingSizeDesc(tbItemTemplate))
end

local function RefreshBaseInfo(self)
    local Item = self.Item
    SetName(self, Item:GetName())
    SetCount(self, self.nAvailableCount)
    SetDesc(self, ItemSystem:GetItemIntro(Item:GetTemplateId()))
    SetIcon(self, Item:GetTemplate())
    ShowSellPrice(self, Item:GetCurrencyId(), Item:GetSellPrice())
    SetSizeText(self, Item:GetTemplate())
end

----------life cycle----------

function UPHomePackSub:SetData(Item, nAvailableCount)
    self.Item = Item
    self.nAvailableCount = nAvailableCount
    RefreshBaseInfo(self)
end

function UPHomePackSub:OnLoad()
end

function UPHomePackSub:OnShow()
end

function UPHomePackSub:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.kmbtnSell.OnClicked, self, OnClickedBtnSell)
end


function UPHomePackSub:SetOnItemSellPressedDelegate(OnItemSellPressedDelegate)
    self.OnItemSellPressedDelegate = OnItemSellPressedDelegate
end

return UPHomePackSub