-----------------------------------------------------
--File Name    : ShopSystem.lua
--Author       : zhiyuan
--Create Time  : 2019-07-19
--Description  : 商店系统
-----------------------------------------------------
local ShopSystem = {}

local L10N = require("L10N")
local UIDef = require("UIDef")
local ShopIni = require("ShopIni")
local UIUtils = require("UIUtils")
local TimeUtil = require("TimeUtil")
local UIManager = require("UIManager")
local UISetUtils = require("UISetUtils")
local ItemSystem = require("ItemSystem")
local DelayTimer = require("DelayTimer")
local Proto = require("ClientProtoNames")
local CurrencyIni = require("CurrencyIni")
local EventManager = require("EventManager")
local ItemDataTable = require("ItemDataTable")
local ShopDataTable = require("ShopDataTable")
local AwardDataTable = require("AwardDataTable")
local ClientEventDef = require("ClientEventDef")
local SelfEventHelper = require("SelfEventHelper")
local ItemCategoryDef = require("ItemCategoryDef")
local PlayerSelfHelper = require("GamePlayerSelfHelper")
local NetworkManager = dynamic_require("NetworkManager")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local AwardGiftBoxDataTable = require("AwardGiftBoxDataTable")

ShopSystem.tbRefreshShopTimer = nil
ShopSystem.bShopNeedRefresh = nil
ShopSystem.bInLobby = false

local DELAY_SECONDS_MAX = 5

local UNEXCHANGED_ID = CurrencyIni.tbExchange.nUnchangedId
local EXCHANGED_ID = CurrencyIni.tbExchange.nExchangedId
local EXCHANGE_RATIO = CurrencyIni.tbExchange.nExchangeRatio
-----------------------------------------local function---------------------------------------------
local function GetShopComponent()
    local PlayerSelf = PlayerSelfHelper:Get()
    local ShopComponent = PlayerSelf.ShopComponent
    if ShopComponent == nil then
        error("GetShopComponent failed!ShopComponent == nil!")
    end
    return ShopComponent
end

local function RequestRefreshShop(self)
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_RefreshGoods)
    self.bShopNeedRefresh = false
end

local function RequestGoShopping(nGoodsId, nGoodsCount, nCurrencyId, bAutoExchange)
    local tbShoppingGoods = {
        goods_id = nGoodsId,
        goods_count = nGoodsCount,
        currency_id = nCurrencyId,
        currency_auto_exchange = bAutoExchange
    }
    local c2s_GoShopping = {
        shopping_goods = tbShoppingGoods
    }
    NetworkManager:GetHubServerProxy():SendPacket(Proto.c2s_GoShopping, c2s_GoShopping)
end

local function ClearRefreshShopTimer(self)
    log("[Shop]ClearRefreshShopTimer")
    if self.tbRefreshShopTimer ~= nil then
        DelayTimer:ClearTimer(self.tbRefreshShopTimer)
        self.tbRefreshShopTimer = nil
    end
end

local function StartRefreshShopTimer(self, nRemainSeconds)
    log("[Shop]StartRefreshShopTimer", nRemainSeconds)
    if self.tbRefreshShopTimer ~= nil then
        error("Already Start RefreshShopTimer!")
    end
    local FunRefreshShopCallback = function()
        self.tbRefreshShopTimer = nil
        if UIManager:IsWndOpen(UIDef.UI_LOBBY_SHOP) then
            RequestRefreshShop(self)
        else
            self.bShopNeedRefresh = true
        end
    end
    local nRandomDelaySeconds = math.random(1, DELAY_SECONDS_MAX)
    local DelayHandle = DelayTimer:DelayRun(FunRefreshShopCallback, nRemainSeconds + nRandomDelaySeconds)
    self.tbRefreshShopTimer = DelayHandle
end

local function CheckBuyLimit(self, tbGoodsTemplate)
    if tbGoodsTemplate.bHasBuyLimit then
        local nBuyTimes = self:GetBuyTimes(tbGoodsTemplate.nId)
        local nRemainBuyTimes = math.max(0, tbGoodsTemplate.nBuyLimit - nBuyTimes)
        if nRemainBuyTimes <= 0 then
            if tbGoodsTemplate.bHasBuyLimitRefreshMinute then
                local nRemainDay = self:GetRemainRefreshDay(tbGoodsTemplate)
                if nRemainDay then
                    UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("SHOP_REFRESH_GOODS_CANNOT_BUY_COUNT_LIMIT"), nRemainDay))
                else
                    UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_CANNOT_BUY_COUNT_LIMIT"))
                end
            else
                UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_CANNOT_BUY_COUNT_LIMIT"))
            end
            return false
        else
            return true
        end
    end
    return true
end

local function IsOwnedPermanentItem(nTemplateId)
    local tbItems = ItemSystem:GetItemsByTemplateId(nTemplateId)
    if tbItems and (#tbItems > 0) then
        local Item = tbItems[1]
        if Item:HasExpiration() then
            return false
        end
        return true
    end
    return false
end

local function CheckShipSkinHasShip(tbGoodsTemplate)
    local nItemTemplateId = tbGoodsTemplate.nItemTemplateId
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbItemTemplate.nCategory
    if nCategory == ItemCategoryDef.SHIP_SKIN then
        local nShipItemId = tbItemTemplate.nShipItemId
        if IsOwnedPermanentItem(nShipItemId) then
            return true
        else
            local l10nToastFormat = UISetUtils.GetL10NTextByKey("SHOP_SHIP_SKIL_BUT_NO_SHIP")
            local tbShipItemTemplate = ItemDataTable:GetTemplate(nShipItemId)
            local l10nToast = L10N:Format(l10nToastFormat, tbShipItemTemplate.l10nName, tbItemTemplate.l10nName)
            UIUtils.ShowToast(l10nToast)
            return false
        end
    else
        return true
    end
end

local function CheckCanBuy(self, tbGoodsTemplate)
    if CheckBuyLimit(self, tbGoodsTemplate)
        and CheckShipSkinHasShip(tbGoodsTemplate)
    then
        return true
    end
    return false
end

local function OnPlayerDataSync(self)
    RequestRefreshShop(self)
end

local function CheckShopGoodRefreshWithNoRecord(self, tbGoodsTemplate, now, nRefreshTime)
    local nShelfTime = tbGoodsTemplate.bHasShelfTime and tbGoodsTemplate.nShelfTime or now
    local nDiscountTime = tbGoodsTemplate.bHasDiscountTime and tbGoodsTemplate.nDiscountTime or now

    local tbRefTimes = { nShelfTime, nDiscountTime }
    local nMinTime = nil
    for _, v in pairs( tbRefTimes ) do
        if v > now then
            if nMinTime == nil or v < nMinTime then
                nMinTime = v
            end
        end
    end
    if nMinTime then
        if not nRefreshTime or nMinTime < nRefreshTime then
            return nMinTime
        end
    end
    return nRefreshTime
end

local function CheckShopGoodRefreshWithRecord(self, tbGoodsTemplate, tbRecords, now, nRefreshTime)
    local nNewRefreshTime = nRefreshTime
    local nNextRefreshTime = self:GetNextRefreshTime(tbGoodsTemplate)

    if not nNewRefreshTime or (nNextRefreshTime and nNextRefreshTime < nNewRefreshTime) then
        nNewRefreshTime = nNextRefreshTime
    end
    if tbGoodsTemplate.bHasShelfTime then
        local nShelfTime = tbGoodsTemplate.nShelfTime
        if nShelfTime > now then
            if not nNewRefreshTime or nShelfTime < nNewRefreshTime then
                nNewRefreshTime = nShelfTime
            end
        else
            local nEndTime = nShelfTime + tbGoodsTemplate.nDurationSeconds
            if nEndTime > now then
                if not nNewRefreshTime or nEndTime < nNewRefreshTime then
                    nNewRefreshTime = nEndTime
                end
            end
        end
    end

    --将打折时间加到计算下次刷新时间中
    if tbGoodsTemplate.bHasDiscountTime then
        local nDiscountTime =  tbGoodsTemplate.nDiscountTime
        local nDiscountEndTime = tbGoodsTemplate.nDiscountTime + tbGoodsTemplate.nDiscountDurationSeconds
        if nDiscountTime > now then
            if not nNewRefreshTime or nDiscountTime < nNewRefreshTime then
                nNewRefreshTime = nDiscountTime
            end
        else
            if nDiscountEndTime > now then
                if not nNewRefreshTime or nDiscountEndTime < nNewRefreshTime then
                    nNewRefreshTime = nDiscountEndTime
                end
            end
        end
    end

    return nNewRefreshTime
end

local function CheckShopRefresh(self)
    local ShopComponent = GetShopComponent()
    local tbGoodsTemplates = ShopDataTable:GetAllGoodsTemplate()
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nRefreshTime = nil
    for nGoodsId, tbGoodsTemplate in pairs(tbGoodsTemplates) do
        local tbRecords = ShopComponent:GetGoodsRecord(nGoodsId)
        if tbRecords == nil then
            nRefreshTime = CheckShopGoodRefreshWithNoRecord(self, tbGoodsTemplate, now, nRefreshTime)
        else
            nRefreshTime = CheckShopGoodRefreshWithRecord(self, tbGoodsTemplate, tbRecords, now, nRefreshTime)
        end
    end

    if nRefreshTime then
        self.nNextRefreshTime = nRefreshTime
        if self.bInLobby then
            local nRemainSeconds = nRefreshTime - now
            StartRefreshShopTimer(self, nRemainSeconds)
        end
    end
end

local function ResetShopTimer(self)
    if self.nNextRefreshTime then
        local now = GlobalVariableSystem:GetServerTimeUtc()
        local nRemainSeconds = self.nNextRefreshTime - now
        if nRemainSeconds > 0 then
            StartRefreshShopTimer(self, nRemainSeconds)
        else
            RequestRefreshShop(self)
        end
    end
end

local function OnEnterLobby(self)
    log("[Shop]ShopSystem OnEnterLobby")
    self.bInLobby = true
    if self.tbRefreshShopTimer ~= nil then
        return
    end
    ClearRefreshShopTimer(self)
    ResetShopTimer(self)
end

local function OnLeaveLobby(self)
    self.bInLobby = false
    log("[Shop]ShopSystem OnLeaveLobby")
    ClearRefreshShopTimer(self)
end

local function OnEnterBattle(self)
    log("[Shop]ShopSystem OnEnterBattle")
    ClearRefreshShopTimer(self)
end

-----------------------------------------System Init UnInit---------------------------------------------

function ShopSystem:Init()
    local EventHelper = SelfEventHelper()
    self.EventHelper = EventHelper
    ClearRefreshShopTimer(self)
    EventHelper:RegisterEvent(ClientEventDef.EV_PLAYERDATA_SYNC, self, OnPlayerDataSync)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_LOBBY, self, OnEnterLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_LEAVE_PROCEDURE_LOBBY, self, OnLeaveLobby)
    EventHelper:RegisterEvent(ClientEventDef.EV_ENTER_PROCEDURE_BATTLE, self, OnEnterBattle)
    return true
end

function ShopSystem:Uninit()
    ClearRefreshShopTimer(self)
    self.EventHelper:UnregisterAll()
end

-----------------------------------------给外部模块的调用接口---------------------------------------------

-- 打开商店UI
-- @param nDefaultShop 默认选中的商店id，可以不填
function ShopSystem:OpenShop(nDefaultShop)
    if self.bShopNeedRefresh then
        RequestRefreshShop(self)
    end
    UIManager:OpenWnd(UIDef.UI_LOBBY_SHOP, { nDefaultShop = nDefaultShop })
end

function ShopSystem:GetGoodsRecord(nGoodsId)
    local ShopComponent = GetShopComponent()
    return ShopComponent:GetGoodsRecord(nGoodsId)
end

function ShopSystem:HasOwned(nItemTemplateId)
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate.bHasHoldLimit and IsOwnedPermanentItem(nItemTemplateId) then
        return true
    end

    if tbItemTemplate.nCategory == ItemCategoryDef.GIFT_BOX then
        local nAwardId = tbItemTemplate.nGiftBoxRewardId or 0
        local tbAwardItems = AwardDataTable:GetAwardItem(nAwardId)
        if not tbAwardItems then
            return false
        end
        local bOwnedGiftBoxItems = true
        for _, v in pairs(tbAwardItems) do
            local tbAwardItem = ItemDataTable:GetTemplate(v.nItemId)
            if not tbAwardItem.bHasHoldLimit or not IsOwnedPermanentItem(v.nItemId) then
                bOwnedGiftBoxItems = false
                break
            end
        end
        return bOwnedGiftBoxItems
    elseif tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
        return ItemSystem:HasFashionItem(nItemTemplateId)
    elseif tbItemTemplate.nCategory == ItemCategoryDef.DECORATION then
        local tbDecorationsInBag = ItemSystem:GetItemsByCategory(ItemCategoryDef.DECORATION)
        for _, item in pairs(tbDecorationsInBag) do
           local tbEquipTemplate = item:GetTemplate()
           if  tbEquipTemplate.nSubCategory == tbItemTemplate.nSubCategory then  
               return true
           end 
        end
    end
    return false
end

function ShopSystem:IsBuyLimit(nGoodsId)
    local tbGoodsTemplate = ShopDataTable:GetTemplate(nGoodsId)
    if tbGoodsTemplate.bHasBuyLimit then
        local tbRecords = self:GetGoodsRecord(nGoodsId)
        local nBuyTimes = 0
        if tbRecords then
            nBuyTimes = tbRecords.buy_times
        end
        if nBuyTimes < tbGoodsTemplate.nBuyLimit then
            return true
        else
            return false
        end
    else
        return false
    end
end

function ShopSystem:GetBuyTimes(nGoodsId)
    local tbGoodsTemplate = ShopDataTable:GetTemplate(nGoodsId)
    if tbGoodsTemplate.bHasBuyLimit then
        local tbRecords = self:GetGoodsRecord(nGoodsId)
        local nBuyTimes = 0
        if tbRecords then
            nBuyTimes = tbRecords.buy_times
        end
        return nBuyTimes
    else
        return 0
    end
end

function ShopSystem:GetRemainBuyDay(tbGoodsTemplate)
    if tbGoodsTemplate.bHasShelfTime then
        local now = GlobalVariableSystem:GetServerTimeUtc()
        local nShelfTime = tbGoodsTemplate.nShelfTime
        local nEndTime = nShelfTime + tbGoodsTemplate.nDurationSeconds
        local nDay = math.ceil((nEndTime - now) / TimeUtil.GetOneDaySeconds())
        if nDay <= 0 then
            logerror("remain day less than 0!!!", nDay)
            return nil
        end
        return nDay
    end
    return nil
end

function ShopSystem:IsDiscountCurrency(nCurrencyId, tbGoodsTemplate)
    if tbGoodsTemplate.bHasDiscountTime then
        return nCurrencyId == tbGoodsTemplate.nDiscountCurrencyId
    end
    return false
end

function ShopSystem:GetRemainDiscountDay(tbGoodsTemplate)
    if tbGoodsTemplate.bHasDiscountTime then
        local now = GlobalVariableSystem:GetServerTimeUtc()
        local nDiscountTime = tbGoodsTemplate.nDiscountTime
        if nDiscountTime > now then
            return nil
        end
        local nEndTime = nDiscountTime + tbGoodsTemplate.nDiscountDurationSeconds
        local nDay = math.ceil((nEndTime - now) / TimeUtil.GetOneDaySeconds())
        if nDay <= 0 then
            return nil
        end
        return nDay
    end
    return nil
end

local function GetExChangedCurrency(nUnExchangeCurrencyId, nUnExchangeCount, nTargetCurrencyId)
    if not nUnExchangeCurrencyId then
        return nil
    end

    if nUnExchangeCurrencyId == nTargetCurrencyId then
        return nUnExchangeCount
    else
        if nUnExchangeCurrencyId == UNEXCHANGED_ID and nTargetCurrencyId == EXCHANGED_ID then
            return nUnExchangeCount // EXCHANGE_RATIO
        elseif nUnExchangeCurrencyId == EXCHANGED_ID and nTargetCurrencyId == UNEXCHANGED_ID then
            return math.floor(nUnExchangeCount * EXCHANGE_RATIO)
        end
    end
    return nil
end

function ShopSystem:GetCompensationPrice(tbGoodsTemplate, bCaculateDiscount)
    if tbGoodsTemplate.bCompensation then
        local tbItemTemplate = ItemDataTable:GetTemplate(tbGoodsTemplate.nItemTemplateId)
        local nCategory = tbItemTemplate.nCategory
        if nCategory == ItemCategoryDef.GIFT_BOX then
            local nGiftBoxCurrency = tbGoodsTemplate.nCurrencyId1
            local nGiftBoxPrice = tbGoodsTemplate.nCurrencyCount1

            local nAwardId = tbItemTemplate.nGiftBoxRewardId or 0
            local tbAwardItems = AwardDataTable:GetAwardItem(nAwardId)
            for _, v in pairs(tbAwardItems) do
                if self:HasOwned(v.nItemId) then
                    local tbShopItem = ShopDataTable:GetItemGoodsTemplate(v.nItemId)

                    if tbShopItem then
                        local nExchangeCurrency1 = GetExChangedCurrency(tbShopItem.nCurrencyId1, tbShopItem.nCurrencyCount1, nGiftBoxCurrency)
                        local nExchangeCurrency2 = GetExChangedCurrency(tbShopItem.nCurrencyId2, tbShopItem.nCurrencyCount2, nGiftBoxCurrency)
                        local nRealCost = nExchangeCurrency1 or nExchangeCurrency2
                        if nRealCost then
                            nGiftBoxPrice = nGiftBoxPrice - nRealCost
                        end
                    end
                end
            end

            if nGiftBoxPrice < 0 then
                logerror(" Compensation gift box price wrong")
            end
            if bCaculateDiscount then
                local bIsDiscountCurrency = self:IsDiscountCurrency(nGiftBoxCurrency, tbGoodsTemplate)
                local nRemainDays = self:GetRemainDiscountDay(tbGoodsTemplate)
                if bIsDiscountCurrency and nRemainDays then
                    nGiftBoxPrice = math.floor(nGiftBoxPrice * tbGoodsTemplate.nDiscountRate)
                end
            end

            return nGiftBoxPrice
        end
    end
    return nil
end

--后面用于显示 宝箱详情
function ShopSystem:GetGiftBoxItems(nGiftBoxTemplateId)
    
    local tbItemTemplate = ItemDataTable:GetTemplate(nGiftBoxTemplateId)
    local nAwardId = tbItemTemplate.nGiftBoxRewardId or 0
    local tbAwardItems = AwardDataTable:GetAwardItem(nAwardId)
    if tbAwardItems == nil then
        tbAwardItems = AwardGiftBoxDataTable:GetAwardItem(nAwardId)
    end

    -- for _, v in pairs(tbAwardItems) do
    --     local tbShopItem = ShopDataTable:GetItemGoodsTemplate( v.nItemId)
    --     logdebug("the award id is::", v.nItemId, v.nCount, tbShopItem.nId)
    -- end

    return tbAwardItems
end

function ShopSystem:GetValidDiscountPrice(nCurrencyId, tbGoodsTemplate)
    local bIsDiscountCurrency = self:IsDiscountCurrency(nCurrencyId, tbGoodsTemplate)
    local nRemainDays = self:GetRemainDiscountDay(tbGoodsTemplate)
    if bIsDiscountCurrency and nRemainDays then
        return self:GetDiscountPrice(tbGoodsTemplate.nId)
    end
    return nil
end

function ShopSystem:GetDiscountPrice(nGoodsId)
    local tbGoodsTemplate = ShopDataTable:GetTemplate(nGoodsId)
    if tbGoodsTemplate.bHasDiscountTime then
        local tbRecords = self:GetGoodsRecord(nGoodsId)
        local nPrice = 0
        if tbRecords then
            for _, v in pairs(tbRecords.GoodsCurrency) do
                if tbGoodsTemplate.nDiscountCurrencyId == v.template_id then
                    nPrice = v.count
                    break
                end
            end
        end
        return nPrice
    else
        return 0
    end
end

function ShopSystem:GetNextRefreshTime(tbGoodsTemplate)
    if tbGoodsTemplate.bHasBuyLimitRefreshMinute then
        local nFirstRefreshTime = ShopIni.tbShopRefresh.nFirstRefreshTime  --上一次商店第一次刷新时间
        local nBuyLimitRefreshSeconds = tbGoodsTemplate.nBuyLimitRefreshSeconds --时间间隔
        local now = GlobalVariableSystem:GetServerTimeUtc()

        local ShopComponent = GetShopComponent()
        local tbRecord = ShopComponent:GetGoodsRecord(tbGoodsTemplate.nId)
        if not tbRecord then
            logerror("Cannot find goods record!", tbGoodsTemplate.nId)
            return nil
        end
        local nLastRefreshSeconds = tbRecord.refresh_seconds  --上一次的刷新时间
        if not nLastRefreshSeconds or nLastRefreshSeconds < nFirstRefreshTime then
            nLastRefreshSeconds = nFirstRefreshTime
        end

        --商品的上架时间
        if tbGoodsTemplate.bHasShelfTime and nLastRefreshSeconds < tbGoodsTemplate.nShelfTime then
            nLastRefreshSeconds = tbGoodsTemplate.nShelfTime
        end
        local nRefreshTimes = (now - nLastRefreshSeconds)//nBuyLimitRefreshSeconds
        local nNextRefreshTime = nLastRefreshSeconds + nBuyLimitRefreshSeconds * (nRefreshTimes + 1)
        if tbGoodsTemplate.bHasShelfTime then
            local nShelfTime = tbGoodsTemplate.nShelfTime
            local nEndTime = nShelfTime + tbGoodsTemplate.nDurationSeconds
            if nNextRefreshTime >= nEndTime then
                return nil
            end
        end
        if nNextRefreshTime < now then
            error("GetRemainRefreshDay error!!!nNextRefreshTime:"..nNextRefreshTime..", now:"..now)
        end
        return nNextRefreshTime
    end
    return nil
end

function ShopSystem:GetRemainRefreshDay(tbGoodsTemplate)
    local now = GlobalVariableSystem:GetServerTimeUtc()
    local nNextRefreshTime = self:GetNextRefreshTime(tbGoodsTemplate)
    if nNextRefreshTime then
        local nDay = math.ceil((nNextRefreshTime - now) / TimeUtil.GetOneDaySeconds())
        if nDay <= 0 then
            logerror("remain day less than 0!!!")
            return nil
        end
        return nDay
    end
    return nil
end

function ShopSystem:OnBuyButtonClick(tbGoodsTemplate, bStartAwardSession)
    if CheckCanBuy(self, tbGoodsTemplate) then
        local tbItemTemplate = ItemDataTable:GetTemplate(tbGoodsTemplate.nItemTemplateId)
        local nCategory = tbItemTemplate.nCategory
        if nCategory == ItemCategoryDef.GIFT_BOX then
            UIManager:OpenWnd(UIDef.UI_LOBBY_SHOP_GIFTBOX_PURCHASE, {nItemTemplateId = tbGoodsTemplate.nItemTemplateId, nGoodsId = tbGoodsTemplate.nId})
        else
            local szTopWnd = nil
            if bStartAwardSession then
                szTopWnd = UIManager:GetWndStackTop()
            end
            UIManager:OpenWnd(UIDef.UI_LOBBY_SHOP_ITEM_PURCHASE, {tbGoodsTemplate = tbGoodsTemplate, szSourceWndName = szTopWnd})
        end
    end
end

--这个 buy btn的购买点击，会优先去礼包里找，如果礼包里有就走礼包购买，然后才会去找商城是否有该物品
function ShopSystem:OnBuyButtonClickByTemplateId(nItemTemplateId)
    local tbGoodsTempate = nil
    local tbItemTemplate = ItemSystem:GetItemTemplate(nItemTemplateId)
    if tbItemTemplate.nCategory == ItemCategoryDef.SUIT then
        tbGoodsTempate = ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
    else
        local tbGiftBoxGoods = ShopDataTable:GetItemGiftBoxGoods()
        for nAwardId, tbGoodTemplate in pairs(tbGiftBoxGoods) do
            local bFound = false
            local tbItems = self:GetGiftBoxItems(nAwardId)
    
            if tbItems then
                for _, tbItem in pairs(tbItems) do
                    if nItemTemplateId == tbItem.nItemId then
                        bFound = true 
                        break
                    end
                end
    
                if bFound then  
                    tbGoodsTempate = tbGoodTemplate
                    break
                end
            end
        end
        if not tbGoodsTempate then  
            tbGoodsTempate = ShopDataTable:GetItemGoodsTemplate(nItemTemplateId)
        end
    end

    if tbGoodsTempate then
        self:OnBuyButtonClick(tbGoodsTempate)
    end
end

-----------------------------------------玩家不同的操作的方法---------------------------------------------
-- 请求出售道具
function ShopSystem:RequestGoShopping(nGoodsId, nGoodsCount, nCurrencyId, bAutoExchange)
    RequestGoShopping(nGoodsId, nGoodsCount, nCurrencyId, bAutoExchange)
end

-----------------------------------------处理server的协议回包---------------------------------------------------

function ShopSystem:OnGoShopping(tbShoppingGoods, tbGoodsRecord)
    local ShopComponent = GetShopComponent()
    if tbGoodsRecord then
        ShopComponent:AddGoodsRecord(tbGoodsRecord)
    end
    EventManager:OnFireEvent(ClientEventDef.EV_GO_SHOPPING_SUCCESS, tbShoppingGoods.goods_id, tbShoppingGoods.goods_count, tbShoppingGoods.currency_id)
end

function ShopSystem:OnRefreshGoods(tbGoodsRecords)
    ClearRefreshShopTimer(self)
    local ShopComponent = GetShopComponent()
    if tbGoodsRecords then
        ShopComponent:ClearAndAddAllGoodsRecords(tbGoodsRecords)
    end
    CheckShopRefresh(self)
    EventManager:OnFireEvent(ClientEventDef.EV_REFRESH_SHOP_FINISH)
end

return ShopSystem
