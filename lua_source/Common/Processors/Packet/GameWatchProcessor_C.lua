
local luaclass                    = require("luaclass")
local GameWatchProcessor    = require("GameWatchProcessor")
local GameWatchProcessor_C  = luaclass("GameWatchProcessor_C",GameWatchProcessor)

local Proto                 = require("DungeonCommonProtoNames")
local EventManager          = require("EventManager")
local ClientEventDef        = require("ClientEventDef")
local CommonEventDef        = require("CommonEventDef")
-----------------------------------------------------


local function NotifyWatchTeamBattle(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_CHANGE_WATCH_MATE, tbPacket.watch_mate_id, tbPacket.watch_vehicle_id, tbPacket.offsetYaw, tbPacket.info, tbPacket.watch_team_id, tbPacket.is_success)
end

local function NotifyStopWatchTeamBattle(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_STOP_WATCH_MATE)
end

local function NotifyViewerChangeAimState(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_MATE_CHANGE_AIM_STATE, tbPacket.is_ship_aim, tbPacket.is_in_aim, true)
end

local function NotifyViewerCarronadeCameraActiveChanged(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_MATE_CARRONADE_ACTIVE_CHANGE, tbPacket.active)
end

local function NotifyViewerMovementState(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_MATE_MOVEMENT_STATE, tbPacket.last_state, tbPacket.current_state, true)
end

local function NotifyViewersWeaponBullet(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_MATE_BULLET_CHANGED, tbPacket)
end

local function NotifyViewerIsMovingNow(self, tbPacket, nSenderUniqueId)
    -- EventManager:OnFireEvent(CommonEventDef.EV_MATE_IS_MOVING_CHANGED, tbPacket.is_moving)
end

local function NotifyViewerMovementMode(self, tbPacket, nSenderUniqueId)
   -- EventManager:OnFireEvent(CommonEventDef.EV_MATE_MOVE_MODE_CHANGED, tbPacket.pre_move_mode, tbPacket.move_mode)
end

local function NotifyWatchMateKillInfo(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_MATE_KILL_INFO_CHANGED, tbPacket)
end

local function NotifyViewersGetInVehicle(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(CommonEventDef.EV_WATCH_MATE_ON_VEHICLE, tbPacket.vehicle_id, tbPacket.is_enter)
end

local function NotifyShowWatchMateTips(self, tbPacket, nSenderUniqueId)
    EventManager:OnFireEvent(ClientEventDef.EV_SHOW_WATCH_MATE_TIPS, tbPacket)
end

function GameWatchProcessor_C:RegisterPackets()
    self:BindMethod(Proto.d2c_NotifyWatchTeamMate, self, NotifyWatchTeamBattle)
    self:BindMethod(Proto.d2c_NotifyStopWatchTeammateBattle, self, NotifyStopWatchTeamBattle)
    self:BindMethod(Proto.d2c_NotifyViewerChangeAimState, self, NotifyViewerChangeAimState)
    self:BindMethod(Proto.d2c_NotifyViewerCarronadeCameraActiveChanged, self, NotifyViewerCarronadeCameraActiveChanged)
    self:BindMethod(Proto.d2c_NotifyViewerMovementState, self, NotifyViewerMovementState)
    self:BindMethod(Proto.d2c_NotifyViewersWeaponBullet, self, NotifyViewersWeaponBullet)
    self:BindMethod(Proto.d2c_NotifyViewerIsMovingNow, self, NotifyViewerIsMovingNow)
    self:BindMethod(Proto.d2c_NotifyViewerMovementMode, self, NotifyViewerMovementMode)
    self:BindMethod(Proto.d2c_NotifyWatchMateKillInfo, self, NotifyWatchMateKillInfo)
    self:BindMethod(Proto.d2c_NotifyViewersGetInVehicle, self, NotifyViewersGetInVehicle)
    self:BindMethod(Proto.d2c_FFAWatchMateTips, self, NotifyShowWatchMateTips)
end

return GameWatchProcessor_C