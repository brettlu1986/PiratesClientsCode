-----------------------------------------------------
--File Name    : BattleRescuingComponent.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-08
--Description  : 用于处理玩家的救援逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local BattleRescuingComponent = luaclass("BattleRescuingComponent", GameComponentBase)

local PropName = require("PropName")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local GameplayUtilityHelper = require("GameplayUtilityHelper")

local EMPTY_RESCUING_INFO = {}

-- 用于管理自己进入救援范围的队友名单
BattleRescuingComponent.tbNearbyDyingTeammates = nil
BattleRescuingComponent.rRescuingInfo = nil

function BattleRescuingComponent:OnCreate(...)
    BattleRescuingComponent.super.OnCreate(self, ...)
    self.tbNearbyDyingTeammates = {}
end

function BattleRescuingComponent:OnDestroy(...)
    log("[BattleRescuingComponent] OnDestroy", self.Owner.szName)
    self.tbNearbyDyingTeammates = nil
    BattleRescuingComponent.super.OnDestroy(self, ...)
end

-- @ServerOnly
-- 仅供 BattleDyingComponent 调用
function BattleRescuingComponent:EnterTeammateRescuingTrigger(tbTeammate)
    if self.tbNearbyDyingTeammates then
        self.tbNearbyDyingTeammates[tbTeammate] = true
        self:RefreshRescuingState()
        EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_ENTER_RESCUINGTRIGGER, self.Owner, tbTeammate)
    else
        logerror("[BattleRescuingComponent] EnterTeammateRescuingTrigger failed, tbNearbyDyingTeammates is nil")
    end
end

-- @ServerOnly
-- 仅供 BattleDyingComponent 调用
function BattleRescuingComponent:ExitTeammateRescuingTrigger(tbTeammate)
    if self.tbNearbyDyingTeammates then
        self.tbNearbyDyingTeammates[tbTeammate] = nil
        self:RefreshRescuingState()
        EventManager:OnFireEvent(CommonEventDef.EV_PLAYER_LEAVE_RESCUINGTRIGGER, self.Owner, tbTeammate)
    else
        logerror("[BattleRescuingComponent] ExitTeammateRescuingTrigger failed, tbNearbyDyingTeammates is nil")
    end
end

local function GetOriginRescuingInfo(self)
    if self.Owner:IsAlive()
    and (not self.Owner:GetCurrentPropertyComponent():GetIsRescuing()) then
        local tbCharacterInstanceIds = {}
        for tbTeammate in pairs(self.tbNearbyDyingTeammates) do
            if self:IsValidRescuingTarget(tbTeammate, false) then
                table.insert(tbCharacterInstanceIds, tbTeammate:GetServerInstanceId())
            end
        end
        return {character_instance_ids = tbCharacterInstanceIds}
    else
        return EMPTY_RESCUING_INFO
    end
end

-- @ServerOnly
-- 刷新玩家可救援状态
function BattleRescuingComponent:RefreshRescuingState()
    if self.rRescuingInfo then
        self.rRescuingInfo:Set(GetOriginRescuingInfo(self))
    end
end

-- @Public
-- @ServerOnly
-- 救援队友
function BattleRescuingComponent:RescueTeammate(tbCharacter)
    if self.tbNearbyDyingTeammates[tbCharacter]
    and self.Owner:IsAlive()
    and (not self.Owner:GetCurrentPropertyComponent():GetIsRescuing())
    and self:IsValidRescuingTarget(tbCharacter, true) then
        tbCharacter.BattleDyingComponent:Rescue(self.Owner, true)
        return true
    end
    return false
end

-- @public
-- 是否为一个有效的被救援目标
function BattleRescuingComponent:IsValidRescuingTarget(tbCharacter, bCheckWorldStatic)
    -- 如果队友正在被救，无效
    if (tbCharacter.BattleDyingComponent and tbCharacter.BattleDyingComponent:IsBeingRescued())
    -- 如果需要检测碰撞，且中间有碰撞，无效
    or (bCheckWorldStatic and GameplayUtilityHelper.CheckWorldStaticBetweenTwoActors(self.Owner.pUEActor, tbCharacter.pUEActor, false, GWorld)) then
        return false
    end
    return true
end

function BattleRescuingComponent:OnActorCreated(...)
    BattleRescuingComponent.super.OnActorCreated(self, ...)
    self.rRescuingInfo = self.Owner.CustomReplicationComponent:BindMethod(PropName.rRescuingInfo, GetOriginRescuingInfo(self), self, self.OnRescuingInfoChanged, false)
end

function BattleRescuingComponent:OnActorDestroyed(...)
    self.rRescuingInfo = nil
    BattleRescuingComponent.super.OnActorDestroyed(self, ...)
end

function BattleRescuingComponent:OnRescuingInfoChanged(_Property, tbRescuingInfo)
    -- derived class must implement it
end

return BattleRescuingComponent