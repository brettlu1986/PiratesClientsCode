-----------------------------------------------------
--File Name    : UPPickupExchangeItem.lua
--Author       : zhiyuan
--Create Time  : 2019-06-04
--Description  : 拾取时替换的的up
-----------------------------------------------------
local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPPickupExchangeItem = luaclass("UPPickupExchangeItem", PrefabBase)

local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemColorGradeHelper = require("BattleItemColorGradeHelper")
local UISetUtils = require("UISetUtils")
local UIUtils = require("UIUtils")
local GlobalVariableSystem = require("GlobalVariableSystem_C")

UPPickupExchangeItem.nItemInstanceId = 0
UPPickupExchangeItem.nItemTemplateId = 0
UPPickupExchangeItem.nCurCount = 0
UPPickupExchangeItem.nTotalCount = 0
UPPickupExchangeItem.tbChosenItems = nil
UPPickupExchangeItem.nTotalPickupCount = nil
UPPickupExchangeItem.nLastToastTime = nil

local TOAST_INTERVAL = 1

local function GetMaxCount(self)
    local nChosenCount = 0
    for k, v in pairs(self.tbChosenItems) do
        if k ~= self.nItemTemplateId then
            nChosenCount = nChosenCount + v.nCount
        end
    end
    return math.max(0, self.nTotalPickupCount - nChosenCount)
end

-- local function GetMaxProValue(self)
--     local nMaxCount = GetMaxCount(self)
--     return nMaxCount / self.nTotalCount
-- end

local function RefreshInternal(self)
    local pWidgetRef = self.pWidgetRef
    local nValue = self.nCurCount / self.nTotalCount
    pWidgetRef.sldrController:SetValue(nValue)
    pWidgetRef.pgbContoller:SetPercent(nValue)
    pWidgetRef.ktxtExchangeCount:SetText(string.format("%s/%s", tostring(self.nCurCount), tostring(self.nTotalCount)))
end

local function RefreshBaseInfo(self)
    local pWidgetRef = self.pWidgetRef
    local nItemTemplateId = self.nItemTemplateId
    local tbItemTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    pWidgetRef.ktxtItemName:SetText(tbItemTemplate.l10nName)
    local szColorGradeImg = BattleItemColorGradeHelper.GetColorGradeImg(nItemTemplateId)
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItemBg, szColorGradeImg:load())
    local tbItemResTemplate = BattleItemDataTable:GetResTemplate(nItemTemplateId)
    local szIconPath = tbItemResTemplate.szIconPath
    UISetUtils.SetImageBrushRes(pWidgetRef.imgItem, szIconPath:load(), true)
end

local function OnSlided(self, value)
    -- local nMaxValue = GetMaxProValue(self)
    -- if value > nMaxValue then
    --     value = nMaxValue
    --     local now = GlobalVariableSystem:GetServerTimeUtc()
    --     if now - self.nLastToastTime > TOAST_INTERVAL then
    --         UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("PICKUP_EXCHANGE_ITEM_MAX"))
    --         self.nLastToastTime = now
    --     end
    -- end
    local nMaxCount = GetMaxCount(self)
    self.nCurCount = math.floor(self.nTotalCount * value)
    if self.nCurCount > nMaxCount then
        self.nCurCount = nMaxCount
        local now = GlobalVariableSystem:GetServerTimeUtc()
        if now - self.nLastToastTime > TOAST_INTERVAL then
            UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("PICKUP_EXCHANGE_ITEM_MAX"))
            self.nLastToastTime = now
        end
    end
    if self.nCurCount == 0 then
        self.tbChosenItems[self.nItemTemplateId] = nil
    else
        local tbData = {}
        tbData.nCount = self.nCurCount
        tbData.nItemInstanceId = self.nItemInstanceId
        self.tbChosenItems[self.nItemTemplateId] = tbData
    end
    RefreshInternal(self)
    self.OnCountChangedDelegate:Fire()
end

function UPPickupExchangeItem:RefreshItem(Item)
    if Item then
        self.nTotalCount = Item:GetStackCount()
        self.nCurCount = 0
        self.nItemInstanceId = Item:GetInstanceId()
        self.nItemTemplateId = Item:GetTemplateId()
        self.pWidgetRef:SetVisibility(ESlateVisibility.Visible)
        RefreshBaseInfo(self)
        RefreshInternal(self)
    else
        self.nTotalCount = 0
        self.nCurCount = 0
        self.nItemInstanceId = 0
        self.nItemTemplateId = 0
        self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
    end
    self.nLastToastTime = 0
end

function UPPickupExchangeItem:SetChosenItems(tbChosenItems)
    self.tbChosenItems = tbChosenItems
end

function UPPickupExchangeItem:SetTotalPickupCount(nTotalPickupCount)
    self.nTotalPickupCount = nTotalPickupCount
end

function UPPickupExchangeItem:SetCountChangedDelegate(OnCountChangedDelegate)
    self.OnCountChangedDelegate = OnCountChangedDelegate
end

function UPPickupExchangeItem:OnBindEvent( EventHelper )
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.sldrController.OnValueChanged, self, OnSlided)
end

return UPPickupExchangeItem
