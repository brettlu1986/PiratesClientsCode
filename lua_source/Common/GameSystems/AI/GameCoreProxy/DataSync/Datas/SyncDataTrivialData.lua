local luaclass = require("luaclass")
local SyncDataBase = require("SyncDataBase")
local SyncDataTrivialData = luaclass("SyncDataTrivialData", SyncDataBase)
local CommonEventDef = require("CommonEventDef")
-- local GlobalVariableSystem          = dynamic_require("GlobalVariableSystem")
local ShipUtilityExHelper           = require("ShipUtilityExHelper")
local DungeonIni                    = require("DungeonIni")
local AgentStatisticsDef            = require("AgentStatisticsDef")
local GameCoreVariable              = require("GameCoreVariable")
local BattleShipWeaponSystem        = dynamic_require("BattleShipWeaponSystem")

local MOUNTAIN_CHECK_DISTANCE_INTERVER = math.floor(DungeonIni.tbUIConfig.nMountainCheckInterval / GameCoreVariable.nDefaultTickInterval)
local MOUNTAIN_CHECK_DISTANCE = DungeonIni.tbUIConfig.nMountainCheckDistance
local EFallingState = EMovementMode.MOVE_Falling

SyncDataTrivialData.bRescuable = false
SyncDataTrivialData.nLastDistanceWithMountain = MOUNTAIN_CHECK_DISTANCE -- 上次检测的山脉距离
SyncDataTrivialData.nLastDistanceCalcutateTime = 0 -- 上次检测山脉距离的时间
SyncDataTrivialData.bInChargedAttackTime = false
SyncDataTrivialData.pCharacterMovement = nil

function SyncDataTrivialData:OnEnterRescue(tbOwnerCharacter, tbTeammate)
    if self.tbOwner == tbOwnerCharacter then
        self.bRescuable = true
    end
end

function SyncDataTrivialData:OnLeaveRescue(tbOwnerCharacter, tbTeammate)
    if self.tbOwner == tbOwnerCharacter then
        self.bRescuable = false
    end
end


function SyncDataTrivialData:BindEvent(SelfEventHelper)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_PLAYER_ENTER_RESCUINGTRIGGER,   self, self.OnEnterRescue)
    SelfEventHelper:RegisterEvent(CommonEventDef.EV_PLAYER_LEAVE_RESCUINGTRIGGER,   self, self.OnLeaveRescue)
end

function SyncDataTrivialData:UnbindEvent(SelfEventHelper)
    SelfEventHelper:UnregisterAll()
end

function SyncDataTrivialData:GetDistanceWithMountain()
    local tbOwner = self.tbOwner
    if tbOwner:IsShip() then
        self.nLastDistanceCalcutateTime = self.nLastDistanceCalcutateTime + 1
        if self.nLastDistanceCalcutateTime >= MOUNTAIN_CHECK_DISTANCE_INTERVER then
            self.nLastDistanceCalcutateTime = 0
            self.nLastDistanceWithMountain = ShipUtilityExHelper.GetDistanceWithMountain(tbOwner.pUEActor, MOUNTAIN_CHECK_DISTANCE, false, GWorld)
        end
        return self.nLastDistanceWithMountain
    else
        return 0
    end
end


local function IsJumping(self)
    if not self.pCharacterMovement then
        return false
    end
    local CurrentMovementMode = self.pCharacterMovement.MovementMode
    if CurrentMovementMode == EFallingState then
        return true
    end
    return false
end

local function IsShipFiring(tbPlayer)
    if not tbPlayer:IsShip() then
        return false
    end
    local ShipWeaponItem = BattleShipWeaponSystem:GetActiveWeaponItem(tbPlayer)
    if ShipWeaponItem then
        return ShipWeaponItem:IsInFiring()
    end
    return false
end

local function IsAiming(tbPlayer)
    if tbPlayer:IsShip() then
        return BattleShipWeaponSystem:GetIsInAim(tbPlayer)
    else
        local HumanWeaponComponent = tbPlayer.HumanWeaponComponent
        if not HumanWeaponComponent then
            logerror("Cannot find bot HumanWeaponComponent", tbPlayer:GetServerInstanceId())
            return false
        end
        return HumanWeaponComponent:IsAiming()
    end
end

local ServerProtoNames      = require("GameCoreServerProtoNames")
local tbIgnoredPacketInChargedTime = {
    ServerProtoNames.s2c_fire,
    ServerProtoNames.s2c_switchWeapon,
}

function SyncDataTrivialData:OnSync(tbPack)
    local tbOwner = self.tbOwner
    local tbAgent= self.tbAgent
    local tbAgentStatistics = self.tbAgentStatistics
    local ProgressBarComponent = tbOwner.ProgressBarComponent
    if ProgressBarComponent:IsStarted() then
        tbPack.progress_bar_time = tbOwner.ProgressBarComponent.ProgressBarTimer:GetRemainingTime()
    else
        tbPack.progress_bar_time = 0
    end

    local PropertyComponent = tbOwner:GetCurrentPropertyComponent()
    tbPack.ep_percent = PropertyComponent:GetEpPercent()

    tbPack.rescuable = self.bRescuable

    tbPack.distance_with_mountain = self:GetDistanceWithMountain()

    tbPack.damage_count = tbAgentStatistics and tbAgentStatistics:GetProperty(AgentStatisticsDef.DAMAGE_COUNT) or 0
    tbPack.is_jumping = IsJumping(self)

    tbPack.progress_bar = ProgressBarComponent:GetCurrentTemplateId()

    tbPack.is_ship_firing = IsShipFiring(tbOwner)
    tbPack.is_aiming = IsAiming(tbOwner)
    if tbOwner:IsHuman() then
        tbPack.is_running = tbOwner.HumanMovementStateComponent:GetRun()
    else
        tbPack.is_running = false
    end
    tbPack.charged_attack_time = tbAgent:GetChargedAttackTime()
    if self.bInChargedAttackTime and tbPack.charged_attack_time <= 0 then
        -- for i,v in ipairs(tbIgnoredPacketInChargedTime) do
        --     tbAgent:RemoveIngorePacket(v)
        -- end
        self.bInChargedAttackTime = false
    elseif not self.bInChargedAttackTime and tbPack.charged_attack_time > 0 then
        for i,v in ipairs(tbIgnoredPacketInChargedTime) do
            tbAgent:AddIngorePacket(v, tbPack.charged_attack_time)
        end
        self.bInChargedAttackTime = true
    end
end


function SyncDataTrivialData:OnStart()
    self.nLastDistanceWithMountain  = MOUNTAIN_CHECK_DISTANCE
    self.nLastDistanceCalcutateTime = 0
    local tbPlayer = self.tbOwner
    self.pCharacterMovement = nil
    if tbPlayer:IsHuman() then
        local pUEActor = tbPlayer.pUEActor
        if pUEActor then
            self.pCharacterMovement = pUEActor.CharacterMovement
        end
    end
end


function SyncDataTrivialData:OnStop()

end

return SyncDataTrivialData