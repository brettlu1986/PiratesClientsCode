
-----------------------------------------------------
--File Name    : HumanConcealComponent.lua
--Author       : ZuoKun
--Create Time  : 2020-03-19
--Description  : 人隐匿
-----------------------------------------------------

local luaclass = require("luaclass")
local GameComponentBase = require("GameComponentBase")
local HumanConcealComponent = luaclass("HumanConcealComponent",GameComponentBase)
local PropName = require("PropName")

local SelfEventHelper = require("SelfEventHelper")
local CommonEventDef = require("CommonEventDef")
local HumanMovementStateType = require("HumanMovementStateType")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local Timer = require("Timer")
local HumanConcealIni = require("HumanConcealIni")
-- local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local DamageTypeEx = require("DamageTypeEx")
local GlobalVariableSystem = dynamic_require("GlobalVariableSystem")
local BattleItemCategoryDef = require("BattleItemCategoryDef")
local BattleItemSystemHelper = require("BattleItemSystemHelper")
local GameObjectTypeDef = require("GameObjectTypeDef")

local DELAY_CONCEAL = "DelayConceal"
local PUNISHMENT_TIMER = "PunishmentTimer"
local DEFAULT_CONCEAL_EXITAIM = 2

local StateDelayConceal = {
    [HumanMovementStateType.UpRight_State] = HumanConcealIni.nUpRightDelayConceal,
    [HumanMovementStateType.Crouch_State] = HumanConcealIni.nCrouchDelayConceal,
    [HumanMovementStateType.Crawl_State] = HumanConcealIni.nCrawlDelayConceal,
}

HumanConcealComponent.EventHelper = nil 
HumanConcealComponent.bActiveConceal = false
HumanConcealComponent.nPunishment = 0
HumanConcealComponent.BPConcealComponent = nil
HumanConcealComponent.bMoving = false
HumanConcealComponent.bInProgressBar = false
HumanConcealComponent.nConceal = 1
HumanConcealComponent.nArmorLevel = 1
HumanConcealComponent.nDefaultConceal = 1
local function LOG_DEBUG(self, ...)
    -- local LocalPlayer = GamePlayerSelfHelper:Get()
    log(string.format("[ConcealComponent]Object[%s]", self.Owner.szName), ...)
    -- log(debug.traceback())
end

local function OnConceal(self, bInstant)
    if self.nConceal >= 1 and self.bActiveConceal then 
        self.bActiveConceal = false 
        return 
    end 
    self.bActiveConceal = true
    if not GlobalVariableSystem:IsServerLogic() then 
        if bInstant == nil then 
            bInstant = false
        end
        local nCurrentPunishment = 1
        
        if self.nPunishment ~= 0 then  
            nCurrentPunishment = 1 / self.nPunishment
        end 
        LOG_DEBUG(self, "OnConceal nConceal", self.nConceal, "bActiveConceal", self.bActiveConceal, "nPunishment", nCurrentPunishment)
        self.BPConcealComponent:ChangeConceal(nCurrentPunishment, self.nConceal, bInstant)
    end
end

local function SetConceal(self, nConceal)
    LOG_DEBUG(self, "SetConceal CurrentConceal", self.nConceal, "NewConceal", nConceal)
    self.nConceal = nConceal
end

local function GetConcealDelayTime(self)
    local MovementState = self.Owner.HumanMovementStateComponent:GetCurrentState()
    return StateDelayConceal[MovementState]
end
-- 隐匿CD
local function DelayConceal(self)
    if self.bActiveConceal then  
        return 
    end 
    if Timer.IsOwnerTimerAlived(self, DELAY_CONCEAL) then 
        return 
    end 
    
    local DelayTime = GetConcealDelayTime(self)
    LOG_DEBUG(self, "DelayConceal", DelayTime)
    
    -- Timer.StopOwnerTimer(self, DELAY_CONCEAL)
    Timer.StartOwnerTimer(self, DELAY_CONCEAL, function()
        OnConceal(self)
    end, DelayTime, false)
end

-- 隐匿惩罚
local function PunishmentConceal(self, nPunishment)
    LOG_DEBUG(self, "PunishmentConceal CurrentPunishment", self.nPunishment, "nPunishment", nPunishment)
    if Timer.IsOwnerTimerAlived(self, PUNISHMENT_TIMER) then  
        if self.nPunishment == 0 then  
            self.nPunishment = nPunishment
        else 
            self.nPunishment = nPunishment * self.nPunishment
        end 
    end 

    if self.nPunishment > HumanConcealIni.nMaxPunishment then  
        self.nPunishment = HumanConcealIni.nMaxPunishment
    end 

    Timer.StopOwnerTimer(self, PUNISHMENT_TIMER)
    Timer.StartOwnerTimer(self, PUNISHMENT_TIMER, function() 
        LOG_DEBUG(self, "PunishmentConceal Clear")
        self.nPunishment = 0
    end, HumanConcealIni.nPunishmentTime, false)
end

-- 打断隐匿
local function AbortConceal(self, nPunishment, bInstant)
    -- self.Owner.pUEActor:SetDefaultConceal(0)
    if bInstant == nil then 
        bInstant = false
    end
    self.BPConcealComponent:ChangeToDefaultConceal(bInstant)
    Timer.StopOwnerTimer(self, DELAY_CONCEAL)
    if not self.bActiveConceal then  
        return 
    end     
    LOG_DEBUG(self, "AbortConceal")
    self.bActiveConceal = false 
    PunishmentConceal(self, nPunishment)
end

local function IsPlayerSelfAiming(self)
    if GlobalVariableSystem:IsClient() and (self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf)  then  
        local WeaponComponent = self.Owner.HumanWeaponComponent
        local bAiming = WeaponComponent:IsAiming()
        return bAiming
    end
    return false
end

local function CanConceal(self)
    if not self.rHumanConceal:Get() then  
        return false
    end 
    local Owner = self.Owner
    local MovementState = Owner.HumanMovementStateComponent:GetCurrentState()
    if self.bMoving then
        return false 
    elseif MovementState ~= HumanMovementStateType.Crawl_State 
        and MovementState ~= HumanMovementStateType.Crouch_State 
        and MovementState ~= HumanMovementStateType.UpRight_State  then 
        return false
    end

    local HumanWeaponComponent = Owner.HumanWeaponComponent
    if HumanWeaponComponent:IsAttacking() or HumanWeaponComponent:IsReloading() then 
        return false
    end
    if self.bInProgressBar then  
        return false
    end 
    if IsPlayerSelfAiming(self) then  
        return false
    end

    return true
end

local function OnMovementStateChanged(self, tbCharacter, nOldState, nNewState, bOnActorCreated)
    if not self.rHumanConceal:Get() then  
        return 
    end 
    if tbCharacter ~= self.Owner then  
        return 
    end 

    local nConceal = 1
    local tbConcealDataLevel = HumanConcealIni.tbConcealData[self.nArmorLevel]
    if nNewState == HumanMovementStateType.UpRight_State then  
        nConceal = tbConcealDataLevel.nUpRightToConceal
        self.nDefaultConceal = tbConcealDataLevel.nUpRightStartConceal
    elseif nNewState == HumanMovementStateType.Crouch_State then 
        nConceal = tbConcealDataLevel.nCrouchToConceal
        self.nDefaultConceal = tbConcealDataLevel.nCrouchStartConceal
    elseif nNewState == HumanMovementStateType.Crawl_State then 
        nConceal = tbConcealDataLevel.nCrawlToConceal
        self.nDefaultConceal = tbConcealDataLevel.nCrawlStartConceal
    else 
        self.nDefaultConceal = tbConcealDataLevel.nUpRightStartConceal
    end
    self:UpdateDefaultConceal()
    -- 其他状态算做移动打断
    if not CanConceal(self) then 
        AbortConceal(self, HumanConcealIni.nMovePunishmentFactor)
        -- nConceal = tbConcealDataLevel.nUpRightToConceal
        SetConceal(self, nConceal)
    else 
        SetConceal(self, nConceal)
        if bOnActorCreated then  
            OnConceal(self)
        else 
            self.bActiveConceal = false
            DelayConceal(self)
        end
    end
end

-- 移动
local function OnPlayerDisplacement(self, bDisplacement)
    self.bMoving = bDisplacement
    if not self.rHumanConceal:Get() then  
        return 
    end 

    -- local MovementState = self.Owner.HumanMovementStateComponent:GetCurrentState()
    if bDisplacement then -- and MovementState == HumanMovementStateType.UpRight_State then 
        AbortConceal(self, HumanConcealIni.nMovePunishmentFactor)
    elseif CanConceal(self) then
        DelayConceal(self)
    end 
end

-- 被攻击
local function OnHumanHit(self, tbTaker, tbCauser, nDamage, nDamageType)
    if not self.rHumanConceal:Get() then  
        return 
    end  
    if tbTaker ~= self.Owner then  
        return 
    end 
    if nDamageType == DamageTypeEx.POISON_CIRCLE or nDamageType == DamageTypeEx.FALLING then 
        return 
    end 
    AbortConceal(self, HumanConcealIni.nHitPunishmentFactor, true)
    if CanConceal(self) then
        DelayConceal(self)
    end     
end

local function OnWeaponStateChanged(self, nCurrentState, Owner)
    if not self.rHumanConceal:Get() then  
        return 
    end  
    if Owner ~= self.Owner then  
        return 
    end     
    if nCurrentState == HumanWeaponStateDef.ATTACKING then 
        AbortConceal(self, HumanConcealIni.nAttackPunishmentFactor, true)
    elseif nCurrentState == HumanWeaponStateDef.RELOADING then
        AbortConceal(self, HumanConcealIni.nReloadPunishmentFactor, true)
    elseif CanConceal(self) then
        DelayConceal(self)
    end
end

local function OnProgressEvent(self, nInstanceId, bStart)
    local SelfInstanceId = self.Owner:GetServerInstanceId()
    if SelfInstanceId ~= nInstanceId then 
        return 
    end 
    if not self.rHumanConceal:Get() then  
        return 
    end  

    if bStart then 
        self.bInProgressBar = true
        AbortConceal(self, HumanConcealIni.nProgressPunishmentFactor, true)
    else 
        self.bInProgressBar = false
        if CanConceal(self) then
            DelayConceal(self)
        end         
    end
end

local function UpdateArmorLeve(self)
    if not self.rHumanConceal:Get() then  
        return 
    end      
    local nMovementState = self.Owner.HumanMovementStateComponent:GetCurrentState()
    OnMovementStateChanged(self, self.Owner, nMovementState, nMovementState, false)
    -- self:UpdateDefaultConceal()
    
    -- if self.bActiveConceal then  
    --     self.BPConcealComponent:ChangeConceal(1, self.nConceal)
    -- end 
end

local function OnAimChanged(self, bAim, tbObject)
    if tbObject:GetServerInstanceId() == self.Owner:GetServerInstanceId() then 
        if bAim then   
            local BPConcealComponent = self.BPConcealComponent
            if BPConcealComponent then 
                BPConcealComponent:SetDefaultConceal(DEFAULT_CONCEAL_EXITAIM)
            end
            AbortConceal(self, 0, true)
        else 
            if self.rHumanConceal:Get() then  
                self:UpdateDefaultConceal(true, true)
            end
            -- DelayConceal(self)
            if CanConceal(self) then
                OnConceal(self, true)
            end
        end
    end
end

function HumanConcealComponent:OnArmorEquip(nOwnerCharacterInstanceId)
    local SelfInstanceId = self.Owner:GetServerInstanceId()
    if SelfInstanceId ~= nOwnerCharacterInstanceId then 
        return 
    end     
    if not self.rHumanConceal:Get() then  
        return 
    end  
    self.nArmorLevel = self:GetCurrentArmorLevel()
    self.rArmorLevel:Set(self.nArmorLevel)
    -- UpdateArmorLeve(self)
end

function HumanConcealComponent:OnArmorUnEquip(nOwnerCharacterInstanceId)
    local SelfInstanceId = self.Owner:GetServerInstanceId()
    if SelfInstanceId ~= nOwnerCharacterInstanceId then 
        return 
    end       
    if not self.rHumanConceal:Get() then  
        return 
    end  
    self.nArmorLevel = 1
    self.rArmorLevel:Set(self.nArmorLevel)
    -- UpdateArmorLeve(self)
end

local function RegisterEvent(self)
    local EventHelper = self.EventHelper
    -- local pUEActor = self.OwnerActor
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_MOVEMENT_STATE_CHANGED, self, OnMovementStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_WEAPON_STATE_CHANGED, self, OnWeaponStateChanged)
    EventHelper:RegisterEvent(CommonEventDef.EV_PROGRESS_CHANGED, self, OnProgressEvent)
    EventHelper:RegisterEvent(CommonEventDef.EV_ON_TAKE_DAMAGE, self, OnHumanHit)
    if GlobalVariableSystem:IsServerLogic() then  
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_EQUIPED_SERVER, self, self.OnArmorEquip)
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_ARMOR_ON_UNEQUIPED_SERVER, self, self.OnArmorUnEquip)
    end

    if GlobalVariableSystem:IsClient() and (self.Owner:GetObjectType() == GameObjectTypeDef.PlayerSelf)  then  
        EventHelper:RegisterEvent(CommonEventDef.EV_HUMAN_AIM_CHANGED, self, OnAimChanged)
    end 

    local pUEActor = self.Owner.pUEActor
    EventHelper:RegisterCppDelegate(pUEActor.OnPlayerDisplacement, self, OnPlayerDisplacement)
end

local function ClearAll(self)
    -- if self.EventHelper then 
    --     self.EventHelper:UnregisterAll()
    --     -- self.EventHelper = nil 
    -- end     
    Timer.StopOwnerAllTimer(self, true)
    self.nConceal = 1
    self.bActiveConceal = false
    local BPConcealComponent = self.BPConcealComponent
    if BPConcealComponent then 
        BPConcealComponent:SetDefaultConceal(1)
        BPConcealComponent:ChangeToDefaultConceal(true)    
    end
end

local function OnRepHumanConceal(self, _Property, bHumanConceal, bOnActorCreated)
    if bHumanConceal then 
        -- RegisterEvent(self)
        local HumanMovementStateComponent = self.Owner.HumanMovementStateComponent
        local CurrentState = HumanMovementStateComponent:GetCurrentState()
        OnMovementStateChanged(self, self.Owner, 0, CurrentState, bOnActorCreated)
        -- self:OnArmorEquip(self.Owner:GetServerInstanceId())
    else
        ClearAll(self)
    end
end

local function OnRepHumanArmorLevel(self, _Property, nArmorLevel)
    self.nArmorLevel = nArmorLevel
    UpdateArmorLeve(self)
end

function HumanConcealComponent:OnActorCreated(pUEActor)
    HumanConcealComponent.super.OnActorCreated(self, pUEActor)

    local rComponent = self.Owner.CustomReplicationComponent
    self.rHumanConceal = rComponent:BindMethod(
        PropName.bHumanConceal,
        false, self, OnRepHumanConceal, true)
    self.rArmorLevel = rComponent:BindMethod(
        PropName.nArmorLevel,
        1, self, OnRepHumanArmorLevel, true)

    if not self.EventHelper then 
        self.EventHelper = SelfEventHelper()
    end

    self.BPConcealComponent = pUEActor.ConcealComponent

    self.BPConcealComponent.CastShadowConceal = HumanConcealIni.nCastShadowConceal

    OnRepHumanConceal(self, nil, self.rHumanConceal:Get(), true)
    OnRepHumanArmorLevel(self, nil, self.rArmorLevel:Get())
    RegisterEvent(self)
end

function HumanConcealComponent:OnActorDestroyed(pUEActor)
    HumanConcealComponent.super.OnActorDestroyed(self, pUEActor)
    ClearAll(self)
    if self.EventHelper then 
        self.EventHelper:UnregisterAll()
        self.EventHelper = nil 
    end  
end

function HumanConcealComponent:StartConceal()
    self.rHumanConceal:Set(true)
end


function HumanConcealComponent:EndConceal()
    self.rHumanConceal:Set(false)
    self.nArmorLevel = 1
    self.rArmorLevel:Set(self.nArmorLevel)
end

function HumanConcealComponent:IsInConceal()
    return self.bActiveConceal
end

function HumanConcealComponent:GetCurrentArmorLevel()
    local nCharacterInstanceId = self.Owner:GetServerInstanceId()
    local tbArmors = BattleItemSystemHelper:GetEquippedItems(nCharacterInstanceId, BattleItemCategoryDef.HUMAN_ARMOR, nCharacterInstanceId, false)
    if tbArmors then
        local tbArmor = tbArmors[1] 
        if tbArmor then  
            return tbArmor:GetGrade()
        end
    end
    return 1
end

function HumanConcealComponent:UpdateDefaultConceal(bForce, bInstant)
    if IsPlayerSelfAiming(self) then  
        return false
    end
    LOG_DEBUG(self, "UpdateDefaultConceal nDefaultConceal", self.nDefaultConceal)
    self.BPConcealComponent:SetDefaultConceal(self.nDefaultConceal)
    
    if bForce or not self.bActiveConceal then  
        if bInstant == nil then 
            bInstant = false
        end 
        self.BPConcealComponent:ChangeToDefaultConceal(bInstant)
    end 
end

return HumanConcealComponent