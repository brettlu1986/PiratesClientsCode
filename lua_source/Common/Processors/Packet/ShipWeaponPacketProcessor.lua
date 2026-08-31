local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local ShipWeaponPacketProcessor = luaclass("ShipWeaponPacketProcessor", NetMessageProcessorBase)

local Proto = require("DungeonCommonProtoNames")
local BattleItemSystemServer = require("BattleItemSystemServer")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local NetworkManager = dynamic_require("NetworkManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local function RequestShipActivateWeaponItem(tbPacket, nSenderUniqueId)
    local tbCharacter = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbCharacter and tbCharacter:IsShip() then
        local WeaponItem = BattleItemSystemServer:GetItem(tbPacket.weapon_item_instance_id)
        BattleShipWeaponSystem:ActivateWeaponItem(tbCharacter, WeaponItem)
    end
end

local function RequestShipEquipThrownItem(tbPacket, nSenderUniqueId)
    local tbCharacter = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbCharacter and tbCharacter:IsShip() then
        BattleShipWeaponSystem:EquipThrownItem(tbCharacter, tbPacket.thrown_item_template_id)
    end
end

local function RequestShipFire(tbPacket, nSenderUniqueId)
    local tbCharacter = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbCharacter and tbCharacter:IsShip() then
        BattleShipWeaponSystem:Fire(tbCharacter, tbPacket.firing_operation)
    end
end

local function RequestShipLoadBullet(tbPacket, nSenderUniqueId)
    local tbCharacter = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbCharacter and tbCharacter:IsShip() then
        BattleShipWeaponSystem:LoadBullet(tbCharacter)
    end
end

local function RequestShipChangeAimState(tbPacket, nSenderUniqueId)
    local tbCharacter = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbCharacter and tbCharacter:IsShip() then
        BattleShipWeaponSystem:ChangeAimState(tbCharacter, tbPacket.is_in_aim)
    end
end

function ShipWeaponPacketProcessor:RegisterPackets()
    if GlobalVariableSystem:IsDedicatedClient() then
        return
    end
    self:BindFunc(Proto.c2d_RequestShipActivateWeaponItem   , RequestShipActivateWeaponItem)
    self:BindFunc(Proto.c2d_RequestShipEquipThrownItem      , RequestShipEquipThrownItem)
    self:BindFunc(Proto.c2d_RequestShipFire                 , RequestShipFire)
    self:BindFunc(Proto.c2d_RequestShipLoadBullet           , RequestShipLoadBullet)
    self:BindFunc(Proto.c2d_RequestShipChangeAimState       , RequestShipChangeAimState)
end

function ShipWeaponPacketProcessor:Init()
    ShipWeaponPacketProcessor.super.Init(self)
    self:SetBinder(NetworkManager:GetRPCNetworkProxy())
    self:RegisterPackets()
    return true
end

return ShipWeaponPacketProcessor
