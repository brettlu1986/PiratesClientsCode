-----------------------------------------------------
--File Name    : ItemComponent.lua
--Author       : zhiyuan
--Create Time  : 2019-02-28
--Description  : 大厅道具的component
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local ItemComponent = luaclass("ItemComponent", GameComponentBase)
local ItemClass = require("Item")
local ItemDataTable = require("ItemDataTable")

-- 某个大类的的物品id列表
-- { key nCategoryId, value tbItemInstanceIds}
ItemComponent.tbCategoryItemIds = nil

-- 所有的物品
-- { key nItemInstanceId, value Item}
ItemComponent.tbAllItems = nil
-----------------------------------------local function---------------------------------------------

local function CreateItem(tbItemData)
    local Item = ItemClass()
    local tbItemTemplate = ItemDataTable:GetTemplate(tbItemData.template_id)
    if tbItemTemplate == nil then
        logerror("Cannot find template id!", tbItemData.template_id)
        return nil
    end
    Item:SetTemplate(tbItemTemplate)
    Item:SetInstanceId(tbItemData.instance_id)
    Item:SetStackCount(tbItemData.count)
    Item:SetCreateSeconds(tbItemData.create_time)
    Item:SetExpireAtSeconds(tbItemData.expired_at)
    return Item
end

local function GetItems(self, tbItemInstanceIds)
    local tbItems = {}
    if tbItemInstanceIds ~= nil then
        for _, v in ipairs(tbItemInstanceIds) do
            local Item = self:GetItem(v)
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

local function FindIndexInList(tbList, nData)
    local nIndex = -1
    if tbList ~= nil then
        for i, v in ipairs(tbList) do
            if nData == v then
                nIndex = i
                break
            end
        end
    end
    return nIndex
end

-----------------------------------------初始化---------------------------------------------
-- tbParams:repeated Item
function ItemComponent:OnCreate(Owner, tbParams)
    ItemComponent.super.OnCreate(self, Owner, tbParams)
    if tbParams == nil then
        tbParams = {}
    end

    self.tbAllItems = {}
    self.tbCategoryItemIds = {}

    self:AddItems(tbParams)
    return true
end

-----------------------------------------道具的基础方法---------------------------------------------

function ItemComponent:GetItem(nInstanceId)
    return self.tbAllItems[nInstanceId]
end

function ItemComponent:AddItems(tbItemDatas)
    local tbItems = {}
    for _, tbItemData in ipairs(tbItemDatas) do
        local Item = self:AddItem(tbItemData)
        if Item ~= nil then
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

function ItemComponent:AddItem(tbItemData)
    local Item = CreateItem(tbItemData)
    if Item == nil then
        return nil
    end
    local nItemInstanceId = Item:GetInstanceId()
    local tbItemTemplate = Item:GetTemplate()
    local nCategory = tbItemTemplate.nCategory

    self.tbAllItems[nItemInstanceId] = Item

    local tbItemInstanceIds = self.tbCategoryItemIds[nCategory]
    if tbItemInstanceIds == nil then
        self.tbCategoryItemIds[nCategory] = {}
        tbItemInstanceIds = self.tbCategoryItemIds[nCategory]
    end
    table.insert(tbItemInstanceIds, nItemInstanceId)
    return Item
end

function ItemComponent:SetItemStackCount(nInstanceId, nCount)
    local Item = self:GetItem(nInstanceId)
    Item:SetStackCount(nCount)
end

function ItemComponent:SetItemCreateTime(nInstanceId, nCreateTime)
    local Item = self:GetItem(nInstanceId)
    Item:SetCreateSeconds(nCreateTime)
end

function ItemComponent:SetItemExpiredAtSeconds(nInstanceId, nExpiredAt)
    local Item = self:GetItem(nInstanceId)
    Item:SetExpireAtSeconds(nExpiredAt)
end

function ItemComponent:RemoveItem(nInstanceId)
    local Item = self:GetItem(nInstanceId)
    local tbItemTemplate = Item:GetTemplate()
    local nCategory = tbItemTemplate.nCategory
    local tbItemInstanceIds = self.tbCategoryItemIds[nCategory]

    local nIndex = FindIndexInList(tbItemInstanceIds, nInstanceId)

    if nIndex > 0 then
        table.remove(tbItemInstanceIds, nIndex)
    end

    self.tbAllItems[nInstanceId] = nil

    return tbItemTemplate.nId
end

function ItemComponent:GetItemsByCategory(nItemCategory)
    local tbItemInstanceIds = self.tbCategoryItemIds[nItemCategory]
    return GetItems(self, tbItemInstanceIds)
end

function ItemComponent:GetItemsByTemplateId(nItemTemplateId)
    local tbItems = {}
    local tbItemTemplate = ItemDataTable:GetTemplate(nItemTemplateId)
    if tbItemTemplate then
        local nCategory = tbItemTemplate.nCategory
        local tbItemInstanceIds = self.tbCategoryItemIds[nCategory]
        if tbItemInstanceIds ~= nil then
            for _, v in ipairs(tbItemInstanceIds) do
                local Item = self:GetItem(v)
                if Item:GetTemplateId() == nItemTemplateId then
                    table.insert(tbItems, Item)
                end
            end
        end
    end
    return tbItems
end

function ItemComponent:GetItemCount(nItemTemplateId)
    local nCount = 0
    local tbItems = self:GetItemsByTemplateId(nItemTemplateId)
    for i, Item in ipairs(tbItems) do
        local nStackCount = Item:GetStackCount()
        nCount = nCount + nStackCount
    end
    return nCount
end

return ItemComponent
