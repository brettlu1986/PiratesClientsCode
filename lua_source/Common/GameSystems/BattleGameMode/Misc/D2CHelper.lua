local D2CHelper = {}

local Proto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GameObjectTypeDef = require("GameObjectTypeDef")
local DamageHurtDef = require("DamageHurtDef")
local BattleSpecialToastHelper = require("BattleSpecialToastHelper")

local function IsPlayerSelf(tbPlayer)
    return tbPlayer and (tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf)
end

-- 停船
function D2CHelper:MulticastStopMove()
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_StopMove)
end

-- 退出瞄准鱼雷等模式，恢复正常模式
function D2CHelper:MulticastSwitchCommonHandlerMode()
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_SwitchCommonHandlerMode)
end

function D2CHelper:PlayerSwitchCommonHandlerMode(tbPlayer)
    if IsPlayerSelf(tbPlayer) then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_SwitchCommonHandlerMode)
    end
end

-- 镜头回到船后
function D2CHelper:MulticastResetCameraControl()
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_ResetCameraControl)
end

function D2CHelper:PlayerResetCameraControl(tbPlayer)
    if IsPlayerSelf(tbPlayer) then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_ResetCameraControl)
    end
end

-- 设置镜头方向
function D2CHelper:PlayerSetCameraYaw(tbPlayer, nYaw)
    if IsPlayerSelf(tbPlayer) then
        local tbPacket = {
            nYaw = nYaw
        }
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_SetCameraYaw, tbPacket)
    end
end

function D2CHelper:SendCommonToast(tbPlayer, szKey, szParam0, szParam1, szParam2)
    if IsPlayerSelf(tbPlayer) then
        local tbPacket = {
            key = szKey,
            param0 = szParam0,
            param1 = szParam1,
            param2 = szParam2
        }
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_ShowCommonToast, tbPacket)
    end
end

function D2CHelper:MulticastBattleToast(nId, szParam0, szParam1, szParam2, nToastType, nWaitTime)
    local tbPacket = {}
    BattleSpecialToastHelper.FillToastInfo(
        tbPacket,
        nil,
        nId,
        szParam0, szParam1, szParam2,
        nToastType,
        nil,
        nWaitTime)
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_BattleToast, tbPacket)
end

function D2CHelper:MulticastKillToast(nInType,
    szInKiller, szInDeader,
    nInKillerInstanceId, nInDeaderInstanceId,
    nInDamageType,
    nInWeaponTemplateId)

    local tbPacket = {
        nType = nInType,
        szKiller = szInKiller,
        szDeader = szInDeader,
        nKillerInstanceId = nInKillerInstanceId,
        nDeaderInstanceId = nInDeaderInstanceId,
        nDamageType = nInDamageType,
        nWeaponTemplateId = nInWeaponTemplateId
    }
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_BattleKillToast, tbPacket, false)
end

function D2CHelper:SendAutoBattle(tbPlayer, bEnable)
    if IsPlayerSelf(tbPlayer) then
        local tbPacket = {
            enable = bEnable
        }
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_AutoBattle, tbPacket)
    end
end

function D2CHelper:NotifyOnHitPlayer(tbPlayer, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, nRegionType, nHurtTag)
    local tbPacket =
    {
        taker_id = tbPlayer.nServerInstanceId,
        causer_id = tbCauser and tbCauser.nServerInstanceId ,
        damage = nDamage,
        damage_type = nDamageType,
        hp = nHp, 
        weapon_tempId = nWeaponTemplateId,
        region_type = nRegionType,
        hurt_tag = nHurtTag or DamageHurtDef.HURT_NONE
    }
    -- NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_NotifyOnHitPlayer, { causer_id  = tbCauser.nServerInstanceId, damage = nDamage })
    if IsPlayerSelf(tbPlayer) then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_NotifyOnHitPlayer, tbPacket)
    end
    if (tbCauser ~= tbPlayer) and IsPlayerSelf(tbCauser) then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbCauser:GetUEControllerUniqueId(), Proto.d2c_NotifyOnHitPlayer, tbPacket)
    end
end

function D2CHelper:NotifyProgressBarStartFailed(tbPlayer, nFailedReasonId)
    if IsPlayerSelf(tbPlayer) then
        local tbPacket = {}
        tbPacket.failed_reason_id = nFailedReasonId
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), Proto.d2c_NotifyProgressBarStartFailed, tbPacket)
    end
end

function D2CHelper:MulticastGameOver()
    local tbPacket = {}
    NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_BattleGameOver, tbPacket, false)
end

return D2CHelper