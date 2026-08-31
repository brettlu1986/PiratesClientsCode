local BattleShipWeaponProtoHelper = {}

local Proto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GameObjectTypeDef = require("GameObjectTypeDef")

local function LOG(...)
    log("[BattleShipWeapon][ProtoHelper]", ...)
end

local function LOG_WITH_CHARACTER(tbCharacter, ...)
    LOG(tbCharacter and tbCharacter.szName, ...)
end

local function IsPlayerSelf(tbCharacter)
    return tbCharacter and (tbCharacter.ObjectType == GameObjectTypeDef.PlayerSelf)
end

local function SendToServer(szMessageType, tbMessageBody)
    NetworkManager:GetRPCNetworkProxy():SendToServer(szMessageType, tbMessageBody)
    LOG(szMessageType, t2s(tbMessageBody))
end

local function SendToClient(tbCharacter, szMessageType, tbMessageBody)
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbCharacter:GetUEControllerUniqueId(), szMessageType, tbMessageBody)
    LOG_WITH_CHARACTER(tbCharacter, szMessageType, t2s(tbMessageBody))
end

--[[
    C2D
]]
-- 请求激活舰船武器
function BattleShipWeaponProtoHelper.RequestActivateWeaponItem(nWeaponItemInstanceId)
    local c2d_RequestShipActivateWeaponItem = {
        weapon_item_instance_id = nWeaponItemInstanceId
    }
    SendToServer(Proto.c2d_RequestShipActivateWeaponItem, c2d_RequestShipActivateWeaponItem)
end

-- 请求装备舰船投掷物 
function BattleShipWeaponProtoHelper.RequestEquipThrownItem(nThrownItemTemplateId)
    local c2d_RequestShipEquipThrownItem = {
        thrown_item_template_id = nThrownItemTemplateId
    }
    SendToServer(Proto.c2d_RequestShipEquipThrownItem, c2d_RequestShipEquipThrownItem)
end

-- 请求开火
function BattleShipWeaponProtoHelper.RequestFire(nFiringOperation)
    local c2d_RequestShipFire = {
        firing_operation = nFiringOperation
    }
    SendToServer(Proto.c2d_RequestShipFire, c2d_RequestShipFire)
end

-- 请求装弹
function BattleShipWeaponProtoHelper.RequestLoadBullet()
    SendToServer(Proto.c2d_RequestShipLoadBullet)
end

-- 请求改变开镜状态
function BattleShipWeaponProtoHelper.RequestChangeAimState(bInAim)
    local c2d_RequestShipChangeAimState = {
        is_in_aim = bInAim
    }
    SendToServer(Proto.c2d_RequestShipChangeAimState, c2d_RequestShipChangeAimState)
end

--[[
    D2C
]]
-- 通知客户端激活的舰船武器改变
function BattleShipWeaponProtoHelper.NotifyActiveWeaponItemChanged(tbCharacter, ActiveWeaponItem)
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyActiveShipWeaponItemChanged = {
        weapon_item_instance_id = ActiveWeaponItem and ActiveWeaponItem:GetInstanceId()
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyActiveShipWeaponItemChanged, d2c_NotifyActiveShipWeaponItemChanged)
end

-- 通知客户端装备的投掷物改变
function BattleShipWeaponProtoHelper.NotifyEquippedThrownItemChanged(tbCharacter, EquippedThrownItem)
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyEquippedShipThrownItemChanged = {
        thrown_item_instance_id = EquippedThrownItem and EquippedThrownItem:GetInstanceId()
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyEquippedShipThrownItemChanged, d2c_NotifyEquippedShipThrownItemChanged)
end

-- 通知客户端开始CD
function BattleShipWeaponProtoHelper.NotifyFiringCdBegan(WeaponItem, nDuration, nElapsedTime)
    if not WeaponItem then
        return
    end
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyShipWeaponFiringCdBegan =
    {
        weapon_item_instance_id = WeaponItem:GetInstanceId(),
        duration = nDuration,
        elapsed_time = nElapsedTime
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyShipWeaponFiringCdBegan, d2c_NotifyShipWeaponFiringCdBegan)
end

-- 舰船武器开始装弹通知
function BattleShipWeaponProtoHelper.NotifyBulletLoadBegan(WeaponItem, nDuration, nElapsedTime)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyShipWeaponBulletLoadingBegan =
    {
        weapon_item_instance_id = WeaponItem:GetInstanceId(),
        duration = nDuration,
        elapsed_time = nElapsedTime
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyShipWeaponBulletLoadingBegan, d2c_NotifyShipWeaponBulletLoadingBegan)
end

-- 舰船武器结束装弹通知
function BattleShipWeaponProtoHelper.NotifyBulletLoadEnded(WeaponItem)
    local tbCharacter = WeaponItem:GetOwnerCharacter()
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyShipWeaponBulletLoadingEnded =
    {
        weapon_item_instance_id = WeaponItem:GetInstanceId()
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyShipWeaponBulletLoadingEnded, d2c_NotifyShipWeaponBulletLoadingEnded)
end

-- 通知客户端开镜状态改变
function BattleShipWeaponProtoHelper.NotifyAimStateChanged(tbCharacter, bIsInAim)
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyShipAimStateChanged =
    {
        is_in_aim = bIsInAim
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyShipAimStateChanged, d2c_NotifyShipAimStateChanged)
end

-- 通知客户端开镜状态改变
function BattleShipWeaponProtoHelper.NotifyFiringOperationChanged(tbCharacter, nWeaponInstanceId, nFiringOperation)
    if not IsPlayerSelf(tbCharacter) then
        return
    end
    local d2c_NotifyShipFiringOperationChanged =
    {
        weapon_item_instance_id = nWeaponInstanceId,
        firing_operation = nFiringOperation
    }
    SendToClient(tbCharacter, Proto.d2c_NotifyShipFiringOperationChanged, d2c_NotifyShipFiringOperationChanged)
end

return BattleShipWeaponProtoHelper