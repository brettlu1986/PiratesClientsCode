-----------------------------------------------------
--File Name    : BattleItemPacketProcessor.lua
--Author       : zhiyuan
--Create Time  : 2018-08-15
--Description  : 接收客户端发过来的物品系统相关的协议
-----------------------------------------------------
local luaclass = require("luaclass")
local NetMessageProcessorBase = require("NetMessageProcessorBase")
local BattleItemPacketProcessor = luaclass("BattleItemPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local BattleItemSystemServer  = require("BattleItemSystemServer")
local GameObjectSystem = dynamic_require("GameObjectSystem")

local function UniqueIdToInstanceId(nSenderUniqueId)
    local tbSender = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if not tbSender then
        logwarning("Cannot find sender!", nSenderUniqueId)
        return nil
    end
    return tbSender:GetServerInstanceId()
end

local function BuildItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:BuildItem(nInstanceId, tbPacket.template_id, tbPacket.slot_index)
end

local function CancelBuildItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:CancelBuildItem(nInstanceId)
end

local function EquipItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:EquipItem(nInstanceId, tbPacket.owner_instance_id, tbPacket.item_instance_id, tbPacket.slot_index, true)
end

local function UnequipItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:UnEquipItem(nInstanceId, tbPacket.item_instance_id, tbPacket.count)
end

local function EquipStackableItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:EquipStackableItem(nInstanceId, tbPacket.owner_instance_id, tbPacket.item_template_id, tbPacket.count)
end

local function ExchangeStorageLocation(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:ExchangeStorageLocation(nInstanceId, tbPacket.item_instance_id1, tbPacket.item_instance_id2)
end

local function PickupItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:PickUpSceneItem(nInstanceId, tbPacket.instance_id, tbPacket.count)
end

local function ThrowAwayItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:ThrowAwayItem(nInstanceId, tbPacket.instance_id, tbPacket.count)
end

local function BeginViewSceneItems(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:BeginViewItemsDetail(nInstanceId, tbPacket.instance_ids)
end

local function EndViewSceneItems(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:EndViewItemsDetail(nInstanceId)
end

local function ThrowAwayAndPickupItem(self, tbPacket, nSenderUniqueId)
    local nInstanceId = UniqueIdToInstanceId(nSenderUniqueId)
    if not nInstanceId then
        return
    end
    BattleItemSystemServer:ThrowAwayAndPickupItem(nInstanceId, tbPacket)
end

-- 注册处理包
function BattleItemPacketProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(ProtoDC.c2d_BuildItem, self, BuildItem)
    self:BindMethod(ProtoDC.c2d_CancelBuildItem, self, CancelBuildItem)
    self:BindMethod(ProtoDC.c2d_EquipItem, self, EquipItem)
    self:BindMethod(ProtoDC.c2d_UnequipItem, self, UnequipItem)
    self:BindMethod(ProtoDC.c2d_EquipStackableItem, self, EquipStackableItem)
    self:BindMethod(ProtoDC.c2d_ExchangeStorageLocation, self, ExchangeStorageLocation)
    self:BindMethod(ProtoDC.c2d_PickupItem, self, PickupItem)
    self:BindMethod(ProtoDC.c2d_ThrowAwayItem, self, ThrowAwayItem)
    self:BindMethod(ProtoDC.c2d_ThrowAwayAndPickupItem, self, ThrowAwayAndPickupItem)
    self:BindMethod(ProtoDC.c2d_BeginViewSceneItems, self, BeginViewSceneItems)
    self:BindMethod(ProtoDC.c2d_EndViewSceneItems, self, EndViewSceneItems)
end

-- 初始化
function BattleItemPacketProcessor:Init()
    BattleItemPacketProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

return BattleItemPacketProcessor