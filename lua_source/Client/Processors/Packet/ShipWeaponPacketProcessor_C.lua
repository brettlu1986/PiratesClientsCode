local luaclass = require("luaclass")
local ShipWeaponPacketProcessor = require("ShipWeaponPacketProcessor")
local ShipWeaponPacketProcessor_C = luaclass("ShipWeaponPacketProcessor_C", ShipWeaponPacketProcessor)

local Proto = require("DungeonCommonProtoNames")
local BattleItemSystemClient = require("BattleItemSystemClient")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")

local function NotifyActiveShipWeaponItemChanged(tbPacket, nSenderUniqueId)
    local WeaponItem = BattleItemSystemClient:GetItem(tbPacket.weapon_item_instance_id)
    BattleShipWeaponSystem:ReceiveActiveWeaponItemChanged(WeaponItem)
end

local function NotifyEquippedShipThrownItemChanged(tbPacket, nSenderUniqueId)
    local WeaponItem = BattleItemSystemClient:GetItem(tbPacket.thrown_item_instance_id)
    BattleShipWeaponSystem:ReceiveEquippedThrownItemChanged(WeaponItem)
end

local function NotifyShipWeaponFiringCdBegan(tbPacket, nSenderUniqueId)
    local WeaponItem = BattleItemSystemClient:GetItem(tbPacket.weapon_item_instance_id)
    if not WeaponItem then return end
    BattleShipWeaponSystem:ReceiveFiringCDBegan(WeaponItem, tbPacket.duration, tbPacket.elapsed_time)
end

local function NotifyShipWeaponBulletLoadingBegan(tbPacket, nSenderUniqueId)
    local WeaponItem = BattleItemSystemClient:GetItem(tbPacket.weapon_item_instance_id)
    if not WeaponItem then return end
    BattleShipWeaponSystem:ReceiveBulletLoadingBegan(WeaponItem, tbPacket.duration, tbPacket.elapsed_time)
end

local function NotifyShipWeaponBulletLoadingEnded(tbPacket, nSenderUniqueId)
    local WeaponItem = BattleItemSystemClient:GetItem(tbPacket.weapon_item_instance_id)
    if not WeaponItem then return end
    BattleShipWeaponSystem:ReceiveBulletLoadingEnded(WeaponItem)
end

local function NotifyShipFiringOperationChanged(tbPacket, nSenderUniqueId)
    local WeaponItem = BattleItemSystemClient:GetItem(tbPacket.weapon_item_instance_id)
    if not WeaponItem then return end
    BattleShipWeaponSystem:ReceiveFiringOperationChanged(WeaponItem, tbPacket.firing_operation)
end

local function NotifyShipAimStateChanged(tbPacket, nSenderUniqueId)
    BattleShipWeaponSystem:ReceiveAimStateChanged(tbPacket.is_in_aim)
end

function ShipWeaponPacketProcessor_C:RegisterPackets()
    ShipWeaponPacketProcessor_C.super.RegisterPackets(self)
    self:BindFunc(Proto.d2c_NotifyActiveShipWeaponItemChanged   , NotifyActiveShipWeaponItemChanged)
    self:BindFunc(Proto.d2c_NotifyEquippedShipThrownItemChanged , NotifyEquippedShipThrownItemChanged)
    self:BindFunc(Proto.d2c_NotifyShipWeaponFiringCdBegan       , NotifyShipWeaponFiringCdBegan)
    self:BindFunc(Proto.d2c_NotifyShipWeaponBulletLoadingBegan  , NotifyShipWeaponBulletLoadingBegan)
    self:BindFunc(Proto.d2c_NotifyShipWeaponBulletLoadingEnded  , NotifyShipWeaponBulletLoadingEnded)
    self:BindFunc(Proto.d2c_NotifyShipFiringOperationChanged    , NotifyShipFiringOperationChanged)
    self:BindFunc(Proto.d2c_NotifyShipAimStateChanged           , NotifyShipAimStateChanged)
end

return ShipWeaponPacketProcessor_C
