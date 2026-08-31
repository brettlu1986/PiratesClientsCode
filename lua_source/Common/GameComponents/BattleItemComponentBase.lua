-----------------------------------------------------
--File Name    : BattleItemComponentCommon.lua
--Author       : zhiyuan
--Create Time  : 2018-08-24
--Description  : 战斗物品component的基类
-----------------------------------------------------
local luaclass = require("luaclass")
local GameComponentBaseClass = require("GameComponentBase")
local BattleItemComponentBase = luaclass("BattleItemComponentBase", GameComponentBaseClass)

local BattleItemRoomDef = require("BattleItemRoomDef")
local BattleItemDataTable = require("BattleItemDataTable")
local BattleItemCategoryDataTable = require("BattleItemCategoryDataTable")
local BattleItemSystemHelper = require("BattleItemSystemHelper")

-- key : RoomType
-- value : { key roomId, value ItemRoom}
BattleItemComponentBase.tbAllItemRoomMap = nil

BattleItemComponentBase.bIsClient = nil

local function GetUnequipSortedRooms(self)
    local tbRooms = {}
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        for nRoomId, ItemRoom in pairs(v) do
            table.insert(tbRooms, ItemRoom)
        end
    end
    table.sort(tbRooms, BattleItemRoomDef.UnequipSortFunc)
    return tbRooms
end

local function GetEquipSortedRooms(self)
    local tbRooms = {}
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        for nRoomId, ItemRoom in pairs(v) do
            table.insert(tbRooms, ItemRoom)
        end
    end
    table.sort(tbRooms, BattleItemRoomDef.EquipSortFunc)
    return tbRooms
end

function BattleItemComponentBase:PrintData()
    -- logdebug("BattleItemComponentBase:PrintData", self, self.tbAllItemRoomMap)
    -- for nRoomType, v in pairs(self.tbAllItemRoomMap) do
    --     for nRoomId, ItemRoom in pairs(v) do
    --         ItemRoom:PrintData(self.bIsClient)
    --     end
    -- end
end

function BattleItemComponentBase:OnCreate(Owner, tbParams)
    BattleItemComponentBase.super.OnCreate(self, Owner, tbParams)
    self.tbAllItemRoomMap = {}
end

function BattleItemComponentBase:OnActorCreated(pUEActor)
    BattleItemComponentBase.super.OnActorCreated(self, pUEActor)
end

function BattleItemComponentBase:OnActorDestroyed(pUEActor)
    BattleItemComponentBase.super.OnActorDestroyed(self, pUEActor)
end

function BattleItemComponentBase:ItemExists(nItemInstanceId)
    for _, tbRooms in pairs(self.tbAllItemRoomMap) do
        for _, Room in pairs(tbRooms) do
            if Room:ItemExists(nItemInstanceId) then
                return true
            end
        end
    end
    return false
end

-- 获得某个物品上装配的物品room
function BattleItemComponentBase:GetAllEquipmentItemRoomsWhichOwnerIsItem(nOwnerItemInstanceId)
    local tbEquipmentItemRooms = nil
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        if BattleItemRoomDef:OwnerIsItem(nRoomType) then
            for nRoomId, Room in pairs(tbRooms) do
                if nRoomId == nOwnerItemInstanceId then
                    if not Room:IsEmpty() then
                        if tbEquipmentItemRooms == nil then
                            tbEquipmentItemRooms = {}
                        end
                        table.insert(tbEquipmentItemRooms, Room)
                    end
                end
            end
        end
    end
    return tbEquipmentItemRooms
end

function BattleItemComponentBase:GetAllEquipmentItemRooms()
    local tbEquipmentItemRooms = nil
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        for nRoomId, Room in pairs(tbRooms) do
            if not Room:IsEmpty() and BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
                if tbEquipmentItemRooms == nil then
                    tbEquipmentItemRooms = {}
                end
                table.insert(tbEquipmentItemRooms, Room)
            end
        end
    end
    return tbEquipmentItemRooms
end

function BattleItemComponentBase:GetAllEquipmentShipItemRooms()
    local tbEquipmentItemRooms = nil
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        for nRoomId, Room in pairs(tbRooms) do
            if not Room:IsEmpty() and BattleItemRoomDef:IsEquipmentRoom(nRoomType) and BattleItemRoomDef:IsShipItemRoom(nRoomType) then
                if tbEquipmentItemRooms == nil then
                    tbEquipmentItemRooms = {}
                end
                table.insert(tbEquipmentItemRooms, Room)
            end
        end
    end
    return tbEquipmentItemRooms
end

function BattleItemComponentBase:GetAllEquipmentItems()
    local tbEquipmentItems = nil
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        for nRoomId, Room in pairs(tbRooms) do
            if not Room:IsEmpty() and BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
                if tbEquipmentItems == nil then
                    tbEquipmentItems = {}
                end
                local tbInstanceIds = Room:GetAllItemInstanceIds()
                for _, nInstanceId in pairs(tbInstanceIds) do
                    local Item = BattleItemSystem:GetItem(nInstanceId)
                    table.insert(tbEquipmentItems, Item)
                end
            end
        end
    end
    return tbEquipmentItems
end

function BattleItemComponentBase:GetAllEquipmentItemsOnShip()
    local tbEquipmentItems = nil
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        for nRoomId, Room in pairs(tbRooms) do
            if not Room:IsEmpty() and BattleItemRoomDef:IsEquipmentRoom(nRoomType) and BattleItemRoomDef:IsShipItemRoom(nRoomType) then
                if tbEquipmentItems == nil then
                    tbEquipmentItems = {}
                end
                local tbInstanceIds = Room:GetAllItemInstanceIds()
                for _, nInstanceId in pairs(tbInstanceIds) do
                    local Item = BattleItemSystem:GetItem(nInstanceId)
                    table.insert(tbEquipmentItems, Item)
                end
            end
        end
    end
    return tbEquipmentItems
end

function BattleItemComponentBase:GetAllEquipmentItemsOnHuman()
    local tbEquipmentItems = nil
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        for nRoomId, Room in pairs(tbRooms) do
            if not Room:IsEmpty() and BattleItemRoomDef:IsEquipmentRoom(nRoomType) and BattleItemRoomDef:IsHumanItemRoom(nRoomType) then
                if tbEquipmentItems == nil then
                    tbEquipmentItems = {}
                end
                local tbInstanceIds = Room:GetAllItemInstanceIds()
                for _, nInstanceId in pairs(tbInstanceIds) do
                    local Item = BattleItemSystem:GetItem(nInstanceId)
                    table.insert(tbEquipmentItems, Item)
                end
            end
        end
    end
    return tbEquipmentItems
end

-- 移除某个物品上装配的物品room
function BattleItemComponentBase:RemoveEquipmentItemRoomsWhichOwnerIsItem(nOwnerItemInstanceId)
    for nRoomType, tbRooms in pairs(self.tbAllItemRoomMap) do
        if BattleItemRoomDef:OwnerIsItem(nRoomType) then
            tbRooms[nOwnerItemInstanceId] = nil
        end
    end
end

function BattleItemComponentBase:ClearAllEquipmentItemRoom()
    local tbRoomTypeToRemove = {}
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        -- todo @zhiyuan 后面调整物品安装层级关系来去掉这个特殊判断
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) and nRoomType ~= BattleItemRoomDef.SHIP_ROOM then
            table.insert(tbRoomTypeToRemove, nRoomType)
        end
    end
    for _, v in pairs(tbRoomTypeToRemove) do
        self.tbAllItemRoomMap[v] = nil
    end
end

function BattleItemComponentBase:ClearAllShipEquipmentItemRoom()
    local tbRoomTypeToRemove = {}
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        -- todo @zhiyuan 后面调整物品安装层级关系来去掉这个特殊判断
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) and nRoomType ~= BattleItemRoomDef.SHIP_ROOM and BattleItemRoomDef:IsShipItemRoom(nRoomType) then
            table.insert(tbRoomTypeToRemove, nRoomType)
        end
    end
    for _, v in pairs(tbRoomTypeToRemove) do
        self.tbAllItemRoomMap[v] = nil
    end
end

function BattleItemComponentBase:GetOrCreateItemRoom(nRoomType, nRoomId)
    local tbAllItemRoomMap = self.tbAllItemRoomMap
    local tbRooms = tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        tbAllItemRoomMap[nRoomType] = {}
        tbRooms = tbAllItemRoomMap[nRoomType]
    end
    local Room = tbRooms[nRoomId]
    if Room == nil then
        local tbRoomClass = BattleItemRoomDef:GetItemRoomClass(nRoomType)
        tbRooms[nRoomId] = tbRoomClass()
        Room = tbRooms[nRoomId]
        Room:Init(nRoomType, nRoomId)
        Room:SetOwnerCharacter(self.Owner)
    end
    return Room
end

function BattleItemComponentBase:GetRoom(nRoomType, nRoomId)
    local tbRooms = self.tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        return nil
    end
    if nRoomId == nil then -- 这种情况下tbRooms里最多有一个Room，所以返回第一个
        -- luacheck: push ignore
        for _, v in pairs(tbRooms) do
            assert(not BattleItemRoomDef:IsEquipmentRoom(nRoomType), "nRoomId is nil! But Room is equipped room!")
            return v
        end
        -- luacheck: pop
        return nil
    end
    local Room = tbRooms[nRoomId]
    if Room == nil then
        return nil
    end
    return Room
end

function BattleItemComponentBase:GetItemRoom(nItemInstanceId)
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    local Item = BattleItemSystem:GetItem(nItemInstanceId)
    local tbStorageLocation = Item:GetStorageLocation()
    return self:GetRoom(tbStorageLocation.nRoomType, tbStorageLocation.nOwnerInstanceId)
end

function BattleItemComponentBase:GetUnequippedItemCount(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    local nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nCategory)
    local tbRooms = self.tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        return 0
    end
    local nItemCount = 0
    for k, v in pairs(tbRooms) do
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
            error("BattleItemComponentBase:GetUnequippedItemCount failed! room is not unequipped room!")
        end
        local nItemCountInOneRoom = v:GetItemCount(nItemTemplateId, self.bIsClient)
        nItemCount = nItemCount + nItemCountInOneRoom
    end
    return nItemCount
end

function BattleItemComponentBase:GetItemCount(nItemTemplateId)
    local nItemCount = 0
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        for nRoomId, ItemRoom in pairs(v) do
            local tbIds = ItemRoom:GetAllItemInstanceIds()
            for _, nId in pairs(tbIds) do
                local Item = BattleItemSystem:GetItem(nId)
                if Item:GetTemplateId() == nItemTemplateId then
                    nItemCount = nItemCount + Item:GetStackCount()
                end
            end
        end
    end
    return nItemCount
end

function BattleItemComponentBase:GetUnequippedItems(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    local nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nCategory)
    local tbRooms = self.tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        return {}
    end
    local tbItems = {}
    for k, v in pairs(tbRooms) do
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
            error("BattleItemComponentBase:GetUnequippedItems failed! room is not unequipped room!")
        end
        tbItems = v:GetItemsByTemplateId(nItemTemplateId, self.bIsClient)
        if #tbItems > 0 then
            return tbItems
        end
    end
    return tbItems
end

local function fnSortByStackCountDescendingOrder(ItemA, ItemB)
    return ItemA:GetStackCount() < ItemB:GetStackCount()
end

function BattleItemComponentBase:GetUnequippedLeastStackCountInstance(nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    local nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nCategory)
    local tbRooms = self.tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        return nil
    end
    local tbItems = {}
    for k, v in pairs(tbRooms) do
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
            error("BattleItemComponentBase:GetUnequippedItems failed! room is not unequipped room!")
        end
        tbItems = v:GetItemsByTemplateId(nItemTemplateId, self.bIsClient)
        if #tbItems > 0 then
            break
        end
    end
    if #tbItems == 0 then
        return nil
    end
    table.sort(tbItems, fnSortByStackCountDescendingOrder)

    return tbItems[1]
end

function BattleItemComponentBase:GetUnequippedLeastStackCountInstanceId(nItemTemplateId)
    local Item = self:GetUnequippedLeastStackCountInstance(nItemTemplateId)
    return Item and Item:GetInstanceId()
end

function BattleItemComponentBase:GetEquippedItemCount(nOwnerInstanceId, nItemTemplateId)
    local tbTemplate = BattleItemDataTable:GetTemplate(nItemTemplateId)
    local nCategory = tbTemplate.nCategory
    local nRoomType = BattleItemCategoryDataTable:GetEquippedRoomType(nCategory)
    local tbRooms = self.tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        return 0
    end
    local ItemRoom = tbRooms[nOwnerInstanceId]
    if ItemRoom == nil then
        return 0
    end
    if not BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
        error("BattleItemComponentBase:GetEquippedItemCount failed! room is not equipped room!")
    end

    return ItemRoom:GetItemCount(nItemTemplateId, self.bIsClient)
end

function BattleItemComponentBase:GetUnequippedItemsByCategory(nItemCategory)
    local nRoomType = BattleItemCategoryDataTable:GetUnequippedRoomType(nItemCategory)
    local tbRooms = self.tbAllItemRoomMap[nRoomType]
    if tbRooms == nil then
        return {}
    end
    local tbItemsWithOneCategory = {}
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for k, v in pairs(tbRooms) do
        if BattleItemRoomDef:IsEquipmentRoom(nRoomType) then
            error("BattleItemComponentBase:GetUnequippedItemsByCategory failed! room is not unequipped room!")
        end
        local tbItemInstanceIds = v:GetAllItemInstanceIds()
        for _, nId in pairs(tbItemInstanceIds) do
            local Item = BattleItemSystem:GetItem(nId)
            if Item == nil then
                error("BattleItemComponentBase:GetUnequippedItemsByCategory failed! Item not found!")
            end
            if Item:GetCategory() == nItemCategory then
                table.insert( tbItemsWithOneCategory, Item)
            end
        end
    end
    return tbItemsWithOneCategory
end

function BattleItemComponentBase:IsItemEnough(nItemTemplateId, nItemCount)
    local nItemTotalCount = 0
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for nRoomType, v in pairs(self.tbAllItemRoomMap) do
        for nRoomId, ItemRoom in pairs(v) do
            local tbIds = ItemRoom:GetAllItemInstanceIds()
            for _, nId in pairs(tbIds) do
                local Item = BattleItemSystem:GetItem(nId)
                if Item:GetTemplateId() == nItemTemplateId then
                    nItemTotalCount = nItemTotalCount + Item:GetStackCount()
                    if nItemTotalCount >= nItemCount then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function BattleItemComponentBase:RemoveAllItemOnCharacter()
    local tbItemInstanceIds = {}
    local tbRooms = GetUnequipSortedRooms(self)
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for _, ItemRoom in ipairs(tbRooms) do
        local tbIds = ItemRoom:GetAllItemInstanceIds()
        for _, nId in pairs(tbIds) do
            local Item = BattleItemSystem:GetItem(nId)
            local nItemRoomType, _, _ = Item:SplitAndGetStorageLocation()
            if BattleItemRoomDef:IsEquipmentRoom(nItemRoomType) then
                Item:OnUnequip(self.bIsClient)
            end
            Item:PreRemoveFromPlayer(true)
            Item:ClearStorageLocationAndOwner()
            table.insert(tbItemInstanceIds, nId)
        end
    end
    self.tbAllItemRoomMap = {}
    return tbItemInstanceIds
end

function BattleItemComponentBase:GetAllItemProtoDatas()
    local tbItemProtos = {}
    local tbRooms = GetEquipSortedRooms(self)
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for _, ItemRoom in ipairs(tbRooms) do
        local tbIds = ItemRoom:GetAllItemInstanceIds()
        for _, nId in pairs(tbIds) do
            local Item = BattleItemSystem:GetItem(nId)
            table.insert(tbItemProtos, Item:GetProtoData())
        end
    end
    return tbItemProtos
end

function BattleItemComponentBase:GetAllItems()
    local tbItems = {}
    local tbRooms = GetEquipSortedRooms(self)
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(self.bIsClient)
    for _, ItemRoom in ipairs(tbRooms) do
        local tbIds = ItemRoom:GetAllItemInstanceIds()
        for _, nId in pairs(tbIds) do
            local Item = BattleItemSystem:GetItem(nId)
            table.insert(tbItems, Item)
        end
    end
    return tbItems
end

function BattleItemComponentBase:OnDestroy()
    self:RemoveAllItemOnCharacter()
end

return BattleItemComponentBase