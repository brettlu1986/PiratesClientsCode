-----------------------------------------------------
--File Name    : BattleCabinInventoryRoom.lua
--Author       : zhiyuan
--Create Time  : 2018-08-30
--Description  : 船舱room
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleInventoryRoom = require("BattleInventoryRoom")
local BattleCabinInventoryRoom = luaclass("BattleCabinInventoryRoom", BattleInventoryRoom)
local ShipDataTable = require("ShipDataTable")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")

local function GetShipTemplate(self)
    local nShipTemplateId = self:GetOwnerCharacter():GetShipTemplateId()
    return ShipDataTable:GetTemplate(nShipTemplateId)
end

-- override
function BattleCabinInventoryRoom:GetInventoryCapacity(bIsClient)
    local tbShipTemplate = GetShipTemplate(self)
    return tbShipTemplate.nInventoryCapacity
end

-- override
function BattleCabinInventoryRoom:GetMaxInventorySlots(bIsClient)
    local tbShipTemplate = GetShipTemplate(self)
    local nMaxSlotsBase = tbShipTemplate.nMaxInventorySlots
    local tbPlayer = self:GetOwnerCharacter()
    local nExtra = BattleHumanDecorationSystem.GetShipExtraPackageCapacityValue(tbPlayer)
    if nExtra ~= nil and nExtra > 0 then
        return nMaxSlotsBase + nExtra
    end
    return nMaxSlotsBase
end

return BattleCabinInventoryRoom