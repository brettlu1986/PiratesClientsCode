
local BattleItemSystemProtocalHelper = {}

local NetworkManager = dynamic_require("NetworkManager")
local ProtoDC = require("DungeonCommonProtoNames")
local GameObjectTypeDef = require("GameObjectTypeDef")

function BattleItemSystemProtocalHelper:SyncAddItem(Item)
    local tbCharacter = Item:GetOwnerCharacter()
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_SyncAddItem =
    {
        item = Item:GetProtoData()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncAddItem, d2c_SyncAddItem)
end

function BattleItemSystemProtocalHelper:SyncRemoveItem(tbCharacter, nItemInstanceId)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_SyncRemoveItem =
    {
        instance_id = nItemInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncRemoveItem, d2c_SyncRemoveItem)
end

function BattleItemSystemProtocalHelper:SyncItemStackCount(Item)
    local tbCharacter = Item:GetOwnerCharacter()
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_SyncItemStackCount =
    {
        instance_id = Item:GetInstanceId(),
        stack_count = Item:GetStackCount()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncItemStackCount, d2c_SyncItemStackCount)
end

function BattleItemSystemProtocalHelper:SyncItemDurability(Item)
    local tbCharacter = Item:GetOwnerCharacter()
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_SyncItemDurability =
    {
        instance_id = Item:GetInstanceId(),
        durability = Item:GetDurability()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncItemDurability, d2c_SyncItemDurability)
end

function BattleItemSystemProtocalHelper:SyncItemStorageLocation(Item)
    local tbCharacter = Item:GetOwnerCharacter()
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_SyncItemStorageLocation =
    {
        instance_id = Item:GetInstanceId(),
        storage_location = Item:GetStorageLocationProtoData()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncItemStorageLocation, d2c_SyncItemStorageLocation)
end

function BattleItemSystemProtocalHelper:SyncOnUnequipAllShipEquipItems(tbCharacter)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_OnUnequipAllShipEquipItems)
end

function BattleItemSystemProtocalHelper:SyncD2CBuildItem(tbCharacter, nResult, nTemplateId, nSlotIndex)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_BuildItem =
    {
        result = nResult,
        template_id = nTemplateId,
        slot_index = nSlotIndex
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_BuildItem, d2c_BuildItem)
end

function BattleItemSystemProtocalHelper:SyncD2CBuildItemCancel(tbCharacter)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_BuildItemCancel)
end

function BattleItemSystemProtocalHelper:SyncD2CBuildItemFinish(tbCharacter, nItemInstanceId)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_BuildItemFinish =
    {
        instance_id = nItemInstanceId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_BuildItemFinish, d2c_BuildItemFinish)
end

function BattleItemSystemProtocalHelper:SyncD2CEquipItem(tbCharacter, nResult, nItemInstanceId, nOwnerInstanceId, nSlotIndex)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_EquipItem =
    {
        result = nResult,
        owner_instance_id = nOwnerInstanceId,
        item_instance_id = nItemInstanceId,
        slot_index = nSlotIndex,
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_EquipItem, d2c_EquipItem)
end

function BattleItemSystemProtocalHelper:SyncD2CUnequipItem(tbCharacter, nResult, nItemInstanceId, nCount, nItemTemplateId)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_UnequipItem =
    {
        result = nResult,
        item_instance_id = nItemInstanceId,
        count = nCount,
        item_template_id = nItemTemplateId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_UnequipItem, d2c_UnequipItem)
end

function BattleItemSystemProtocalHelper:SyncD2CEquipStackableItem(tbCharacter, nResult, nOwnerInstanceId, nItemTemplateId, nCount, nAddCount)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_EquipStackableItem =
    {
        result = nResult,
        owner_instance_id = nOwnerInstanceId,
        item_template_id = nItemTemplateId,
        count = nCount,
        add_count = nAddCount
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_EquipStackableItem, d2c_EquipStackableItem)
end

function BattleItemSystemProtocalHelper:SyncD2CExchangeStorageLocation(tbCharacter, nResult, Item1, Item2)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_ExchangeStorageLocation =
    {
        result = nResult,
        item_instance_id1 = Item1:GetInstanceId(),
        storage_location1 = Item1:GetStorageLocationProtoData(),
        item_instance_id2 = Item2:GetInstanceId(),
        storage_location2 = Item2:GetStorageLocationProtoData()
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_ExchangeStorageLocation, d2c_ExchangeStorageLocation)
end

function BattleItemSystemProtocalHelper:SyncD2CPickupItem(tbCharacter, nResult, nItemInstanceId, nItemTemplateId)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_PickupItem =
    {
        result = nResult,
        instance_id = nItemInstanceId,
        template_id = nItemTemplateId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_PickupItem, d2c_PickupItem)
end

function BattleItemSystemProtocalHelper:SyncD2CThrowAwayAndPickupItem(tbCharacter, nResult, nItemInstanceId, nItemTemplateId)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_ThrowAwayAndPickupItem =
    {
        result = nResult,
        instance_id = nItemInstanceId,
        template_id = nItemTemplateId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_ThrowAwayAndPickupItem, d2c_ThrowAwayAndPickupItem)
end

function BattleItemSystemProtocalHelper:SyncD2CThrowAwayItem(tbCharacter, nResult, nItemInstanceId, nCount, nItemTemplateId)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local d2c_ThrowAwayItem =
    {
        result = nResult,
        item_instance_id = nItemInstanceId,
        count = nCount,
        item_template_id = nItemTemplateId
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_ThrowAwayItem, d2c_ThrowAwayItem)
end

-- 同步让客户端重置物品数据
function BattleItemSystemProtocalHelper:SyncD2CResetBattleItemData(tbCharacter, tbItemDatas, nGrade)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local tbPacket = {
        items = tbItemDatas,
        built_grade = nGrade
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_ResetBattleItemData, tbPacket)
end


-- 同步船的战备数据
function BattleItemSystemProtocalHelper:SyncD2CSyncShipPreparation(tbCharacter)
    if tbCharacter.ObjectType ~= GameObjectTypeDef.PlayerSelf then
        return
    end
    local tbPrepareInfo = tbCharacter.tbPrepareInfo
    local tbPacket = {
        ship_preparation_template_ids = tbPrepareInfo.tbShipPreparationTemplateIds,
        ship_skin_ids = tbPrepareInfo.tbShipSkinIds
    }
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), ProtoDC.d2c_SyncShipPreparation, tbPacket)
end


return BattleItemSystemProtocalHelper
