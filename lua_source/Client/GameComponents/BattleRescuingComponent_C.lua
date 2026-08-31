-----------------------------------------------------
--File Name    : BattleRescuingComponent_C.lua
--Author       : Song Fuhao
--Create Time  : 2019-12-09
--Description  : 用于处理救援的客户端逻辑
-----------------------------------------------------
local luaclass = require("luaclass")
local BattleRescuingComponent = require("BattleRescuingComponent")
local BattleRescuingComponent_C = luaclass("BattleRescuingComponent_C", BattleRescuingComponent)

local Timer                 = require("Timer")
local ClientEventDef        = require("ClientEventDef")
local EventManager          = require("EventManager")
local Proto                 = require("DungeonCommonProtoNames")
local NetworkManager        = dynamic_require("NetworkManager")
local GameObjectSystem      = dynamic_require("GameObjectSystem")

local REFRESH_TIMER_INTERVAL = 0.5

BattleRescuingComponent_C.bExistValidRescuingTarget = false
BattleRescuingComponent_C.RefreshTimerHandle = nil
BattleRescuingComponent_C.tbTeammateInstanceIds = nil

-- 获得一个有效的重伤队友
local function GetValidRescuingTarget(self)
    for _, nInstanceId in pairs(self.tbTeammateInstanceIds) do
        local tbCharacter = GameObjectSystem:FindByInstanceId(nInstanceId)
        if tbCharacter and self:IsValidRescuingTarget(tbCharacter, true) then
            return tbCharacter
        end
    end
    return nil
end

-- 刷新是否有有效的重伤队友信息
local function RefreshValidDyingTeammate(self)
    local bExistValidRescuingTarget = GetValidRescuingTarget(self) ~= nil
    if self.bExistValidRescuingTarget ~= bExistValidRescuingTarget then
        self.bExistValidRescuingTarget = bExistValidRescuingTarget
        if bExistValidRescuingTarget then
            EventManager:OnFireEvent(ClientEventDef.EV_ON_ENTER_RESCUING_TRIGGER)
        else
            EventManager:OnFireEvent(ClientEventDef.EV_ON_EXIT_RESCUING_TRIGGER)
        end
    end
end

local function EnterRescuingTrigger(self, tbTeammateInstanceIds)
    self.tbTeammateInstanceIds = tbTeammateInstanceIds
    RefreshValidDyingTeammate(self)

    if not self.RefreshTimerHandle then
        self.RefreshTimerHandle = Timer.NewTimerMethod(self, RefreshValidDyingTeammate, REFRESH_TIMER_INTERVAL, true)
    end
end

local function ExitRescuingTrigger(self)
    if self.RefreshTimerHandle then
        self.RefreshTimerHandle:Clear()
        self.RefreshTimerHandle = nil
    end

    self.tbTeammateInstanceIds = {}
    RefreshValidDyingTeammate(self)
end

function BattleRescuingComponent_C:OnActorCreated(...)
    BattleRescuingComponent_C.super.OnActorCreated(self, ...)
    self:OnRescuingInfoChanged(self.rRescuingInfo, self.rRescuingInfo:Get())
end

function BattleRescuingComponent_C:OnDestroy(...)
    if self.RefreshTimerHandle then
        self.RefreshTimerHandle:Clear()
        self.RefreshTimerHandle = nil
    end

    BattleRescuingComponent_C.super.OnDestroy(self, ...)
end

-- 请求救援队友（会自动挑选一个附近的有效队友）
function BattleRescuingComponent_C:RequestRescueTeammate()
    local tbTeammate = GetValidRescuingTarget(self)
    if tbTeammate then
        local c2d_RequestRescueTeammate = {}
        c2d_RequestRescueTeammate.character_instance_id = tbTeammate:GetServerInstanceId()
        NetworkManager:GetRPCNetworkProxy():SendToServer(Proto.c2d_RequestRescueTeammate, c2d_RequestRescueTeammate)
    end
end

function BattleRescuingComponent_C:OnRescuingInfoChanged(_Property, tbRescuingInfo)
    local tbCharacterInstanceIds = tbRescuingInfo and tbRescuingInfo.character_instance_ids
    if tbCharacterInstanceIds and (#tbCharacterInstanceIds > 0) then
        EnterRescuingTrigger(self, tbCharacterInstanceIds)
    else
        ExitRescuingTrigger(self)
    end
end

function BattleRescuingComponent_C:IsExistValidRescuingTarget()
    return self.bExistValidRescuingTarget
end

return BattleRescuingComponent_C
