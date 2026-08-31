-----------------------------------------------------
--File Name    : ULLobbyShopGoodsList.lua
--Author       : zhiyuan
--Create Time  : 2019-07-19
--Description  : 商店商品列表的UI逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")
local ULLobbyShopGoodsList = luaclass("ULLobbyShopGoodsList", UILogicBase)


local UIDef = require("UIDef")
local ShopSystem = require("ShopSystem")
local ShopDataTable = require("ShopDataTable")
local CurrencySystem = require("CurrencySystem")
local SelfVerticalListHelper = require("SelfVerticalListHelper")

local function fnSortGoods(tbGoodsDataA, tbGoodsDataB)
    local tbGoodsTemplateA = tbGoodsDataA.tbGoodsTemplate
    local tbGoodsTemplateB = tbGoodsDataB.tbGoodsTemplate

    local nItemTemplateIdA = tbGoodsTemplateA.nItemTemplateId
    local nItemTemplateIdB = tbGoodsTemplateB.nItemTemplateId

    if ShopSystem:HasOwned(nItemTemplateIdA) then
        return false
    end

    if ShopSystem:HasOwned(nItemTemplateIdB) then
        return true
    end

    local nSortWeightA = tbGoodsTemplateA.nSortWeight
    local nSortWeightB = tbGoodsTemplateB.nSortWeight
    if nSortWeightA ~= nSortWeightB then
        return nSortWeightA > nSortWeightB
    end

    return tbGoodsTemplateA.nId > tbGoodsTemplateB.nId
end

local function GetGoodsDatas(nShopId, nTabId)
    local tbTemplates = ShopDataTable:GetTemplatesByShopIdAndTabId(nShopId, nTabId)
    local tbGoods = {}
    for _, v in ipairs(tbTemplates) do
        local tbGoodData = {}
        tbGoodData.tbGoodsTemplate = v
        local tbRecord = ShopSystem:GetGoodsRecord(v.nId)
        if tbRecord then
            table.insert(tbGoods, tbGoodData)
        end
    end
    table.sort(tbGoods, fnSortGoods)
    return tbGoods
end

local function GetSpecialCurrencyId(tbGoods)
    for _, v in ipairs(tbGoods) do
        local tbGoodsTemplate = v.tbGoodsTemplate
        local nCurrencyId1 = tbGoodsTemplate.nCurrencyId1
        if not CurrencySystem:IsDefaultDisplayCurrencyIds(nCurrencyId1) then
            return nCurrencyId1
        end

        if tbGoodsTemplate.bHasSecondCurrencyPrice then
            local nCurrencyId2 = tbGoodsTemplate.nCurrencyId2
            if not CurrencySystem:IsDefaultDisplayCurrencyIds(nCurrencyId2) then
                return nCurrencyId2
            end
        end
    end
    return nil
end

local function RefreshCurrencyBar(self, tbGoods)
    local nCurrencyId = GetSpecialCurrencyId(tbGoods)
    if nCurrencyId then
        self.Owner.pbWindowFrame:SetSpecialCurrency(nCurrencyId)
    else
        self.Owner.pbWindowFrame:ResetCurrency()
    end
end

function ULLobbyShopGoodsList:RefreshGoods(nShopId, nTabId, bSort)
    if bSort then
        local tbGoods = GetGoodsDatas(nShopId, nTabId)
        self.ListHelper:SetData(tbGoods)
        self.ListHelper:ScrollToTop(false)
        RefreshCurrencyBar(self, tbGoods)
    else
        self.ListHelper:SetData(self.ListHelper.tbDataList)
    end
end

function ULLobbyShopGoodsList:OnLoad()
    local pWidgetRef =self.pWidgetRef
    self.ListHelper = SelfVerticalListHelper()
    self.ListHelper:Init(self, pWidgetRef.kmlistItems, {}, UIDef.UP_LOBBY_SHOP_ITEM)
end

function ULLobbyShopGoodsList:OnUnload()
    self.ListHelper:Uninit()
end

function ULLobbyShopGoodsList:OnBindEvent(EventHelper)
end


return ULLobbyShopGoodsList