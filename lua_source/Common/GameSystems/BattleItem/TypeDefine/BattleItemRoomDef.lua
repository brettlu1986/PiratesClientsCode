-----------------------------------------------------
--File Name    : BattleItemRoomDef.lua
--Author       : zhiyuan
--Create Time  : 2018-08-11
--Description  : 物品Room的定义
-----------------------------------------------------

local BattleItemRoomDef =
{
    HUMAN_INVENTORY               = 1,        -- 人的背包
    CABIN                         = 2,        -- 船舱
    MATERIAL_ROOM                 = 3,        -- 材料背包

    SHIP_WEAPON_ROOM              = 4,        -- 装配船上的武器的room
    SHIP_PART_ROOM                = 5,        -- 装配船上的零件的room
    SHIP_WEAPON_ATTACHMENT_ROOM   = 6,        -- 装配船上的武器配件的room
    SHIP_DRESS_ROOM               = 7,        -- 装配船的外装的room
    SHIP_WEAPON_BULLET_ROOM       = 8,        -- 装配船的武器子弹的room

    HUMAN_WEAPON_ROOM             = 9,        -- 装配人的武器的room
    HUMAN_ARMOR_ROOM              = 10,       -- 装配人的护甲的room
    HUMAN_WEAPON_ATTACHMENT_ROOM  = 11,       -- 装配人的武器配件的room
    HUMAN_DRESS_ROOM              = 12,       -- 装配人的外装的room
    HUMAN_WEAPON_BULLET_ROOM      = 13,       -- 装配人的武器子弹的room
    HUMAN_INVENTORY_ROOM          = 14,       -- 装配人物背包的room

    SCENE_ITEM_ROOM               = 15,       -- 场景中的物品room
    SHIP_ROOM                     = 16,       -- 装备船的room
}

local tbItemRoomClasses = {}

local function RegisterItemRoomData(szRoomClass, bOwnerIsItem, bIsEquipmentRoom, bIsInventoryRoom, nRoomOwner, nUnequipSortWeight)
    local tbRegisterRoomData = {
        szRoomClass = szRoomClass,
        bOwnerIsItem = bOwnerIsItem,
        bIsEquipmentRoom = bIsEquipmentRoom,
        bIsInventoryRoom = bIsInventoryRoom,
        nRoomOwner = nRoomOwner,
        nUnequipSortWeight = nUnequipSortWeight,
    }
    return tbRegisterRoomData
end

local RoomOwnerDef = {
    HUMAN = 1,
    SHIP = 2,
    SCENE = 3
}

tbItemRoomClasses[BattleItemRoomDef.HUMAN_INVENTORY]              = RegisterItemRoomData("BattleHumanInventoryRoom", false, false, true, RoomOwnerDef.HUMAN, 0)
tbItemRoomClasses[BattleItemRoomDef.CABIN]                        = RegisterItemRoomData("BattleCabinInventoryRoom", false, false, true, RoomOwnerDef.SHIP, 0)
tbItemRoomClasses[BattleItemRoomDef.MATERIAL_ROOM]                = RegisterItemRoomData("BattleMaterialInventoryRoom", false, false, true, RoomOwnerDef.SHIP, 0)
tbItemRoomClasses[BattleItemRoomDef.SHIP_WEAPON_ROOM]             = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.SHIP, 4)
tbItemRoomClasses[BattleItemRoomDef.SHIP_PART_ROOM]               = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.SHIP, 3)
tbItemRoomClasses[BattleItemRoomDef.SHIP_WEAPON_ATTACHMENT_ROOM]  = RegisterItemRoomData("BattleEquipmentItemRoom", true, true, false, RoomOwnerDef.SHIP, 0)
tbItemRoomClasses[BattleItemRoomDef.SHIP_DRESS_ROOM]              = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.SHIP, 0)
tbItemRoomClasses[BattleItemRoomDef.SHIP_WEAPON_BULLET_ROOM]      = RegisterItemRoomData("BattleEquipmentItemRoom", true, true, false, RoomOwnerDef.SHIP, 0)
tbItemRoomClasses[BattleItemRoomDef.HUMAN_WEAPON_ROOM]            = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.HUMAN, 2)
tbItemRoomClasses[BattleItemRoomDef.HUMAN_ARMOR_ROOM]             = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.HUMAN, 1)
tbItemRoomClasses[BattleItemRoomDef.HUMAN_WEAPON_ATTACHMENT_ROOM] = RegisterItemRoomData("BattleEquipmentItemRoom", true, true, false, RoomOwnerDef.HUMAN, 0)
tbItemRoomClasses[BattleItemRoomDef.HUMAN_DRESS_ROOM]             = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.HUMAN, 0)
tbItemRoomClasses[BattleItemRoomDef.HUMAN_WEAPON_BULLET_ROOM]     = RegisterItemRoomData("BattleEquipmentItemRoom", true, true, false, RoomOwnerDef.HUMAN, 0)
tbItemRoomClasses[BattleItemRoomDef.HUMAN_INVENTORY_ROOM]         = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.HUMAN, 0)
tbItemRoomClasses[BattleItemRoomDef.SCENE_ITEM_ROOM]              = RegisterItemRoomData("SceneItemPackageRoom", false, false, false, RoomOwnerDef.SCENE, 0)
tbItemRoomClasses[BattleItemRoomDef.SHIP_ROOM]                    = RegisterItemRoomData("BattleEquipmentItemRoom", false, true, false, RoomOwnerDef.SHIP, 5)

function BattleItemRoomDef:FillItemRoomClassTable()
    for _, v in pairs(tbItemRoomClasses) do
        v.tbRoomClass = require(v.szRoomClass)
    end
end

function BattleItemRoomDef:GetItemRoomClass(nItemRoomType)
    return tbItemRoomClasses[nItemRoomType].tbRoomClass
end

function BattleItemRoomDef:OwnerIsItem(nItemRoomType)
    return tbItemRoomClasses[nItemRoomType].bOwnerIsItem
end

function BattleItemRoomDef:IsEquipmentRoom(nItemRoomType)
    if nItemRoomType == nil then
        return false
    end
    return tbItemRoomClasses[nItemRoomType].bIsEquipmentRoom
end

function BattleItemRoomDef:IsInventoryRoom(nItemRoomType)
    if nItemRoomType == nil then
        return false
    end
    return tbItemRoomClasses[nItemRoomType].bIsInventoryRoom
end

function BattleItemRoomDef:IsHumanItemRoom(nItemRoomType)
    if nItemRoomType == nil then
        return false
    end
    return tbItemRoomClasses[nItemRoomType].nRoomOwner == RoomOwnerDef.HUMAN
end

function BattleItemRoomDef:IsShipItemRoom(nItemRoomType)
    if nItemRoomType == nil then
        return false
    end
    return tbItemRoomClasses[nItemRoomType].nRoomOwner == RoomOwnerDef.SHIP
end

function BattleItemRoomDef:IsValid(nItemRoomType)
    if nItemRoomType == nil then
        return false
    end
    return tbItemRoomClasses[nItemRoomType] ~= nil
end


local function GetUnequipSortWeight(nItemRoomType)
    return tbItemRoomClasses[nItemRoomType].nUnequipSortWeight
end

function BattleItemRoomDef.UnequipSortFunc(ItemRoom1, ItemRoom2)
    local nItemRoomType1 = ItemRoom1:GetRoomType()
    local nItemRoomType2 = ItemRoom2:GetRoomType()
    local nWeight1 = GetUnequipSortWeight(nItemRoomType1)
    local nWeight2 = GetUnequipSortWeight(nItemRoomType2)

    if nWeight1 ~= nWeight2 then
        return nWeight1 < nWeight2
    end

    if nItemRoomType1 ~= nItemRoomType2 then
       return nItemRoomType1 < nItemRoomType2
    end

    return ItemRoom1:GetRoomId() < ItemRoom2:GetRoomId()
end

function BattleItemRoomDef.EquipSortFunc(ItemRoom1, ItemRoom2)
    local nItemRoomType1 = ItemRoom1:GetRoomType()
    local nItemRoomType2 = ItemRoom2:GetRoomType()
    local nWeight1 = GetUnequipSortWeight(nItemRoomType1)
    local nWeight2 = GetUnequipSortWeight(nItemRoomType2)

    if nWeight1 ~= nWeight2 then
        return nWeight1 > nWeight2
    end

    if nItemRoomType1 ~= nItemRoomType2 then
       return nItemRoomType1 > nItemRoomType2
    end

    return ItemRoom1:GetRoomId() > ItemRoom2:GetRoomId()
end

return BattleItemRoomDef