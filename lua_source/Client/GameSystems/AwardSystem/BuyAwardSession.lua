local luaclass = require("luaclass")
local CommonAwardSession = require("CommonAwardSession")
local BuyAwardSession = luaclass("BuyAwardSession", CommonAwardSession)

local AwardSystem = require("AwardSystem")
local ShopDataTable = require("ShopDataTable")

BuyAwardSession.nGoodsId = nil
BuyAwardSession.nCount = nil
BuyAwardSession.szSourceWndName = nil
BuyAwardSession.bFinished = false

function BuyAwardSession:OnStarted(tbParams)
    BuyAwardSession.super.OnStarted(self, tbParams)

    self.nGoodsId = tbParams.nGoodsId
    self.nCount = tbParams.nCount
    self.szSourceWndName = tbParams.szSourceWndName

end

function BuyAwardSession:OnFinished()
    BuyAwardSession.super.OnFinished(self)
    AwardSystem:ShowCacheAward(self.szSourceWndName)
end

function BuyAwardSession:CheckShowAward(nSourceType)
    return self.bFinished
end

function BuyAwardSession:TryFinish()
    local tbAwardData = (AwardSystem.tbAwardDatas and AwardSystem.tbAwardDatas[1]) and AwardSystem.tbAwardDatas[1].tbAwardDatas
    if not tbAwardData then
        return
    end

    local tbGoodTemplate = ShopDataTable:GetTemplate(self.nGoodsId)

    local bFinish = false
    for _, tbItemData in pairs(tbAwardData) do
        if tbItemData.nItemTemplateId == tbGoodTemplate.nItemTemplateId then
            bFinish = true
        end
    end

    if not bFinish then
        return
    end

    self.bFinished = true

    return BuyAwardSession.super.TryFinish(self)
end

return BuyAwardSession