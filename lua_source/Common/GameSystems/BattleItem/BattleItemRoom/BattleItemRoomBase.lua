-----------------------------------------------------
--File Name    : BattleItemRoomBase.lua
--Author       : zhiyuan
--Create Time  : 2018-08-11
--Description  : Item 容器
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemRoomBase = luaclass("BattleItemRoomBase")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

BattleItemRoomBase.tbOwnerCharacter = nil
-- Room类型，默认为背包类型
BattleItemRoomBase.nType = nil
BattleItemRoomBase.nRoomId = nil
-- 物品列表
BattleItemRoomBase.tbItemList = nil

function BattleItemRoomBase:PrintData(bIsClient)
    -- logdebug("room type id", self.nType, self.nRoomId)
    -- local tbIds = self:GetAllItemInstanceIds()
    -- local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    -- for nSlotIndex, nId in pairs(tbIds) do
    --     local Item = BattleItemSystem:GetItem(nId)
    --     logdebug("print ", self.nType, self.nRoomId, nSlotIndex,
    --         require("dkjson").encode(Item:GetStorageLocation()), Item:GetInstanceId(),
    --         Item:GetOwnerCharacter(), Item:GetOwnerCharacterInstanceId(), Item:GetTemplateId())
    -- end
end

function BattleItemRoomBase:GetRoomType()
    return self.nType
end

function BattleItemRoomBase:GetRoomId()
    return self.nRoomId
end

function BattleItemRoomBase:GetOwnerUEControllerUniqueId()
    return self.tbOwnerCharacter:GetUEControllerUniqueId()
end

function BattleItemRoomBase:SetOwnerCharacter(tbOwnerCharacter)
    self.tbOwnerCharacter = tbOwnerCharacter
end

function BattleItemRoomBase:GetOwnerCharacter()
    return self.tbOwnerCharacter
end

function BattleItemRoomBase:HasOwnerCharacter()
    return self.tbOwnerCharacter ~= nil
end

function BattleItemRoomBase:GetOwnerCharacterInstanceId()
    return self.tbOwnerCharacter and self.tbOwnerCharacter:GetServerInstanceId() or -1
end

function BattleItemRoomBase:Init(nRoomType, nRoomId)
    self.nType = nRoomType
    self.nRoomId = nRoomId
    self.tbItemList = {}
end

function BattleItemRoomBase:GetAllItemInstanceIds()
    return self.tbItemList
end

function BattleItemRoomBase:AddItem(nItemInstanceId)
    table.insert(self.tbItemList, nItemInstanceId)
end

function BattleItemRoomBase:RemoveItemByInstanceId(nItemInstanceId)
    local nIndex = 0
    for i, v in ipairs(self.tbItemList) do
        if v == nItemInstanceId then
            nIndex = i
            break
        end
    end
    if nIndex > 0 then
        table.remove(self.tbItemList, nIndex)
    else
        error("Cannot find nItemInstanceId to delete!" .. nItemInstanceId)
    end
end

function BattleItemRoomBase:GetItemCount(nItemTemplateId, bIsClient)
    local nItemCount = 0
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for _, v in pairs(self.tbItemList) do
        local Item = BattleItemSystem:GetItem(v)
        if Item == nil then
            error("BattleItemRoomBase:GetItemCount failed! cannot find item instance! itemInstanceId:"
            .. v.. ", itemTemplateId:".. nItemTemplateId)
        end
        if Item:GetTemplateId() == nItemTemplateId then
            local nStackCount = Item:GetStackCount()
            nItemCount = nItemCount + nStackCount
        end
    end
    return nItemCount
end

function BattleItemRoomBase:GetItemsByTemplateId(nItemTemplateId, bIsClient)
    local tbItems = {}
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for _, v in pairs(self.tbItemList) do
        local Item = BattleItemSystem:GetItem(v)
        if Item == nil then
            error("BattleItemRoomBase:GetItemCount failed! cannot find item instance! itemInstanceId:"
            .. v.. ", itemTemplateId:".. nItemTemplateId)
        end
        if Item:GetTemplateId() == nItemTemplateId then
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

function BattleItemRoomBase:GetRoomItems(bIsClient)
    local tbRoomItems = {}
    local tbItemInstanceIds = self:GetAllItemInstanceIds()
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    for k, v in pairs(tbItemInstanceIds) do
        local Item = BattleItemSystem:GetItem(v)
        if Item == nil then
            error("Cannot find Item! nItemInstanceId:".. v)
        end
        tbRoomItems[k] = Item
    end
    return tbRoomItems
end

function BattleItemRoomBase:ItemExists(nItemInstanceId)
    for _, v in pairs(self.tbItemList) do
        if v == nItemInstanceId then
            return true
        end
    end
    return false
end

function BattleItemRoomBase:IsEmpty()
    -- luacheck: push ignore
    for _, _ in pairs(self.tbItemList) do
        return false
    end
    -- luacheck: pop
    return true
end

return BattleItemRoomBase
