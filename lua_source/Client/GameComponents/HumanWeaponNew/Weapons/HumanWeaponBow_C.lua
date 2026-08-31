local luaclass = require("luaclass")
local HumanWeaponBow = require("HumanWeaponBow")
local HumanWeaponBow_C = luaclass("HumanWeaponBow_C", HumanWeaponBow)
local HumanWeaponMisc = require("HumanWeaponMisc")
local HumanWeaponHelper = require("HumanWeaponHelper")
local HumanWeaponType = require("HumanWeaponType")
local HumanWeaponStateDef = require("HumanWeaponStateDef")
local HumanWeaponCalculator = require("HumanWeaponCalculator")
local Timer = require("Timer")
local EventManager = require("EventManager")
local ClientEventDef = require("ClientEventDef")
local PropName = require("PropName")
local AttackSubState = HumanWeaponMisc.AttackSubState
local AnimDef = require("AnimDef")

-- local szHoldedSocket = "BowHoldedSocket"
-- local szUnHoldedSocket = "BowUnHoldedSocket"


local PRE_ATTACK_TIMER= "PreAttackTimer"

HumanWeaponBow_C.bNeedPlayAttackMontage = false
HumanWeaponBow_C.nStartAttackTime = 0

-- local szPreAttackSection = "Attack"
function HumanWeaponBow_C:GetWeaponBPType()
    return HumanWeaponType.Bow
end 

-- function HumanWeaponBow_C:GetHoldSocketName()
--     return szHoldedSocket
-- end 

-- function HumanWeaponBow_C:GetUnholdSocketName()
--     return szUnHoldedSocket
-- end 

local function GetCurrentPreAttackKey(self)
    return self.bAiming and AnimDef.ON_BOW_AIM_PRE_ATTACK or AnimDef.ON_BOW_PRE_ATTACK  
end

local function CancelCurrentAttack(self)
    self.pWeaponActor:SetUseParentBone(false)
    local szPreKey = GetCurrentPreAttackKey(self)
    self.OwnerComponent:StopCurrentMontage(szPreKey) 
    self.Owner.pUEActor:SetPreAttack(false)
end

local function GetCurrentPostAttackKey(self)
    return self.bAiming and AnimDef.ON_BOW_AIM_POST_ATTACK or AnimDef.ON_BOW_POST_ATTACK
end
local PreAttackTime = 0
local nMaxAccumulateTime = 1
local function PreAttackInClient(self, tbAttackInfo, tbSubInfo)
    self.pWeaponActor:SetUseParentBone(true)
    self.nStartAttackTime = KismetSystemLibrary.GetGameTimeInSeconds(GWorld)
    local szPreKey = GetCurrentPreAttackKey(self)
    local pMontage = self.OwnerComponent:GetMontageWithAnimKey(szPreKey, true)

    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)

    -- local nMontageTime = ExtendBlueprintFunctions.GetMontageLength(pMontage) / nAttackCoefficient

    local nTime = ExtendBlueprintFunctions.GetMontageSectionLength(pMontage, AnimDef.SectionName.BOW_ATTACK_START) / nAttackCoefficient

    local nLoopTime, _ = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.BOW_ATTACK_LOOP) 
    nLoopTime = nLoopTime / nAttackCoefficient
    nMaxAccumulateTime = nLoopTime - nTime


    self.OwnerComponent:PlayMontageWithAnimKey(szPreKey, nAttackCoefficient)

    self.Owner.pUEActor:SetPreAttack(true)

    PreAttackTime = nTime
    Timer.StartOwnerTimer(self, PRE_ATTACK_TIMER, nil, PreAttackTime)
    -- logdebug("nMaxAccumulateTime", nMaxAccumulateTime, nLoopTime, nTime)
    
    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, true, PreAttackTime, nMaxAccumulateTime)
    
    HumanWeaponHelper.HumanAttackSubstateRequest(self.nInstanceId, AttackSubState.PRE_ATTACK)
    logdebug("pre attack bow lzz1")
    self.nCurrentAttackSubState = AttackSubState.PRE_ATTACK
end 

local function PreAttackFinished(self, tbAttackInfo, bCancel, tbSubInfo)
    if bCancel then  
        EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, false)
        CancelCurrentAttack(self)
        HumanWeaponHelper.SendCancelBowAttack(self.nInstanceId)
        return 
    end
end 

local function MidAttackInClient(self, tbAttackInfo, tbSubInfo)
    local tbTimer = Timer.GetOwnerTimer(self, PRE_ATTACK_TIMER)
    local nTime = 0
    if tbTimer then  
        nTime = tbTimer:GetRemainingTime()
    end 
    self.nAccumulateTime = 0
    -- 前摇已经完整结束
    if nTime <= 0 then 
        self.nAccumulateTime =  (KismetSystemLibrary.GetGameTimeInSeconds(GWorld) - self.nStartAttackTime - PreAttackTime) / nMaxAccumulateTime
        if self.nAccumulateTime > 1 then  
            self.nAccumulateTime = 1
        end 
    end 
    
    --tbSubInfo.bCanDeactivateExternally = self.bAiming

    local szPostKey = GetCurrentPostAttackKey(self)
    self.Owner.pUEActor:SetPreAttack(false)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    local pMontage = self.OwnerComponent:GetMontageWithAnimKey(szPostKey, true)
    local nFireTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.WAND_FIRE) / nAttackCoefficient
    
    local PlayMidAttackAnim = function()
        self.Owner.pUEActor:SetPreAttack(false)
        self.pWeaponActor:SetUseParentBone(false)
        self.OwnerComponent:PlayMontageWithAnimKey(szPostKey, nAttackCoefficient)
        if self.nCurrentAttackSubState ~= AttackSubState.POST_ATTACK then
            HumanWeaponHelper.HumanAttackSubstateRequest(self.nInstanceId, AttackSubState.MID_ATTACK)
        end
    end

    if nTime and nTime > 0 then
        Timer.StopOwnerTimer(self, PRE_ATTACK_TIMER)
        Timer.StartOwnerTimer(self, PRE_ATTACK_TIMER, PlayMidAttackAnim, nTime)
    else
        PlayMidAttackAnim()
    end

    tbSubInfo.nDuration = nTime + nFireTime
    self.nCurrentAttackSubState = AttackSubState.MID_ATTACK
end 

local function MidOnAttackFinished(self, tbAttackInfo, bCancel, tbSubInfo)

    EventManager:OnFireEvent(ClientEventDef.EV_HUMAN_WEAPON_ACCUMULATE, false)

    if bCancel then  
        self.pWeaponActor:SetUseParentBone(false)
        return 
    end
    self:AttackInClient()
end 

local function PostAttackInClient(self, tbAttackInfo, tbSubInfo)
    self.pWeaponActor:SetUseParentBone(false)
    local szPostKey = GetCurrentPostAttackKey(self)
    self.Owner.pUEActor:SetPreAttack(false)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    local pMontage = self.OwnerComponent:GetMontageWithAnimKey(szPostKey, true)
    local nTime = ExtendBlueprintFunctions.GetMontageLength(pMontage) / nAttackCoefficient
    local nFireTime = ExtendBlueprintFunctions.GetMontageSectionStartEndTime(pMontage, AnimDef.SectionName.WAND_FIRE) / nAttackCoefficient
    tbSubInfo.nDuration = nTime - nFireTime
    self.nCurrentAttackSubState = AttackSubState.POST_ATTACK
end 

function HumanWeaponBow_C:OnHumanBowPreAttact()
    self.pWeaponActor:SetUseParentBone(true)
    local szPreKey = GetCurrentPreAttackKey(self)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    self.OwnerComponent:PlayMontageWithAnimKey(szPreKey, nAttackCoefficient)
    self.Owner.pUEActor:SetPreAttack(true)
end 

function HumanWeaponBow_C:OnRepHumanBowMidAttact()
    self.pWeaponActor:SetUseParentBone(false)

    local szPostKey = GetCurrentPostAttackKey(self)
    local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    self.OwnerComponent:PlayMontageWithAnimKey(szPostKey, nAttackCoefficient)
    self.Owner.pUEActor:SetPreAttack(false)
end 

function HumanWeaponBow_C:OnRepGunAttackRoute(tbRepData)
    if not self.pWeaponActor then 
        return 
    end
    if tbRepData then 
        self.nAccumulateTime = tbRepData.accumulate_time
    else 
        self.nAccumulateTime = 0
        return
    end

    -- logdebug("self.nAccumulateTime", self.nAccumulateTime)
    self:FillBPAttackParams(nil)
    HumanWeaponBow_C.super.OnRepGunAttackRoute(self, tbRepData)

    -- self.pWeaponActor:SetUseParentBone(false)

    -- local szPostKey = GetCurrentPostAttackKey(self)
    -- local nAttackCoefficient = self:GetOwnerProperty(PropName.nAttackCoefficient)
    -- self.OwnerComponent:PlayMontageWithAnimKey(szPostKey, nAttackCoefficient)
    self.Owner.pUEActor:SetPreAttack(false)
end 

function HumanWeaponBow_C:OnCreated(OwnerComponent, nInstanceId, nTemplateId, nSlot)
    HumanWeaponBow_C.super.OnCreated(self, OwnerComponent, nInstanceId, nTemplateId, nSlot)
    self.bAutoClearReload = false
    -- self.pWeaponActor:ReloadClient()

    local tbPreSubAttackInfo = {
        OnActivate = PreAttackInClient,   -- 攻击，子类重载
        OnDeactivate = PreAttackFinished,
        nDuration = nil,                          -- 持续时间
        bCanDeactivateExternally = true,
    }
    local tbMidSubAttackInfo = {
        OnActivate = MidAttackInClient,   -- 攻击，子类重载
        OnDeactivate = MidOnAttackFinished,   -- 攻击结束
        nDuration = nil,                          -- 持续时间
        bCanDeactivateExternally = false,
    }    
    local tbPostSubAttackInfo = {
        OnActivate = PostAttackInClient,   -- 攻击，子类重载
        nDuration = nil,                          -- 持续时间
        bCanDeactivateExternally = false,
    }    
    -- self:AddAttackSubState(self.tbAttackInfo, self.tbSubAttackInfo)    
    self.tbAttackInfo[1] = tbPreSubAttackInfo
    self.tbAttackInfo[2] = tbMidSubAttackInfo
    self.tbAttackInfo[3] = tbPostSubAttackInfo
    self.tbAttackInfo.nStateCount = 3
end


function HumanWeaponBow_C:OnAimChanged(bAiming)
    HumanWeaponBow_C.super.OnAimChanged(self, bAiming)

    

    if self.pWeaponActor then
        self.pWeaponActor:SetUseParentBone(bAiming)
        HumanWeaponHelper.ChangeWeaponActorStateForAim(self.Owner, self.pWeaponActor.ReloadArrow, bAiming)
    end
end

function HumanWeaponBow_C:OnDestroyed()
    Timer.StopOwnerAllTimer(self, true)
    HumanWeaponBow_C.super.OnDestroyed(self)
end

function HumanWeaponBow_C:GenerateAttackInfo()
    local tbAttackInfo = HumanWeaponBow_C.super.GenerateAttackInfo(self)
    tbAttackInfo.nExitTypeWhenFinish = HumanWeaponMisc.AttackExitType.ALL_STATE_FINISHED
    return tbAttackInfo
end 

function HumanWeaponBow_C:OnStateActivate(nState)
    HumanWeaponBow_C.super.OnStateActivate(self, nState)

    if(nState == HumanWeaponStateDef.HOLDING or nState == HumanWeaponStateDef.HOLDED) then
        -- if(self:GetCurrentAmmo() ~= 0) then
            self.nCurrentAttackSubState = AttackSubState.IDLE
            self.pWeaponActor:ReloadClient()

            if self.pWeaponActor then
                HumanWeaponHelper.ChangeWeaponActorStateForAim(self.Owner, self.pWeaponActor.ReloadArrow, self.bAiming)
            end
        -- end
    elseif(nState == HumanWeaponStateDef.UNHOLDING or nState == HumanWeaponStateDef.UNHOLDED) then
        self.Owner.pUEActor:SetPreAttack(false)
        -- Timer.StopOwnerAllTimer(self, true)
        Timer.StopOwnerTimer(self, PRE_ATTACK_TIMER)

        self.pWeaponActor:ClearReload()
        self.pWeaponActor:SetUseParentBone(false)
    end
end

function HumanWeaponBow_C:OnStateDeactivate(nState, bCancel)
    HumanWeaponBow_C.super.OnStateDeactivate(self, nState, bCancel)
    if(nState == HumanWeaponStateDef.ATTACKING) then
        local szPreKey = GetCurrentPreAttackKey(self)
        self.OwnerComponent:StopCurrentMontage(szPreKey)
    end
end

function HumanWeaponBow_C:RequestGunAttackRoute(StartPose, ShotDir, bMultiEnd, tbIndexes)
    HumanWeaponHelper.SendGunAttackRoute(self.nInstanceId, StartPose, ShotDir, bMultiEnd, self.nAccumulateTime, tbIndexes)
end 

function HumanWeaponBow_C:FillBPAttackParams(tbAttackInfo)
    -- 这块先这么凑合吧，从蓝图挪过来太累
    HumanWeaponBow_C.super.FillBPAttackParams(self, nil)
    local pWeaponActor = self.pWeaponActor
    local bAim = self.bAiming
    local tbWeaponProperty = self:GetProperty()

    local SpreadAngle = HumanWeaponCalculator.CalculateSpreadAngle(self.OwnerComponent.Owner, tbWeaponProperty, self.nAccumulateTime * self:GetOwnerProperty(PropName.nBulletDispersionMagnification))
    pWeaponActor.BulletSpeed = self:GetOwnerProperty(PropName.nBulletInitialSpeed) * (1 + self.nAccumulateTime * self:GetOwnerProperty(PropName.nBulletSpeedMagnification))

    local nDispersionRatio = self:GetOwnerProperty(PropName.nDispersionRatio)
    SpreadAngle.X = SpreadAngle.X * nDispersionRatio
    SpreadAngle.Y = SpreadAngle.Y * nDispersionRatio
    pWeaponActor.SpreadAngle = SpreadAngle

    pWeaponActor.DeviationX = bAim and tbWeaponProperty.nAimDeviationX or tbWeaponProperty.nDeviationX
    pWeaponActor.DeviationY = bAim and tbWeaponProperty.nAimDeviationY or tbWeaponProperty.nDeviationY
    pWeaponActor.DeviationX = pWeaponActor.DeviationX * nDispersionRatio
    pWeaponActor.DeviationY = pWeaponActor.DeviationY * nDispersionRatio
end

function HumanWeaponBow_C:OnRepAttackSubState(nState)
    logdebug("on rep sub stata lz")
    HumanWeaponBow_C.super.OnRepAttackSubState(self, nState)

    if self.nCurrentAttackSubState == nState then
        return false
    end

    if self.nCurrentAttackSubState == AttackSubState.MID_ATTACK and nState ~= AttackSubState.POST_ATTACK then
        -- 攻击中只能切 post attack
        return false
    end

    if nState == AttackSubState.PRE_ATTACK then 
        self:OnHumanBowPreAttact()
    end

    if nState == AttackSubState.MID_ATTACK or (nState == AttackSubState.POST_ATTACK and self.nCurrentAttackSubState ~= AttackSubState.MID_ATTACK) then
        self:OnRepHumanBowMidAttact()
    end

    -- 取消
    if self.nCurrentAttackSubState == AttackSubState.PRE_ATTACK and nState == AttackSubState.IDLE then
        local nWeaponState = self.OwnerComponent:GetCurrentState()
        if nWeaponState == HumanWeaponStateDef.HOLDING or nWeaponState == HumanWeaponStateDef.ATTACKING or nWeaponState == HumanWeaponStateDef.HOLDED then
            CancelCurrentAttack(self)
        end
    end

    self.nCurrentAttackSubState = nState

end

return HumanWeaponBow_C