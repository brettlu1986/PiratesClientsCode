-----------------------------------------------------
--File Name    : ShopPacketProcessor.lua
--Author       : zhiyuan
--Create Time  : 2019-07-19
--Description  : 商店的协议接收
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local ShopPacketProcessor = luaclass("ShopPacketProcessor", NetMessageProcessorBase)

local L10N = require("L10N")
local UIUtils = require("UIUtils")
local ShopSystem = require("ShopSystem")
local UISetUtils = require("UISetUtils")
local Proto = require("ClientProtoNames")
local EventManager = require("EventManager")
local ShopDataTable = require("ShopDataTable")
local ItemDataTable = require("ItemDataTable")
local ClientEventDef = require("ClientEventDef")
local ItemCategoryDef = require("ItemCategoryDef")
local NetworkManager = dynamic_require("NetworkManager")
local CostCurrencyHelper = require("CostCurrencyHelper")

-- 商品刷新
function ShopPacketProcessor:OnRefreshGoods(tbPacket)
    ShopSystem:OnRefreshGoods(tbPacket.goods)
end

-- 购买商品
function ShopPacketProcessor:OnGoShopping(tbPacket)
    CostCurrencyHelper:FinishRequest()
    local nReturnCode = tbPacket.return_code
    local ReturnCode = Proto.ReturnCode
    local tbShoppingGoods = tbPacket.shopping_goods
    if nReturnCode == ReturnCode.OK then
        ShopSystem:OnGoShopping(tbShoppingGoods, tbPacket.goods)
    elseif nReturnCode == ReturnCode.SHOP_GOODS_COUNT_LIMITED then -- 购买数量超过限制
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_COUNT_LIMITED"))
    elseif nReturnCode == ReturnCode.SHOP_ID_INVALID then -- 商品id不存在
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_ID_INVALID"))
    elseif nReturnCode == ReturnCode.SHOP_CURRENCY_ID_INVALID then -- 货币id不存在
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_CURRENCY_ID_INVALID"))
    elseif nReturnCode == ReturnCode.SHOP_NOT_ENOUGH_CURRENCY then -- 货币数量不足
        EventManager:OnFireEvent(ClientEventDef.EV_SHOP_NOT_ENOUGH_CURRENCY, tbShoppingGoods)
    elseif nReturnCode == ReturnCode.SHOP_GOODS_OFF_SHELF then -- 商品未上架
        UIUtils.ShowToast(UISetUtils.GetL10NTextByKey("SHOP_GOODS_OFF_SHELF"))
    elseif nReturnCode == ReturnCode.SHOP_NO_SHIP_WITH_SKIN then -- 未拥有皮肤对应的舰船
        local nGoodsId = tbShoppingGoods.goods_id
        local tbGoodsTemplate = ShopDataTable:GetTemplate(nGoodsId)
        local nItemTemplateId = tbGoodsTemplate.nItemTemplateId
        local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
        local nCategory = tbItemTemplate.nCategory
        if nCategory == ItemCategoryDef.SHIP_SKIN then
            local nShipItemId = tbItemTemplate.nShipItemId
            local l10nToastFormat = UISetUtils.GetL10NTextByKey("SHOP_SHIP_SKIL_BUT_NO_SHIP")
            local tbShipItemTemplate = ItemDataTable:GetTemplate(nShipItemId)
            local l10nToast = L10N:Format(l10nToastFormat, tbShipItemTemplate.l10nName, tbItemTemplate.l10nName)
            UIUtils.ShowToast(l10nToast)
        else
            UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("SHOP_FAILED_OTHER_REASON"), nReturnCode))
        end
    else
        UIUtils.ShowToast(L10N:Format(UISetUtils.GetL10NTextByKey("SHOP_FAILED_OTHER_REASON"), nReturnCode))
    end
end

-- 注册处理包
function ShopPacketProcessor:RegisterPackets()
    local HubServerProxy = NetworkManager:GetHubServerProxy()
    self:SetBinder(HubServerProxy)
    self:BindMethod(Proto.s2c_GoShopping, self, self.OnGoShopping)
    self:BindMethod(Proto.s2c_RefreshGoods, self, self.OnRefreshGoods)
end

-- 初始化
function ShopPacketProcessor:Init()
    ShopPacketProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

-- 结束
function ShopPacketProcessor:Uninit()
    ShopPacketProcessor.super.Uninit(self)
end

return ShopPacketProcessor
