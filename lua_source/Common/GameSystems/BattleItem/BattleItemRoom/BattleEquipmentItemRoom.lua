-----------------------------------------------------
--File Name    : BattleEquipmentItemRoom.lua
--Author       : zhiyuan
--Create Time  : 2018-08-20
--Description  : 存放已经装备的物品的room
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleItemRoomBase = require("BattleItemRoomBase")
local BattleEquipmentItemRoom = luaclass("BattleEquipmentItemRoom", BattleItemRoomBase)
local BattleItemSystemHelper = require("BattleItemSystemHelper")

-- @override
function BattleEquipmentItemRoom:AddItem(nItemInstanceId, nSlotIndex)
    local nEquippedItemInstanceId = self.tbItemList[nSlotIndex]
    if nEquippedItemInstanceId ~= nil then
        if nEquippedItemInstanceId == nItemInstanceId then
            logerror("BattleEquipmentItemRoom:AddItem failed! UnEquip first!"
                 .. nItemInstanceId..", "..self.nType..", ".. self.nRoomId..", "..nSlotIndex)
            return
        else
            error("BattleEquipmentItemRoom:AddItem failed! UnEquip first!"
                 .. nItemInstanceId..", "..self.nType..", ".. self.nRoomId..", "..nSlotIndex)
        end
    end
    self.tbItemList[nSlotIndex] = nItemInstanceId
    return true
end

-- @override
function BattleEquipmentItemRoom:RemoveItemByInstanceId(nItemInstanceId)
    local nSlotIndex = nil
    for k, v in pairs(self.tbItemList) do
        if v == nItemInstanceId then
            nSlotIndex = k
            break
        end
    end

    if nSlotIndex then
        self.tbItemList[nSlotIndex] = nil
    else
        error("Cannot find nItemInstanceId to delete!".. nItemInstanceId)
    end
end

function BattleEquipmentItemRoom:GetItemBySlotIndex(nSlotIndex, bIsClient)
    if nSlotIndex == nil then
        nSlotIndex = 1
    end
    local nInstanceId = self.tbItemList[nSlotIndex]
    if nInstanceId == nil then
        -- 临时代码，用来排查道具同步顺序问题
        if bIsClient and (nSlotIndex == 1) then
            log("BattleEquipmentItemRoom:GetItemBySlotIndex nInstanceId is nil", bIsClient, nSlotIndex)
        end
        return nil
    end
    local BattleItemSystem = BattleItemSystemHelper:GetBattleItemSystem(bIsClient)
    local Item = BattleItemSystem:GetItem(nInstanceId)
    if Item == nil then
        error("Cannot find item!".. nInstanceId)
    end
    return Item
end

function BattleEquipmentItemRoom:RemoveItemBySlotIndex(nSlotIndex)
    if self.tbItemList[nSlotIndex] == nil then
        logwarning("Slot is empty! Do not need to delete!", nSlotIndex)
    end
    self.tbItemList[nSlotIndex] = nil
end

return BattleEquipmentItemRoom