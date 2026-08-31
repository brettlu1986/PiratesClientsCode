local luaclass = require "luaclass"
local NetMessageProcessorBase = require "NetMessageProcessorBase"
local C2DDungeonPacketProcessor = luaclass("C2DDungeonPacketProcessor", NetMessageProcessorBase)

local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("DungeonCommonProtoNames")

local BattleGameModeSystem = dynamic_require("BattleGameModeSystem")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleCommandSystem = require("BattleCommandSystem")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")

local BattleResultSystem = dynamic_require("BattleResultSystem")
local DestructibleObjectInteractionalSystem = dynamic_require("DestructibleObjectInteractionalSystem")
local BattleHumanDecorationSystem = require("BattleHumanDecorationSystem")
local TimeCheaterCheck = dynamic_require("TimeCheaterCheck")
local SelectionPointHelper = require("SelectionPointHelper")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")

local function QuitDungeon(self, tbPacket, nSenderUniqueId)
    log("Receive QuitDungeon request.")
    local nQuitReason = tbPacket.reason
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbGameMode ~= nil and tbPlayer ~= nil then
        tbGameMode:QuitDungeon(tbPlayer, nQuitReason)
    else
        logwarning("QuitDungeon dungeon failed. GameMode:", tbGameMode, "; Player:", tbPlayer)
        return
    end
end

local function LeaveDungeon(self, tbPacket, nSenderUniqueId)
    log("Receive LeaveDungeon request.")
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbGameMode ~= nil and tbPlayer ~= nil then
        tbGameMode:LeaveDungeon(tbPlayer)
    else
        logwarning("LeaveDungeon dungeon failed. GameMode:", tbGameMode, "; Player:", tbPlayer)
        return
    end
end

local function EnableAutoBattle(self, tbPacket, nSenderUniqueId)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbGameMode ~= nil and tbPlayer ~= nil then
        if(tbPlayer.BattleAIComponent) then
            tbPlayer.BattleAIComponent:SetEnable(tbPacket.enable)
        end
    end
end

local function RetryGame(self, tbPacket, nSenderUniqueId)
    local tbGameMode = BattleGameModeSystem:GetGameMode()
    if(tbGameMode and tbGameMode.TryResetAllSteps) then
        tbGameMode:TryResetAllSteps(nSenderUniqueId)
    end
end

local function RequestStatisticsData(self, tbPacket, nSenderUniqueId)

end

local function SendTacticsCommand(self, tbPacket, nSenderUniqueId)
    BattleCommandSystem:RequestSendCommand(nSenderUniqueId, tbPacket)
end

local function JumpFromTransporter(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_JUMP_FROM_TRANSPORTER, nSenderUniqueId, true)
end

local function ParachuteOpen(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTE_OPEN, nSenderUniqueId)
end

local function ChangeMovementState(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.HumanMovementStateComponent then
        tbPlayer.HumanMovementStateComponent:RequestChangeMovement(tbPacket.movement_state)
    end
end

local function ChangeShipAvatarRes(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ShipAvatarComponent then
        tbPlayer.ShipAvatarComponent:SetAvatarResData(tbPacket.avatar_res)
    end
end

local function ConsumeItemRequest(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ConsumableItemComponentServer then
        tbPlayer.ConsumableItemComponentServer:ConsumeItemRequest(tbPacket.instance_id)
    end
end

local function ConsumeItemInterrupt(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ConsumableItemComponentServer then
        tbPlayer.ConsumableItemComponentServer:ConsumeItemInterrupt()
    end
end

local function AbortProgressBar(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ProgressBarComponent then
        tbPlayer.ProgressBarComponent:Abort(tbPacket.abort_type)
    end
end

local function StartProgressBar(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ProgressBarComponent then
        tbPlayer.ProgressBarComponent:Start(tbPacket.template_id)
    end
end

local function ChangeContinuousRun(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.HumanMovementStateComponent then
        tbPlayer.HumanMovementStateComponent:SetRun(tbPacket.is_continuous_run)
    end
end

local function ChangeShipPosture(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ShipAvatarComponent then
        tbPlayer.ShipAvatarComponent:SetShipPosture(tbPacket.posture)
    end
end

local function RequestRescueTeammate(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        local tbCharacter = GameObjectSystem:FindByInstanceId(tbPacket.character_instance_id)
        if tbCharacter then
            tbPlayer.BattleRescuingComponent:RescueTeammate(tbCharacter)
        end
    end
end

local function FFASelectionPoint(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_SELECTION_POINT, tbPacket, true)
end

local function FFACancelSelectionPoint(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        EventManager:OnFireEvent(CommonEventDef.EV_FFA_SELECTION_POINT, {nInstanceId = tbPlayer:GetServerInstanceId()}, false)
    end
end

local function OnRootMotionJump(self, tbPacket, nSenderUniqueId)
    if not GlobalVariableSystem.bUseNewSpeel then
        local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        if tbPlayer and tbPlayer.HumanMovementStateComponent then
            tbPlayer.HumanMovementStateComponent:RequestSpeel(tbPacket.jump_type, tbPacket.destructible_id, tbPacket.wall_position, tbPacket.yaw)
        end
    end
end

local function OnRootMotionJumpNew(self, tbPacket, nSenderUniqueId)
    if GlobalVariableSystem.bUseNewSpeel then
        local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
        if tbPlayer and tbPlayer.HumanMovementStateComponent then
            tbPlayer.HumanMovementStateComponent:RequestSpeelNew(tbPacket.jump_type, tbPacket.destructible_id, tbPacket.speel_position, tbPacket.target_position, tbPacket.expect_start_position, tbPacket.yaw)
        end
    end
end

local function FFAMapSign(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_MAP_SIGN, tbPacket)
end


local function SetEnableHumanMove(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.HumanMovementStateComponent then
        tbPlayer.HumanMovementStateComponent:SetEnableMove(tbPacket.enable)
    end
end

local function ChangeSwimmingType(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.HumanMovementStateComponent then
        tbPlayer.HumanMovementStateComponent:ChangeSwimmingType(tbPacket.region_type)
    end
end


local function SetEnterFreeView(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer:IsHuman() and tbPlayer.pUEActor then
        local pUEActor = tbPlayer.pUEActor
        local Dir = pUEActor:GetBaseAimRotation()
        if pUEActor and pUEActor.PlayerProperty then
            pUEActor.PlayerProperty:EnableFreeView(tbPacket.IsEnter, Dir)
        end
    end
end

local function TestNet(self, tbPacket, nSenderUniqueId)
    NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, Proto.d2c_TestNet)
end

local function RequestVehicleState(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    local tbVehicle = GameObjectSystem:FindByInstanceId(tbPacket.vehicle_id)
    if tbPlayer and tbPlayer:IsHuman() and tbPlayer:IsAlive() and tbVehicle then
        -- tbVehicle:GetInVehicle(tbPlayer, tbPacket.in_vehicle)
        tbPlayer.GameVehicleComponent:RequestVehicleState(tbPacket.vehicle_state, tbPacket.vehicle_id, tbPacket.end_pos, tbPacket.vehicle_trigger_type)
    end
end

local function SearchPropDataForGM(self, tbPacket, nSenderUniqueId)
    -- 为了便于热更新，随用随加载，仅Debug使用
    local PropValueGMHelper = require("PropValueGMHelper")
    local tbCharacter = GameObjectSystem:FindByInstanceId(tbPacket.character_instance_id)
    local tbSearcher = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    PropValueGMHelper.Search(tbPacket.key, tbCharacter, tbSearcher)
end

local function AdditionalSuccessChoice(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        EventManager:OnFireEvent(CommonEventDef.EV_ADDITIONALSUCCESS_CHOICE, tbPlayer, tbPacket)
    end
end

local function TeleportToSafeLocation(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        local ProgressBarComponent = tbPlayer.ProgressBarComponent
        if ProgressBarComponent then
            local OnSuccessed = function()                
                if tbPlayer:IsHuman() then
                    if tbPlayer.BattleHumanMovementComponent then
                        tbPlayer.BattleHumanMovementComponent:TeleportToSafeLocation()
                    end
                else
                    if tbPlayer.pUEActor and tbPlayer.pUEActor.ShipMovementComponent then
                        tbPlayer.pUEActor.ShipMovementComponent:TeleportToSafeLocation()
                    end                    
                end                    
            end

            local bBlocked = EngineExtActorShell.IsCanSafeTeleport(GWorld, tbPlayer.pUEActor)
            if bBlocked then
                local TeleportProgressBarId = 26
                local nDefaultTime = ProgressBarComponent:GetTime(TeleportProgressBarId)
                ProgressBarComponent:Start(TeleportProgressBarId, nil, OnSuccessed, nil, nDefaultTime)
            else
                local D2CHelper = require("D2CHelper")
                D2CHelper:SendCommonToast(tbPlayer, "TELEPORT_SAFE_LOCATION_ERROR")
            end            
        end
    end
end

local function RequestDeathPlayback(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        local tbData = BattleResultSystem:CreateDeathPlaybackStaticsData(tbPlayer)
        NetworkManager:GetRPCNetworkProxy():SendToClient(nSenderUniqueId, Proto.d2c_FFADeathPlayback, tbData)        
    else
        logerror("RequestDeathPlayback failed not find player", nSenderUniqueId)
    end
end

local function SetHideOtherSelectionPoint(self, tbPacket)
    SelectionPointHelper:SetHideOtherSelectionPoint(tbPacket.hide)
    -- NetworkManager:GetRPCNetworkProxy():Multicast(Proto.d2c_HideOtherSelectionPoint, {hide = tbPacket.hide})
end

local function SwitchDoor(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        log("Request SwitchDoor :", tbPlayer.nSenderUniqueId)
        DestructibleObjectInteractionalSystem:OnRecvSwitchDoor(tbPacket, tbPlayer:GetServerInstanceId())
    else
        logerror("Request SwitchDoor failed not find player", nSenderUniqueId)
    end
end

local function RequestCheckCheater(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        TimeCheaterCheck:HandleCheaterCheckRequest(tbPlayer, tbPacket.check_interval)
    end
end

local function OnRequestNearbyDiamond(self, tbPacket, nSenderUniqueId)
    log("Receive RequestNearbyDiamond request.")
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        BattleHumanDecorationSystem:HandleNearbyDiamondRequest(tbPlayer, nSenderUniqueId)
    end
end

-- 注册处理包
function C2DDungeonPacketProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)
    self:BindMethod(Proto.c2d_QuitDungeon, self, QuitDungeon)
    self:BindMethod(Proto.c2d_LeaveDungeon, self, LeaveDungeon)
    self:BindMethod(Proto.c2d_AutoBattle, self, EnableAutoBattle)
    self:BindMethod(Proto.c2d_RetryGame, self, RetryGame)
    self:BindMethod(Proto.c2d_RequestStatisticsData, self, RequestStatisticsData)
    self:BindMethod(Proto.c2d_SendTacticsCommand, self, SendTacticsCommand)
    self:BindMethod(Proto.c2d_JumpFromTransporter, self, JumpFromTransporter)
    self:BindMethod(Proto.c2d_ParachuteOpen, self, ParachuteOpen)
    self:BindMethod(Proto.c2d_ChangeMovementState, self, ChangeMovementState)
    self:BindMethod(Proto.c2d_ShipAvatarResUpdate, self, ChangeShipAvatarRes)
    self:BindMethod(Proto.c2d_ConsumeItemRequest, self, ConsumeItemRequest)
    self:BindMethod(Proto.c2d_ConsumeItemInterrupt, self, ConsumeItemInterrupt)
    self:BindMethod(Proto.c2d_StartProgressBar, self, StartProgressBar)
    self:BindMethod(Proto.c2d_AbortProgressBar, self, AbortProgressBar)
    self:BindMethod(Proto.c2d_ChangeContinuousRun, self, ChangeContinuousRun)
    self:BindMethod(Proto.c2d_ChangeShipPosture, self, ChangeShipPosture)
    self:BindMethod(Proto.c2d_RequestRescueTeammate, self, RequestRescueTeammate)
    self:BindMethod(Proto.c2d_FFASelectionPoint, self, FFASelectionPoint)
    self:BindMethod(Proto.c2d_FFACancelSelectionPoint, self, FFACancelSelectionPoint)
    self:BindMethod(Proto.c2d_RootMotionJump, self, OnRootMotionJump)
    self:BindMethod(Proto.c2d_RootMotionJumpNew, self, OnRootMotionJumpNew)
    self:BindMethod(Proto.c2d_FFAMapSign, self, FFAMapSign)
    self:BindMethod(Proto.c2d_EnableHumanMove, self, SetEnableHumanMove )
    self:BindMethod(Proto.c2d_ChangeSwimmingType, self, ChangeSwimmingType )
    self:BindMethod(Proto.c2d_EnterFreeView, self, SetEnterFreeView)
    self:BindMethod(Proto.c2d_TestNet, self, TestNet)
    self:BindMethod(Proto.c2d_RequestVehicleState, self, RequestVehicleState)
    self:BindMethod(Proto.c2d_SearchPropDataForGM, self, SearchPropDataForGM)
    self:BindMethod(Proto.c2d_AdditionalSuccessChoice, self, AdditionalSuccessChoice)
    self:BindMethod(Proto.c2d_TeleportToSafeLocation, self, TeleportToSafeLocation)
    self:BindMethod(Proto.c2d_FFADeathPlayback, self, RequestDeathPlayback)
    self:BindMethod(Proto.c2d_HideOtherSelectionPoint, self, SetHideOtherSelectionPoint)
    self:BindMethod(Proto.c2d_SwitchDoor, self, SwitchDoor)
    self:BindMethod(Proto.c2d_RequestCheckCheater, self, RequestCheckCheater)
    self:BindMethod(Proto.c2d_RequestNearbyDiamond, self, OnRequestNearbyDiamond)
end

-- 初始化
function C2DDungeonPacketProcessor:Init()
    C2DDungeonPacketProcessor.super.Init(self)

    self:RegisterPackets()
    return true
end

return C2DDungeonPacketProcessor
