local BattleFFAReLoginHelper = {}

local HumanMovementStateType = require("HumanMovementStateType")
local ProtoDR = require("DungeonRepProtoNames")

local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local ProtoDC = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local BattleTeamSystem = require("BattleTeamSystem")
local SelectionPointHelper = require("SelectionPointHelper")
local TransporterDataTable = require("TransporterDataTable")
local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local PlayerStatsHelper = require("PlayerStatsHelper")
local BattleResultSystem = dynamic_require("BattleResultSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")
local BattleShipWeaponProtoHelper = require("BattleShipWeaponProtoHelper")
local BattleShipWeaponSystem = dynamic_require("BattleShipWeaponSystem")
local ShipWeaponSlotDef = require("ShipWeaponSlotDef")
local BattleItemCategoryDef = require("BattleItemCategoryDef")

-- 同步船武器开火CD
local function SyncShipWeaponFiringCd(WeaponItem)
    local nElapsedTime = GlobalVariableSystem:GetDSTimeSeconds() - WeaponItem:GetLastFiringTime()
    local nDuration = WeaponItem:GetLastFiringCD()
    if nElapsedTime < nDuration then
        BattleShipWeaponProtoHelper.NotifyFiringCdBegan(WeaponItem, nDuration, nElapsedTime)
    end
end

-- 同步船武器装弹CD
local function SyncShipWeaponBulletLoading(WeaponItem)
    if WeaponItem:GetCategory() ~= BattleItemCategoryDef.SHIP_WEAPON then
        return
    end
    local nElapsedTime = GlobalVariableSystem:GetDSTimeSeconds() - WeaponItem:GetBulletLoadingStartTime()
    local nDuration = WeaponItem:GetBulletLoadingTime()
    if nElapsedTime < nDuration then
        BattleShipWeaponProtoHelper.NotifyBulletLoadBegan(WeaponItem, nDuration, nElapsedTime)
    end
end

-- 同步船武器状态
local function SyncShipWeaponState(tbPlayer)
    -- 只要活着，不管出于人状态还是船状态，都需要重新同步下去当前装备的投掷物和激活的武器
    local ActiveWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbPlayer)
    local EquippedThrownItem = BattleShipWeaponSystem:GetEquippedWeaponItem(tbPlayer, ShipWeaponSlotDef.THROW)
    BattleShipWeaponProtoHelper.NotifyActiveWeaponItemChanged(tbPlayer, ActiveWeaponItem)
    BattleShipWeaponProtoHelper.NotifyEquippedThrownItemChanged(tbPlayer, EquippedThrownItem)
    if not tbPlayer:IsShip() then
        return
    end
    BattleShipWeaponSystem:ChangeAimState(tbPlayer, false)
    for nSlot=ShipWeaponSlotDef.MIN, ShipWeaponSlotDef.MAX do
        local WeaponItem = BattleShipWeaponSystem:GetEquippedWeaponItem(tbPlayer, nSlot)
        if WeaponItem then
            SyncShipWeaponFiringCd(WeaponItem)
            SyncShipWeaponBulletLoading(WeaponItem)
        end
    end
end

function BattleFFAReLoginHelper:OnPlayerReLogin(tbPlayer, jgmFFASetting)
    --发送击杀人数信息
    BattleFFAReLoginHelper:ReLoginSendKillCountInfo(tbPlayer)
    --发送dungeon和player状态信息
    BattleFFAReLoginHelper:SendDungeonAndPlayerState(tbPlayer, true)
    --发送中心区区域开启信息
    BattleFFAReLoginHelper:ReLoginSendCoreAreaInfo(jgmFFASetting:IsCoreAreaOpen(), tbPlayer)
    --玩家如果结算了的话，发送结算协议
    BattleFFAReLoginHelper:ReLoginSendTeamResult(jgmFFASetting.nTeamModeId, jgmFFASetting.nPlayerCount, jgmFFASetting.nTeamCount ,tbPlayer)
    --玩家如果在跳伞落地前，则调用全局同步的开关
    BattleFFAReLoginHelper:ReLoginSetControllerReplication(tbPlayer)
    --最近使用的载具信息
    BattleFFAReLoginHelper:ReLoginSendRecentUsedVehicleInfo(tbPlayer)
    --上次刷新的离玩家最近的宝石位置信息
    BattleFFAReLoginHelper:ReloginSendLastDiamondInfo(tbPlayer)
    --是否已经结束
    BattleFFAReLoginHelper:ReLoginSendGameOver(jgmFFASetting:GameOver(), tbPlayer)
end

function BattleFFAReLoginHelper:SendDungeonAndPlayerState(tbPlayer, bLogin)
    --ReLogin需要看下人物的状态
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if not tbGameMode then
        return
    end

    local tbGameState = tbGameMode.tbGameState
    local nFFAProcessState = tbGameState.nFFAProcessState
    local nState = nFFAProcessState:Get()

    if nState < ProtoDR.rFFAProcessState_EState.COUNTDOWN then
        return
    end

    local tbPacket = {}
    local bBattle = nState >= ProtoDR.rFFAProcessState_EState.PARACHUTING
    tbPacket.time = 0
    
    if bBattle then
        local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
        local nMovmementState = HumanMovementStateComponent and HumanMovementStateComponent:GetCurrentState()
        if nMovmementState then
            bBattle = nMovmementState ~= HumanMovementStateType.InPlane_State
                and nMovmementState ~= HumanMovementStateType.Parachutine_State
                and nMovmementState ~= HumanMovementStateType.Falling_State
                and nMovmementState ~= HumanMovementStateType.Gliding_State
            if nMovmementState == HumanMovementStateType.Falling_State then
                local BPParachuting = tbPlayer.pUEActor.BPParachutingNew
                if BPParachuting then
                    log("SendDungeonAndPlayerState falling")
                    BPParachuting:Reconnect()
                end
            elseif nMovmementState == HumanMovementStateType.InPlane_State then
                local _, _, _, nTransporterId = SelectionPointHelper:GetBornPos(tbPlayer:GetServerInstanceId())
                local tbData = TransporterDataTable:GetTemplate(nTransporterId)
                if tbData and tbData.nLaunchTime then
                    local nCurTime = GlobalVariableSystem:GetLocalTime()
                    local nTime = tbData.nLaunchTime - (nCurTime - tbGameMode:GetBattleStartTimestamp())
                    if nTime > 0 then
                        tbPacket.launch_time = nCurTime + nTime
                    end
                end
            end
        end
    end
    tbPacket.state = nState
    tbPacket.battle = bBattle
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_DungeonAndPlayerState, tbPacket)
end

function BattleFFAReLoginHelper:ReLoginSendTeamResult(nTeamModeId, nPlayerCount, nTeamCount, tbPlayer)
    local nPlayerInstanceId = tbPlayer:GetServerInstanceId()
    if BattleResultSystem:IsPlayerBattleEnd(nPlayerInstanceId) then
        -- 结算
        local tbPacket = {}
        local nWinerTeamId = BattleResultSystem:GetWinerTeamId()
        local nTeamId = BattleTeamSystem:FindTeamId(tbPlayer)
        local bTeamDead, nTeamRank = nil,nil

        if nWinerTeamId and nWinerTeamId == nTeamId then
            bTeamDead = true
            nTeamRank = 1
        else
            bTeamDead, nTeamRank = BattleResultSystem:TryGetTeamRankAfterPlayerBattleEnd(tbPlayer, nTeamCount)
        end

        -- 队伍数据
        tbPacket.nMode = nTeamModeId
        tbPacket.bTeamDead = bTeamDead
        tbPacket.nTeamRank = nTeamRank
        tbPacket.nPlayerCount = nPlayerCount
        tbPacket.nTeamCount  = nTeamCount

        -- 组织队伍结算数据
        tbPacket.FFATeamResult = {}
        local tbTeamdata = tbPlayer.BattleTeamComponent.tbTeamdata
        for _, tbData in ipairs(tbTeamdata) do
            local nInstanceId = tbData.nInstanceId
            local tbResultData = BattleResultSystem:GetPlayerResultData(nInstanceId)
            if tbResultData then
                table.insert(tbPacket.FFATeamResult, tbResultData)
            end
        end

        local nMVPInstanceId, nMVPPlayerId = BattleResultSystem:GetTeamMVP(tbPlayer)
        if bTeamDead then
            tbPacket.nMVPInstanceId = nMVPInstanceId
            tbPacket.nMVPPlayerId = nMVPPlayerId
        end

        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFATeamResult, tbPacket)
        local tbRefreshPacket = {}
        tbRefreshPacket.bTeamDead = bTeamDead
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_ReLoginRefreshBattleResultWnd, tbRefreshPacket)
    end
end

function BattleFFAReLoginHelper:ReLoginSendKillCountInfo(tbPlayer)
    local nKillerKillCount = PlayerStatsHelper:GetKillCountByPlayerId(tbPlayer:GetPlayerId())
    local tbKillerKillPacket = {}
    tbKillerKillPacket.nKillCount = nKillerKillCount
    NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_FFAKillInfo, tbKillerKillPacket)
end

function BattleFFAReLoginHelper:ReLoginSendCoreAreaInfo(bIsCoreAreaOpen, tbPlayer)
    if bIsCoreAreaOpen then
        local tbShowCoreAreaPacket = {}
        tbShowCoreAreaPacket.bShowDialog = false
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(),ProtoDC.d2c_FFAShowCoreArea, tbShowCoreAreaPacket)
    end
end

function BattleFFAReLoginHelper:ReLoginSetControllerReplication(tbPlayer)
    --ReLogin需要看下人物的状态
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if not tbGameMode then
        return
    end

    local tbGameState = tbGameMode.tbGameState
    local nFFAProcessState = tbGameState.nFFAProcessState
    local nState = nFFAProcessState:Get()

    local bBattle = false
    if nState ~= nil then
        bBattle = nState >= ProtoDR.rFFAProcessState_EState.PARACHUTING
        if bBattle then
            local HumanMovementStateComponent = tbPlayer.HumanMovementStateComponent
            local nMovmementState = HumanMovementStateComponent and HumanMovementStateComponent:GetCurrentState()
            if nMovmementState then
                bBattle = nMovmementState ~= HumanMovementStateType.InPlane_State
                    and nMovmementState ~= HumanMovementStateType.Parachutine_State
                    and nMovmementState ~= HumanMovementStateType.Falling_State
            end
        end
    end

    if not bBattle then
        local nTeamId = tbPlayer.BattleTeamComponent.nTeamId
        local pController = tbPlayer.pUEActor:GetController()
        PiratesReplicationBPHelpers.SetTeamForPlayerController(pController, nTeamId)
        log("ReLoginSetControllerReplication:",bBattle,nTeamId,pController and "Controller valid." or "Controller not valid.")
    end
end

function BattleFFAReLoginHelper:BattleItemResetAfterReLogin(tbPlayer)
    if tbPlayer:IsDead() then
        return
    end
    SyncShipWeaponState(tbPlayer)
    if tbPlayer:IsHuman() then
        local WeaponComponent = tbPlayer.HumanWeaponComponent
        local tbCurrentWeapon = WeaponComponent:GetCurrentWeapon()

        if tbCurrentWeapon then
            local nInstanceId = tbCurrentWeapon:GetInstanceId()
            log("ReLoginSendCurrentWeapon Weapon Instance Id:",nInstanceId)

            local tbTempCurrentWeaponPacket = {}
            tbTempCurrentWeaponPacket.weapon_id = nInstanceId
            tbTempCurrentWeaponPacket.force = true
            NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_HumanSetCurrentWeapon, tbTempCurrentWeaponPacket)
        end
    end
end

function BattleFFAReLoginHelper:ReLoginSendRecentUsedVehicleInfo(tbPlayer)
    local nVehicleId = tbPlayer.BattleTeamComponent:GetRecentUsedVehicleId(tbPlayer)
    if nVehicleId ~= 0 then
        local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleId)
        if not tbVehicle then  
            return 
        end

        local tbPacket = {}
        tbPacket.nVehicleId = nVehicleId
        local pLocation = tbVehicle:GetLocation()
        tbPacket.nX = math.ceil(pLocation.X)
        tbPacket.nY = math.ceil(pLocation.Y)

        log("ReLoginSendRecentUsedVehicleInfo:",tbPacket.nVehicleId,tbPacket.nX,tbPacket.nY)
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_ReLoginRecentUsedVehicle, tbPacket)
    end
end

function BattleFFAReLoginHelper:ReloginSendLastDiamondInfo(tbPlayer)
    BattleHumanDecorationSystem:SendLastDiamondIfExist(tbPlayer, tbPlayer:GetUEControllerUniqueId())
end

function BattleFFAReLoginHelper:ReLoginSendGameOver(bGameOver, tbPlayer)
    if bGameOver then
        NetworkManager:GetRPCNetworkProxy():SendToClient(tbPlayer:GetUEControllerUniqueId(), ProtoDC.d2c_BattleGameOver, {})
    end
end

return BattleFFAReLoginHelper