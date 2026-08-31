-----------------------------------------------------
--File Name    : BattleDyingComponent.lua
--Author       : Song Fuhao
--Create Time  : 2019-01-08
--Description  : 用于处理玩家的重伤救援逻辑
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local BattleDyingComponent = luaclass("BattleDyingComponent", GameComponentBase)

local PropName = require("PropName")
local Timer = require("Timer")
local DelayTimer = require("DelayTimer")
local DungeonIni = require("DungeonIni")
local CppDelegate = require("CppDelegate")
local DamageTypeEx = require("DamageTypeEx")
local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local BattleTeamSystem = require("BattleTeamSystem")
local HumanMovementStateType = require("HumanMovementStateType")
local GameObjectSystem = dynamic_require("GameObjectSystem")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleAbilityDefine = require("BattleAbilityDefine")

local COLLISION_PROFILE_NAME_HUMAN = "OnlyOverlapPawn"
local COLLISION_PROFILE_NAME_SHIP = "OnlyOverlapVehicle"

local SHIP_RESCUE_PROGRESS_BAR_ID = 22
local SHIP_BE_RESCUED_PROGRESS_BAR_ID = 23
local HUMAN_RESCUE_PROGRESS_BAR_ID = 24
local HUMAN_BE_RESCUED_PROGRESS_BAR_ID = 25

-- 重伤状态的Buff
local DYING_BUFF_ID = 31006
-- 救援状态的Buff
local RESCUING_BUFF_ID = 31007
-- 救援成功下离开重伤状态的Buff
local SUCCESS_EXIT_DYING_BUFF_ID = 31008
-- 被救援状态的Buff
local BE_RESCUED_BUFF_ID = 31012

BattleDyingComponent.tbRescuer = nil
BattleDyingComponent.tbNearbyTeammates = nil
BattleDyingComponent.nMaxHpOverlapId = -1
BattleDyingComponent.nDyingHpReduceSpeed = 0
BattleDyingComponent.ReduceHpTimer = nil
BattleDyingComponent.nLastRescuingSucceedTime = -1
BattleDyingComponent.nDyingPublishCount = 0

-- 从DungeonIni中根据人船获取对应配置
local function GetConfigFromDungeonIni(self, szConfigName)
    if self.Owner:IsHuman() then
        return DungeonIni.tbDying[szConfigName .. "ForHuman"]
    else
        return DungeonIni.tbDying[szConfigName .. "ForShip"]
    end
end

local function GetPropertyComponent(tbPlayer)
    if tbPlayer:IsHuman() then
        return tbPlayer.HumanBattlePropertyComponent
    else
        return tbPlayer.ShipBattlePropertyComponent
    end
end

local function GetOriginRescueTime(tbPlayer)
    if tbPlayer:IsHuman() then
        return GetPropertyComponent(tbPlayer):GetPropOriginValue(PropName.nHumanRescuedTime)
    else
        return GetPropertyComponent(tbPlayer):GetPropOriginValue(PropName.nShipRescuedTime)
    end
end

-- 获取重伤状态下最大血量配置
local function GetDyingHp(self)
    return GetPropertyComponent(self.Owner):GetMaxDyingHp()
end

-- 获取救援成功后血量
local function GetRescuedHp(self)
    return GetPropertyComponent(self.Owner):GetRescuedHp()
end

-- 获取重伤状态下血量递减速度
local function GetDyingHpReduceSpeed(self)
    local nDyingPublishmentRatio = GetConfigFromDungeonIni(self, "nDyingPublishmentRatio")
    nDyingPublishmentRatio = 1 + self.nDyingPublishCount * nDyingPublishmentRatio
    return nDyingPublishmentRatio * GetPropertyComponent(self.Owner):GetDyingHpReduceSpeed()
end

-- 获取救援所需时间
local function GetRescuedTime(self)
    if DungeonIni.tbDying.bEnableDualRescueTimeReduction then
        -- 施救、被救双方饰品减时叠加逻辑：
        -- 开启叠加后：最终时间 = 施救者的时间 - 自己缩减的值 - 被救者缩减的值
        local nOriginalRescueTime = GetOriginRescueTime(self.tbRescuer)
        local nRescuerReduction = nOriginalRescueTime - GetPropertyComponent(self.tbRescuer):GetRescuedTime()
        if nRescuerReduction < 0 then
            logerror(string.format("nRescuerReduction < 0! nRescuerReduction = %f, nOriginalRescueTime = %f, tbRescuer name = %s", nRescuerReduction, nOriginalRescueTime, self.tbRescuer.szName))
            assert(false)
        end
        local nOriginRescueeTime = GetOriginRescueTime(self.Owner)
        local nRescueeReduction = nOriginRescueeTime - GetPropertyComponent(self.Owner):GetRescuedTime()
        if nRescueeReduction < 0 then
            logerror(string.format("nRescueeReduction < 0! nRescueeReduction = %f, nOriginRescueeTime = %f, Owner name = %s", nRescueeReduction, nOriginRescueeTime, self.Owner.szName))
            assert(false)
        end
        local nFinalRescueTime = nOriginalRescueTime - nRescuerReduction - nRescueeReduction
        if nFinalRescueTime <= 0 then
            logerror(string.format("nFinalRescueTime <= 0! nFinalRescueTime = %f, nOriginalRescueTime = %f, nRescuerReduction = %f, nRescueeReduction = %f, tbRescuer name = %s, Owner name = %s", nFinalRescueTime, nOriginalRescueTime, nRescuerReduction, nRescueeReduction, self.tbRescuer.szName, self.Owner.szName))
            assert(false)
        end
        return nFinalRescueTime
    else
        -- 不开启叠加的情况：施救、被救方谁的时间短取谁的：
        local nRescuerTime = GetPropertyComponent(self.tbRescuer):GetRescuedTime()
        local nRescueeTime = GetPropertyComponent(self.Owner):GetRescuedTime()
        local nFinalRescueTime = ( nRescuerTime < nRescueeTime ) and nRescuerTime or nRescueeTime
        if nFinalRescueTime <= 0 then
            logerror(string.format("nFinalRescueTime <= 0! nFinalRescueTime = %f, tbRescuer name = %s, Owner name = %s", nFinalRescueTime, self.tbRescuer.szName, self.Owner.szName))
            assert(false)
        end
        return nFinalRescueTime
    end
end

-- 获取救援距离
local function GetRescuingRange(self, bInRescuing)
    local nRescuingRange = GetConfigFromDungeonIni(self, "nRescuingRange")
    if bInRescuing then
        nRescuingRange = nRescuingRange * GetConfigFromDungeonIni(self, "nRescuingRangeRatio")
    end
    return nRescuingRange
end

-- 使队伍中所有未死亡角色直接死亡
local function KillAllTeammate(self)
    local tbTeammates = BattleTeamSystem:GetTeamMembersByPlayer(self.Owner)
    if tbTeammates then
        for _,tbTeammate in pairs(tbTeammates) do
            if (tbTeammate ~= self.Owner) and (not tbTeammate:IsDead()) then
                tbTeammate:KillSelf(DamageTypeEx.KILL_SELF)
            end
        end
    end
end

-- 判断一个玩家是否有任意一个队友存活
local function HasAnyTeammateAlive(self)
    local tbPlayer = self.Owner
    local tbTeammates = BattleTeamSystem:GetTeamMembersByPlayer(tbPlayer)
    if tbTeammates then
        for _,tbTeammate in pairs(tbTeammates) do
            if (tbTeammate ~= tbPlayer) and tbTeammate:IsAlive() then
                return true
            end
        end
    end

    return false
end

local function ClearDelayFindPlayerTimer(self)
    if self.DelayFindPlayerTimer then
        DelayTimer:ClearTimer(self.DelayFindPlayerTimer)
        self.DelayFindPlayerTimer = nil
    end
end

-- 玩家进入重伤救援的Trigger
local function OnPlayerEnterTrigger(self, _, pOtherActor)
    local tbPlayer = self.Owner
    local tbOtherPlayer = GameObjectSystem:FindByUEActor(pOtherActor)
    if tbOtherPlayer then
        if BattleTeamSystem:CheckTeammate(tbPlayer, tbOtherPlayer) and (not tbOtherPlayer:IsDead()) then
            tbOtherPlayer.BattleRescuingComponent:EnterTeammateRescuingTrigger(tbPlayer)
            self.tbNearbyTeammates[tbOtherPlayer] = true
            log("[BattleDyingComponent] OnPlayerEnterTrigger", tbOtherPlayer.szName)
        end
    else
        -- 识别出碰撞的时候Player的Lua实例还没创建出来，暂时通过RunNextTick的方式解决
        self.DelayFindPlayerTimer =  DelayTimer:RunNextTick(function()
            ClearDelayFindPlayerTimer(self)
            OnPlayerEnterTrigger(self, _, pOtherActor)
        end)
    end
end

-- 玩家离开重伤救援的Trigger
local function OnPlayerExitTrigger(self, _, pOtherActor)
    local tbPlayer = self.Owner
    local tbOtherPlayer = GameObjectSystem:FindByUEActor(pOtherActor)
    if tbOtherPlayer then
        if BattleTeamSystem:CheckTeammate(tbPlayer, tbOtherPlayer) and (not tbOtherPlayer:IsDead()) then
            log("[BattleDyingComponent] OnPlayerExitTrigger", tbOtherPlayer.szName)
            self.tbNearbyTeammates[tbOtherPlayer] = nil
            tbOtherPlayer.BattleRescuingComponent:ExitTeammateRescuingTrigger(tbPlayer)
        end
        if (tbOtherPlayer == self.tbRescuer) and self.tbRescuer.ProgressBarComponent then
            self.tbRescuer.ProgressBarComponent:Abort()
        end
    end
end

-- 创建重伤救援的Trigger
local function SpawnRescuingTrigger(self)
    local tbPlayer = self.Owner
    local pUEActor = tbPlayer.pUEActor
    local pSphereComponent = EngineExtActorShell.CreateActorComponent(pUEActor, SphereComponent)
    self.pSphereComponent = pSphereComponent
    self.OnBeginOverlapDelegate = CppDelegate:BindMethod(pSphereComponent.OnComponentBeginOverlap, self, OnPlayerEnterTrigger)
    self.OnEndOverlapDelegate = CppDelegate:BindMethod(pSphereComponent.OnComponentEndOverlap, self, OnPlayerExitTrigger)

    pSphereComponent:IgnoreActorWhenMoving(pUEActor, true)
    pSphereComponent:SetCollisionProfileName(tbPlayer:IsHuman() and COLLISION_PROFILE_NAME_HUMAN or COLLISION_PROFILE_NAME_SHIP)
    pSphereComponent:K2_AttachToComponent(pUEActor:K2_GetRootComponent(), ""--[[SocketName]], EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, EAttachmentRule.KeepRelative, true)
    pSphereComponent:SetSphereRadius(GetRescuingRange(self, false), true)
end

-- 销毁重伤救援的Trigger
local function DestroyRescuingTrigger(self)
    ClearDelayFindPlayerTimer(self)
    local tbPlayer = self.Owner
    for tbTeammate,_ in pairs(self.tbNearbyTeammates) do
        tbTeammate.BattleRescuingComponent:ExitTeammateRescuingTrigger(tbPlayer)
    end
    if self.OnBeginOverlapDelegate then
        self.OnBeginOverlapDelegate:Unbind()
        self.OnBeginOverlapDelegate = nil
    end
    if self.OnEndOverlapDelegate then
        self.OnEndOverlapDelegate:Unbind()
        self.OnEndOverlapDelegate = nil
    end
    if self.pSphereComponent then
        self.pSphereComponent:K2_DestroyComponent(tbPlayer.pUEActor)
        self.pSphereComponent = nil
    end
    self.tbNearbyTeammates = {}
end

-- 刷新所有队友救援状态
local function RefreshNearbyTeammateRescuingState(self)
    for tbTeammate,_ in pairs(self.tbNearbyTeammates) do
        tbTeammate.BattleRescuingComponent:RefreshRescuingState()
    end
end

-- 重伤下血量递减逻辑
local function ReduceHpInDying(self)
    local tbPlayer = self.Owner
    local PropertyComponent = tbPlayer:GetCurrentPropertyComponent()
    PropertyComponent:ApplyDamage(tbPlayer, DamageTypeEx.DYING_REDUCE, self.nDyingHpReduceSpeed)
end

-- 清除重伤血量递减Timer
local function ClearDyingHpReduceTimer(self)
    if self.ReduceHpTimer then
        self.ReduceHpTimer:Clear()
        self.ReduceHpTimer = nil
    end
end

-- 处理重伤处罚逻辑
local function HandleDyingPublishment(self)
    local nCurrentTime = GlobalVariableSystem:GetDSTimeSeconds()
    local nDyingPublishmentInterval = GetConfigFromDungeonIni(self, "nDyingPublishmentInterval")
    if (self.nLastRescuingSucceedTime ~= -1)
    and ((nCurrentTime - self.nLastRescuingSucceedTime) < nDyingPublishmentInterval) then
        self.nDyingPublishCount = self.nDyingPublishCount + 1
    else
        self.nDyingPublishCount = 0
    end
end

-- 设置救援队友
local function SetRescuer(self, tbRescuer)
    self.tbRescuer = tbRescuer
    tbRescuer.BuffComponentServer:AddBuffWithInstigator(tbRescuer, RESCUING_BUFF_ID)
    local RescuerPropertyComponent = tbRescuer:GetCurrentPropertyComponent()
    RescuerPropertyComponent:SetPropOriginValue(RescuerPropertyComponent.nIsRescuingId, true)
end

-- 取消救援队友设置
local function UnsetRescuer(self)
    if self.tbRescuer then
        self.tbRescuer.BuffComponentServer:RemoveBuffById(RESCUING_BUFF_ID)
        local RescuerPropertyComponent = self.tbRescuer:GetCurrentPropertyComponent()
        RescuerPropertyComponent:SetPropOriginValue(RescuerPropertyComponent.nIsRescuingId, false)
        self.tbRescuer = nil
    end
end

-- 进入重伤状态
local function EnterDyingState(self)
    local tbPlayer = self.Owner
    -- 打断当前转圈操作
    tbPlayer.ProgressBarComponent:Abort()

    HandleDyingPublishment(self)

    local nDyingHp = GetDyingHp(self)
    local PropertyComponent = tbPlayer:GetCurrentPropertyComponent()
    PropertyComponent:SetPropOriginValue(PropertyComponent.nIsDyingId, true)
    PropertyComponent:SetPropOriginValue(PropertyComponent.nHpId, nDyingHp)
    self.nMaxHpOverlapId = PropertyComponent:PropOverlap_Override(PropertyComponent.nMaxHpId, nDyingHp)
    self.nDyingHpReduceSpeed = GetDyingHpReduceSpeed(self)

    SpawnRescuingTrigger(self)
    local nDyingReduceInterval = GetConfigFromDungeonIni(self, "nDyingReduceInterval")
    self.ReduceHpTimer = Timer.NewTimerMethod(self, ReduceHpInDying, nDyingReduceInterval, true)
    tbPlayer.BuffComponentServer:RemoveBuffByGroupId(BattleAbilityDefine.DYING_REMOVE_BUFF_GROUP_ID)
    tbPlayer.BuffComponentServer:AddBuffWithInstigator(tbPlayer, DYING_BUFF_ID)
    tbPlayer.BattleRescuingComponent:RefreshRescuingState()
end

-- 离开重伤状态
local function ExitDyingState(self)
    local tbPlayer = self.Owner
    tbPlayer.BuffComponentServer:AddBuffWithInstigator(tbPlayer, SUCCESS_EXIT_DYING_BUFF_ID)
    UnsetRescuer(self)
    ClearDyingHpReduceTimer(self)
    local PropertyComponent = tbPlayer:GetCurrentPropertyComponent()
    PropertyComponent:SetPropOriginValue(PropertyComponent.nIsDyingId, false)
    DestroyRescuingTrigger(self)
    tbPlayer.BuffComponentServer:RemoveBuffById(DYING_BUFF_ID)
    tbPlayer.BattleRescuingComponent:RefreshRescuingState()
end

-- 救援成功
local function OnRescueSuccessed(self)
    ExitDyingState(self)
    self.Owner.BuffComponentServer:RemoveBuffById(BE_RESCUED_BUFF_ID)
    local PropertyComponent = self.Owner:GetCurrentPropertyComponent()
    PropertyComponent:RemovePropOverlap(PropertyComponent.nMaxHpId, self.nMaxHpOverlapId)
    PropertyComponent:SetPropOriginValue(PropertyComponent.nHpId, GetRescuedHp(self))
    self.nLastRescuingSucceedTime = GlobalVariableSystem:GetDSTimeSeconds()
end

local function OnRescueAborted(self)
    if self:IsBeingRescued() then
        local tbRescuer = self.tbRescuer
        UnsetRescuer(self)
        tbRescuer.ProgressBarComponent:Abort()
        self.Owner.ProgressBarComponent:Abort()
        self.Owner.BuffComponentServer:RemoveBuffById(BE_RESCUED_BUFF_ID)
        self.pSphereComponent:SetSphereRadius(GetRescuingRange(self, false), true)
        RefreshNearbyTeammateRescuingState(self)
        self.ReduceHpTimer:Resume()
    end
end

-- 任意角色死亡
local function OnPawnDead(self, tbCharacter)
    if GlobalVariableSystem.bDyingEnabled then
        if tbCharacter == self.Owner then
            log("[BattleDyingComponent] OnPawnDead", tbCharacter.szName)
            if tbCharacter:IsDying() then
                OnRescueAborted(self)
                ExitDyingState(self)
            end
            -- 最后一个队友也倒地时，所有队友都直接死亡
            if not HasAnyTeammateAlive(self) then
                KillAllTeammate(self)
            end
        end
    end
end

-- 开始救援转圈
local function StartRescuingProgress(self)
    local OnSuccessed = function()
        UnsetRescuer(self)
        OnRescueSuccessed(self)
    end
    local OnAborted = function()
        OnRescueAborted(self)
    end
    local nRescueProgressBarId = SHIP_RESCUE_PROGRESS_BAR_ID
    local nBeRescuedProgressBarId = SHIP_BE_RESCUED_PROGRESS_BAR_ID
    if self.Owner:IsHuman() then
        nRescueProgressBarId = HUMAN_RESCUE_PROGRESS_BAR_ID
        nBeRescuedProgressBarId = HUMAN_BE_RESCUED_PROGRESS_BAR_ID
    end
    local nRescuedTime = GetRescuedTime(self)

    self.pSphereComponent:SetSphereRadius(GetRescuingRange(self, true), false)

    self.Owner.BuffComponentServer:AddBuffWithInstigator(self.Owner, BE_RESCUED_BUFF_ID)

    self.tbRescuer.ProgressBarComponent:Start(nRescueProgressBarId, nil, OnSuccessed, OnAborted, nRescuedTime)
    self.Owner.ProgressBarComponent:Start(nBeRescuedProgressBarId, nil, nil, OnAborted, nRescuedTime)
end

function BattleDyingComponent:OnCreate(...)
    BattleDyingComponent.super.OnCreate(self, ...)
    self.tbNearbyTeammates = {}
    EventManager:BindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
end

function BattleDyingComponent:OnDestroy(...)
    ClearDelayFindPlayerTimer(self)
    ClearDyingHpReduceTimer(self)
    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_OBJECT_ON_PAWN_PRE_DEAD, self, OnPawnDead)
    self.tbNearbyTeammates = nil
    BattleDyingComponent.super.OnDestroy(self, ...)
end

function BattleDyingComponent:OnActorDestroyed(...)
    if self.Owner:IsDying() then
        OnRescueAborted(self)
        ExitDyingState(self)
    end
    BattleDyingComponent.super.OnActorDestroyed(self, ...)
end

-- @public
-- 判断是否正在被救援
function BattleDyingComponent:IsBeingRescued()
    return self.tbRescuer ~= nil
end

-- @public
-- 救援
-- 只能由BattleRescuingComponent调用
function BattleDyingComponent:Rescue(tbRescuer)
    SetRescuer(self, tbRescuer)
    StartRescuingProgress(self)
    RefreshNearbyTeammateRescuingState(self)
    self.ReduceHpTimer:Pause()
end

-- @public
-- 尝试进入救援状态
-- 只能由BattlePropertyComponentBase调用
function BattleDyingComponent:TryToEnterDying(nDamageType, nHp)
    if GlobalVariableSystem.bDyingEnabled then
        -- 如果超出重伤血量伤害直接死亡
        -- if (GetDyingHp(self) + nHp) <= 0 then
        --     return false
        -- end
        -- 自杀时跳过重伤
        if nDamageType == DamageTypeEx.KILL_SELF then
            return false
        end
        -- 如果队友都死了直接死亡
        if not HasAnyTeammateAlive(self) then
            return false
        end
        -- 人形态下处于游泳状态直接死亡
        if self.Owner:IsHuman() then
            local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
            if HumanMovementStateComponent
            and (HumanMovementStateComponent:GetCurrentState() == HumanMovementStateType.Swimming) then
                return false
            end
        end
        EnterDyingState(self)
        return true
    end
    return false
end

function BattleDyingComponent:ForceExitDyingState()
    if self.Owner:IsDying() then
        ExitDyingState(self)
    end
end

return BattleDyingComponent