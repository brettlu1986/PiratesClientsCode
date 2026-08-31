local luaclass = require("luaclass")
local LogEventOpBase = dynamic_require("LogEventOpBase")
local FFAHumanStateLogEventOp = luaclass("FFAHumanStateLogEventOp", LogEventOpBase)
local CommonEventDef = require("CommonEventDef")
-- local HumanMovementStateType = require("HumanMovementStateType")
local Analytics = require("DungeonAnalyticsProtoNames")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GameObjectTypeDef = require("GameObjectTypeDef")
local BotAISystem = dynamic_require("BotAISystem")

-- local SwimmingStateType = Analytics.Swimming_SwimmingStateType
-- local VehicleUseType = Analytics.VehicleUse_VehicleType
local VehicleType = Analytics.Vehicle_VehicleType
local AIHelper = require("AIHelper")
local HumanVehicleStateDef = require("HumanVehicleStateDef")
-- local DamageTypeEx = require("DamageTypeEx")
--

-- {playerid = info}
FFAHumanStateLogEventOp.tbPlayerUseVehicleInfo =  nil
FFAHumanStateLogEventOp.tbPlayerSwimminfo = nil
FFAHumanStateLogEventOp.nRealPlayerCount = 0
FFAHumanStateLogEventOp.tbDeepWaterInfo = nil

local function LOG(...)
    log("[FFAHumanStateLogEventOp]", ...)
end

--  local function LogPlayerSwimmingEvent(self, nPlayerId, nSwimmingType)
--     local tbPacket = {}
--     tbPacket.common_infos = self:GetBattleCommonPropertys()
--     tbPacket.player_id = nPlayerId
--     tbPacket.swimming_state = nSwimmingType
--     if nSwimmingType == SwimmingStateType.START then
--         self.tbPlayerSwimminfo[nPlayerId] = KismetSystemLibrary.GetGameTimeInSeconds(GWorld)
--         tbPacket.swimming_time = 0
--     else
--         local nStartTime = self.tbPlayerSwimminfo[nPlayerId]
--         local nTime = 0
--         if nStartTime ~= nil then
--             nTime = math.floor(KismetSystemLibrary.GetGameTimeInSeconds(GWorld) - nStartTime)
--         end
--         tbPacket.swimming_time = nTime
--         self.tbPlayerSwimminfo[nPlayerId] = nil
--     end
--     LOG("LogPlayerSwimmingEvent", t2s(tbPacket))
--     self:LogEvent(Analytics.Swimming, tbPacket)
--  end

--  local function LogPlayerVehicleEvent(self)
--     local VehicleUse = {}
--     VehicleUse.common_infos = self:GetBattleCommonPropertys()
--     local nCount = 0

--     for k, v in pairs(self.tbPlayerUseVehicleInfo) do
--         VehicleUse.player_id = k
--         VehicleUse.vehicle_type = VehicleUseType.HORSE
--         VehicleUse.item_template_id = v.nTemplatedId
--         VehicleUse.use_vehicle_time =  math.floor(v.nTime)
--         VehicleUse.use_vehicle_distance = math.floor(v.nDistance / 100)
--         self:LogEvent(Analytics.VehicleUse, VehicleUse)
--         LOG("VehicleUse", t2s(VehicleUse))
--         nCount = nCount + 1
--     end

--     local VehicleUseCount = {}
--     VehicleUseCount.common_infos = self:GetBattleCommonPropertys()
--     VehicleUseCount.use_vehicle_player_count = nCount
--     VehicleUseCount.unuse_vehicle_player_count = self.nRealPlayerCount - nCount
--     LOG("VehicleUseCount", t2s(VehicleUseCount))
--     self:LogEvent(Analytics.VehicleUseCount, VehicleUseCount)
--  end

 local function VehicleStart(self, nPlayerId, nVehicleInstanceId)
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if not tbVehicle then
        return
    end
    local tbParam = self.tbPlayerUseVehicleInfo[nPlayerId]
    if not tbParam then
        tbParam = {}
        tbParam.nTime = 0
        tbParam.nDistance = 0
        tbParam.nVehicleId = nVehicleInstanceId
        tbParam.nTemplatedId = tbVehicle:GetTemplateId()
        self.tbPlayerUseVehicleInfo[nPlayerId] = tbParam
    end
    tbParam.nStartTime = KismetSystemLibrary.GetGameTimeInSeconds(GWorld)
    LOG("VehicleStart", t2s(self.tbPlayerUseVehicleInfo))
 end

 local function VehicleEnd(self, nPlayerId, nVehicleInstanceId)
    local tbVehicle = GameObjectSystem:FindByInstanceId(nVehicleInstanceId)
    if not tbVehicle then
        return
    end
    local tbParam = self.tbPlayerUseVehicleInfo[nPlayerId]
    if not tbParam then
        return
    end
    -- tbParam.nStartTime = KismetSystemLibrary.GetGameTimeInSeconds(GWorld)
    local nRideTime = 0
    local nDistance = math.floor(tbVehicle.pUEActor.CharacterMovement:GetTotalDistance())
    tbVehicle.pUEActor.CharacterMovement:ClearTotalDistance()
    if tbParam.nStartTime > 0 then
        nRideTime = math.floor(KismetSystemLibrary.GetGameTimeInSeconds(GWorld) - tbParam.nStartTime)
        tbParam.nDistance = tbParam.nDistance + nDistance
        tbParam.nStartTime = 0
    end
    tbParam.nTime = tbParam.nTime + nRideTime
    LOG("VehicleEnd", t2s(self.tbPlayerUseVehicleInfo))

    local Vehicle = {}
    self:SavePlayerCommonPropertysToPacket(nPlayerId, Vehicle)
    Vehicle.template_id = tbVehicle:GetTemplateId()
    Vehicle.type = VehicleType.HORSE
    Vehicle.distance = nDistance
    Vehicle.ride_time = nRideTime
    LOG("Analytics.Vehicle", t2s(Vehicle))
    self:LogEvent(Analytics.Vehicle, Vehicle)
 end

 local function OnVehicleStateChanged(self, GamePlayer, nVehicleState, nVehicleInstanceId)
    if AIHelper.IsAIControlled(GamePlayer) then
        return
    end
    local PlayerId = GamePlayer.nPlayerId
    if nVehicleState == HumanVehicleStateDef.AttachToVehicle then
        VehicleStart(self, PlayerId, nVehicleInstanceId)
    end

    if nVehicleState == HumanVehicleStateDef.None then
        VehicleEnd(self, PlayerId, nVehicleInstanceId)
    end
 end

 local function OnGridTypeChanged(self, tbGameObject, nRegionType)
    if not tbGameObject:IsHuman() then
        return
    end

    if AIHelper.IsAIControlled(tbGameObject) then
        return
    end

    local bOcean = false
    if nRegionType == EPiratesGridRegionType.Ocean then
        bOcean= true
    end

    local nPlayerId = tbGameObject.nPlayerId
    local tbParam = self.tbDeepWaterInfo[nPlayerId]
    if not tbParam then
        if not bOcean then
            return
        end
        tbParam = {}
        tbParam.nTime = 0
        tbParam.nStartTime = KismetSystemLibrary.GetGameTimeInSeconds(GWorld)
        self.tbDeepWaterInfo[nPlayerId] = tbParam
    end
    if bOcean then
        tbParam.nStartTime = KismetSystemLibrary.GetGameTimeInSeconds(GWorld)
    else
        if tbParam.nStartTime > 0 then
            tbParam.nTime = tbParam.nTime + (KismetSystemLibrary.GetGameTimeInSeconds(GWorld) - tbParam.nStartTime)
            tbParam.nStartTime = 0
        end
    end
    LOG("OnGridTypeChanged", t2s(self.tbDeepWaterInfo))
 end

-- local function LogDrownInfotEvent(self, nPlayerId, tbParam)
--     local PlayerDrownInfo = {}
--     PlayerDrownInfo.common_infos = self:GetBattleCommonPropertys()

--     PlayerDrownInfo.player_id = nPlayerId

--     if tbParam.nStartTime > 0 then
--         tbParam.nTime = tbParam.nTime + (KismetSystemLibrary.GetGameTimeInSeconds(GWorld) - tbParam.nStartTime)
--         tbParam.nStartTime = 0
--     end

--     PlayerDrownInfo.deep_swimming_time = math.floor(tbParam.nTime)

--     self:LogEvent(Analytics.PlayerDrownInfo, PlayerDrownInfo)
--     LOG("PlayerDrownInfo", t2s(PlayerDrownInfo))
-- end

-- local function OnCharacterDead(self, GamePlayer, LastDamageCauser, nLastDamageType)
--     if nLastDamageType ~= DamageTypeEx.DROWN or not GamePlayer:IsHuman() then
--         return
--     end
--     if AIHelper.IsAIControlled(GamePlayer) then
--         return
--     end
--     local nPlayerId = GamePlayer.nPlayerId
--     local tbParam = self.tbDeepWaterInfo[nPlayerId]
--     if not tbParam then
--         return
--     end
    -- LogPlayerSwimmingEvent(self, nPlayerId, SwimmingStateType.END)
    -- LogDrownInfotEvent(self, nPlayerId, tbParam)
-- end

-- local function OnHumanMovementStateChanged(self, GamePlayer, nLastMovementState, nNewMovementState)
--     if AIHelper.IsAIControlled(GamePlayer) then
--         return
--     end
    -- local PlayerId = GamePlayer.nPlayerId
    -- if nNewMovementState == HumanMovementStateType.Swimming then
        -- LogPlayerSwimmingEvent(self, PlayerId, SwimmingStateType.START)
    -- end

    -- if nLastMovementState == HumanMovementStateType.Swimming and nNewMovementState ~= HumanMovementStateType.Swimming then
        -- LogPlayerSwimmingEvent(self, PlayerId, SwimmingStateType.END)
    -- end
-- end

local function LogPlayerLoginEvent(self, tbPlayer)
    if tbPlayer.ObjectType == GameObjectTypeDef.PlayerSelf and
       not BotAISystem:IsBot(tbPlayer) then
        self.nRealPlayerCount = self.nRealPlayerCount + 1
    end
end

--游戏开始时(选点界面弹出)触发
function FFAHumanStateLogEventOp:OnBattleBegin()
    FFAHumanStateLogEventOp.super.OnBattleBegin(self)
    local EventHelper = self.EventHelper
    -- EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnHumanMovementStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GAME_MODE_ON_PLAYER_LOGIN, self, LogPlayerLoginEvent)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_VEHICLE_STATE_CHANGE, self, OnVehicleStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_GRID_TYPE_CHANGED, self,  OnGridTypeChanged)
    -- EventHelper:RegisterEvent(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_DEAD, self,  OnCharacterDead)
end

--游戏结束时(有队伍吃鸡或者副本回收)触发
function FFAHumanStateLogEventOp:OnBattleEnd()
    --add code here.
    -- LogPlayerVehicleEvent(self)
    -- self.EventHelper:UnregisterAll()
    FFAHumanStateLogEventOp.super.OnBattleEnd(self)
end

function FFAHumanStateLogEventOp:Init()
    FFAHumanStateLogEventOp.super.Init(self)
    self.tbPlayerUseVehicleInfo = {}
    self.tbPlayerSwimminfo = {}
    self.tbDeepWaterInfo = {}
      --add code here.

    -- self:OnBattleBegin()
end

function FFAHumanStateLogEventOp:Uninit()
    FFAHumanStateLogEventOp.super.Uninit(self)
    -- self:OnBattleEnd()
    self.tbPlayerUseVehicleInfo = nil
    self.tbPlayerSwimminfo = nil
end

return FFAHumanStateLogEventOp