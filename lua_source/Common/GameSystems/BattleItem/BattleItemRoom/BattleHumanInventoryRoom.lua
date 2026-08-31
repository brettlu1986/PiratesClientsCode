-----------------------------------------------------
--File Name    : BattleHumanInventoryRoom.lua
--Author       : zhiyuan
--Create Time  : 2018-08-30
--Description  : 人的背包room
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleInventoryRoom = require("BattleInventoryRoom")
local BattleHumanInventoryRoom = luaclass("BattleHumanInventoryRoom", BattleInventoryRoom)
local HumanInventoryHelper = require("HumanInventoryHelper")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")

function BattleHumanInventoryRoom:GetInventoryCapacity(bIsClient)
    local nCapacityBase = HumanInventoryHelper:GetHumanBackpackCapacityBase()
    local nCapacity = nCapacityBase
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local EquippedHumanBackpackItem = HumanInventoryHelper:GetHumanBackpackItem(nCharacterInstanceId, bIsClient)
    if EquippedHumanBackpackItem then
        local tbTemplate = EquippedHumanBackpackItem:GetTemplate()
        local nDelta = tbTemplate.nInventoryCapacity
        nCapacity = nCapacity + nDelta
    end
    return nCapacity
end

function BattleHumanInventoryRoom:GetMaxInventorySlots(bIsClient)
    local nMaxSlotsBase = HumanInventoryHelper:GetHumanBackpackMaxInventorySlotsBase()
    local nMaxSlots = nMaxSlotsBase
    local nCharacterInstanceId = self:GetOwnerCharacterInstanceId()
    local EquippedHumanBackpackItem = HumanInventoryHelper:GetHumanBackpackItem(nCharacterInstanceId, bIsClient)
    if EquippedHumanBackpackItem then
        local tbTemplate = EquippedHumanBackpackItem:GetTemplate()
        local nDelta = tbTemplate.nMaxInventorySlots
        nMaxSlots = nMaxSlots + nDelta
    end
    local tbPlayer = self:GetOwnerCharacter()
    local nExtra = BattleHumanDecorationSystem.GetHumanExtraPackageCapacityValue(tbPlayer)
    if nExtra ~= nil and nExtra > 0 then
        nMaxSlots = nMaxSlots + nExtra
    end
    return nMaxSlots
end

return BattleHumanInventoryRoom