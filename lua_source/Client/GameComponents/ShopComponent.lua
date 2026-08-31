-----------------------------------------------------
--File Name    : ShopComponent.lua
--Author       : zhiyuan
--Create Time  : 2019-07-19
--Description  : 商店的component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ShopComponent = luaclass("ShopComponent", GameComponentBase)

-- 购买记录，只有限购的才需要购买记录
-- self.tbGoodsRecords = {}
-- local goods_id = 1
-- local tbRecord = {}
-- tbRecord.goods_id = goods_id
-- tbRecord.buy_times = 1
-- tbRecord.refresh_seconds = 1
-- self.tbGoodsRecords[goods_id] = tbRecord
ShopComponent.tbGoodsRecords = nil

-----------------------------------------local function---------------------------------------------

local function AddGoodsRecord(self, tbRecord)
    self.tbGoodsRecords[tbRecord.goods_id] = tbRecord
end

local function AddGoodsRecords(self, tbRecords)
    for _, v in ipairs(tbRecords) do
        AddGoodsRecord(self, v)
    end
end

-----------------------------------------初始化---------------------------------------------

function ShopComponent:OnCreate(Owner, _)
    ShopComponent.super.OnCreate(self, Owner, _)

    self.tbGoodsRecords = {}
    return true
end

-----------------------------------------商店数据操作的基础方法---------------------------------------------

-- 修改购买记录（有限购的才需要购买记录）
function ShopComponent:AddGoodsRecord(tbRecord)
    AddGoodsRecord(self, tbRecord)
end

function ShopComponent:ClearAndAddAllGoodsRecords(tbGoodsRecords)
    self.tbGoodsRecords = {}
    AddGoodsRecords(self, tbGoodsRecords)
end

-- 获得商品记录(可能返回nil)
function ShopComponent:GetGoodsRecord(nGoodsId)
    return self.tbGoodsRecords[nGoodsId]
end

return ShopComponent
