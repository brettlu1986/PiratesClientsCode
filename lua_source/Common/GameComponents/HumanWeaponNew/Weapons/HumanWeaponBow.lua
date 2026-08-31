local luaclass = require("luaclass")
local HumanWeaponProjectile = dynamic_require("HumanWeaponProjectile")
local HumanWeaponBow = luaclass("HumanWeaponBow", HumanWeaponProjectile)
local GameObjectSystem = dynamic_require("GameObjectSystem")
local TakeDamage = require("HDC_HumanBulletNew")
local HumanWeaponMisc = require("HumanWeaponMisc")
local PropName = require("PropName")
local AIHelper = require("AIHelper")
local Timer = require("Timer")
local AnimDef = require("AnimDef")

local EventManager = require("EventManager")
local CommonEventDef = require("CommonEventDef")
local HumanWeaponHelper = require("HumanWeaponHelper")

local AttackSubState = HumanWeaponMisc.AttackSubState

local PRE_ATTACK_ANIM_KEY = AnimDef.ON_BOW_PRE_ATTACK
local POST_ATTACK_ANIM_KEY = AnimDef.ON_BOW_POST_ATTACK

local tbTempNotify = {}
HumanWeaponBow.nAccumulateTime = 0

HumanWeaponBow.CheatAttackTarget = nil
HumanWeaponBow.szCheatAttackDamageType = nil
HumanWeaponBow.nGravityScale = 0.2

local BOW_ATTACK_SUB_STATE_TIMER = "BowAttackSubStateTimer"
local CHEAT_RELOAD_TIMER = "CheatReloadTimer"
local BOW_PRE_ATTACK_TIME = 0.84    -- s
local BOW_POST_ATTACK_TIME = 0.6    -- s

local function CheatIdle(self)
    if (not self.bServer) or (not AIHelper.IsAIControlled(self.Owner)) then
        return
    end

    self:SetRepAttackSubState(AttackSubState.IDLE)

    local tbProperty = self:GetProperty()
    local nReloadTime = tbProperty.nReloadTime
    Timer.StartOwnerTimer(self, CHEAT_RELOAD_TIMER, function()
        if self:GetCurrentAmmo() <= 0 then
            self.OwnerComponent:Reload(nReloadTime)
        end
    end, tbProperty.nRateOfFire)
end

local function CheatPostAttack(self)
    if (not self.bServer) or (not AIHelper.IsAIControlled(self.Owner)) then
        return
    end

    if Timer.IsOwnerTimerAlived(self, BOW_ATTACK_SUB_STATE_TIMER) then
        return
    end

    -- self:SetRepAttackSubState(AttackSubState.POST_ATTACK)
    -- RouteAttack 中会设置

    local nPostAttackTime = BOW_POST_ATTACK_TIME

    local pMontage = self.OwnerComponent:GetMontageWithAnimKey(POST_ATTACK_ANIM_KEY)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    if pMontage and nAttackCoefficient then
        nPostAttackTime = ExtendBlueprintFunctions.GetMontageLength(pMontage) / nAttackCoefficient
    end

    log("[HumanWeaponBow] CheatPostAttack", nPostAttackTime)

    Timer.StartOwnerTimer(self, BOW_ATTACK_SUB_STATE_TIMER, function()
        CheatIdle(self)
    end, nPostAttackTime)
    logdebug("weapon bow lz 1")
end

local function CheatMidAttack(self)
    if (not self.bServer) or (not AIHelper.IsAIControlled(self.Owner)) then
        return
    end
    self:SetRepAttackSubState(AttackSubState.MID_ATTACK)

    log("[HumanWeaponBow] CheatMidAttack")

    local fnFinishMidCheatAttack = function()
        HumanWeaponBow.super.CheatAttack(self, self.CheatAttackTarget, self.szCheatAttackDamageType)
        self.CheatAttackTarget = nil
        self.szCheatAttackDamageType = nil
    
        CheatPostAttack(self)
    end

    local pMontage = self.OwnerComponent:GetMontageWithAnimKey(POST_ATTACK_ANIM_KEY)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    local nMidAttackTime = 0
    if pMontage and nAttackCoefficient then
        nMidAttackTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.WAND_FIRE) / nAttackCoefficient
    end

    if nMidAttackTime and nMidAttackTime > 0 then
        Timer.StartOwnerTimer(self, BOW_ATTACK_SUB_STATE_TIMER, function()
            fnFinishMidCheatAttack()
        end, nMidAttackTime)
    else
        fnFinishMidCheatAttack()
    end
    logdebug("weapon bow lz2")
end

local function CheatPreAttack(self, nTime)
    if (not self.bServer) or (not AIHelper.IsAIControlled(self.Owner)) then
        return
    end

    if Timer.IsOwnerTimerAlived(self, BOW_ATTACK_SUB_STATE_TIMER) then
        return
    end

    self:SetRepAttackSubState(AttackSubState.PRE_ATTACK)
    
    local nPreAttackAnimTime = BOW_PRE_ATTACK_TIME
    
    local pMontage = self.OwnerComponent:GetMontageWithAnimKey(PRE_ATTACK_ANIM_KEY)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    
    if pMontage and nAttackCoefficient then
        nPreAttackAnimTime = ExtendBlueprintFunctions.GetMontageSectionLength(pMontage, AnimDef.SectionName.BOW_ATTACK_START) / nAttackCoefficient
    end

    if nTime and nTime > 0 then
        nTime = nTime + nPreAttackAnimTime
    else
        nTime = nPreAttackAnimTime
    end

    log("[HumanWeaponBow] CheatPreAttack", nTime)

    Timer.StartOwnerTimer(self, BOW_ATTACK_SUB_STATE_TIMER, function()
        CheatMidAttack(self)
    end, nTime)
end

local function OnPlayerRelogin(self, tbPlayer)
    if not (tbPlayer and self.Owner) then
        return
    end
    
    if tbPlayer:GetServerInstanceId() ~= self.Owner:GetServerInstanceId() then
        return
    end

    local nCurrentSubState = self:GetRepAttackSubState()
    if nCurrentSubState == AttackSubState.PRE_ATTACK then
        self:OnCancel()
    end
end

function HumanWeaponBow:BowPreAttack()
    logdebug("weapon bow lz 3")
    self:RepAttack(self.rHumanAttackSubState, AttackSubState.PRE_ATTACK)
end 

function HumanWeaponBow:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    logdebug("weapon bow lz 14")
    HumanWeaponBow.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)

    self.rHumanBowPreAttact = OwnerComponent.rHumanBowPreAttact

    EventManager:BindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerRelogin)
end

function HumanWeaponBow:OnDestroyed()
    HumanWeaponBow.super.OnDestroyed(self)

    EventManager:UnBindEventMethod(CommonEventDef.EV_GAME_MODE_ON_PLAYER_RELOGIN, self, OnPlayerRelogin)
    logdebug("weapon bow lz 5")
end

function HumanWeaponBow:RouteAttack(tbRepData)
    HumanWeaponBow.super.RouteAttack(self, tbRepData)
    self.nAccumulateTime = tbRepData.accumulate_time
    self:SetRepAttackSubState(AttackSubState.POST_ATTACK)
end

function HumanWeaponBow:AttackOnceInServer(nTakerId, StartPos, EndPos, nHitBodyType, szDamageType, nProjectileIndex)
    logdebug("attack once lz")
    local Owner = self.Owner
    local tbProperty = self:GetProperty()
    -- tbProperty.nDamageMagnification
    local nDamage = self:GetOwnerProperty(PropName.nDamagePerAttack) * (1 + self.nAccumulateTime * self:GetOwnerProperty(PropName.nDamageFullCharge))

    local nInstanceId = self.nInstanceId
    --  已经扣过一次了
    -- if(not self:DecreaseAmmo(tbProperty.nDecreaseBulletCount)) then
    --     return
    -- end
    local Taker = GameObjectSystem:FindByInstanceId(nTakerId)
    if(Taker == nil) then
        return
    end
    if not self:CheckAttackFrequency() then
        return
    end
    -- tbTempEnds[1] = EndPos
    tbTempNotify.weapon_id = nInstanceId
    tbTempNotify.start = StartPos
    tbTempNotify.end_pos = EndPos
    local StartAttackPos = self.tbStartAttackPoses[nProjectileIndex]
    local StartAttackDir = self.tbStartAttackDirs[nProjectileIndex]
    if(self:CheckAttackHit(StartAttackPos, StartAttackDir, Taker, nHitBodyType)) then
        TakeDamage(Taker, nDamage, Owner, tbProperty, nHitBodyType)
        tbTempNotify.taker = Taker:GetServerInstanceId()
    else
        tbTempNotify.taker = nil
    end
    self.OwnerComponent:OnDamageEnd()
    self:RepAttack(self.rHumanGunAttackOnceResult, tbTempNotify)
    self.StartAttackPos = nil
    self.StartAttackDir = nil
    logdebug("weapon bow lz 6")
end

function HumanWeaponBow:OnCancel()
    self:SetRepAttackSubState(AttackSubState.IDLE)
end

function HumanWeaponBow:CheatAttack(Target, szDamageType, nHoldTime)
    self.CheatAttackTarget = Target
    self.szCheatAttackDamageType = szDamageType
    
    log("[HumanWeaponBow] CheatAttack")
    CheatPreAttack(self, nHoldTime)
end

function HumanWeaponBow:CancelCheatAttack()
    if (not self.bServer) or (not AIHelper.IsAIControlled(self.Owner)) then
        return
    end

    self:SetRepAttackSubState(AttackSubState.IDLE)

    Timer.StopOwnerAllTimer(self, true)
end

function HumanWeaponBow:GetRemainReloadingTime()
    local nReloadTime = HumanWeaponBow.super.GetRemainReloadingTime(self)
    local nCurrentSubState = self:GetRepAttackSubState()

    -- 当前没在装弹但是在攻击要加上装弹时间
    if nCurrentSubState ~= AttackSubState.IDLE and nReloadTime == 0 then
        local nPlayRate = self:GetOwnerProperty(PropName.nReloadCoefficient)
        nReloadTime = nReloadTime + self:GetProperty().nReloadTime * nPlayRate
    end

    -- 加上当前SubState的时间
    local BowAttackSubStateTimer = Timer.GetOwnerTimer(self, BOW_ATTACK_SUB_STATE_TIMER)
    if BowAttackSubStateTimer then
        nReloadTime = nReloadTime + BowAttackSubStateTimer:GetRemainingTime()
    end

    -- 如果当前SubState是PreAttack或MidAttack要加上PostAttack的时间
    if nCurrentSubState == AttackSubState.PRE_ATTACK or nCurrentSubState == AttackSubState.MID_ATTACK then
        nReloadTime = nReloadTime + BOW_POST_ATTACK_TIME
    end

    return nReloadTime


end

function HumanWeaponBow:GetRemainingPreAttackTime()
    if self:GetRepAttackSubState() ~= AttackSubState.PRE_ATTACK then
        return 0
    end

    local BowAttackSubStateTimer = Timer.GetOwnerTimer(self, BOW_ATTACK_SUB_STATE_TIMER)
    if not BowAttackSubStateTimer then
        return 0
    end

    return BowAttackSubStateTimer:GetRemainingTime()
end

function HumanWeaponBow:Reload(nTime)
    logdebug("weapon bow lz 7")
    self:SetRepAttackSubState(AttackSubState.IDLE)
    return HumanWeaponBow.super.Reload(self, nTime)
end

function HumanWeaponBow:OnServerUnHolded()
    self:SetRepAttackSubState(AttackSubState.IDLE)
    HumanWeaponBow.super.OnServerUnHolded(self)
end

function HumanWeaponBow:SetRepAttackSubState(nState)
    if nState == AttackSubState.PRE_ATTACK then
        HumanWeaponHelper.ServerAttackEvent(self.Owner, self.nInstanceId)
    end
    return HumanWeaponBow.super.SetRepAttackSubState(self, nState)
end

return HumanWeaponBow