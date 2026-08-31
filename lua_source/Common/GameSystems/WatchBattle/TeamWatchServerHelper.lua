local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleTeamCategoryDefine = require("BattleTeamCategoryDefine")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")
local BitHelper = require("BitHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

local ECategoryType = BattleTeamCategoryDefine.tbCategoryType

local TeamWatchServerHelper = {}

local function GetUniqueId(nServerInsId)
    local tbObj = GameObjectSystem:FindByInstanceId(nServerInsId)
    if tbObj then
        return tbObj:GetUEControllerUniqueId()
    end
    return 0
end

local function IsPlayerSelf(tbPlayer)
    return tbPlayer and (tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf)
end

function TeamWatchServerHelper.SendShipAmmoInfoToViewers(tbPlayer, ShipWeaponItem, bCheckActiveWeapon, bShipWeaponSlotMove, nSlot)
    if IsPlayerSelf(tbPlayer) then
        local bIsShip = tbPlayer:IsShip()
        if bIsShip then
            local nTemplateId = 0
            local nShipBulletCount = 0
            local nShipBulletMax = 0
            if ShipWeaponItem then
                nTemplateId = ShipWeaponItem:GetTemplateId()
                
                if ShipWeaponItem:GetCategory() == BattleItemCategoryDef.SHIP_THROWN_ITEM then
                    nShipBulletCount = BattleItemSystemHelper:GetUnequippedItemCount(tbPlayer:GetServerInstanceId(), nTemplateId, false)
                    nShipBulletMax = nShipBulletCount
                else
                    local nBulletItemTemplateId = ShipWeaponItem:GetBulletItemTemplateId()
                    if nBulletItemTemplateId then
                        nShipBulletCount = ShipWeaponItem:GetBulletLoadedCount()
    
                        nShipBulletMax = ShipWeaponItem:IsInfiniteBullet() and ShipWeaponItem:GetBulletMaxLoadingCount() 
                            or ShipWeaponItem:GetBulletUnloadedCount(false)
                    end
                end

                if bCheckActiveWeapon then   
                    local BattleShipWeaponComponent = tbPlayer.BattleShipWeaponComponent
                    local tbActiveWeapon = BattleShipWeaponComponent:GetActiveWeaponItem()
                    local nActiveTemplateId = tbActiveWeapon and tbActiveWeapon:GetTemplateId()
                    if nActiveTemplateId ~= nTemplateId then  
                        nTemplateId = nil
                    end
                end
            end

            if nTemplateId then
                TeamWatchServerHelper.NotifyViewersWeaponBullet(tbPlayer, nTemplateId, nShipBulletCount, nShipBulletMax, bShipWeaponSlotMove, nSlot)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersAimState(tbPlayer, bIsShip, bInAim)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then 
        local tbViewers = WatchBattleComponent:GetViewers()
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    is_ship_aim = bIsShip,
                    is_in_aim = bInAim,
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewerChangeAimState, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersCarronadeCameraActiveChanged(tbPlayer, bActive)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    active = bActive
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewerCarronadeCameraActiveChanged, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersMovementState(tbPlayer, nLastMovementState, nCurrentMovementState)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    last_state = nLastMovementState,
                    current_state = nCurrentMovementState,
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewerMovementState, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersWeaponBullet(tbPlayer, nTemplateId, nBulletCount, nBulletMax, bShipWeaponSlotMove, nSlot)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        local bShipSlotMove = bShipWeaponSlotMove ~= nil and bShipWeaponSlotMove == true
        local nWeaponSlot = nSlot or ShipWeaponSlotDef.UNKNOWN
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    template_id = nTemplateId,
                    bullet_count = nBulletCount,
                    bullet_max = nBulletMax,
                    bShipWeaponSlotMove = bShipSlotMove,
                    ship_weapon_slot = nWeaponSlot,
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewersWeaponBullet, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersIsWalkingNow(tbPlayer, bIsMoving)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    is_moving = bIsMoving,
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewerIsMovingNow, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersMovementModeChanged(tbPlayer, pPreMovementMode, pCurMovementMode)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    pre_move_mode = enumtoint(pPreMovementMode),
                    move_mode = enumtoint(pCurMovementMode),
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewerMovementMode, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersKillInfo(tbPlayer, nKillCount)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    nKillCount = nKillCount,
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyWatchMateKillInfo, tbPacket)
            end
        end
    end
end

function TeamWatchServerHelper.NotifyViewersGetInVehicle(tbPlayer, nVehicleId, bGetIn)
    local WatchBattleComponent = tbPlayer.WatchBattleComponent
    if WatchBattleComponent and WatchBattleComponent:HasViewers() then
        local tbViewers = WatchBattleComponent:GetViewers() 
        local nCount = #tbViewers
        local nUniqueId, tbPacket
        for i = 1, nCount do
            nUniqueId = GetUniqueId(tbViewers[i])
            if nUniqueId > 0 then
                tbPacket = {
                    vehicle_id = nVehicleId,
                    is_enter = bGetIn,
                }
                NetworkManager:GetRPCNetworkProxy():SendToClient(nUniqueId, Proto.d2c_NotifyViewersGetInVehicle, tbPacket)
            end
        end
    end
end

local function RepBaseInfo(tbAllData, rBattleTeamBaseInfo)
    local tbPacket = {}
    tbPacket.BaseInfos = {}

    for _, tbCurInfo in pairs(tbAllData.tbSortedBaseInfos) do
        local tbPlayerData = {}
        tbPlayerData.nGenderType = tbCurInfo.nGenderType
        tbPlayerData.name        = tbCurInfo.name
        tbPlayerData.bIsBot      = tbCurInfo.bIsBot
        tbPlayerData.nPlayerId   = tbCurInfo.nPlayerId

        table.insert( tbPacket.BaseInfos, tbPlayerData )
    end

    rBattleTeamBaseInfo:Set(tbPacket)
end

local function RepHealthInfo(tbTeamdata, rBattleTeamHealthInfo)
    local tbPacket = {}
    tbPacket.HealthInfos = {}

    for Key, Value in pairs(tbTeamdata) do
        local tbPlayerData = {}
        tbPlayerData.nHp         = Value.nHp
        tbPlayerData.nMaxHp      = Value.nMaxHp

        table.insert( tbPacket.HealthInfos, tbPlayerData )
    end

    rBattleTeamHealthInfo:Set(tbPacket)
end

local function RepStateInfo(tbTeamdata, rBattleTeamStateInfo)
    local tbPacket = {}
    tbPacket.StateInfos = {}

    for Key, Value in pairs(tbTeamdata) do
        local tbPlayerData = {}
        tbPlayerData.nState      = Value.nState
        tbPlayerData.nVehicleId  = Value.nVehicleId

        table.insert( tbPacket.StateInfos, tbPlayerData )
    end

    rBattleTeamStateInfo:Set(tbPacket)
end

local function RepPosInfo(tbTeamdata, rBattleTeamPosInfo)
    local tbPacket = {}
    tbPacket.PosInfos = {}

    for Key, Value in pairs(tbTeamdata) do
        local tbPlayerData = {}
        local COORDINATE_PROPORTION = 100

        tbPlayerData.nPosXY   = BitHelper:XYToPos(Value.nPlayerX / COORDINATE_PROPORTION, Value.nPlayerY / COORDINATE_PROPORTION)
        tbPlayerData.nPosZYaw = BitHelper:XYToPos(Value.nPlayerZ, Value.nPlayerYaw)

        table.insert( tbPacket.PosInfos, tbPlayerData )
    end

    rBattleTeamPosInfo:Set(tbPacket)
end

local function RepSignInfo(tbTeamdata, rBattleTeamSignInfo)
    local tbPacket = {}
    tbPacket.SignInfos = {}

    for Key, Value in pairs(tbTeamdata) do
        local tbPlayerData = {}
        tbPlayerData.SignType    = Value.SignType
        tbPlayerData.nSignX      = Value.nSignX
        tbPlayerData.nSignY      = Value.nSignY

        table.insert( tbPacket.SignInfos, tbPlayerData )
    end

    rBattleTeamSignInfo:Set(tbPacket)
end

local function RepIDInfo(tbAllData, rTeamPlayersInfo)
    local tbPacket = {}
    tbPacket.nTeamId       = tbAllData.nTeamId
    tbPacket.nPlayerCount  = tbAllData.nPlayerCount
    tbPacket.tbPlayerIds   = tbAllData.tbPlayerIds
    tbPacket.tbInstanceIds = tbAllData.tbInstanceIds

    rTeamPlayersInfo:Set(tbPacket)
end

function TeamWatchServerHelper.RepBattleTeamData(eType, tbAllData, rBaseInfo, rHealthInfo, rStateInfo, rPosInfo, rSignInfo, rIDsInfo)
    --将tbTeamData拆成各种协议发出去
    if eType & ECategoryType.BaseInfo > 0 then
        RepBaseInfo(tbAllData, rBaseInfo)
    end

    if eType & ECategoryType.HealthInfo > 0 then
        RepHealthInfo(tbAllData.tbTeamData, rHealthInfo)
    end

    if eType & ECategoryType.StateInfo > 0 then
        RepStateInfo(tbAllData.tbTeamData, rStateInfo)
    end

    if eType & ECategoryType.PosInfo > 0 then
        RepPosInfo(tbAllData.tbTeamData, rPosInfo)
    end

    if eType & ECategoryType.SignInfo > 0 then
        RepSignInfo(tbAllData.tbTeamData, rSignInfo)
    end

    if eType & ECategoryType.IDInfo > 0 then
        RepIDInfo(tbAllData, rIDsInfo)
    end
end
-------------------------------------------------------------

return TeamWatchServerHelper