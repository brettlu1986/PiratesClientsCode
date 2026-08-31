-----------------------------------------------------
--File Name    : LobbyCaptainVisual.lua
--Author       : WuJizhou
--Create Time  : 9/20/2020, 10:54:54 AM
--Description  : LobbyCaptainVisual
-----------------------------------------------------
local LobbyCaptainVisual = {}

local SelfEventHelper = require("SelfEventHelper")
local UIManager = require("UIManager")
local UIDef = require("UIDef")
local ClientEventDef = require("ClientEventDef")
local ItemDataTable = require("ItemDataTable")
local ItemSystem = require("ItemSystem")
local ItemCategoryDef = require("ItemCategoryDef")
local CostCurrencyHelper = require("CostCurrencyHelper")

LobbyCaptainVisual.tbOwnerSystem = nil
LobbyCaptainVisual.CacheItemTemplateId = nil

local tbAllUI = {
    UIDef.UI_LOBBY_CAPTAIN_VISUAL,
}

local function ShowUI(self, tbParams)
    tbParams.tbOwnerSystem = self.tbOwnerSystem
    UIManager:OpenWnd(UIDef.UI_LOBBY_CAPTAIN_VISUAL, tbParams)
end

local function CloseUI(self)
    for _, szUI in ipairs(tbAllUI) do
        UIManager:CloseWnd(szUI)
    end
end

local function ShowScene(self)
    self.tbOwnerSystem:SetShouldBeVisible(UIDef.UI_LOBBY_CAPTAIN_VISUAL, true)
    self.tbOwnerSystem:SetCamera(UIDef.UI_LOBBY_CAPTAIN_VISUAL, 1)
end

local function CloseScene(self)
    self.tbOwnerSystem:SetShouldBeVisible(UIDef.UI_LOBBY_CAPTAIN_VISUAL, false)
end

local function OnBuyItem(self, nItemTemplateId)
    self.CacheItemTemplateId = nItemTemplateId
end

local function OnShopNotEnoughCurrency(self, tbShoppingGoods)
    if not tbShoppingGoods.currency_auto_exchange then
        CostCurrencyHelper:FirstCostFailed()
    else
        CostCurrencyHelper:SecondCostFailed()
    end
end


local function DoActive(self, tbParams)
    tbParams = tbParams == nil and {} or tbParams
    ShowScene(self)
    ShowUI(self, tbParams)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_BUY_ITEM, self, OnBuyItem)
    self.EventHelper:RegisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, self, OnShopNotEnoughCurrency)
end

local function OnTryToWearFinished(self, tbParams)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED)
    DoActive(self, tbParams)
end

local function TryToWear(self, tbParams)
    local nItemTemplateId = tbParams.nItemTemplateId
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    local tbTakeOffInstanceIds = {}
    local tbPutOnInstanceIds = {}
    if nCategory == ItemCategoryDef.FASHION or nCategory == ItemCategoryDef.HUMAN_WEAPON_FASHION then
        local tbItems = ItemSystem:GetItemsByTemplateId(nItemTemplateId)
        if tbItems and #tbItems > 0 then
            local tbItem = tbItems[1]
            table.insert(tbPutOnInstanceIds, tbItem:GetInstanceId())
        end
    elseif nCategory == ItemCategoryDef.SUIT then
        local bHas, tbItems = ItemSystem:HasFashionItem(nItemTemplateId)
        if bHas then
            for _, tbItem in ipairs(tbItems) do
                table.insert(tbPutOnInstanceIds, tbItem:GetInstanceId())
            end
        end
    end
    if #tbPutOnInstanceIds > 0 then
        for _, nInstanceId in ipairs(tbPutOnInstanceIds) do
            self.EventHelper:FireEvent(ClientEventDef.EV_SELECT_LOBBY_ITEM, nInstanceId)
        end
        ItemSystem:RequestToFitFashion(tbPutOnInstanceIds, tbTakeOffInstanceIds)
        self.EventHelper:RegisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED, self, function () OnTryToWearFinished(self, tbParams) end)
    else
        OnTryToWearFinished(self)
    end
end

local function ProcessParams(self, tbParams)
    local bProcess = false
    if tbParams and tbParams.nItemTemplateId then
        TryToWear(self, tbParams)
        bProcess = true
    end
    return bProcess
end


function LobbyCaptainVisual:Init()
    self.EventHelper = SelfEventHelper()
end

function LobbyCaptainVisual:Uninit()
    self.EventHelper = nil
end

function LobbyCaptainVisual:Activate(tbOwnerSystem, tbParams)
    self.tbOwnerSystem = tbOwnerSystem
    local bWaitingProcessParams = ProcessParams(self, tbParams)
    if not bWaitingProcessParams then
        DoActive(self)
    end
end
 

function LobbyCaptainVisual:Deactivate()
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_FASHION_DO_CHANGED)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_LOBBY_CAPTAIN_BUY_ITEM)
    self.EventHelper:UnregisterEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY)
    CloseScene(self)
    CloseUI(self)
end

function LobbyCaptainVisual:MakeContext(tbOutContext)
    tbOutContext.nItemTemplateId = self.CacheItemTemplateId
    self.CacheItemTemplateId = nil
end

function LobbyCaptainVisual:ParseContext(tbContext, tbOutParam)
    tbOutParam.nItemTemplateId = tbContext.nItemTemplateId
end


return LobbyCaptainVisual