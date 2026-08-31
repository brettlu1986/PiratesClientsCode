-----------------------------------------------------
--File Name    : UPHomeItemExchange.lua
--Author       : zhiyuan
--Create Time  : 2019-05-08
--Description  : 道具兑换的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPHomeItemExchange = luaclass("UPHomeItemExchange", ListItemBase)

local ItemDataTable = require("ItemDataTable")
local BuildingDataTable = require("BuildingDataTable")
local UISetUtils = require("UISetUtils")
local LobbyItemUiHelper = require("LobbyItemUiHelper")

UPHomeItemExchange.tbExchangeTemplate = nil
UPHomeItemExchange.OnExchangeButtonPressedDelegate = nil

local function OnClicked(self)
    if self.OnExchangeButtonPressedDelegate then
        self.OnExchangeButtonPressedDelegate:Fire(self.tbExchangeTemplate)
    end
end

local function SetIcon(self, tbItemTemplate)
    local nBuildingId = tbItemTemplate.nBuildingId
    local tbBuildingTemplate = BuildingDataTable:GetTemplate(nBuildingId)
    local szIcon = tbBuildingTemplate.szIcon
    UISetUtils.SetImageBrushRes(self.pWidgetRef.imgIcon, szIcon:load())
end

local function SetName(self, l10nName)
    self.pWidgetRef.kmtxtName:SetText(l10nName)
end

local function SetSizeText(self, tbItemTemplate)
    self.pWidgetRef.kmtxtSize:SetText(LobbyItemUiHelper.GetBuildingSizeDesc(tbItemTemplate))
end

local function Refresh(self, tbData)
    local tbExchangeTemplate = tbData.tbTemplate
    self.tbExchangeTemplate = tbExchangeTemplate
    self.OnExchangeButtonPressedDelegate = tbData.OnExchangeButtonPressedDelegate

    local tbItemTemplate = ItemDataTable:GetTemplate(tbExchangeTemplate.nItemTemplateId)

    SetName(self, tbItemTemplate.l10nName)
    SetIcon(self, tbItemTemplate)
    SetSizeText(self, tbItemTemplate)
end

function UPHomeItemExchange:OnRefresh(tbData)
    Refresh(self, tbData)
end

function UPHomeItemExchange:OnBindEvent(EventHelper)
    EventHelper:RegisterCppDelegate(self.pWidgetRef.btnExchange.OnClicked, self, OnClicked)
end

return UPHomeItemExchange
