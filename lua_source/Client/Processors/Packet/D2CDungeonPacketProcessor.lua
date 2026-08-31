local luaclass = require "luaclass"
local NetMessageProcessorBase = require "NetMessageProcessorBase"
local D2CDungeonPacketProcessor = luaclass("D2CDungeonPacketProcessor", NetMessageProcessorBase)

local UIUtils = require("UIUtils")
local UITextDef = require("UITextDef")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local Proto = require("DungeonCommonProtoNames")
local NetworkManager = dynamic_require("NetworkManager")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local BattleInteractionSystem = dynamic_require("BattleInteractionSystem")
local BattleHumanDecorationSystem = dynamic_require("BattleHumanDecorationSystem")
local MiniMapSystem = require("MiniMapSystem")
local LogReportSystem = dynamic_require("LogReportSystem")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")

local function PlayMatinee(self, tbPacket, nSenderUniqueId)
    local nMatineeId = tbPacket.matinee_id
    local bClientOnly = tbPacket.client_only
    local bPause = tbPacket.pause
    log("recv play matinee ", nMatineeId)
    BattleInteractionSystem:OnPlayMatinee(nMatineeId, nil, nil, bClientOnly, bPause)
end

local function StopMatinee(self, tbPacket, nSenderUniqueId)
    BattleInteractionSystem:OnStopMatinee()
end

local function OnRecvJumpFromTransporter(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_JUMP_FROM_TRANSPORTER, nSenderUniqueId, false)
end

local function OnRecvParachuteOpen(self)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_PARACHUTE_OPEN)
end

local function ConsumeItemStart(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ConsumableItemComponentClient then
        tbPlayer.ConsumableItemComponentClient:ConsumeItemStart(tbPacket.code, tbPacket.instance_id, tbPacket.hp_percentage_cap)
    end
end

local function ConsumeItemInterrupt(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ConsumableItemComponentClient then
        tbPlayer.ConsumableItemComponentClient:ConsumeItemInterrupt(tbPacket.instance_id)
    end
end

local function ConsumeItemSuccess(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ConsumableItemComponentClient then
        tbPlayer.ConsumableItemComponentClient:ConsumeItemSuccess(tbPacket.instance_id)
    end
end

local function ConsumeItemEnd(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.ConsumableItemComponentClient then
        tbPlayer.ConsumableItemComponentClient:ConsumeItemEnd(tbPacket.instance_id)
    end
end

local function NotifyOnHitPlayer(self, tbPacket, nSenderUniqueId)
    local tbTaker = GameObjectSystem:FindByInstanceId(tbPacket.taker_id)
    local tbCauser = GameObjectSystem:FindByInstanceId(tbPacket.causer_id)
    local nDamage = tbPacket.damage
    local nDamageType = tbPacket.damage_type
    --把受伤前的血量也带下来， 用于表现头顶血量
    local nHp = tbPacket.hp
    --武器id带下来，用于计算伤害数字变色
    local nWeaponTemplateId = tbPacket.weapon_tempId
    --击中位置带下来，用于计算播放特效位置
    local nRegionType = tbPacket.region_type
    if tbTaker then
        tbTaker:GetCurrentPropertyComponent():ClientSyncDamageInfo(tbCauser, nDamageType)
    end
    --集中标记，用于显示伤害图标
    local nHurtTag = tbPacket.hurt_tag
    EventManager:OnFireEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, tbTaker, tbCauser, nDamage, nDamageType, nHp, nWeaponTemplateId, {nRegionType = nRegionType, nHurtTag = nHurtTag})
    -- if tbCauser:GetServerInstanceId() == GamePlayerSelfHelper:Get():GetServerInstanceId() then
    --     logdebug(string.format("[NotifyOnHitPlayer] tbTaker=%s, tbCauser=%s, nDamage=%f, nDamageType=%d, hurtTag=%d", tbTaker and tbTaker.szName, tbCauser and tbCauser.szName, nDamage, nDamageType, nHurtTag))
    -- end
    log(string.format("[NotifyOnHitPlayer] tbTaker=%s, tbCauser=%s, nDamage=%f, nDamageType=%d", tbTaker and tbTaker.szName, tbCauser and tbCauser.szName, nDamage, nDamageType, nHurtTag))
end

local function NotifyProgressBarStartFailed(self, tbPacket, nSenderUniqueId)
    UIUtils.ShowToast(UITextDef.FAILED_WITH_PLAYER_IN_DYING)
end


local function OnHumanExtraPackageCapacityValueSynced(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        BattleHumanDecorationSystem.ModifyHumanExtraPackageCapacityValue(tbPlayer, tbPacket.value)
    end
end

local function OnShipExtraPackageCapacityValueSynced(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        BattleHumanDecorationSystem.ModifyShipExtraPackageCapacityValue(tbPlayer, tbPacket.value)
    end
end

local function OnShipExtraMaterialCapacityRatioSynced(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        BattleHumanDecorationSystem.ModifyShipExtraMaterialCapacityRatio(tbPlayer, tbPacket.ratio)
    end
end

local function OnAirDropVisiblitySynced(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        BattleHumanDecorationSystem.ModifyAirDropVisibleOnMap(tbPlayer, tbPacket.is_visible)
    end
end

local function OnRecvServerNearbyDiamondInfo(self, tbPacket, nSenderUniqueId)
    log("Client receive Nearby diamond info.")
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer then
        MiniMapSystem:HandleServerNearbyDiamondInfo(tbPlayer, tbPacket.bFound, tbPacket.nX, tbPacket.nY, tbPacket.nZ)
    end
end


local function OnRequestVehicleFailed(self, tbPacket, nSenderUniqueId)
    local tbPlayer = GameObjectSystem:FindByUniqueId(nSenderUniqueId)
    if tbPlayer and tbPlayer.GameVehicleComponent then
        tbPlayer.GameVehicleComponent:OnRequestVehicleFailed(tbPlayer, tbPacket.failed_reason_id)
    end
end

local function OnReLoginRefreshBattleResultWnd(self,tbPacket,nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_FFA_RELOGIN_REFRESH_BATTLE_RESULT,tbPacket.bTeamDead)
end

local function OnBattleGameOver(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_DUNGEON_GAME_OVER)
end

local function OnRecvServerLog(self, tbPacket, nSenderUniqueId)
    LogReportSystem:RecvServerLog(tbPacket.timestamp, tbPacket.frame, tbPacket.category, tbPacket.level, tbPacket.message, tbPacket.traceback)
end

-- 注册处理包
function D2CDungeonPacketProcessor:RegisterPackets()
    local tbProxy = NetworkManager:GetRPCNetworkProxy()
    self:SetBinder(tbProxy)

    self:BindMethod(Proto.d2c_PlayMatinee, self, PlayMatinee)
    self:BindMethod(Proto.d2c_StopMatinee, self, StopMatinee)

    self:BindMethod(Proto.d2c_JumpFromTransporter, self, OnRecvJumpFromTransporter)
    self:BindMethod(Proto.d2c_ParachuteOpen, self, OnRecvParachuteOpen)

    self:BindMethod(Proto.d2c_ConsumeItemStart, self, ConsumeItemStart)
    self:BindMethod(Proto.d2c_ConsumeItemInterrupt, self, ConsumeItemInterrupt)
    self:BindMethod(Proto.d2c_ConsumeItemSuccess, self, ConsumeItemSuccess)
    self:BindMethod(Proto.d2c_ConsumeItemEnd, self, ConsumeItemEnd)

    self:BindMethod(Proto.d2c_NotifyOnHitPlayer, self, NotifyOnHitPlayer)
    self:BindMethod(Proto.d2c_NotifyProgressBarStartFailed, self, NotifyProgressBarStartFailed)

    self:BindMethod(Proto.d2c_SyncHumanExtraPackageCapacityValue, self, OnHumanExtraPackageCapacityValueSynced)
    self:BindMethod(Proto.d2c_SyncShipExtraPackageCapacityValue, self, OnShipExtraPackageCapacityValueSynced)
    self:BindMethod(Proto.d2c_SyncShipExtraMaterialCapacityRatio, self, OnShipExtraMaterialCapacityRatioSynced)
    self:BindMethod(Proto.d2c_SyncAirDropVisibility, self, OnAirDropVisiblitySynced)
    self:BindMethod(Proto.d2c_NearbyDiamond, self, OnRecvServerNearbyDiamondInfo)

    self:BindMethod(Proto.d2c_RequestVehicleFailed, self, OnRequestVehicleFailed)
    self:BindMethod(Proto.d2c_ReLoginRefreshBattleResultWnd, self, OnReLoginRefreshBattleResultWnd)
    self:BindMethod(Proto.d2c_BattleGameOver, self, OnBattleGameOver)
    self:BindMethod(Proto.d2c_MulticastServerLog, self, OnRecvServerLog)
end

-- 初始化
function D2CDungeonPacketProcessor:Init()
    D2CDungeonPacketProcessor.super.Init(self)
    self:RegisterPackets()
    return true
end

return D2CDungeonPacketProcessor
