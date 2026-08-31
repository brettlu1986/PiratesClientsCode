-----------------------------------------------------
--File Name    : BattleItemComponentServer.lua
--Author       : zhiyuan
--Create Time  : 2018-08-24
--Description  : 服务端的战斗物品component
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemComponentBase = require("BattleItemComponentBase")
local BattleItemComponentServer = luaclass("BattleItemComponentServer", BattleItemComponentBase)

local BattleItemSystemServer = require("BattleItemSystemServer")

BattleItemComponentServer.tbMaterialExtraAddCounts = nil

local function fnSortByStackCountDescendingOrder(ItemA, ItemB)
    return ItemA:GetStackCount() < ItemB:GetStackCount()
end

function BattleItemComponentServer:OnCreate(Owner, tbParams)
    BattleItemComponentServer.super.OnCreate(self, Owner, tbParams)
    self.bIsClient = false
end

function BattleItemComponentServer:DecreaseItems(nItemTemplateId, nItemCount, nSlotIndex)
    if nItemCount <= 0 then
        return
    end
    local nNeedDecreaseCount = nItemCount
    local tbItems = {}
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        for nRoomId, ItemRoom in pairs(v) do
            local tbIds = ItemRoom:GetAllItemInstanceIds()
            for _, nId in pairs(tbIds) do
                local Item = BattleItemSystemServer:GetItem(nId)
                if nSlotIndex ~= nil and nSlotIndex > 0 then
                    local _, _, nSlot = Item:SplitAndGetStorageLocation()
                    if Item:GetTemplateId() == nItemTemplateId and nSlot == nSlotIndex then
                        table.insert(tbItems, Item)
                    end
                else
                    if Item:GetTemplateId() == nItemTemplateId then
                        table.insert(tbItems, Item)
                    end
                end
            end
        end
    end
    table.sort(tbItems, fnSortByStackCountDescendingOrder)
    local nCharacterInstanceId = self.Owner.nServerInstanceId
    for _, v in pairs(tbItems) do
        local nStackCount = v:GetStackCount()
        local nDecrease = math.min(nStackCount, nNeedDecreaseCount)
        BattleItemSystemServer:DecreasePlayerItemCount(nCharacterInstanceId, v:GetInstanceId(), nDecrease)
        nNeedDecreaseCount = nNeedDecreaseCount - nDecrease
        if nNeedDecreaseCount == 0 then
            break
        end
    end
end

function BattleItemComponentServer:RecordExtraAddMaterial(nItemTemplateId, nItemCount)
    if self.tbMaterialExtraAddCounts == nil then
        self.tbMaterialExtraAddCounts = {}
    end
    local nCount = self.tbMaterialExtraAddCounts[nItemTemplateId]
    if nCount == nil then
        nCount = 0
    end
    nCount = nCount + nItemCount
    self.tbMaterialExtraAddCounts[nItemTemplateId] = nCount
end

function BattleItemComponentServer:GetExtraAddMaterial(nItemTemplateId)
    if self.tbMaterialExtraAddCounts == nil then
        return 0
    end
    local nCount = self.tbMaterialExtraAddCounts[nItemTemplateId]
    if nCount == nil then
        nCount = 0
    end
    return nCount
end

return BattleItemComponentServer